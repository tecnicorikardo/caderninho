import { useState } from "react";
import { account } from "@/lib/appwrite";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useUserContext } from "@/lib/userContext";

// ─── Desktop nav (top) ───────────────────────────────────────────────────────
const DESKTOP_NAV = [
  { to: "/dashboard",       label: "Dashboard" },
  { to: "/sales",           label: "Vendas" },
  { to: "/customers",       label: "Clientes" },
  { to: "/inventory",       label: "Estoque" },
  { to: "/commission",      label: "Comissões" },
  { to: "/receivables",     label: "Recebimentos" },
  { to: "/financial-report",label: "Relatório" },
  { to: "/plans",           label: "⭐ Planos" },
  { to: "/settings",        label: "Configurações" },
];

// ─── Mobile bottom bar (4 tabs) ──────────────────────────────────────────────
const BOTTOM_TABS = [
  {
    to: "/dashboard",
    label: "Dashboard",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" className="w-6 h-6" stroke={active ? "#0d9488" : "#94a3b8"} strokeWidth={2}>
        <rect x="3" y="3" width="7" height="7" rx="1" />
        <rect x="14" y="3" width="7" height="7" rx="1" />
        <rect x="3" y="14" width="7" height="7" rx="1" />
        <rect x="14" y="14" width="7" height="7" rx="1" />
      </svg>
    ),
  },
  {
    to: "/sales",
    label: "Nova Venda",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" className="w-6 h-6" stroke={active ? "#0d9488" : "#94a3b8"} strokeWidth={2}>
        <circle cx="9" cy="21" r="1" /><circle cx="20" cy="21" r="1" />
        <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6" />
        <line x1="12" y1="10" x2="12" y2="16" /><line x1="9" y1="13" x2="15" y2="13" />
      </svg>
    ),
  },
  {
    to: "/receivables",
    label: "Recebimentos",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" className="w-6 h-6" stroke={active ? "#0d9488" : "#94a3b8"} strokeWidth={2}>
        <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
        <line x1="1" y1="10" x2="23" y2="10" />
        <line x1="6" y1="16" x2="10" y2="16" />
      </svg>
    ),
  },
  {
    to: "__menu__",
    label: "Menu",
    icon: (active: boolean) => (
      <svg viewBox="0 0 24 24" fill="none" className="w-6 h-6" stroke={active ? "#0d9488" : "#94a3b8"} strokeWidth={2}>
        <line x1="3" y1="6" x2="21" y2="6" />
        <line x1="3" y1="12" x2="21" y2="12" />
        <line x1="3" y1="18" x2="21" y2="18" />
      </svg>
    ),
  },
];

// ─── Menu drawer (slide-up) ───────────────────────────────────────────────────
const MENU_ITEMS = [
  { to: "/inventory",       label: "Estoque",        emoji: "📦" },
  { to: "/customers",       label: "Clientes",       emoji: "👥" },
  { to: "/commission",      label: "Comissões",      emoji: "💰" },
  { to: "/financial-report",label: "Relatório",      emoji: "📊" },
  { to: "/plans",           label: "Planos",         emoji: "⭐" },
  { to: "/settings",        label: "Configurações",  emoji: "⚙️" },
];

function MenuDrawer({ onClose }: { onClose: () => void }) {
  const navigate = useNavigate();

  function go(to: string) {
    onClose();
    navigate(to);
  }

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/40 z-40"
        onClick={onClose}
      />
      {/* Drawer */}
      <div className="fixed bottom-16 left-0 right-0 z-50 bg-white rounded-t-2xl shadow-2xl px-4 pt-4 pb-6 animate-slide-up">
        <div className="w-10 h-1 bg-slate-200 rounded-full mx-auto mb-4" />
        <div className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 px-1">Menu</div>
        <div className="space-y-1">
          {MENU_ITEMS.map(item => (
            <button
              key={item.to}
              onClick={() => go(item.to)}
              className="w-full flex items-center gap-4 px-4 py-3.5 rounded-xl hover:bg-slate-50 active:bg-slate-100 transition-colors text-left"
            >
              <span className="text-2xl w-8 text-center">{item.emoji}</span>
              <span className="text-base font-medium text-gray-800">{item.label}</span>
              <span className="ml-auto text-gray-300 text-lg">›</span>
            </button>
          ))}
        </div>
        <button
          onClick={onClose}
          className="mt-4 w-full rounded-xl border border-slate-200 py-3 text-sm text-gray-500 hover:bg-slate-50"
        >
          Fechar
        </button>
      </div>
    </>
  );
}

// ─── Layout principal ─────────────────────────────────────────────────────────
export default function DashboardLayout({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  const location = useLocation();
  const [menuOpen, setMenuOpen] = useState(false);
  const { emailVerified } = useUserContext();
  const [verifyLoading, setVerifyLoading] = useState(false);
  const [verifyDismissed, setVerifyDismissed] = useState(
    () => sessionStorage.getItem("email_verify_dismissed") === "1"
  );

  async function handleResendVerification() {
    setVerifyLoading(true);
    try {
      await account.createVerification(`${window.location.origin}/`);
      sessionStorage.setItem("email_verify_dismissed", "1");
      setVerifyDismissed(true);
    } catch {
      // silencioso
    } finally {
      setVerifyLoading(false);
    }
  }

  function handleDismiss() {
    sessionStorage.setItem("email_verify_dismissed", "1");
    setVerifyDismissed(true);
  }

  async function handleLogout() {
    if (confirm("Deseja sair da conta?")) {
      await account.deleteSession("current");
      window.location.href = "/";
    }
  }

  const isMenuRoute = MENU_ITEMS.some(m => m.to === location.pathname);

  return (
    <div className="min-h-screen bg-slate-50">
      {/* ── Header ── */}
      <header className="header-gradient shadow-lg sticky top-0 z-30">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl overflow-hidden flex-shrink-0 shadow-inner">
              <img src="/icon.png" alt="B" className="w-full h-full object-cover" />
            </div>
            <div>
              <div className="text-[10px] font-semibold text-teal-200 uppercase tracking-[0.15em] leading-none">Bloquinho Digital</div>
              <h1 className="text-lg font-display font-bold text-white leading-tight tracking-tight">{title}</h1>
            </div>
          </div>

          {/* Desktop nav */}
          <nav className="hidden md:flex items-center gap-0.5 text-sm">
            {DESKTOP_NAV.map((n) => (
              <Link
                key={n.to}
                className={`px-3 py-2 rounded-lg font-medium transition-all duration-200 ${
                  location.pathname === n.to
                    ? "bg-white/20 text-white shadow-sm"
                    : "text-teal-100 hover:bg-white/10 hover:text-white"
                }`}
                to={n.to}
              >
                {n.label}
              </Link>
            ))}
          </nav>

          <button
            onClick={handleLogout}
            className="text-xs font-medium text-teal-100 hover:text-white border border-white/25 hover:border-white/50 hover:bg-white/10 px-3 py-2 rounded-lg transition-all duration-200"
          >
            Sair
          </button>
        </div>
      </header>

      {/* ── Banner de verificação de email ── */}
      {emailVerified === false && !verifyDismissed && (
        <div className="bg-amber-50 border-b border-amber-200 px-4 py-2.5 flex items-center justify-between gap-3">
          <div className="flex items-center gap-2 text-sm text-amber-800">
            <span>✉️</span>
            <span>Confirme seu e-mail para garantir acesso à sua conta.</span>
          </div>
          <div className="flex items-center gap-2 flex-shrink-0">
            <button
              onClick={handleResendVerification}
              disabled={verifyLoading}
              className="text-xs font-semibold text-amber-700 hover:text-amber-900 underline disabled:opacity-50"
            >
              {verifyLoading ? "Enviando…" : "Reenviar link"}
            </button>
            <button onClick={handleDismiss} className="text-amber-400 hover:text-amber-700 text-lg leading-none">×</button>
          </div>
        </div>
      )}

      {/* ── Conteúdo ── */}
      {/* pb-20 no mobile para não ficar atrás da bottom bar */}
      <main className="max-w-6xl mx-auto p-4 md:p-6 pb-24 md:pb-6">
        {children}
      </main>

      {/* ── Bottom Navigation (mobile only) ── */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-30 bg-white border-t border-slate-200 shadow-lg">
        <div className="flex items-stretch h-16">
          {BOTTOM_TABS.map((tab) => {
            const isMenu = tab.to === "__menu__";
            const isActive = isMenu
              ? menuOpen || isMenuRoute
              : location.pathname === tab.to;

            if (isMenu) {
              return (
                <button
                  key="menu"
                  onClick={() => setMenuOpen(v => !v)}
                  className="flex-1 flex flex-col items-center justify-center gap-0.5 transition-colors"
                >
                  {tab.icon(isActive)}
                  <span className={`text-[10px] font-medium ${isActive ? "text-teal-600" : "text-slate-400"}`}>
                    {tab.label}
                  </span>
                </button>
              );
            }

            return (
              <Link
                key={tab.to}
                to={tab.to}
                onClick={() => setMenuOpen(false)}
                className="flex-1 flex flex-col items-center justify-center gap-0.5 transition-colors"
              >
                {tab.icon(isActive)}
                <span className={`text-[10px] font-medium ${isActive ? "text-teal-600" : "text-slate-400"}`}>
                  {tab.label}
                </span>
                {/* Indicador ativo */}
                {isActive && (
                  <span className="absolute bottom-0 w-8 h-0.5 bg-teal-500 rounded-full" />
                )}
              </Link>
            );
          })}
        </div>
      </nav>

      {/* ── Menu Drawer ── */}
      {menuOpen && <MenuDrawer onClose={() => setMenuOpen(false)} />}
    </div>
  );
}
