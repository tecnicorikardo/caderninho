import { useState, useRef, useEffect } from "react";
import { geminiModel } from "@/lib/gemini";

export type ChatMessage = {
  role: "user" | "assistant";
  text: string;
};

export function useGeminiChat(systemPrompt: string) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const chatRef = useRef<any>(null);
  const promptRef = useRef(systemPrompt);

  // Atualiza o prompt ref quando mudar (contexto carregado)
  // e reseta o chat para usar o novo prompt
  useEffect(() => {
    if (promptRef.current !== systemPrompt) {
      promptRef.current = systemPrompt;
      chatRef.current = null; // força novo chat com contexto atualizado
    }
  }, [systemPrompt]);

  async function sendMessage(text: string) {
    setMessages(prev => [...prev, { role: "user", text }]);
    setLoading(true);
    try {
      if (!chatRef.current) {
        chatRef.current = geminiModel.startChat({
          systemInstruction: {
            role: "system",
            parts: [{ text: systemPrompt }],
          },
          history: [],
        });
      }
      const result = await chatRef.current.sendMessage(text);
      const response = result.response.text();
      setMessages(prev => [...prev, { role: "assistant", text: response }]);
    } catch (err) {
      console.error("Gemini error:", err);
      setMessages(prev => [...prev, {
        role: "assistant",
        text: "Desculpe, nao consegui processar sua pergunta agora. Tente novamente.",
      }]);
    } finally {
      setLoading(false);
    }
  }

  function clearChat() {
    setMessages([]);
    chatRef.current = null;
  }

  return { messages, loading, sendMessage, clearChat };
}
