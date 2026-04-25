import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "@/lib/firebase";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Falha ao entrar");
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <form onSubmit={onSubmit} className="w-full max-w-sm rounded-xl bg-white p-6 shadow">
        <h1 className="text-xl font-semibold">Entrar</h1>
        <p className="text-sm text-gray-600 mt-1">Use seu e-mail e senha.</p>

        <label className="block mt-4 text-sm font-medium">E-mail</label>
        <input
          className="mt-1 w-full rounded-lg border px-3 py-3 min-h-12"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="email"
          required
        />

        <label className="block mt-3 text-sm font-medium">Senha</label>
        <input
          className="mt-1 w-full rounded-lg border px-3 py-3 min-h-12"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="current-password"
          required
        />

        {error ? <p className="mt-3 text-sm text-red-700">{error}</p> : null}

        <button
          type="submit"
          className="mt-4 w-full rounded-lg bg-gray-900 text-white px-4 py-3 min-h-12"
        >
          Entrar
        </button>
      </form>
    </div>
  );
}

