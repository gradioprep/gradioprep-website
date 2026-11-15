-- Step 8: full 30-observation PA may never publish feedback-only.
-- The qualified Founder remains the sole academic reviewer. This protects
-- existing verified scoring/teacher-report lineage, not approval authority.
ALTER FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid)
  RENAME TO publish_pa_evaluation_feedback_pre_scored_gate;
REVOKE ALL ON FUNCTION public.publish_pa_evaluation_feedback_pre_scored_gate(uuid,uuid)
  FROM PUBLIC,anon,authenticated,service_role;

-- Preserve the previous partial-fixture feedback-only pathway and idempotency
-- while requiring the separate joint scoring-and-feedback release for any full
-- thirty-observation baseline. Keep the underlying legacy operation unreachable
-- by authenticated clients: the secure wrapper is the only public entry point.
CREATE FUNCTION public.publish_pa_evaluation_feedback(
  p_review_id uuid,p_idempotency_key uuid
)
RETURNS TABLE(report_record_id uuid,report_version_id uuid,version_number integer,is_replay boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  base public.evaluation_report_versions%ROWTYPE;
  observation_count integer;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_feedback_publication_forbidden';
  END IF;
  SELECT v.* INTO base
  FROM private.pa_evaluation_feedback_reviews r
  JOIN public.evaluation_report_versions v
    ON v.id=r.report_version_id AND v.report_record_id=r.report_record_id
  WHERE r.id=p_review_id AND v.report_scope='pa_baseline';
  IF FOUND THEN
    SELECT count(*)::integer INTO observation_count
    FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(base.content_snapshot->'observations')='array'
        THEN base.content_snapshot->'observations'
        ELSE '[]'::jsonb END);
    IF observation_count=30 THEN
      RAISE EXCEPTION USING ERRCODE='55000',
        MESSAGE='pa_full_instrument_requires_scored_report';
    END IF;
  END IF;
  RETURN QUERY SELECT x.report_record_id,x.report_version_id,x.version_number,x.is_replay
    FROM public.publish_pa_evaluation_feedback_pre_scored_gate(
      p_review_id,p_idempotency_key
    ) x;
END;
$$;
ALTER FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid)
  TO authenticated;
COMMENT ON FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid) IS
 'Owner+AAL2 only: partial PA feedback-only legacy pathway; complete 30-observation PA requires joint human scoring and feedback via publish_approved_pa_scored_report.';
