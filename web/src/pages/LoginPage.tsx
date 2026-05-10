import { useState } from "react";
import { account } from "@/lib/appwrite";
import { ID } from "appwrite";
import { databases, DATABASE_ID, COLLECTIONS } from "@/lib/appwrite";
import type { AppUser } from "@/App";

type Mode = "login" | "register" | "forgot";

function errorMessage(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes("Invalid credentials") || msg.includes("user_invalid_credentials")) return "E-mail ou senha incorretos.";
  if (msg.includes("email-already-in-use") || msg.includes("user_already_exists")) return "Este e-mail já está cadastrado.";
  if (msg.includes("weak-password") || msg.includes("password_recently_used")) return "A senha deve ter pelo menos 8 caracteres.";
  if (msg.includes("Invalid email") || msg.includes("user_invalid_email")) return "E-mail inválido.";
  if (msg.includes("too-many-requests") || msg.includes("rate_limit")) return "Muitas tentativas. Aguarde alguns minutos.";
  if (msg.includes("Recovery email")) return "E-mail de recuperação enviado!";
  return "Algo deu errado. Tente novamente.";
}

export default function LoginPage({ onLogin }: { onLogin: (user: AppUser) => void }) {
  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function reset() {
    setError(null);
    setSuccess(null);
    setPassword("");
  }

  function switchMode(m: Mode) {
    reset();
    setMode(m);
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);

    try {
      if (mode === "login") {
        const session = await account.createEmailPasswordSession(email, password);
        const user = await account.get();
        onLogin({ uid: user.$id, email: user.email });

      } else if (mode === "register") {
        if (!name.trim()) { setError("Informe seu nome."); setLoading(false); return; }

        // Criar conta no Appwrite
        const user = await account.create(ID.unique(), email, password, name.trim());

        // Fazer login automaticamente
        await account.createEmailPasswordSession(email, password);

        // Criar perfil no banco
        const now = new Date().toISOString();
        await databases.createDocument(DATABASE_ID, COLLECTIONS.PROFILES, ID.unique(), {
          userId: user.$id,
          createdAt: now,
          updatedAt: now,
          onboardedAt: null,
          growthLevel: "Semente",
          brandMargins: JSON.stringify([
            { brand: "Natura", marginPercent: 30 },
            { brand: "Avon", marginPercent: 30 },
            { brand: "Casa & Estilo", marginPercent: 15 },
          ]),
          planStatus: "free",
          themeColor: null,
        });

        onLogin({ uid: user.$id, email: user.email });

      } else if (mode === "forgot") {
        const redirectUrl = `${window.location.origin}/`;
        await account.createRecovery(email, redirectUrl);
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

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 to-slate-100 flex items-center justify-center p-6">
      <div className="w-full max-w-sm">

        {/* Logo */}
        <div className="text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-teal-600 flex items-center justify-center text-white font-bold text-2xl mx-auto shadow-lg">B</div>
          <div className="text-xs font-semibold text-teal-600 uppercase tracking-widest mt-2">Bloquinho Digital</div>
          <div className="text-gray-500 text-sm mt-1">
            {mode === "login" && "Entre na sua conta"}
            {mode === "register" && "Crie sua conta grátis"}
            {mode === "forgot" && "Recuperar senha"}
          </div>
        </div>

        <form onSubmit={onSubmit} className="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 space-y-4">

          {mode === "register" && (
            <div>
              <label className="inp-label">Seu nome</label>
              <input
                className="inp"
                type="text"
                placeholder="Como quer ser chamada?"
                value={name}
                onChange={e => setName(e.target.value)}
                autoComplete="name"
                required
              />
            </div>
          )}

          <div>
            <label className="inp-label">E-mail</label>
            <input
              className="inp"
              type="email"
              placeholder="seu@email.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
              autoComplete="email"
              required
            />
          </div>

          {mode !== "forgot" && (
            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="inp-label mb-0">Senha</label>
                {mode === "login" && (
                  <button
                    type="button"
                    onClick={() => switchMode("forgot")}
                    className="text-xs text-teal-600 hover:underline"
                  >
                    Esqueci minha senha
                  </button>
                )}
              </div>
              <input
                className="inp"
                type="password"
                placeholder={mode === "register" ? "Mínimo 8 caracteres" : "••••••••"}
                value={password}
                onChange={e => setPassword(e.target.value)}
                autoComplete={mode === "register" ? "new-password" : "current-password"}
                required
              />
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

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-60 transition-colors"
          >
            {loading
              ? "Aguarde…"
              : mode === "login" ? "Entrar"
              : mode === "register" ? "Criar conta"
              : "Enviar e-mail de recuperação"
            }
          </button>

          <div className="text-center text-xs text-gray-500 pt-1">
            {mode === "login" && (
              <>
                Não tem conta?{" "}
                <button type="button" onClick={() => switchMode("register")} className="text-teal-600 font-medium hover:underline">
                  Cadastre-se
                </button>
              </>
            )}
            {mode === "register" && (
              <>
                Já tem conta?{" "}
                <button type="button" onClick={() => switchMode("login")} className="text-teal-600 font-medium hover:underline">
                  Entrar
                </button>
              </>
            )}
            {mode === "forgot" && (
              <button type="button" onClick={() => switchMode("login")} className="text-teal-600 font-medium hover:underline">
                ← Voltar para o login
              </button>
            )}
          </div>
        </form>
      </div>
    </div>
  );
}
