import { useEffect, useState } from "react";
import { account } from "@/lib/supabase";
import { ID, OAuthProvider, Permission, Role } from "@/lib/supabase";
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/supabase";
import type { AppUser } from "@/App";
import {
  isBiometricAvailable,
  hasBiometricCredential,
  registerBiometric,
  authenticateWithBiometric,
  removeBiometricCredential,
} from "@/lib/biometric";

type Mode = "login" | "register" | "forgot";

// ── Helpers ───────────────────────────────────────────────────────────────────

function formatCpf(v: string) {
  return v.replace(/\D/g, "").slice(0, 11)
    .replace(/(\d{3})(\d)/, "$1.$2")
    .replace(/(\d{3})(\d)/, "$1.$2")
    .replace(/(\d{3})(\d{1,2})$/, "$1-$2");
}

function cleanCpf(v: string) {
  return v.replace(/\D/g, "");
}

function validateCpf(cpf: string): boolean {
  const c = cleanCpf(cpf);
  if (c.length !== 11 || /^(\d)\1+$/.test(c)) return false;
  let sum = 0;
  for (let i = 0; i < 9; i++) sum += parseInt(c[i]) * (10 - i);
  let r = (sum * 10) % 11;
  if (r === 10 || r === 11) r = 0;
  if (r !== parseInt(c[9])) return false;
  sum = 0;
  for (let i = 0; i < 10; i++) sum += parseInt(c[i]) * (11 - i);
  r = (sum * 10) % 11;
  if (r === 10 || r === 11) r = 0;
  return r === parseInt(c[10]);
}

function errorMessage(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes("Email not confirmed") || msg.includes("email_not_confirmed")) return "Confirme seu e-mail antes de entrar.";
  if (msg.includes("Invalid credentials") || msg.includes("user_invalid_credentials")) return "E-mail ou senha incorretos.";
  if (msg.includes("email-already-in-use") || msg.includes("user_already_exists")) return "Este e-mail já está cadastrado.";
  if (msg.includes("duplicate key") || msg.includes("users_profiles_cpf_key")) return "Este CPF já está cadastrado. Faça login ou recupere sua senha.";
  if (msg.includes("weak-password") || msg.includes("password_recently_used")) return "A senha deve ter pelo menos 8 caracteres.";
  if (msg.includes("Invalid email") || msg.includes("user_invalid_email")) return "E-mail inválido.";
  if (msg.includes("too-many-requests") || msg.includes("rate_limit")) return "Muitas tentativas. Aguarde alguns minutos.";
  return "Algo deu errado. Tente novamente.";
}

function pendingProfileKey(email: string) {
  return `pending_profile_${email.trim().toLowerCase()}`;
}

async function upsertRegistrationProfile(userId: string, cpfClean: string) {
  const cpfCheck = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
    Query.equal("cpf", cpfClean),
  ]).catch(() => ({ documents: [] }));

  if (cpfCheck.documents.some(doc => doc.userId !== userId)) {
    throw new Error("users_profiles_cpf_key");
  }

  const now = new Date().toISOString();
  const profileData = {
    userId,
    cpf: cpfClean,
    createdAt: now,
    updatedAt: now,
    growthLevel: "Semente",
    brandMargins: JSON.stringify([
      { brand: "Natura", marginPercent: 30 },
      { brand: "Avon", marginPercent: 30 },
      { brand: "Casa & Estilo", marginPercent: 15 },
    ]),
    planStatus: "free",
    themeColor: null,
  };

  const existingProfile = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
    Query.equal("userId", userId),
    Query.limit(1),
  ]).catch(() => ({ documents: [] }));

  if (existingProfile.documents.length > 0) {
    await databases.updateDocument(DATABASE_ID, COLLECTIONS.PROFILES, existingProfile.documents[0].$id, {
      ...profileData,
      createdAt: existingProfile.documents[0].createdAt ?? now,
    });
    return;
  }

  await databases.createDocument(DATABASE_ID, COLLECTIONS.PROFILES, ID.unique(), profileData, [
    Permission.read(Role.user(userId)),
    Permission.update(Role.user(userId)),
    Permission.delete(Role.user(userId)),
  ]);
}

async function applyPendingRegistrationProfile(userId: string, email: string) {
  const key = pendingProfileKey(email);
  const raw = localStorage.getItem(key);
  if (!raw) return;

  const pending = JSON.parse(raw) as { cpf?: string };
  if (!pending.cpf) return;

  await upsertRegistrationProfile(userId, pending.cpf);
  localStorage.removeItem(key);
}

// ── Componente principal ──────────────────────────────────────────────────────

export default function LoginPage({ onLogin }: { onLogin: (user: AppUser) => void }) {
  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [cpf, setCpf] = useState("");
  const [pendingUser, setPendingUser] = useState<AppUser | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // Biometria
  const [biometricAvailable, setBiometricAvailable] = useState(false);
  const [biometricReady, setBiometricReady] = useState(false);
  const [offerBiometric, setOfferBiometric] = useState(false);

  useEffect(() => {
    async function checkBiometric() {
      const available = await isBiometricAvailable();
      setBiometricAvailable(available);
      setBiometricReady(available && hasBiometricCredential());
    }
    checkBiometric();
  }, []);

  function reset() { setError(null); setSuccess(null); setPassword(""); }
  function switchMode(m: Mode) { reset(); setMode(m); }

  // ── Login com biometria ───────────────────────────────────────────────────
  async function handleBiometricLogin() {
    setLoading(true);
    setError(null);
    try {
      const userId = await authenticateWithBiometric();
      if (!userId) {
        setError("Biometria não reconhecida. Use e-mail e senha.");
        setLoading(false);
        return;
      }
      // Verifica se a sessão ainda está ativa
      const user = await account.get();
      if (user.$id !== userId) {
        removeBiometricCredential();
        setBiometricReady(false);
        setError("Sessão expirada. Faça login com e-mail e senha.");
        setLoading(false);
        return;
      }
      onLogin({ uid: user.$id, email: user.email });
    } catch {
      setError("Erro na autenticação biométrica. Use e-mail e senha.");
    } finally {
      setLoading(false);
    }
  }

  // ── Login com Google ──────────────────────────────────────────────────────
  function handleGoogleLogin() {
    account.createOAuth2Session(
      OAuthProvider.Google,
      `${window.location.origin}/`,
      `${window.location.origin}/`,
    );
  }

  // ── Submit principal ──────────────────────────────────────────────────────
  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);

    try {
      // ── LOGIN ─────────────────────────────────────────────────────────
      if (mode === "login") {
        await account.createEmailPasswordSession(email, password);
        const user = await account.get();
        await applyPendingRegistrationProfile(user.$id, user.email);
        const appUser: AppUser = { uid: user.$id, email: user.email };

        if (biometricAvailable && !hasBiometricCredential()) {
          setOfferBiometric(true);
          setPendingUser(appUser);
          setLoading(false);
          return;
        }
        onLogin(appUser);
        return;
      }

      // ── CADASTRO ──────────────────────────────────────────────────────
      if (mode === "register") {
        if (!name.trim()) { setError("Informe seu nome."); setLoading(false); return; }
        const cpfClean = cleanCpf(cpf);
        if (!validateCpf(cpfClean)) { setError("CPF inválido. Verifique os dígitos."); setLoading(false); return; }
        if (password.length < 8) { setError("A senha deve ter pelo menos 8 caracteres."); setLoading(false); return; }

        // Cria conta. Se exigir confirmação de e-mail, a sessão fica pendente.
        const user = await account.create(ID.unique(), email, password, name.trim());
        if (user.emailConfirmationRequired) {
          localStorage.setItem(pendingProfileKey(email), JSON.stringify({ cpf: cpfClean }));
          setMode("login");
          setPassword("");
          setSuccess("Conta criada! Confirme seu e-mail e depois faça login.");
          setLoading(false);
          return;
        }

        // Com sessão ativa, cria ou atualiza perfil com CPF.
        await upsertRegistrationProfile(user.$id, cpfClean);
        // Reenvia confirmacao se a conta ainda nao estiver verificada.
        await account.createVerification(`${window.location.origin}/`).catch(() => {});

        const appUser: AppUser = { uid: user.$id, email: user.email };

        // Oferece biometria se disponivel.
        if (biometricAvailable && !hasBiometricCredential()) {
          setOfferBiometric(true);
          setPendingUser(appUser);
          setLoading(false);
          return;
        }

        onLogin(appUser);
        return;
      }

      // ── RECUPERAR SENHA ───────────────────────────────────────────────
      if (mode === "forgot") {
        await account.createRecovery(email, `${window.location.origin}/`);
        setSuccess("E-mail de recuperação enviado! Verifique sua caixa de entrada.");
        setLoading(false);
        return;
      }

    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  // ── Oferta de biometria após login ────────────────────────────────────────
  async function handleAcceptBiometric() {
    setLoading(true);
    try {
      const user = await account.get();
      await registerBiometric(user.$id, user.name || user.email);
      setBiometricReady(true);
    } catch {
      // biometria falhou — segue sem ela
    }
    setOfferBiometric(false);
    onLogin(pendingUser!);
    setLoading(false);
  }

  function handleSkipBiometric() {
    setOfferBiometric(false);
    onLogin(pendingUser!);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RENDER
  // ─────────────────────────────────────────────────────────────────────────

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 to-slate-100 flex items-center justify-center p-6">
      <div className="w-full max-w-sm">

        {/* Logo */}
        <div className="text-center mb-6">
          <img
            src="/icon.png"
            alt="Bloquinho Digital"
            className="w-28 h-28 mx-auto mb-3 drop-shadow-xl rounded-2xl object-contain"
          />
          <div className="text-sm font-bold text-teal-700 uppercase tracking-widest mt-1">Bloquinho Digital</div>
          <div className="text-gray-500 text-sm mt-1">
            {mode === "login" && "Entre na sua conta"}
            {mode === "register" && "Crie sua conta grátis"}
            {mode === "forgot" && "Recuperar senha"}
          </div>
        </div>

        {/* ── Oferta de biometria ── */}
        {offerBiometric && (
          <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 space-y-4 text-center">
            <div className="text-4xl">🔐</div>
            <h2 className="text-base font-semibold text-gray-800">Ativar acesso rápido?</h2>
            <p className="text-sm text-gray-500">
              Use sua digital ou Face ID para entrar sem digitar senha nas próximas vezes.
            </p>
            <button onClick={handleAcceptBiometric} disabled={loading}
              className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-60 transition-colors">
              {loading ? "Aguarde…" : "Ativar biometria"}
            </button>
            <button onClick={handleSkipBiometric} className="w-full text-xs text-gray-400 underline">
              Agora não
            </button>
          </div>
        )}

        {/* ── Formulário principal ── */}
        {!offerBiometric && (
          <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 space-y-4">

            {/* Botão biometria — só no login se já registrada */}
            {mode === "login" && biometricReady && (
              <button onClick={handleBiometricLogin} disabled={loading}
                className="w-full rounded-xl bg-slate-800 hover:bg-slate-900 text-white py-3 text-sm font-semibold flex items-center justify-center gap-2 transition-colors disabled:opacity-60">
                <span className="text-lg">🔐</span>
                Entrar com biometria
              </button>
            )}

            {/* Botão Google */}
            {(mode === "login" || mode === "register") && (
              <button onClick={handleGoogleLogin} type="button"
                className="w-full rounded-xl border-2 border-slate-200 hover:border-slate-300 bg-white text-gray-700 py-3 text-sm font-semibold flex items-center justify-center gap-2 transition-colors">
                <svg className="w-4 h-4" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>
                Continuar com Google
              </button>
            )}

            {(mode === "login" || mode === "register") && (
              <div className="flex items-center gap-3">
                <div className="flex-1 h-px bg-slate-100" />
                <span className="text-xs text-gray-400">ou</span>
                <div className="flex-1 h-px bg-slate-100" />
              </div>
            )}

            <form onSubmit={onSubmit} className="space-y-4">

              {/* Campos de cadastro */}
              {mode === "register" && (
                <>
                  <div>
                    <label className="inp-label">Seu nome</label>
                    <input className="inp" type="text" placeholder="Como quer ser chamada?"
                      value={name} onChange={e => setName(e.target.value)}
                      autoComplete="name" required />
                  </div>
                  <div>
                    <label className="inp-label">CPF *</label>
                    <input className="inp" type="text" placeholder="000.000.000-00"
                      value={cpf} onChange={e => setCpf(formatCpf(e.target.value))}
                      maxLength={14} required />
                    <p className="text-xs text-gray-400 mt-1">Identifica sua conta de forma única.</p>
                  </div>
                </>
              )}

              {/* Email */}
              <div>
                <label className="inp-label">E-mail</label>
                <input className="inp" type="email" placeholder="seu@email.com"
                  value={email} onChange={e => setEmail(e.target.value)}
                  autoComplete="email" required />
              </div>

              {/* Senha */}
              {mode !== "forgot" && (
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="inp-label mb-0">Senha</label>
                    {mode === "login" && (
                      <button type="button" onClick={() => switchMode("forgot")}
                        className="text-xs text-teal-600 hover:underline">
                        Esqueci minha senha
                      </button>
                    )}
                  </div>
                  <input className="inp" type="password"
                    placeholder={mode === "register" ? "Mínimo 8 caracteres" : "••••••••"}
                    value={password} onChange={e => setPassword(e.target.value)}
                    autoComplete={mode === "register" ? "new-password" : "current-password"}
                    required />
                </div>
              )}

              {error && (
                <div className="text-xs text-red-700 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
                  {error}
                </div>
              )}
              {success && (
                <div className="text-xs text-green-700 bg-green-50 border border-green-100 rounded-lg px-3 py-2">
                  {success}
                </div>
              )}

              <button type="submit" disabled={loading}
                className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-60 transition-colors">
                {loading ? "Aguarde…"
                  : mode === "login" ? "Entrar"
                  : mode === "register" ? "Criar conta"
                  : "Enviar e-mail de recuperação"}
              </button>
            </form>

            {/* Links de troca de modo */}
            <div className="text-center text-xs text-gray-500 pt-1">
              {mode === "login" && (
                <>Não tem conta?{" "}
                  <button type="button" onClick={() => switchMode("register")}
                    className="text-teal-600 font-medium hover:underline">
                    Cadastre-se
                  </button>
                </>
              )}
              {mode === "register" && (
                <>Já tem conta?{" "}
                  <button type="button" onClick={() => switchMode("login")}
                    className="text-teal-600 font-medium hover:underline">
                    Entrar
                  </button>
                </>
              )}
              {mode === "forgot" && (
                <button type="button" onClick={() => switchMode("login")}
                  className="text-teal-600 font-medium hover:underline">
                  ← Voltar para o login
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
