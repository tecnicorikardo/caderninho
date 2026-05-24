import { useState, useRef, useEffect } from "react";
import { useGeminiChat } from "@/hooks/useGeminiChat";
import { buildUserContext } from "@/lib/aiContext";

const BASE_SYSTEM_PROMPT = `Voce e a Bia, assistente virtual do Bloquinho Digital, um app para revendedoras de cosmeticos (Natura, Avon, Casa & Estilo e outras marcas).

Seu papel e ajudar revendedoras a:
- Entender como usar o app (cadastrar clientes, produtos, registrar vendas, controlar fiado)
- Analisar os dados de vendas, comissoes, fiado e estoque da revendedora
- Dar dicas de vendas e atendimento ao cliente
- Explicar como calcular margem de lucro e comissao
- Orientar sobre controle de estoque e validade de produtos
- Responder duvidas sobre recebimentos, parcelas e fiado
- Dar sugestoes de como aumentar as vendas

Regras importantes:
- Responda SEMPRE em portugues brasileiro, de forma simples e amigavel
- Use linguagem proxima, como se fosse uma amiga ajudando
- Seja objetiva e pratica — respostas curtas e diretas
- Use emojis com moderacao para deixar mais amigavel
- Quando tiver dados reais da revendedora, use-os para dar respostas personalizadas
- Se perguntarem sobre vendas, comissao, fiado ou estoque, consulte os dados fornecidos
- Nao invente dados que nao estejam no contexto

Funcionalidades do Bloquinho Digital:
- Dashboard com resumo de vendas e recebimentos
- Cadastro de clientes com historico de compras
- Controle de estoque com validade dos produtos
- Registro de vendas (a vista, pix, cartao, fiado, parcelado)
- Controle de recebimentos e parcelas em atraso
- Relatorio financeiro com comissao por marca
- Importacao e exportacao de planilha Excel
- Personalizacao de cores do app`;

type Props = {
  uid: string;
};

export default function AIAssistant({ uid }: Props) {
  const [open, setOpen] = useState(false);
  const [input, setInput] = useState("");
  const [contextLoaded, setContextLoaded] = useState(false);
  const [systemPrompt, setSystemPrompt] = useState(BASE_SYSTEM_PROMPT);
  const { messages, loading, sendMessage, clearChat } = useGeminiChat(systemPrompt);
  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Carrega contexto dos dados reais quando abre o chat pela primeira vez
  useEffect(() => {
    if (open && !contextLoaded) {
      buildUserContext(uid).then(ctx => {
        setSystemPrompt(BASE_SYSTEM_PROMPT + ctx);
        setContextLoaded(true);
      });
    }
  }, [open, contextLoaded, uid]);

  useEffect(() => {
    if (open) {
      bottomRef.current?.scrollIntoView({ behavior: "smooth" });
      setTimeout(() => inputRef.current?.focus(), 100);
    }
  }, [messages, open]);

  async function handleSend() {
    const text = input.trim();
    if (!text || loading) return;
    setInput("");
    await sendMessage(text);
  }

  function handleKey(e: React.KeyboardEvent) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  }

  function handleClear() {
    clearChat();
    setContextLoaded(false);
    setSystemPrompt(BASE_SYSTEM_PROMPT);
  }

  const isLoadingContext = open && !contextLoaded;

  return (
    <>
      {/* Botao flutuante */}
      <button
        onClick={() => setOpen(v => !v)}
        className="fixed bottom-20 right-4 md:bottom-6 md:right-6 z-50 w-14 h-14 rounded-full bg-teal-600 hover:bg-teal-700 text-white shadow-lg flex items-center justify-center transition-all hover:scale-110 active:scale-95"
        title="Assistente IA Bia"
        aria-label="Abrir assistente de IA"
      >
        {open ? (
          <svg viewBox="0 0 24 24" fill="none" className="w-6 h-6" stroke="currentColor" strokeWidth={2.5}>
            <path d="M18 6L6 18M6 6l12 12"/>
          </svg>
        ) : (
          <span className="text-2xl">🤖</span>
        )}
      </button>

      {/* Janela do chat */}
      {open && (
        <div
          className="fixed bottom-36 right-4 md:bottom-24 md:right-6 z-50 w-[calc(100vw-2rem)] max-w-sm bg-white rounded-2xl shadow-2xl border border-slate-200 flex flex-col overflow-hidden"
          style={{ height: "min(500px, calc(100vh - 160px))" }}
        >
          {/* Header */}
          <div className="bg-teal-600 px-4 py-3 flex items-center justify-between flex-shrink-0">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center text-lg">🤖</div>
              <div>
                <div className="text-white font-semibold text-sm">Bia — Assistente</div>
                <div className="text-teal-200 text-xs">
                  {isLoadingContext ? "Carregando seus dados..." : "Bloquinho Digital"}
                </div>
              </div>
            </div>
            <button
              onClick={handleClear}
              className="text-teal-200 hover:text-white text-xs underline"
              title="Limpar conversa"
            >
              Limpar
            </button>
          </div>

          {/* Mensagens */}
          <div className="flex-1 overflow-y-auto p-3 space-y-3 bg-slate-50">

            {/* Loading do contexto */}
            {isLoadingContext && (
              <div className="text-center py-4 space-y-2">
                <div className="flex justify-center gap-1">
                  <span className="w-2 h-2 bg-teal-400 rounded-full animate-bounce" style={{ animationDelay: "0ms" }} />
                  <span className="w-2 h-2 bg-teal-400 rounded-full animate-bounce" style={{ animationDelay: "150ms" }} />
                  <span className="w-2 h-2 bg-teal-400 rounded-full animate-bounce" style={{ animationDelay: "300ms" }} />
                </div>
                <div className="text-xs text-gray-500">Carregando seus dados de vendas...</div>
              </div>
            )}

            {/* Boas vindas */}
            {!isLoadingContext && messages.length === 0 && (
              <div className="text-center py-4 space-y-3">
                <div className="text-3xl">👋</div>
                <div className="text-sm font-medium text-gray-700">Oi! Sou a Bia, sua assistente.</div>
                <div className="text-xs text-gray-500">Ja carreguei seus dados. Pode me perguntar sobre vendas, comissoes, fiado e muito mais!</div>
                <div className="grid grid-cols-1 gap-2 mt-2">
                  {[
                    "Como estao minhas vendas este mes?",
                    "Quem tem fiado comigo?",
                    "Qual minha comissao este mes?",
                    "Tem produto vencendo?",
                  ].map(q => (
                    <button
                      key={q}
                      onClick={() => sendMessage(q)}
                      className="text-xs text-left bg-white border border-slate-200 rounded-xl px-3 py-2 hover:bg-teal-50 hover:border-teal-300 transition-colors text-gray-600"
                    >
                      {q}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Mensagens */}
            {messages.map((msg, i) => (
              <div key={i} className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}>
                <div className={`max-w-[85%] rounded-2xl px-3 py-2 text-sm leading-relaxed whitespace-pre-wrap ${
                  msg.role === "user"
                    ? "bg-teal-600 text-white rounded-br-sm"
                    : "bg-white border border-slate-200 text-gray-800 rounded-bl-sm shadow-sm"
                }`}>
                  {msg.text}
                </div>
              </div>
            ))}

            {/* Digitando */}
            {loading && (
              <div className="flex justify-start">
                <div className="bg-white border border-slate-200 rounded-2xl rounded-bl-sm px-4 py-3 shadow-sm">
                  <div className="flex gap-1 items-center">
                    <span className="w-2 h-2 bg-teal-400 rounded-full animate-bounce" style={{ animationDelay: "0ms" }} />
                    <span className="w-2 h-2 bg-teal-400 rounded-full animate-bounce" style={{ animationDelay: "150ms" }} />
                    <span className="w-2 h-2 bg-teal-400 rounded-full animate-bounce" style={{ animationDelay: "300ms" }} />
                  </div>
                </div>
              </div>
            )}
            <div ref={bottomRef} />
          </div>

          {/* Input */}
          <div className="p-3 border-t border-slate-200 bg-white flex-shrink-0">
            <div className="flex gap-2">
              <input
                ref={inputRef}
                type="text"
                value={input}
                onChange={e => setInput(e.target.value)}
                onKeyDown={handleKey}
                placeholder={isLoadingContext ? "Aguarde..." : "Digite sua pergunta..."}
                disabled={loading || isLoadingContext}
                className="flex-1 rounded-xl border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:border-teal-500 disabled:opacity-50"
              />
              <button
                onClick={handleSend}
                disabled={loading || !input.trim() || isLoadingContext}
                className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-3 py-2 disabled:opacity-40 transition-colors"
              >
                <svg viewBox="0 0 24 24" fill="none" className="w-4 h-4" stroke="currentColor" strokeWidth={2.5}>
                  <path d="M22 2L11 13M22 2L15 22l-4-9-9-4 20-7z" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
