import { useEffect, useState, type FormEvent } from "react";
import type { Navigate } from "../App";
import { useAuth } from "./AuthProvider";

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

export default function AccountPage({ go }: { go: Navigate }) {
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

  useEffect(() => {
    let active = true;
    setAccount(null);
    setAccountUnavailable(false);
    setError("");
    setMessage("");

    if (!auth.session?.access_token) return () => { active = false; };

    void fetch("/api/v1/me", {
      headers: { Authorization: `Bearer ${auth.session.access_token}` },
      cache: "no-store",
    }).then(async (response) => {
      const result = await response.json() as CurrentAccount | { error?: string; message?: string };
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
  }, [auth.session?.access_token]);

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
        const confirmationRequired = await auth.signUp(displayName, email, password);
        setMessage(confirmationRequired
          ? "Account created. Check the local test inbox for the confirmation message, then return here to sign in."
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
      setMessage("If an account matches that email address, a recovery link has been sent to the local test inbox.");
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
      setMessage("You are signed out.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "We could not sign you out.");
    } finally {
      setSubmitting(false);
    }
  }

  return <div className="proto-account-page">
    <div className="proto-account-intro">
      <p className="proto-eyebrow"><span />SECURE ACCOUNT FOUNDATION · PHASE 1B</p>
      <h1>Your account, <em>with care.</em></h1>
      <p>Sign in to view your account profile. This early build uses a local synthetic database; it is not connected to the official live website or real learner records.</p>
    </div>

    {!auth.configured ? <section className="proto-panel proto-account-card">
      <span className="proto-account-icon">i</span>
      <h2>Account sign-in is not connected on this public preview.</h2>
      <p>This is an intentional safety state. The public preview can show the real website interface, while account authentication and permission tests run against the local synthetic database in the development environment.</p>
      <p>No password or account details should be entered here.</p>
      <button className="proto-action secondary" type="button" onClick={() => go("home")}>← Back to homepage</button>
    </section> : auth.loading ? <section className="proto-panel proto-account-card" role="status">Checking your sign-in status…</section> : auth.session && accountUnavailable ? <section className="proto-panel proto-account-card">
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
      <div className="proto-account-roles">
        <small>ACTIVE ROLE(S)</small>
        {account?.roles.length ? account.roles.map(role => <span key={role}>{role.replaceAll("_", " ")}</span>) : <em>Loading role assignment…</em>}
      </div>
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
        <div><p className="proto-eyebrow"><span />LOCAL AUTHENTICATION</p><h2>{mode === "sign-in" ? "Welcome back." : "Create a student account."}</h2></div>
        <span className="proto-account-status">Synthetic data</span>
      </div>
      <p className="proto-account-description">New sign-ups receive Student access only. Guardian, Grader, Admin and Owner roles cannot be selected here.</p>
      <form className="proto-account-form" onSubmit={submitAuth}>
        {mode === "sign-up" && <label>Display name<input autoComplete="name" value={displayName} onChange={event => setDisplayName(event.target.value)} maxLength={80} required minLength={2} /></label>}
        <label>Email address<input type="email" autoComplete="email" value={email} onChange={event => setEmail(event.target.value)} required /></label>
        <label>Password<input type="password" autoComplete={mode === "sign-in" ? "current-password" : "new-password"} value={password} onChange={event => setPassword(event.target.value)} minLength={mode === "sign-up" ? 12 : 1} required /></label>
        {mode === "sign-up" && <small className="proto-account-hint">Use at least 12 characters. This local-only test setup does not send real email.</small>}
        <button className="proto-action" type="submit" disabled={submitting}>{submitting ? "Please wait…" : mode === "sign-in" ? "Sign in" : "Create account"}</button>
      </form>
      {mode === "sign-in" && <button className="proto-account-toggle" type="button" onClick={() => { setMode("recovery-request"); setError(""); setMessage(""); }}>Forgot password?</button>}
      <button className="proto-account-toggle" type="button" onClick={() => { setMode(mode === "sign-in" ? "sign-up" : "sign-in"); setError(""); setMessage(""); setPassword(""); }}>
        {mode === "sign-in" ? "New to the local test? Create a synthetic student account." : "Already have a local test account? Sign in."}
      </button>
    </section>}

    {error && <p className="proto-account-feedback error" role="alert">{error}</p>}
    {message && <p className="proto-account-feedback success" role="status">{message}</p>}
    <p className="proto-account-footnote">Prototype security boundary: account access is verified by the server and database. A role label or hidden button in the page is never used as a security check.</p>
  </div>;
}
