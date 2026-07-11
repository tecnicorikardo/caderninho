/**
 * Gerenciamento de tema — aplica a cor principal nas CSS custom properties
 * em tempo real sem recarregar a página.
 */

export const DEFAULT_COLOR = "#0d7a6e";
const THEME_STORAGE_KEY = "bloquinho_theme_color";

export const PRESET_COLORS = [
  { label: "Verde Teal (padrão)", value: "#0d7a6e" },
  { label: "Natura Laranja",      value: "#e8650a" },
  { label: "Avon Rosa",           value: "#c2185b" },
  { label: "Azul Royal",          value: "#1565c0" },
  { label: "Roxo",                value: "#6a1b9a" },
  { label: "Vermelho",            value: "#c62828" },
  { label: "Verde Escuro",        value: "#2e7d32" },
  { label: "Cinza Grafite",       value: "#37474f" },
];

function isHexColor(color: string | null): color is string {
  return Boolean(color && /^#[0-9a-fA-F]{6}$/.test(color));
}

export function getCachedThemeColor(): string | null {
  try {
    const color = localStorage.getItem(THEME_STORAGE_KEY);
    return isHexColor(color) ? color : null;
  } catch {
    return null;
  }
}

export function cacheThemeColor(color: string) {
  if (!isHexColor(color)) return;

  try {
    localStorage.setItem(THEME_STORAGE_KEY, color);
  } catch {
    // Ignora navegadores/modos que bloqueiam localStorage.
  }
}

export function applyCachedTheme() {
  const cachedColor = getCachedThemeColor();
  if (cachedColor) applyTheme(cachedColor);
  return cachedColor;
}

/** Converte hex para RGB separado por espaço (para uso em rgba()) */
function hexToRgb(hex: string): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `${r} ${g} ${b}`;
}

/** Escurece uma cor hex em `amount` (0-100) */
function darken(hex: string, amount: number): string {
  const r = Math.max(0, parseInt(hex.slice(1, 3), 16) - amount);
  const g = Math.max(0, parseInt(hex.slice(3, 5), 16) - amount);
  const b = Math.max(0, parseInt(hex.slice(5, 7), 16) - amount);
  return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
}

/** Clareia uma cor hex em `amount` (0-100) */
function lighten(hex: string, amount: number): string {
  const r = Math.min(255, parseInt(hex.slice(1, 3), 16) + amount);
  const g = Math.min(255, parseInt(hex.slice(3, 5), 16) + amount);
  const b = Math.min(255, parseInt(hex.slice(5, 7), 16) + amount);
  return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
}

/**
 * Aplica a cor principal em todas as CSS custom properties do sistema.
 * Chamado ao carregar o app e ao salvar nas configurações.
 */
export function applyTheme(color: string) {
  const root = document.documentElement;
  const hex = color || DEFAULT_COLOR;

  root.style.setProperty("--brand",       hex);
  root.style.setProperty("--brand-dark",  darken(hex, 20));
  root.style.setProperty("--brand-light", lighten(hex, 160));
  root.style.setProperty("--brand-rgb",   hexToRgb(hex));

  // Atualiza também o meta theme-color (barra do browser mobile)
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute("content", hex);
}
