import { useEffect, useMemo, useState } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { onAuthStateChanged, type User } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { ensureUserProfile } from "@/lib/profile";
import LoginPage from "@/pages/LoginPage";
import OnboardingPage from "@/pages/OnboardingPage";
import DashboardPage from "@/pages/DashboardPage";
import CustomersPage from "@/pages/CustomersPage";

type SessionState =
  | { status: "loading" }
  | { status: "signed_out" }
  | { status: "signed_in"; user: User; onboarded: boolean };

export default function App() {
  const [state, setState] = useState<SessionState>({ status: "loading" });

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setState({ status: "signed_out" });
        return;
      }

      const profile = await ensureUserProfile(user.uid);
      setState({ status: "signed_in", user, onboarded: Boolean(profile.onboardedAt) });
    });

    return () => unsub();
  }, []);

  const rootView = useMemo(() => {
    if (state.status === "loading") return <div className="p-6">Carregando…</div>;
    if (state.status === "signed_out") return <LoginPage />;
    if (!state.onboarded) {
      return (
        <OnboardingPage
          user={state.user}
          onDone={() => setState({ ...state, onboarded: true })}
        />
      );
    }
    return <Navigate to="/dashboard" replace />;
  }, [state]);

  return (
    <Routes>
      <Route path="/" element={rootView} />
      {state.status === "signed_in" && state.onboarded ? (
        <>
          <Route path="/dashboard" element={<DashboardPage user={state.user} />} />
          <Route path="/customers" element={<CustomersPage user={state.user} />} />
        </>
      ) : null}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
