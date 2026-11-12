import { useEffect, useRef, useState, type FormEvent } from "react";
import type { Navigate } from "../App";
import { useAuth } from "./AuthProvider";
import LearnerSubmissionPanel from "./LearnerSubmissionPanel";
import LearnerAttemptPanel from "./LearnerAttemptPanel";
import DiagnosticPanel from "./DiagnosticPanel";
import TranscriptReviewPanel from "./TranscriptReviewPanel";
import GraderWorkspacePanel from "./GraderWorkspacePanel";
import PaFeedbackWorkspacePanel from "./PaFeedbackWorkspacePanel";

type AccountMode = "sign-in" | "sign-up" | "recovery-request";

interface CurrentAccount {
  user: { id: string };
  profile: {
    user_id: string;
    display_name: string;
    account_status: string;
    created_at: string;
  } | null;
  roles: string[];
}

interface StaffInvitation {
  invitation_id: string;
  invited_email: string;
  invited_role: "grader" | "admin";
  created_at: string;
  expires_at: string;
  accepted_at: string | null;
  revoked_at: string | null;
  status: "pending" | "accepted" | "revoked" | "expired";
}

interface CreatedStaffInvitation {
  invitation_id: string;
  invited_email: string;
  invited_role: "grader" | "admin";
  created_at: string;
  expires_at: string;
}

export default function AccountPage({
  go,
  onEvaluationReportReady,
  onOpenEvaluationReport,
}: {
  go: Navigate;
  onEvaluationReportReady: (reportRecordId: string) => void;
  onOpenEvaluationReport: () => void;
}) {
  const auth = useAuth();
  const [mode, setMode] = useState<AccountMode>("sign-in");
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [newDisplayName, setNewDisplayName] = useState("");
  const [account, setAccount] = useState<CurrentAccount | null>(null);
  const [accountUnavailable, setAccountUnavailable] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [mfaCode, setMfaCode] = useState("");
  const [totpEnrollment, setTotpEnrollment] = useState<{
    factorId: string;
    qrCode: string;
    secret: string;
  } | null>(null);
  const [staffInviteToken, setStaffInviteToken] = useState("");
  const [acceptingStaffInvite, setAcceptingStaffInvite] = useState(false);
  const [staffInvitations, setStaffInvitations] = useState<StaffInvitation[]>([]);
  const [staffInvitationsLoading, setStaffInvitationsLoading] = useState(false);
  const [staffInviteEmail, setStaffInviteEmail] = useState("");
  const [staffInviteRole, setStaffInviteRole] = useState<"grader" | "admin">("grader");
  const [newStaffInviteUrl, setNewStaffInviteUrl] = useState("");
  const invitationClaimStarted = useRef(false);

  useEffect(() => {
    const consumeStaffInvitationFragment = () => {
      const fragment = new URLSearchParams(window.location.hash.replace(/^#/, ""));
      const token = fragment.get("staff-invite") ?? "";
      if (!token) return;

      // Remove the one-time bearer token from the visible URL and browser history.
      window.history.replaceState(window.history.state, "", window.location.pathname + window.location.search);
      if (/^[A-Za-z0-9_-]{43}$/.test(token)) setStaffInviteToken(token);
      else setError("This staff invitation link is invalid.");
    };

    // Handle both an invitation link on initial page load and a link opened
    // while this account route is already mounted (a same-document hash change).
    consumeStaffInvitationFragment();
    window.addEventListener("hashchange", consumeStaffInvitationFragment);
    return () => window.removeEventListener("hashchange", consumeStaffInvitationFragment);
  }, []);

  useEffect(() => {
    let active = true;
    setAccount(null);
    setAccountUnavailable(false);

    if (!auth.session?.access_token || auth.passwordRecovery || auth.mfaLoading || auth.mfaChallengeRequired || auth.mfaStatusError) {
      return () => { active = false; };
    }

    void fetch("/api/v1/me", {
      headers: { Authorization: `Bearer ${auth.session.access_token}` },
      cache: "no-store",
    }).then(async (response) => {
      const result = await response.json() as CurrentAccount | { error?: string; code?: string; message?: string };
      if (!response.ok) {
        if (response.status === 401 && "error" in result && result.code === "session_revoked") {
          // A different device may have globally signed out this account. Clear
          // this browser's stale local session so the learner can sign in again.
          await auth.signOut("local").catch(() => undefined);
          return;
        }
        if (response.status === 403 && "error" in result && result.error === "account_unavailable") {
          if (active) {
            setAccount(null);
            setAccountUnavailable(true);
            setError("");
            setMessage("");
          }
          return;
        }
        throw new Error("message" in result && result.message
          ? result.message
          : "The account profile could not be loaded.");
      }
      if (active) {
        const current = result as CurrentAccount;
        setAccount(current);
        setNewDisplayName(current.profile?.display_name ?? "");
      }
    }).catch((requestError: unknown) => {
      if (active) setError(requestError instanceof Error ? requestError.message : "The account profile could not be loaded.");
    });

    return () => { active = false; };
  }, [auth.session?.access_token, auth.passwordRecovery, auth.mfaLoading, auth.mfaChallengeRequired, auth.mfaStatusError]);

  const ownerRole = account?.roles.includes("owner") ?? false;
  const graderRole = account?.roles.includes("grader") ?? false;
  const transcriptReviewRole = ownerRole ? "owner" : null;

  useEffect(() => {
    const accessToken = auth.session?.access_token;
    if (!ownerRole || !accessToken || auth.mfaLoading || auth.mfaCurrentLevel !== "aal2" || auth.mfaChallengeRequired) {
      setStaffInvitations([]);
      setStaffInvitationsLoading(false);
      return;
    }
    let active = true;
    setStaffInvitationsLoading(true);
    void fetch("/api/v1/admin/staff-invitations", {
      headers: { Authorization: "Bearer " + accessToken },
      cache: "no-store",
    }).then(async response => {
      const result = await response.json() as { invitations?: StaffInvitation[]; message?: string };
      if (!response.ok) throw new Error(result.message ?? "Staff invitations could not be loaded.");
      if (active) setStaffInvitations(Array.isArray(result.invitations) ? result.invitations : []);
    }).catch(requestError => {
      if (active) setError(requestError instanceof Error ? requestError.message : "Staff invitations could not be loaded.");
    }).finally(() => {
      if (active) setStaffInvitationsLoading(false);
    });
    return () => { active = false; };
  }, [ownerRole, auth.session?.access_token, auth.mfaLoading, auth.mfaCurrentLevel, auth.mfaChallengeRequired]);

  useEffect(() => {
    const accessToken = auth.session?.access_token;
    if (!staffInviteToken || !accessToken || !account || auth.mfaLoading ||
      auth.mfaChallengeRequired || auth.mfaCurrentLevel !== "aal2" || invitationClaimStarted.current) return;
    invitationClaimStarted.current = true;
    setAcceptingStaffInvite(true);
    void fetch("/api/v1/staff-invitations/accept", {
      method: "POST",
      headers: {
        Authorization: "Bearer " + accessToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ token: staffInviteToken }),
    }).then(async response => {
      const result = await response.json() as { accepted?: boolean; role?: string; message?: string };
      if (!response.ok || !result.accepted || !result.role) {
        throw new Error(result.message ?? "The staff invitation could not be accepted.");
      }
      setAccount(current => current
        ? { ...current, roles: Array.from(new Set([...current.roles, result.role!])) }
        : current);
      setStaffInviteToken("");
      setMessage("Staff invitation accepted. Your " + result.role + " role is active.");
    }).catch(requestError => {
      setError(requestError instanceof Error ? requestError.message : "The staff invitation could not be accepted.");
      invitationClaimStarted.current = false;
    }).finally(() => {
      setAcceptingStaffInvite(false);
    });
  }, [
    staffInviteToken,
    auth.session?.access_token,
    account?.user.id,
    auth.mfaLoading,
    auth.mfaChallengeRequired,
    auth.mfaCurrentLevel,
  ]);

  async function submitAuth(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setError("");
    setMessage("");

    try {
      if (mode === "sign-up") {
        if (displayName.trim().length < 2) {
          throw new Error("Enter a display name with at least two characters.");
        }
        if (password.length < 12) {
          throw new Error("Use a password with at least 12 characters.");
        }
        const confirmationRequired = await auth.signUp(displayName, email, password, staffInviteToken || undefined);
        setMessage(confirmationRequired
          ? "Account created. Check your email for the confirmation message, then return here to sign in."
          : "Account created. Your default Student access is ready.");
      } else {
        await auth.signIn(email, password);
        setPassword("");
      }
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "We could not complete that request.");
    } finally {
      setSubmitting(false);
    }
  }

  async function requestPasswordReset(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      await auth.requestPasswordReset(email);
      // Keep the response identical for known and unknown addresses.
      setMessage("If an account matches that email address, a password recovery link has been sent.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "We could not request a password reset.");
    } finally {
      setSubmitting(false);
    }
  }

  async function completePasswordReset(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      if (password.length < 12) throw new Error("Use a password with at least 12 characters.");
      if (password !== confirmPassword) throw new Error("The passwords do not match.");
      await auth.updatePassword(password);
      setPassword("");
      setConfirmPassword("");
      setMessage("Password updated. You are signed in with your new password.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Your password could not be updated.");
    } finally {
      setSubmitting(false);
    }
  }

  async function verifyMfaChallenge(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const factor = auth.mfaFactors.find(item => item.status === "verified");
    if (!factor) {
      setError("No verified authenticator was found for this account. Contact the project administrator.");
      return;
    }
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      await auth.verifyTotp(factor.id, mfaCode);
      setMfaCode("");
      setMessage("Sign-in verified.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The authenticator code could not be verified.");
    } finally {
      setSubmitting(false);
    }
  }

  async function startTotpEnrollment() {
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      const enrollment = await auth.enrollTotp("GradiPrep authenticator");
      setTotpEnrollment(enrollment);
      setMfaCode("");
      setMessage("Scan the QR code with your authenticator app, or enter the setup key manually.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Authenticator setup could not be started.");
    } finally {
      setSubmitting(false);
    }
  }

  async function completeTotpEnrollment(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!totpEnrollment) return;
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      if (!/^\d{6}$/.test(mfaCode.trim())) throw new Error("Enter the six-digit code from your authenticator app.");
      await auth.verifyTotp(totpEnrollment.factorId, mfaCode.trim());
      setTotpEnrollment(null);
      setMfaCode("");
      setMessage("Authenticator app enabled and verified.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The authenticator could not be verified.");
    } finally {
      setSubmitting(false);
    }
  }

  async function cancelPendingTotpEnrollment() {
    const pendingFactorId = totpEnrollment?.factorId ??
      auth.mfaFactors.find(factor => factor.status !== "verified")?.id;
    if (!pendingFactorId) return;
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      await auth.unenrollMfaFactor(pendingFactorId);
      setTotpEnrollment(null);
      setMfaCode("");
      setMessage("Authenticator setup cancelled.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The unfinished authenticator setup could not be cancelled.");
    } finally {
      setSubmitting(false);
    }
  }

  async function removeTotpFactor(factorId: string) {
    if (staffRole && verifiedTotpFactors.length <= 1) {
      setError("Add and verify a second authenticator before removing this factor from a staff account.");
      return;
    }
    if (!window.confirm("Remove this authenticator from your account?")) return;
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      await auth.unenrollMfaFactor(factorId);
      setMessage("Authenticator removed.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The authenticator could not be removed.");
    } finally {
      setSubmitting(false);
    }
  }

  async function createStaffInvitation(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!auth.session?.access_token) return;
    setSubmitting(true);
    setError("");
    setMessage("");
    setNewStaffInviteUrl("");
    try {
      const response = await fetch("/api/v1/admin/staff-invitations", {
        method: "POST",
        headers: {
          Authorization: "Bearer " + auth.session.access_token,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email: staffInviteEmail.trim(), role: staffInviteRole }),
      });
      const result = await response.json() as { invitation?: CreatedStaffInvitation; invite_url?: string; message?: string };
      if (!response.ok || !result.invitation || !result.invite_url) {
        throw new Error(result.message ?? "The staff invitation could not be created.");
      }
      setNewStaffInviteUrl(result.invite_url);
      setStaffInviteEmail("");
      const createdInvitation: StaffInvitation = {
        ...result.invitation,
        accepted_at: null,
        revoked_at: null,
        status: "pending",
      };
      setStaffInvitations(current => {
        const existing = Array.isArray(current)
          ? current.filter(item => item.invitation_id !== createdInvitation.invitation_id)
          : [];
        return [createdInvitation, ...existing];
      });
      setMessage("Invitation link created. Copy it now; it will not be shown again after you leave this page.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The staff invitation could not be created.");
    } finally {
      setSubmitting(false);
    }
  }

  async function copyStaffInvitationLink() {
    if (!newStaffInviteUrl) return;
    try {
      await navigator.clipboard.writeText(newStaffInviteUrl);
      setMessage("Invitation link copied.");
    } catch {
      setMessage("Clipboard access is unavailable. Select the invitation link field and copy it manually.");
    }
  }

  async function revokeStaffInvitation(invitationId: string, invitedEmail: string) {
    if (!auth.session?.access_token) return;
    if (!window.confirm("Revoke the staff invitation for " + invitedEmail + "?")) return;
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/admin/staff-invitations/" + encodeURIComponent(invitationId) + "/revoke", {
        method: "POST",
        headers: {
          Authorization: "Bearer " + auth.session.access_token,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ reason: "Owner revoked pending invitation" }),
      });
      const result = await response.json() as { message?: string };
      if (!response.ok) throw new Error(result.message ?? "The staff invitation could not be revoked.");
      setStaffInvitations(current => current.map(invitation => invitation.invitation_id === invitationId
        ? { ...invitation, status: "revoked", revoked_at: new Date().toISOString() }
        : invitation));
      setMessage("Staff invitation revoked.");
      setNewStaffInviteUrl("");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The staff invitation could not be revoked.");
    } finally {
      setSubmitting(false);
    }
  }

  async function saveDisplayName(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!auth.session?.access_token) return;
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/me", {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${auth.session.access_token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ display_name: newDisplayName }),
      });
      const result = await response.json() as { error?: string; profile?: CurrentAccount["profile"]; message?: string };
      if (!response.ok || !result.profile) {
        if (response.status === 403 && result.error === "account_unavailable") setAccountUnavailable(true);
        throw new Error(result.message ?? "Your display name could not be saved.");
      }
      setAccount((current) => current ? { ...current, profile: result.profile ?? null } : current);
      setMessage("Display name saved.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Your profile could not be saved.");
    } finally {
      setSubmitting(false);
    }
  }

  async function signOut() {
    setSubmitting(true);
    setError("");
    setMessage("");
    try {
      await auth.signOut();
      setAccount(null);
      setAccountUnavailable(false);
      setNewStaffInviteUrl("");
      setMessage("You are signed out.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "We could not sign you out.");
    } finally {
      setSubmitting(false);
    }
  }

  const verifiedTotpFactors = auth.mfaFactors.filter(factor => factor.status === "verified");
  const pendingTotpFactors = auth.mfaFactors.filter(factor => factor.status !== "verified");
  const staffRole = account?.roles.some(role => ["grader", "admin", "owner"].includes(role)) ?? false;
  const invitationNeedsMfa = Boolean(staffInviteToken && auth.mfaCurrentLevel !== "aal2");

  return <div className="proto-account-page">
    <div className="proto-account-intro">
      <p className="proto-eyebrow"><span />YOUR ACCOUNT</p>
      <h1>Your account, <em>with care.</em></h1>
      <p>Sign in to view your account profile and manage your learning information.</p>
    </div>

    {!auth.configured ? <section className="proto-panel proto-account-card">
      <span className="proto-account-icon">i</span>
      <h2>Account access is currently unavailable.</h2>
      <p>Please return to the homepage and try again later.</p>
      <p></p>
      <button className="proto-action secondary" type="button" onClick={() => go("home")}>← Back to homepage</button>
    </section> : auth.loading ? <section className="proto-panel proto-account-card" role="status">Checking your sign-in status…</section> : auth.session && auth.mfaLoading ? <section className="proto-panel proto-account-card" role="status">Checking account security…</section> : auth.session && auth.mfaStatusError ? <section className="proto-panel proto-account-card">
      <h2>Account security is unavailable.</h2>
      <p>{auth.mfaStatusError}</p>
      <button className="proto-account-signout" type="button" onClick={signOut} disabled={submitting}>Sign out</button>
    </section> : auth.session && auth.mfaChallengeRequired ? <section className="proto-panel proto-account-card">
      <div className="proto-account-card-heading">
        <div><p className="proto-eyebrow"><span />SECURE SIGN-IN</p><h2>Verify your sign-in.</h2></div>
        <span className="proto-account-status">Second factor</span>
      </div>
      <p className="proto-account-description">Enter the six-digit code from your authenticator app to complete sign-in.</p>
      {staffInviteToken && <p className="proto-account-invitation-note">After secure sign-in is complete, the invitation will be checked against this account's verified email address.</p>}
      <form className="proto-account-form" onSubmit={verifyMfaChallenge}>
        <label>Authenticator code<input type="text" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} value={mfaCode} onChange={event => setMfaCode(event.target.value.replace(/\D/g, "").slice(0, 6))} required /></label>
        <button className="proto-action" type="submit" disabled={submitting || mfaCode.length !== 6 || !auth.mfaFactors.some(factor => factor.status === "verified")}>{submitting ? "Please wait…" : "Verify code"}</button>
      </form>
      <button className="proto-account-signout" type="button" onClick={signOut} disabled={submitting}>Sign out</button>
    </section> : auth.session && accountUnavailable ? <section className="proto-panel proto-account-card">
      <span className="proto-account-icon">i</span>
      <h2>Account access is unavailable.</h2>
      <p>This account cannot access protected GradiPrep records. Sign out to leave this session.</p>
      <button className="proto-account-signout" type="button" onClick={signOut} disabled={submitting}>Sign out</button>
    </section> : auth.session && auth.passwordRecovery ? <section className="proto-panel proto-account-card">
      <div className="proto-account-card-heading">
        <div><p className="proto-eyebrow"><span />ACCOUNT RECOVERY</p><h2>Choose a new password.</h2></div>
        <span className="proto-account-status">Secure reset</span>
      </div>
      <p className="proto-account-description">Use at least 12 characters. Your password is managed by the secure sign-in service.</p>
      <form className="proto-account-form" onSubmit={completePasswordReset}>
        <label>New password<input type="password" autoComplete="new-password" value={password} onChange={event => setPassword(event.target.value)} minLength={12} required /></label>
        <label>Confirm new password<input type="password" autoComplete="new-password" value={confirmPassword} onChange={event => setConfirmPassword(event.target.value)} minLength={12} required /></label>
        <button className="proto-action" type="submit" disabled={submitting}>{submitting ? "Please wait…" : "Update password"}</button>
      </form>
      <button className="proto-account-toggle" type="button" onClick={signOut} disabled={submitting}>Cancel and sign out</button>
    </section> : auth.session ? <section className="proto-panel proto-account-card">
      <div className="proto-account-card-heading">
        <div><p className="proto-eyebrow"><span />SIGNED-IN ACCOUNT</p><h2>{account?.profile?.display_name ?? "Your account"}</h2></div>
        <span className="proto-account-status">{account?.profile?.account_status ?? "Loading"}</span>
      </div>
      <p className="proto-account-email">{auth.session.user.email}</p>
      {staffInviteToken && <section className="proto-account-invitation-note" aria-live="polite">
        <strong>Staff invitation pending</strong>
        <p>{acceptingStaffInvite
          ? "Checking your invitation…"
          : invitationNeedsMfa
            ? "Verify your email and complete authenticator verification to accept this invitation. No staff role is active yet."
            : "Your verified account is being checked against the invitation."}</p>
      </section>}
      <div className="proto-account-roles">
        <small>ACTIVE ROLE(S)</small>
        {account?.roles.length ? account.roles.map(role => <span key={role}>{role.replaceAll("_", " ")}</span>) : <em>Loading role assignment…</em>}
      </div>
      {account?.roles.includes("student") && auth.session?.access_token && (
        <>
          <DiagnosticPanel
            accessToken={auth.session.access_token}
            onEvaluationReportReady={onEvaluationReportReady}
            onOpenEvaluationReport={onOpenEvaluationReport}
          />
          <LearnerAttemptPanel accessToken={auth.session.access_token} />
          <LearnerSubmissionPanel accessToken={auth.session.access_token} />
        </>
      )}
      <section className="proto-account-security" aria-labelledby="proto-account-security-heading">
        <div className="proto-account-security-heading">
          <div><p className="proto-eyebrow"><span />ACCOUNT SECURITY</p><h3 id="proto-account-security-heading">Authenticator app</h3></div>
          <span className="proto-account-status">{verifiedTotpFactors.length ? "Verified" : staffRole ? "Required for staff" : "Optional"}</span>
        </div>
        {staffRole && !verifiedTotpFactors.length && <p>An authenticator app must be verified before this account can use protected staff actions.</p>}
        {!staffRole && !verifiedTotpFactors.length && <p>Add a time-based code from an authenticator app for an extra sign-in check.</p>}
        {totpEnrollment ? <div className="proto-account-security-setup">
          <p>Scan this code using an authenticator app. Keep the setup key private and do not share it with anyone.</p>
          <img className="proto-account-security-qr" src={totpEnrollment.qrCode} alt="Authenticator app setup QR code" />
          <p className="proto-account-security-key-label">Manual setup key</p>
          <code className="proto-account-security-key" data-testid="totp-secret">{totpEnrollment.secret}</code>
          <form className="proto-account-form" onSubmit={completeTotpEnrollment}>
            <label>Authenticator code<input type="text" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} value={mfaCode} onChange={event => setMfaCode(event.target.value.replace(/\D/g, "").slice(0, 6))} required /></label>
            <button className="proto-action" type="submit" disabled={submitting || mfaCode.length !== 6}>{submitting ? "Please wait…" : "Verify and enable"}</button>
          </form>
          <button className="proto-account-toggle" type="button" onClick={cancelPendingTotpEnrollment} disabled={submitting}>Cancel setup</button>
        </div> : verifiedTotpFactors.length ? <div className="proto-account-security-factors">
          {verifiedTotpFactors.map(factor => <div className="proto-account-security-factor" key={factor.id}>
            <span><strong>{factor.friendlyName}</strong><small>Verified authenticator</small></span>
            <button className="proto-account-toggle" type="button" onClick={() => removeTotpFactor(factor.id)} disabled={submitting || auth.mfaCurrentLevel !== "aal2" || (staffRole && verifiedTotpFactors.length <= 1)}>Remove</button>
          </div>)}
          <p>Removing a factor refreshes the session assurance level. Protected staff actions remain blocked until a verified factor is available.</p>
        </div> : pendingTotpFactors.length ? <div className="proto-account-security-setup">
          <p>An authenticator setup is unfinished. Cancel it before starting a new setup.</p>
          <button className="proto-account-toggle" type="button" onClick={cancelPendingTotpEnrollment} disabled={submitting}>Cancel pending setup</button>
        </div> : <button className="proto-action" type="button" onClick={startTotpEnrollment} disabled={submitting}>{submitting ? "Please wait…" : "Set up authenticator app"}</button>}
      </section>
      {ownerRole && <section className="proto-account-invitations" aria-labelledby="proto-account-invitations-heading">
        <div className="proto-account-invitations-heading">
          <div>
            <p className="proto-eyebrow"><span />OWNER CONTROLS</p>
            <h3 id="proto-account-invitations-heading">Staff invitations</h3>
          </div>
          <span className="proto-account-status">{auth.mfaCurrentLevel === "aal2" ? "MFA verified" : "MFA required"}</span>
        </div>
        {auth.mfaCurrentLevel !== "aal2"
          ? <p>Verify your authenticator app before creating, viewing or revoking staff invitations.</p>
          : <>
            <p>Invite an existing team member as a Grader or Admin. Each link is single-use, expires after seven days and must be accepted with the matching verified email and authenticator check. Create a secure invitation link here, then share it directly with the intended team member.</p>
            <form className="proto-account-invite-form" onSubmit={createStaffInvitation}>
              <label>Staff email address
                <input type="email" autoComplete="off" value={staffInviteEmail} onChange={event => setStaffInviteEmail(event.target.value)} maxLength={320} required />
              </label>
              <label>Invitation role
                <select value={staffInviteRole} onChange={event => setStaffInviteRole(event.target.value as "grader" | "admin")}>
                  <option value="grader">Grader</option>
                  <option value="admin">Admin</option>
                </select>
              </label>
              <button className="proto-action" type="submit" disabled={submitting || !staffInviteEmail.trim()}>
                {submitting ? "Please wait…" : "Create invitation link"}
              </button>
            </form>
            {newStaffInviteUrl && <div className="proto-account-invite-link">
              <label htmlFor="proto-staff-invite-url">One-time invitation link</label>
              <input id="proto-staff-invite-url" data-testid="staff-invite-url" type="url" value={newStaffInviteUrl} readOnly onFocus={event => event.currentTarget.select()} />
              <button className="proto-account-toggle" type="button" onClick={() => void copyStaffInvitationLink()}>Copy link</button>
              <small>Share this invitation only with the team member it was created for.</small>
            </div>}
            <div className="proto-account-invitation-list" aria-label="Staff invitation list">
              <h4>Recent invitations</h4>
              {staffInvitationsLoading ? <p role="status">Loading invitations…</p> : staffInvitations.length === 0
                ? <p>No invitations yet.</p>
                : staffInvitations.map(invitation => <article className="proto-account-invitation-row" key={invitation.invitation_id}>
                  <div>
                    <strong>{invitation.invited_email}</strong>
                    <small>{invitation.invited_role === "grader" ? "Grader" : "Admin"} · Expires {new Date(invitation.expires_at).toLocaleString()}</small>
                    <span className={"proto-account-invitation-status " + invitation.status}>{invitation.status.charAt(0).toUpperCase() + invitation.status.slice(1)}</span>
                  </div>
                  {invitation.status === "pending" && <button className="proto-account-toggle" type="button"
                    aria-label={"Revoke invitation for " + invitation.invited_email}
                    onClick={() => void revokeStaffInvitation(invitation.invitation_id, invitation.invited_email)}
                    disabled={submitting}>Revoke</button>}
                </article>)}
            </div>
          </>}
      </section>}
      {(ownerRole || graderRole) && auth.session?.access_token && (
        <PaFeedbackWorkspacePanel
          accessToken={auth.session.access_token}
          assuranceLevel={auth.mfaCurrentLevel}
          owner={ownerRole}
        />
      )}
      {graderRole && auth.session?.access_token && (
        <GraderWorkspacePanel
          accessToken={auth.session.access_token}
          assuranceLevel={auth.mfaCurrentLevel}
        />
      )}
      {transcriptReviewRole && auth.session?.access_token && (
        <TranscriptReviewPanel
          accessToken={auth.session.access_token}
          role={transcriptReviewRole}
          assuranceLevel={auth.mfaCurrentLevel}
        />
      )}
      <form className="proto-account-form" onSubmit={saveDisplayName}>
        <label>Display name<input value={newDisplayName} onChange={event => setNewDisplayName(event.target.value)} maxLength={80} required minLength={1} /></label>
        <button className="proto-action" type="submit" disabled={submitting || !account}>Save display name</button>
      </form>
      <button className="proto-account-signout" type="button" onClick={signOut} disabled={submitting}>Sign out</button>
    </section> : mode === "recovery-request" ? <section className="proto-panel proto-account-card">
      <div className="proto-account-card-heading">
        <div><p className="proto-eyebrow"><span />ACCOUNT RECOVERY</p><h2>Reset your password.</h2></div>
        <span className="proto-account-status">Private link</span>
      </div>
      <p className="proto-account-description">Enter your account email address. We will show the same confirmation whether or not an account matches it.</p>
      <form className="proto-account-form" onSubmit={requestPasswordReset}>
        <label>Email address<input type="email" autoComplete="email" value={email} onChange={event => setEmail(event.target.value)} required /></label>
        <button className="proto-action" type="submit" disabled={submitting}>{submitting ? "Please wait…" : "Send recovery link"}</button>
      </form>
      <button className="proto-account-toggle" type="button" onClick={() => { setMode("sign-in"); setError(""); setMessage(""); }}>Back to sign in</button>
    </section> : <section className="proto-panel proto-account-card">
      <div className="proto-account-card-heading">
        <div><p className="proto-eyebrow"><span />ACCOUNT ACCESS</p><h2>{mode === "sign-in" ? "Welcome back." : "Create a student account."}</h2></div>
        <span className="proto-account-status"></span>
      </div>
      <p className="proto-account-description">New sign-ups receive Student access only. Guardian, Grader, Admin and Owner roles cannot be selected here.</p>
      {staffInviteToken && <p className="proto-account-invitation-note">This is a staff invitation. Sign in or create an account using the invited email address, verify that email, then set up an authenticator app. No staff role is assigned until the server confirms every check.</p>}
      <form className="proto-account-form" onSubmit={submitAuth}>
        {mode === "sign-up" && <label>Display name<input autoComplete="name" value={displayName} onChange={event => setDisplayName(event.target.value)} maxLength={80} required minLength={2} /></label>}
        <label>Email address<input type="email" autoComplete="email" value={email} onChange={event => setEmail(event.target.value)} required /></label>
        <label>Password<input type="password" autoComplete={mode === "sign-in" ? "current-password" : "new-password"} value={password} onChange={event => setPassword(event.target.value)} minLength={mode === "sign-up" ? 12 : 1} required /></label>
        {mode === "sign-up" && <small className="proto-account-hint">Use at least 12 characters.</small>}
        <button className="proto-action" type="submit" disabled={submitting}>{submitting ? "Please wait…" : mode === "sign-in" ? "Sign in" : "Create account"}</button>
      </form>
      {mode === "sign-in" && <button className="proto-account-toggle" type="button" onClick={() => { setMode("recovery-request"); setError(""); setMessage(""); }}>Forgot password?</button>}
      <button className="proto-account-toggle" type="button" onClick={() => { setMode(mode === "sign-in" ? "sign-up" : "sign-in"); setError(""); setMessage(""); setPassword(""); }}>
        {mode === "sign-in" ? "New to GradioPrep? Create a student account." : "Already have an account? Sign in."}
      </button>
    </section>}

    {error && <p className="proto-account-feedback error" role="alert">{error}</p>}
    {message && <p className="proto-account-feedback success" role="status">{message}</p>}
    <p className="proto-account-footnote">Your account access and permissions are protected.</p>
  </div>;
}
