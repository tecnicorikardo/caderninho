import { useState } from "react";
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
} from "firebase/auth";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";

type Mode = "login" | "register" | "forgot";

function errorMessage(err: unknown): string {
  const msg = err instanceof Error ? err.message : "";
  if (msg.includes("user-not-found") || msg.includes("invalid-credential")) return "E-mail ou senha incorretos.";
  if (msg.includes("wrong-password")) return "Senha incorreta.";
  if (msg.includes("email-already-in-use")) return "Este e-mail já está cadastrado.";
  if (msg.includes("weak-password")) return "A senha deve ter pelo menos 6 caracteres.";
  if (msg.includes("invalid-email")) return "E-mail inválido.";
  if (msg.includes("too-many-requests")) return "Muitas tentativas. Aguarde alguns minutos.";
  return "Algo deu errado. Tente novamente.";
}

export default function LoginPage() {
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
        await signInWithEmailAndPassword(auth, email, password);

      } else if (mode === "register") {
        if (!name.trim()) { setError("Informe seu nome."); setLoading(false); return; }
        const cred = await createUserWithEmailAndPassword(auth, email, password);
        // Cria o perfil do usuário no Firestore
        await setDoc(doc(db, "users", cred.user.uid), {
          email: email.trim().toLowerCase(),
          displayName: name.trim(),
          growthLevel: "Semente",
          brandMargins: [
            { brand: "Natura", marginPercent: 30 },
            { brand: "Avon", marginPercent: 30 },
            { brand: "Casa & Estilo", marginPercent: 15 },
          ],
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });

      } else if (mode === "forgot") {
        await sendPasswordResetEmail(auth, email);
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

          {/* Campo nome — só no cadastro */}
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

          {/* E-mail */}
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

          {/* Senha — não aparece no "esqueci" */}
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
                placeholder={mode === "register" ? "Mínimo 6 caracteres" : "••••••••"}
                value={password}
                onChange={e => setPassword(e.target.value)}
                autoComplete={mode === "register" ? "new-password" : "current-password"}
                required
              />
            </div>
          )}

          {/* Erro / Sucesso */}
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

          {/* Botão principal */}
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

          {/* Links de alternância */}
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
