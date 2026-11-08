# Phase 1F — Operational Security Runbooks

**Version:** 0.1-draft  
**Date:** 8 November 2026  
**Status:** Seven required runbooks documented; operational activation and Founder/security review remain outstanding.

## 1. Scope and safety boundary

These runbooks define the minimum response sequence for the seven operational scenarios required by the Secure Application Foundation specification. They are written for future authorised operation; they do not imply that hosted Supabase, R2, production monitoring, external email, encryption-key custody, a deletion worker, or a production restore service has been provisioned.

The current verified implementation is a synthetic-data foundation. The local backup verifier runs only inside disposable GitHub-hosted CI. It is not a hosted backup service and must not be used to restore production data. The account-closure feature records approvals, legal holds and a retention inventory; it does not physically erase learner records or external Storage objects.

**Non-negotiable incident rules**

- Use named accounts and the strongest available authentication. Do not share passwords, recovery codes, service-role keys or encryption keys.
- Preserve non-content evidence: UTC timestamps, request/correlation IDs, actor and role, affected resource IDs, action/outcome categories, object checksums, and relevant provider event IDs.
- Never copy learner answers, PDF bytes, signed URLs, invitation tokens, passwords, MFA secrets or service credentials into tickets, chat, email or screenshots.
- Do not delete, rewrite or “clean up” audit evidence during an investigation.
- Restrict access before attempting repair. Record who authorised each containment and recovery action.
- Involve the designated privacy/legal adviser before deciding notification, disclosure, statutory retention or legal-hold questions.
- If a required control or provider capability is unavailable, stop the affected operation and escalate. Do not bypass RLS, audit, MFA, legal-hold or retention safeguards.

Each runbook must be adapted to the final approved provider configuration, named on-call roles, contact channels, legal requirements and recovery targets before real learner data is enabled.

## 2. Compromised account, session or role

**Trigger:** A user reports account takeover; a staff session behaves unexpectedly; MFA/recovery factors may be compromised; an unauthorised role or assignment is suspected.

1. Open an incident record and note the time detected, affected account ID, relevant request IDs, observed role and suspected actions. Do not include the user's content.
2. Notify the security/operations owner through the approved incident channel. For a suspected staff or Owner account compromise, use an independent trusted account; do not rely on the suspected account.
3. Contain access using the approved Auth session-revocation and account-suspension controls. Revoke any exposed staff role or assignment through the authorised role-management workflow. Require AAL2 for privileged changes.
4. If the system cannot reliably revoke the session or role, disable the affected protected route/workflow using the approved operational control and escalate. Do not attempt direct production SQL or grant broader service-role access.
5. Verify from a separate clean session that the old session is rejected, the revoked role no longer authorises protected operations, and unrelated learner access remains denied.
6. Recover identity only after the account owner is independently verified. Reset credentials and compromised MFA/recovery factors using the approved Auth process; require fresh MFA enrolment where appropriate.
7. Review audit records for the incident window, preserve relevant non-content evidence and identify potentially affected records. Ask qualified counsel to assess notification duties.
8. Close only when access has been contained, recovery is verified, affected roles/assignments are correct, evidence is retained and follow-up actions have owners.

**Do not:** assume a password reset automatically invalidates every existing session; reuse a shared staff account; disclose MFA seeds or recovery codes; restore a role merely because a user requests it.

## 3. Leaked key, token or secret rotation

**Trigger:** A credential appears in source control, logs, build output, a ticket, chat, a browser bundle or an untrusted device; a provider reports credential misuse.

1. Record the secret type, affected service/environment, first known exposure time, discovery time and related provider/request IDs. Never paste the value into the incident record.
2. Treat the credential as compromised immediately. Identify its scope using provider metadata and access logs; do not test the value by sharing it or making exploratory requests.
3. Revoke or rotate it in the owning provider's authorised console. Prefer a newly scoped, least-privilege credential. Keep production and Preview credentials separate.
4. Update only the approved secret store or GitHub Actions/Worker secret configuration for the relevant environment. Use the normal protected deployment/release process; production changes require the separate production approval gate.
5. Verify that the former credential is rejected and that the replacement supports only the intended operation. Check for unexpected use during the exposure window.
6. Remove accidental copies from active logs/artifacts and restrict access to the incident evidence. Do not assume deleting a Git commit, comment or message makes a leaked credential safe.
7. Search the repository and relevant build/log surfaces for further exposure without reproducing the secret in reports. Revoke related credentials if their trust boundary may also have been exposed.
8. Record rotation time, credential identifier/fingerprint (not value), scope, verifier, affected environments and any residual exposure. Close after misuse review and corrective actions.

**Do not:** rotate by pasting a key into source code, commit a replacement secret, grant broader permissions to “make it work”, or publish token values in CI output. Any production secret rotation must follow its separately authorised change procedure.

## 4. Suspected cross-learner access or data disclosure

**Trigger:** A learner or staff member sees a record/file outside their authorised scope; a guessed ID or API route returns another learner's data; an audit alert indicates an ownership/assignment mismatch.

1. Treat the event as a potential confidentiality incident. Record UTC time, request ID, actor ID/role, route, target record/file ID, outcome and how the issue was detected. Do not copy the exposed content.
2. Alert the security/operations owner immediately. Preserve relevant audit and provider access metadata before routine log expiry.
3. Contain the narrowest affected route, object-access path or workflow using an approved feature/traffic control. If safe containment is unavailable, disable the affected protected operation and escalate. Do not widen permissions or change RLS to restore availability.
4. Revoke any suspected compromised sessions/roles and remove unauthorised assignments through approved workflows.
5. Reproduce only with synthetic fixtures in the isolated test environment. Check the affected RLS policy, Worker authorization, RPC grants, Storage policy and signed-link path. Add a regression test before re-enabling the affected operation.
6. Establish the scope using IDs, timestamps, request IDs, audit outcomes and provider access metadata. Determine whether access was merely attempted, denied, or actually successful.
7. Obtain qualified privacy/legal advice on affected-user assessment and any notification obligation. Communicate through approved channels only.
8. Re-enable only after a reviewed fix passes the relevant security tests and an independent authorised person confirms the cross-learner denial.

**Do not:** send a learner's PDF or answer text to an external scanning/AI service; use real learner records to reproduce the incident; delete audit entries; describe a denied attempt as a confirmed disclosure.

## 5. Malicious, malformed or abusive PDF upload

**Trigger:** A PDF is malformed, encrypted, oversized, unexpectedly executable/active, repeatedly uploaded for abuse, or associated with suspicious activity.

1. Record the request ID, synthetic/production environment, account ID, submission/file metadata ID, safe rejection category, byte size, page count and checksum where available. Do not attach the file to the incident ticket.
2. Stop any further processing of the affected object. Prevent access using the approved private-object quarantine/restriction procedure; preserve the original object and metadata where lawful and safe.
3. Do not open the file on a staff workstation. Do not render, OCR, upload or forward it to a third-party scanning or analysis service unless that processor and data-transfer path have been separately approved.
4. Check that upload validation rejected the file and that no accepted file version or learner-facing signed URL was created. Verify that object access remains private and cross-learner reads remain denied.
5. Preserve the checksum, opaque object/file ID, request ID, validation outcome and relevant system version. Keep the file itself in its approved restricted evidence location only if retention is authorised.
6. Review repeated attempts, rate-limit signals and affected account/session state. Revoke compromised access if warranted.
7. Exercise cleanup only through the approved lifecycle workflow, after confirming whether the object is required as incident evidence and whether a legal hold applies.
8. Close when the object is contained, no unauthorised access is indicated or the disclosure assessment is complete, abuse controls are reviewed, and regression coverage exists.

**Do not:** make the object public to inspect it; overwrite an accepted original; record PDF bytes, extracted text or signed URLs in audit events; bypass the existing size/page/type validation.

## 6. Database or Storage outage and restore

**Trigger:** The database, Auth, Storage API or private-object service is unavailable, corrupted, or cannot safely serve protected operations.

1. Record the affected service, UTC start time, provider incident ID, environment and user-visible impact. Use non-content diagnostics only.
2. Fail closed for affected protected reads/writes. Do not serve stale private data or fall back to public object URLs. Notify the designated operations owner.
3. Determine whether the issue is an application regression, provider outage, credentials/configuration error or data-integrity event using approved provider health and logs.
4. Confirm the approved backup source, timestamp, integrity evidence, encryption state and recoverability before choosing a restore point. Record the authorised restore point and expected data-loss window.
5. **Current limitation:** the repository's verified restore procedure is synthetic/local CI only. Hosted database backup automation, encrypted object backup, key custody and production recovery have not been approved or proven. Do not run the local verifier against production or treat it as a production restore procedure.
6. Until a hosted restore procedure and credentials are separately approved and tested, escalate to the provider's authorised support/recovery process and keep affected operations disabled. Do not improvise direct production SQL, copy objects to a personal device or restore over the live database.
7. For a future approved restore, restore into an isolated target first; verify migrations/schema, RLS grants and policies, role/ownership boundaries, private Storage configuration, object checksums and application health before any traffic cutover.
8. Obtain explicit incident-owner approval for the recovery point, privacy/legal review where data location or disclosure may be affected, and a second-person verification before re-opening access.
9. Close with timeline, restore point, validation results, data-loss assessment, residual issues and a tested corrective-action plan.

**Do not:** interpret a passing synthetic backup/restore test as proof of hosted disaster recovery, encryption/key custody, RPO/RTO or real-data restoration.

## 7. Failed deletion, retention review or legal hold

**Trigger:** An approved closure cannot proceed; a retention item is stuck; a legal authority or dispute requires preservation; physical deletion is uncertain or an external object remains.

1. Record the deletion-request ID, subject account ID, request state, retention item IDs, object metadata IDs, timestamps and relevant audit/request IDs. Do not copy learner content.
2. Stop the affected deletion execution. If a legal hold is active or plausibly applicable, preserve the data and evidence; do not continue a destructive step while authority is being clarified.
3. Verify the hold's authority category/reference, reason summary, placing actor, review due date and release evidence through the authorised Owner+AAL2 workflow.
4. Do not release a hold or change retention dates merely to clear a queue. Obtain qualified legal/privacy review and a documented decision from the authorised approver.
5. Reconcile the request ledger and retention inventory against the relevant source-record and private-object metadata. Distinguish database state from actual object deletion.
6. **Current limitation:** the implemented workflow creates deletion requests, approval/closure state, legal-hold records and retention inventory. It does not physically erase learner rows or Storage/R2 objects and does not provide a scheduled deletion runner. Do not mark an account as fully erased based on ledger status alone.
7. For a failed or partial future deletion, preserve audit evidence, record each completed/pending item, and resume only through the approved idempotent deletion worker after hold status and retention eligibility are rechecked.
8. Require a second-person verification of the deletion inventory and object-provider confirmation before recording physical deletion as complete. Preserve any legally required minimal evidence.
9. Close only when legal hold disposition is documented, every in-scope item has an evidenced retained/deleted state, backup expiry is separately confirmed, and the user-facing status is accurate.

**Do not:** delete held content, erase audit/legal evidence, interpret a retention-plan row as proof of physical erasure, or release a hold without authority.

## 8. Backup integrity failure or recovery-key loss

**Trigger:** A backup checksum/manifest mismatch occurs; an archive is corrupt; a restore validation fails; an encryption key or key-recovery material is unavailable or suspected compromised.

1. Stop the restore and any automated overwrite/rotation that could destroy the only known-good copy. Record archive ID, manifest version, expected/observed checksum, backup timestamp, tool version and safe error category.
2. Preserve the original backup and manifest in restricted storage. Make a separate forensic copy only through the approved evidence process; do not edit the original.
3. Verify the checksum and object inventory independently. Determine whether the failure is transfer corruption, incomplete backup, schema incompatibility, object mismatch or a key-access problem.
4. Do not repeatedly attempt unknown keys, paste key material into tickets/chat, or store a recovery key beside the backup it protects.
5. If key compromise is suspected, follow the secret-rotation runbook and involve the designated key custodian. If the key is merely unavailable, use only the approved recovery-key custody process. Do not invent or bypass key recovery.
6. Select another known-good backup only after its integrity and recovery point are verified. If none can be verified, stop and escalate to the security/operations owner and provider.
7. **Current limitation:** the synthetic CI archive is explicitly unencrypted and local-only. Hosted backup encryption, key separation, custody, rotation and recovery-key drills remain deferred pending architecture, privacy and cost approval.
8. For a future approved restore, validate archive integrity before restore, then verify database policy/permission effectiveness and private-object checksums in an isolated target. A matching object count or schema snapshot alone is insufficient.
9. Close only after a known-good recovery path is demonstrated, key-custody issues are resolved, affected backups are accounted for and the runbook is updated with verified recovery evidence.

**Do not:** label an unencrypted synthetic CI dump as an encrypted backup; destroy the only source archive; claim recovery-key recovery is available until it has been tested.

## 9. Minimum incident record and readiness checklist

Every incident record should contain only:

- Incident ID, severity, UTC detection/containment/recovery times and incident owner.
- Affected environment/service and system version/commit.
- Actor ID/role, request/correlation IDs, opaque record/object IDs and safe outcome/reason categories.
- Provider incident/event IDs and checksum/manifest identifiers, where relevant.
- Containment and recovery actions, authoriser and independent verifier.
- Privacy/legal assessment owner and decision reference, without learner content.
- Regression test, corrective-action owner, due date and closure approval.

Before enabling real learner data, the Founder and designated security/privacy reviewers must confirm: named on-call contacts; provider-specific session and secret rotation steps; approved monitoring and escalation channels; hosted backup and key custody; tested database/object restore; physical deletion and legal-hold execution; retention and backup expiry; incident evidence access controls; and applicable legal/privacy notices.

**Acceptance boundary:** this document supplies the seven required procedural runbooks. It does not close hosted/production readiness or authorise any of those operations. Phase 1F acceptance still requires code/test evidence, a completed source-to-test crosswalk, review of these procedures, and explicit Founder acceptance. Real learner data, hosted provisioning, paid usage, external processors, DNS changes, production deployment and PR merge remain separately gated.
