/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      // ── Fontes ──────────────────────────────────────────────────────────
      fontFamily: {
        sans:    ["Inter", "system-ui", "sans-serif"],
        display: ["Poppins", "Inter", "sans-serif"],
      },
      // ── Paleta de cores ──────────────────────────────────────────────────
      colors: {
        brand: {
          50:  "#f0fdfa",
          100: "#ccfbf1",
          200: "#99f6e4",
          300: "#5eead4",
          400: "#2dd4bf",
          500: "#14b8a6",
          600: "#0d9488",
          700: "#0d7a6e",
          800: "#0a5f56",
          900: "#083d38",
        },
        accent: {
          DEFAULT: "#e63946",
          dark:    "#c1121f",
          light:   "#fde8ea",
        },
        chart: {
          1: "#06b6d4",
          2: "#0d7a6e",
          3: "#e63946",
          4: "#f77f00",
          5: "#06d6a0",
        },
      },
      // ── Sombras ──────────────────────────────────────────────────────────
      boxShadow: {
        card:  "0 1px 3px 0 rgb(0 0 0 / 0.08), 0 1px 2px -1px rgb(0 0 0 / 0.06)",
        "card-hover": "0 4px 12px 0 rgb(0 0 0 / 0.10), 0 2px 4px -1px rgb(0 0 0 / 0.06)",
        "card-lg": "0 8px 24px 0 rgb(0 0 0 / 0.10), 0 2px 8px -2px rgb(0 0 0 / 0.06)",
      },
      // ── Animações ────────────────────────────────────────────────────────
      keyframes: {
        "slide-up": {
          "0%":   { transform: "translateY(100%)", opacity: "0" },
          "100%": { transform: "translateY(0)",    opacity: "1" },
        },
        "fade-in": {
          "0%":   { opacity: "0", transform: "translateY(4px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
      },
      animation: {
        "slide-up": "slide-up 0.22s ease-out",
        "fade-in":  "fade-in 0.18s ease-out",
      },
      // ── Transições ───────────────────────────────────────────────────────
      transitionDuration: {
        DEFAULT: "200ms",
      },
    },
  },
  plugins: [],
};
