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

interface AuthContextValue {
  configured: boolean;
  loading: boolean;
  session: Session | null;
  passwordRecovery: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (displayName: string, email: string, password: string) => Promise<boolean>;
  requestPasswordReset: (email: string) => Promise<void>;
  updatePassword: (password: string) => Promise<void>;
  signOut: (scope?: "global" | "local") => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [passwordRecovery, setPasswordRecovery] = useState(false);

  useEffect(() => {
    if (!supabase) {
      setSession(null);
      setPasswordRecovery(false);
      setLoading(false);
      return;
    }

    let active = true;
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, nextSession) => {
      if (active) {
        if (event === "PASSWORD_RECOVERY") setPasswordRecovery(true);
        if (event === "SIGNED_OUT") setPasswordRecovery(false);
        setSession(nextSession);
        setLoading(false);
      }
    });

    void supabase.auth.getSession().then(({ data, error }) => {
      if (!active) return;
      setSession(error ? null : data.session);
      setLoading(false);
    });

    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, []);

  const value = useMemo<AuthContextValue>(() => ({
    configured: isSupabaseConfigured,
    loading,
    session,
    passwordRecovery,
    async signIn(email, password) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim().toLowerCase(),
        password,
      });
      if (error) throw error;
      // Keep the React session state in sync immediately; do not depend only
      // on the auth-state callback arriving after the form submission.
      setSession(data.session);
      setLoading(false);
    },
    async signUp(displayName, email, password) {
      if (!supabase) throw new Error("Authentication is not configured in this environment.");
      const { data, error } = await supabase.auth.signUp({
        email: email.trim().toLowerCase(),
        password,
        options: {
          data: { display_name: displayName.trim() },
          emailRedirectTo: new URL("/account", window.location.origin).toString(),
        },
      });
      if (error) throw error;
      if (data.session) {
        setPasswordRecovery(false);
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
      // Global sign-out revokes refresh tokens on every device/session. Local
      // sign-out is used only to clear a browser after the Worker detects that
      // its remote session was already revoked.
      const { error } = await supabase.auth.signOut({ scope });
      if (error) throw error;
      setPasswordRecovery(false);
      setSession(null);
      setLoading(false);
    },
  }), [loading, passwordRecovery, session]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used inside AuthProvider.");
  return context;
}
