import { defineConfig, devices } from "@playwright/test";
import { config } from "dotenv";
import { resolve } from "path";

// Carrega credenciais do .env.test
config({ path: resolve(__dirname, ".env.test") });

export default defineConfig({
  testDir: "./specs",
  timeout: 60_000,
  retries: 1,
  reporter: [["html", { open: "on-failure" }], ["list"]],
  use: {
    baseURL: "https://bloquinhodigital.web.app",
    headless: true,
    screenshot: "only-on-failure",
    video: "off",
    locale: "pt-BR",
  },
  projects: [
    {
      name: "desktop",
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "mobile",
      use: { ...devices["Pixel 5"] }, // Android Chrome — não precisa de webkit
    },
  ],
});
