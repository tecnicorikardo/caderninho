import { useEffect, useMemo, useState } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { account } from "@/lib/appwrite";
import { ensureUserProfile } from "@/lib/profile";
import { applyTheme } from "@/lib/theme";
import LoginPage from "@/pages/LoginPage";
import OnboardingPage from "@/pages/OnboardingPage";
import DashboardPage from "@/pages/DashboardPage";
import CustomersPage from "@/pages/CustomersPage";
import InventoryPage from "@/pages/InventoryPage";
import SettingsPage from "@/pages/SettingsPage";
import SalesPage from "@/pages/SalesPage";
import CommissionPage from "@/pages/CommissionPage";
import ReceivablesPage from "@/pages/ReceivablesPage";
import FinancialReportPage from "@/pages/FinancialReportPage";
import type { UserProfile } from "@/lib/types";

// Tipo de usuário compatível com Appwrite
export type AppUser = {
  uid: string;
  email: string;
};

type SessionState =
  | { status: "loading" }
  | { status: "signed_out" }
  | { status: "signed_in"; user: AppUser; onboarded: boolean };

export default function App() {
  const [state, setState] = useState<SessionState>({ status: "loading" });

  useEffect(() => {
    let active = true;

    async function checkSession() {
      try {
        const user = await account.get();
        if (!active) return;

        const appUser: AppUser = { uid: user.$id, email: user.email };
        const profile = await ensureUserProfile(user.$id);

        if (!active) return;

        if ((profile as UserProfile).themeColor) {
          applyTheme((profile as UserProfile).themeColor!);
        }
        setState({
          status: "signed_in",
          user: appUser,
          onboarded: Boolean(profile.onboardedAt),
        });
      } catch {
        if (active) setState({ status: "signed_out" });
      }
    }

    checkSession();
    return () => { active = false; };
  }, []);

  const rootView = useMemo(() => {
    if (state.status === "loading") {
      return (
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <div className="w-12 h-12 rounded-2xl bg-teal-600 flex items-center justify-center text-white font-bold text-xl mx-auto mb-3">B</div>
            <div className="text-sm text-gray-500">Carregando…</div>
          </div>
        </div>
      );
    }
    if (state.status === "signed_out") {
      return <LoginPage onLogin={(user) => setState({ status: "signed_in", user, onboarded: false })} />;
    }
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
          <Route path="/inventory" element={<InventoryPage user={state.user} />} />
          <Route path="/sales" element={<SalesPage user={state.user} />} />
          <Route path="/settings" element={<SettingsPage user={state.user} />} />
          <Route path="/commission" element={<CommissionPage user={state.user} />} />
          <Route path="/receivables" element={<ReceivablesPage user={state.user} />} />
          <Route path="/financial-report" element={<FinancialReportPage user={state.user} />} />
        </>
      ) : null}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
