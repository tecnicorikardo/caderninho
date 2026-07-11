import { useEffect, useMemo, useState } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { account } from "@/lib/supabase";
import { ensureUserProfile } from "@/lib/profile";
import { applyCachedTheme, applyTheme, cacheThemeColor } from "@/lib/theme";
import { getEffectivePlan, trialDaysLeft } from "@/lib/plan";
import { UserContext } from "@/lib/userContext";
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
import PlansPage from "@/pages/PlansPage";
import PaymentSuccessPage from "@/pages/PaymentSuccessPage";
import PlanGate from "@/ui/PlanGate";
import type { UserProfile } from "@/lib/types";
import type { PlanStatus } from "@/lib/plan";

export type AppUser = {
  uid: string;
  email: string;
  emailVerified?: boolean;
};

type SessionState =
  | { status: "loading" }
  | { status: "signed_out" }
  | { status: "signed_in"; user: AppUser; onboarded: boolean; profile: UserProfile; plan: PlanStatus };

export default function App() {
  const [state, setState] = useState<SessionState>({ status: "loading" });

  useEffect(() => {
    let active = true;
    applyCachedTheme();

    async function checkSession() {
      try {
        const user = await account.get();
        if (!active) return;

        const appUser: AppUser = {
          uid: user.$id,
          email: user.email,
          emailVerified: user.emailVerification,
        };
        const profile = await ensureUserProfile(user.$id);

        if (!active) return;

        if (profile.themeColor) {
          applyTheme(profile.themeColor as string);
          cacheThemeColor(profile.themeColor as string);
        }

        setState({
          status: "signed_in",
          user: appUser,
          onboarded: Boolean(profile.onboardedAt),
          profile,
          plan: getEffectivePlan(profile),
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
            <img src="/icon.png" alt="Bloquinho Digital" className="w-20 h-20 mx-auto mb-3 rounded-2xl drop-shadow-lg object-contain animate-pulse" />
            <div className="text-sm text-gray-500">Carregando…</div>
          </div>
        </div>
      );
    }
    if (state.status === "signed_out") {
      return (
        <LoginPage
          onLogin={async (user) => {
            setState({ status: "loading" });
            try {
              const profile = await ensureUserProfile(user.uid);
              if (profile.themeColor) {
                applyTheme(profile.themeColor as string);
                cacheThemeColor(profile.themeColor as string);
              }
              // Busca emailVerification atualizado do Supabase
              const freshUser = await account.get().catch(() => null);
              setState({
                status: "signed_in",
                user: { ...user, emailVerified: freshUser?.emailVerification ?? false },
                onboarded: Boolean(profile.onboardedAt),
                profile,
                plan: getEffectivePlan(profile),
              });
            } catch {
              const fallbackProfile: UserProfile = { createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
              setState({ status: "signed_in", user, onboarded: false, profile: fallbackProfile, plan: "free" });
            }
          }}
        />
      );
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

  const emailVerified = state.status === "signed_in" ? (state.user.emailVerified ?? true) : true;
  const uid = state.status === "signed_in" ? state.user.uid : "";

  return (
    <UserContext.Provider value={{ emailVerified, uid }}>
      <Routes>
        <Route path="/" element={rootView} />
        {state.status === "signed_in" && state.onboarded ? (
          <>
            <Route path="/dashboard" element={<DashboardPage user={state.user} />} />
            <Route path="/plans" element={
              <PlansPage
                user={state.user}
                currentPlan={state.plan}
                planExpiresAt={state.profile.planExpiresAt as string | null}
                trialDaysLeft={trialDaysLeft(state.profile)}
              />
            } />
            <Route path="/payment-success" element={<PaymentSuccessPage user={state.user} />} />

            {/* Páginas bloqueadas para free */}
            <Route path="/customers" element={
              <PlanGate plan={state.plan} profile={state.profile}>
                <CustomersPage user={state.user} />
              </PlanGate>
            } />
            <Route path="/inventory" element={
              <PlanGate plan={state.plan} profile={state.profile}>
                <InventoryPage user={state.user} />
              </PlanGate>
            } />
            <Route path="/sales" element={
              <PlanGate plan={state.plan} profile={state.profile}>
                <SalesPage user={state.user} />
              </PlanGate>
            } />
            <Route path="/receivables" element={
              <PlanGate plan={state.plan} profile={state.profile}>
                <ReceivablesPage user={state.user} />
              </PlanGate>
            } />
            <Route path="/commission" element={
              <PlanGate plan={state.plan} profile={state.profile}>
                <CommissionPage user={state.user} />
              </PlanGate>
            } />

            {/* Páginas livres para todos */}
            <Route path="/settings" element={<SettingsPage user={state.user} />} />
            <Route path="/financial-report" element={<FinancialReportPage user={state.user} />} />
          </>
        ) : null}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </UserContext.Provider>
  );
}
