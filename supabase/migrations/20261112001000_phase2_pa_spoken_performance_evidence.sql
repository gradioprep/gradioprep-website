-- Private, append-only staff evidence for the live Speaking/Presenting assessment.
-- An outline card is not sufficient to demonstrate oral performance; observations
-- must come from an authenticated, currently assigned human assessor at AAL2.
-- This record never enters a learner report or creates a score without separate review.
CREATE TABLE private.pa_spoken_performance_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_record_id uuid NOT NULL REFERENCES public.evaluation_report_records(id) ON DELETE CASCADE,
  report_version_id uuid NOT NULL,
  assessor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  presentation_observation text NOT NULL CHECK (char_length(btrim(presentation_observation)) BETWEEN 20 AND 2000),
  followup_observation text NOT NULL CHECK (char_length(btrim(followup_observation)) BETWEEN 20 AND 2000),
  observed_live boolean NOT NULL CHECK (observed_live = true),
  recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY (report_version_id,report_record_id)
    REFERENCES public.evaluation_report_versions(id,report_record_id) ON DELETE RESTRICT
);
CREATE INDEX pa_spoken_evidence_report_idx
  ON private.pa_spoken_performance_evidence(report_record_id,recorded_at,id);
ALTER TABLE private.pa_spoken_performance_evidence ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.pa_spoken_performance_evidence FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER pa_spoken_evidence_immutable
  BEFORE UPDATE OR DELETE ON private.pa_spoken_performance_evidence
  FOR EACH ROW EXECUTE FUNCTION private.prevent_pa_feedback_draft_mutation();

CREATE OR REPLACE FUNCTION public.record_pa_spoken_performance(
  p_report_record_id uuid,p_report_version_id uuid,
  p_presentation_observation text,p_followup_observation text,p_observed_live boolean
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  assessment public.evaluation_report_records%ROWTYPE;
  newest_version_id uuid;
  stored_id uuid;
BEGIN
  IF p_report_record_id IS NULL
    OR NOT private.can_author_pa_report_draft(p_report_record_id) THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_spoken_evidence_forbidden';
  END IF;
  IF p_report_version_id IS NULL OR p_observed_live IS DISTINCT FROM true
    OR p_presentation_observation IS NULL
    OR char_length(btrim(p_presentation_observation)) NOT BETWEEN 20 AND 2000
    OR p_followup_observation IS NULL
    OR char_length(btrim(p_followup_observation)) NOT BETWEEN 20 AND 2000 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_spoken_evidence';
  END IF;
  SELECT r.* INTO assessment FROM public.evaluation_report_records AS r
    WHERE r.id=p_report_record_id AND r.report_scope='pa_baseline';
  IF NOT FOUND OR assessment.diagnostic_attempt_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_spoken_report_not_found';
  END IF;
  SELECT v.id INTO newest_version_id FROM public.evaluation_report_versions AS v
    WHERE v.report_record_id=p_report_record_id
    ORDER BY v.version_number DESC LIMIT 1;
  IF newest_version_id IS DISTINCT FROM p_report_version_id THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_spoken_report_version_changed';
  END IF;
  -- A separately captured SP01 outline must belong to this exact PA attempt.
  -- Written notes never substitute for the two witnessed oral observations.
  IF NOT EXISTS (
    SELECT 1 FROM public.diagnostic_attempts AS a
    JOIN public.diagnostic_observations AS o
      ON o.diagnostic_version_id=a.diagnostic_version_id
      AND o.observation_code='SP01' AND o.group_code='SP'
    JOIN public.diagnostic_response_versions AS response
      ON response.attempt_id=a.id AND response.observation_id=o.id
    WHERE a.id=assessment.diagnostic_attempt_id
      AND a.learner_id=assessment.learner_id AND a.status='submitted'
  ) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_spoken_outline_missing';
  END IF;
  INSERT INTO private.pa_spoken_performance_evidence(
    report_record_id,report_version_id,assessor_id,
    presentation_observation,followup_observation,observed_live
  ) VALUES(p_report_record_id,p_report_version_id,auth.uid(),
    btrim(p_presentation_observation),btrim(p_followup_observation),true)
    RETURNING id INTO stored_id;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_spoken_evidence_recorded','pa_spoken_evidence',stored_id,
    'success','private_human_observation');
  RETURN stored_id;
END;
$$;
ALTER FUNCTION public.record_pa_spoken_performance(uuid,uuid,text,text,boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_pa_spoken_performance(uuid,uuid,text,text,boolean)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.record_pa_spoken_performance(uuid,uuid,text,text,boolean)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.get_pa_spoken_performance(p_report_record_id uuid)
RETURNS TABLE(evidence_id uuid,report_version_id uuid,assessor_id uuid,
  presentation_observation text,followup_observation text,recorded_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF p_report_record_id IS NULL OR NOT private.can_author_pa_report_draft(p_report_record_id) THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_spoken_evidence_forbidden';
  END IF;
  RETURN QUERY SELECT e.id,e.report_version_id,e.assessor_id,
    e.presentation_observation,e.followup_observation,e.recorded_at
    FROM private.pa_spoken_performance_evidence AS e
    WHERE e.report_record_id=p_report_record_id
    ORDER BY e.recorded_at,e.id;
END;
$$;
ALTER FUNCTION public.get_pa_spoken_performance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_pa_spoken_performance(uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_pa_spoken_performance(uuid) TO authenticated;
COMMENT ON TABLE private.pa_spoken_performance_evidence IS
  'Private human-witnessed, unscored, append-only oral performance evidence; never learner-exposed, recorded as media or published without human approval.';
