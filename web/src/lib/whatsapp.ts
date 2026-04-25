export function openWhatsAppWithText(text: string) {
  const url = `https://wa.me/?text=${encodeURIComponent(text)}`;
  window.open(url, "_blank", "noopener,noreferrer");
}

export async function shareOrWhatsApp(text: string) {
  const nav = navigator as Navigator & { share?: (data: { text: string }) => Promise<void> };
  if (typeof nav.share === "function") {
    try {
      await nav.share({ text });
      return;
    } catch {
      // fallback para WhatsApp
    }
  }

  openWhatsAppWithText(text);
}

