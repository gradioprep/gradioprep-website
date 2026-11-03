import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import type { Session } from "@supabase/supabase-js";
import { isSupabaseConfigured, supabase } from "../lib/supabase";

export interface AuthMfaFactor {
  id: string;
  friendlyName: string;
  status: string;
}

export interface TotpEnrollment {
  factorId: string;
  qrCode: string;
  secret: string;
}

type AuthenticatorLevel = "aal1" | "aal2";

interface AuthContextValue {
  configured: boolean;
  loading: boolean;
  session: Session | null;
  passwordRecovery: boolean;
  mfaFactors: AuthMfaFactor[];
  mfaCurrentLevel: AuthenticatorLevel;
  mfaNextLevel: AuthenticatorLevel;
  mfaLoading: boolean;
  mfaStatusError: string;
  mfaChallengeRequired: boolean;
  refreshMfaStatus: () => Promise<void>;
  enrollTotp: (friendlyName: string) => Promise<TotpEnrollment>;
  verifyTotp: (factorId: string, code: string) => Promise<void>;
  unenrollMfaFactor: (factorId: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (displayName: string, email: string, password: string, staffInviteToken?: string) => Promise<boolean>;
  requestPasswordReset: (email: string) => Promise<void>;
  updatePassword: (password: string) => Promise<void>;
  signOut: (scope?: "global" | "local") => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [passwordRecovery, setPasswordRecovery] = useState(false);
  const [mfaFactors, setMfaFactors] = useState<AuthMfaFactor[]>([]);
  const [mfaCurrentLevel, setMfaCurrentLevel] = useState<AuthenticatorLevel>("aal1");
  const [mfaNextLevel, setMfaNextLevel] = useState<AuthenticatorLevel>("aal1");
  const [mfaLoading, setMfaLoading] = useState(true);
  const [mfaStatusError, setMfaStatusError] = useState("");

  async function refreshMfaStatus() {
    if (!supabase || !session?.access_token) {
      setMfaFactors([]);
      setMfaCurrentLevel("aal1");
      setMfaNextLevel("aal1");
      setMfaStatusError("");
      setMfaLoading(false);
      return;
    }

    setMfaLoading(true);
    setMfaStatusError("");
    try {
      const [factorResult, assuranceResult] = await Promise.all([
        supabase.auth.mfa.listFactors(),
        supabase.auth.mfa.getAuthenticatorAssuranceLevel(),
      ]);
      if (factorResult.error) throw factorResult.error;
      if (assuranceResult.error) throw assuranceResult.error;

      setMfaFactors(factorResult.data.totp.map((factor) => ({
        id: factor.id,
        friendlyName: factor.friendly_name || "Authenticator app",
        status: factor.status,
      })));
      setMfaCurrentLevel(assuranceResult.data.currentLevel === "aal2" ? "aal2" : "aal1");
      setMfaNextLevel(assuranceResult.data.nextLevel === "aal2" ? "aal2" : "aal1");
    } catch {
      setMfaFactors([]);
      setMfaCurrentLevel("aal1");
      setMfaNextLevel("aal2");
      setMfaStatusError("Account security settings could not be checked. Sign out and try again; protected staff actions remain blocked.");
    } finally {
      setMfaLoading(false);
    }
  }

  useEffect(() => {
    if (!supabase) {
      setSession(null);
      setPasswordRecovery(false);
      setMfaFactors([]);
      setMfaCurrentLevel("aal1");
      setMfaNextLevel("aal1");
      setMfaStatusError("");
      setMfaLoading(false);
      setLoading(false);
      return;
    }

    let active = true;
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, nextSession) => {
      if (active) {
        if (event === "PASSWORD_RECOVERY") setPasswordRecovery(true);
        if (event === "SIGNED_OUT") {
          setPasswordRecovery(false);
          setMfaFactors([]);
          setMfaCurrentLevel("aal1");
          setMfaNextLevel("aal1");
          setMfaLoading(false);
        }
        // Auth profile updates (including password recovery) do not always
        // change the access token. Do not leave the security gate loading when
        // the token-dependent assurance refresh will not run.
        if (nextSession && event !== "USER_UPDATED") setMfaLoading(true);
        setSession(nextSession);
        setLoading(false);
      }
    });

    void supabase.auth.getSession().then(({ data, error }) => {
      if (!active) return;
      const nextSession = error ? null : data.session;
      setSession(nextSession);
      setMfaLoading(Boolean(nextSession));
      setLoading(false);
    });

    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    void refreshMfaStatus();
  }, [session?.access_token]);

  const mfaChallengeRequired = mfaNextLevel === "aal2" && mfaCurrentLevel !== "aal2";

  const value = useMemo<AuthContextValue>(() => ({
    configured: isSupabaseConfigured,
    loading,
    session,
    passwordRecovery,
    mfaFactors,
    mfaCurrentLevel,
    mfaNextLevel,
    mfaLoading,
    mfaStatusError,
    mfaChallengeRequired,
    refreshMfaStatus,
    async enrollTotp(friendlyName) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { data, error } = await supabase.auth.mfa.enroll({
        factorType: "totp",
        friendlyName: friendlyName.trim() || "GradiPrep authenticator",
      });
      if (error) throw error;
      return {
        factorId: data.id,
        qrCode: data.totp.qr_code,
        secret: data.totp.secret,
      };
    },
    async verifyTotp(factorId, code) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { data: challenge, error: challengeError } = await supabase.auth.mfa.challenge({ factorId });
      if (challengeError) throw challengeError;

      const { error: verifyError } = await supabase.auth.mfa.verify({
        factorId,
        challengeId: challenge.id,
        code: code.replace(/\s/g, ""),
      });
      if (verifyError) throw verifyError;

      // Supabase refreshes the active session after verification. Read it back
      // before recalculating the authenticator-assurance level.
      const { data, error: sessionError } = await supabase.auth.getSession();
      if (sessionError) throw sessionError;
      if (data.session) {
        setSession(data.session);
        setLoading(false);
      }
      await refreshMfaStatus();
    },
    async unenrollMfaFactor(factorId) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { error } = await supabase.auth.mfa.unenroll({ factorId });
      if (error) throw error;

      // Removing a factor can leave an AAL2 token in the browser. Refresh the
      // session so the assurance level drops before any protected operation.
      const { data, error: refreshError } = await supabase.auth.refreshSession();
      if (refreshError) throw refreshError;
      if (data.session) {
        setSession(data.session);
        setLoading(false);
      }
      await refreshMfaStatus();
    },
    async signIn(email, password) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      setMfaLoading(true);
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim().toLowerCase(),
        password,
      });
      if (error) throw error;
      setSession(data.session);
      setLoading(false);
    },
    async signUp(displayName, email, password, staffInviteToken) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const emailRedirect = new URL("/account", window.location.origin);
      if (staffInviteToken && /^[A-Za-z0-9_-]{43}$/.test(staffInviteToken)) {
        emailRedirect.hash = "staff-invite=" + staffInviteToken;
      }
      const { data, error } = await supabase.auth.signUp({
        email: email.trim().toLowerCase(),
        password,
        options: {
          data: { display_name: displayName.trim() },
          emailRedirectTo: emailRedirect.toString(),
        },
      });
      if (error) throw error;
      if (data.session) {
        setPasswordRecovery(false);
        setMfaLoading(true);
        setSession(data.session);
        setLoading(false);
      }
      return !data.session;
    },
    async requestPasswordReset(email) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim().toLowerCase(), {
        redirectTo: new URL("/account", window.location.origin).toString(),
      });
      if (error) throw error;
    },
    async updatePassword(password) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { error } = await supabase.auth.updateUser({ password });
      if (error) throw error;
      setPasswordRecovery(false);
    },
    async signOut(scope: "global" | "local" = "global") {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { error } = await supabase.auth.signOut({ scope });
      if (error) throw error;
      setPasswordRecovery(false);
      setSession(null);
      setMfaFactors([]);
      setMfaCurrentLevel("aal1");
      setMfaNextLevel("aal1");
      setMfaLoading(false);
      setLoading(false);
    },
  }), [
    loading,
    session,
    passwordRecovery,
    mfaFactors,
    mfaCurrentLevel,
    mfaNextLevel,
    mfaLoading,
    mfaStatusError,
    mfaChallengeRequired,
  ]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used inside AuthProvider.");
  return context;
}
