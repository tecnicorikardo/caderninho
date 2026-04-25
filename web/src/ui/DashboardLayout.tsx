import { Link } from "react-router-dom";

export default function DashboardLayout({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="min-h-screen">
      <header className="border-b bg-white" style={{ color: "var(--text-main)", borderColor: "rgba(17,24,39,0.1)" }}>
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <div>
            <div className="text-sm" style={{ color: "rgba(17,24,39,0.7)" }}>
              bloquinhodigital
            </div>
            <h1 className="text-xl font-semibold">{title}</h1>
          </div>

          <nav className="flex gap-3 text-sm">
            <Link className="px-3 py-3 min-h-12 rounded-lg hover:bg-gray-100" to="/dashboard">
              Dashboard
            </Link>
            <Link className="px-3 py-3 min-h-12 rounded-lg hover:bg-gray-100" to="/customers">
              Clientes
            </Link>
          </nav>
        </div>
      </header>

      <main className="max-w-5xl mx-auto p-6">{children}</main>
    </div>
  );
}
