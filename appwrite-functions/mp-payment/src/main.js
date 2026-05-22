import { Client, Databases, Query } from "node-appwrite";

const PLAN_PRICES = {
  monthly: { amountCents: 2990,  label: "Bloquinho Digital - Plano Pro Mensal",  months: 1  },
  yearly:  { amountCents: 29990, label: "Bloquinho Digital - Plano Pro Anual",    months: 12 },
};

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

// URL base da API EFI (producao)
const EFI_BASE = "https://api.efipay.com.br";

async function getEfiToken(clientId, clientSecret) {
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
  const res = await fetch(`${EFI_BASE}/v1/authorize`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ grant_type: "client_credentials" }),
  });

  const text = await res.text();
  if (!res.ok || text.trim().startsWith("<")) {
    throw new Error(`EFI auth falhou (${res.status}): ${text.slice(0, 300)}`);
  }
  const data = JSON.parse(text);
  if (!data.access_token) throw new Error("EFI sem access_token: " + text.slice(0, 300));
  return data.access_token;
}

export default async ({ req, res, log, error }) => {
  if (req.method === "OPTIONS") {
    return res.send("", 204, CORS_HEADERS);
  }

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const db = new Databases(client);
  const DB_ID        = process.env.APPWRITE_DATABASE_ID;
  const COL_PROFILES = process.env.APPWRITE_COLLECTION_PROFILES;
  const EFI_CLIENT_ID     = process.env.EFI_CLIENT_ID;
  const EFI_CLIENT_SECRET = process.env.EFI_CLIENT_SECRET;
  const APP_URL = process.env.APP_BASE_URL || "https://bloquinhodigital.web.app";
  const FUNCTION_URL = process.env.FUNCTION_URL || "";

  log(`${req.method} ${req.path}`);

  // ── Criar link de pagamento EFI (one-step) ───────────────────────────────
  if (req.method === "POST" && req.path === "/create-charge") {
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      const { userId, plan, customerName, customerCpf, customerEmail } = body || {};

      if (!userId || !plan || !PLAN_PRICES[plan]) {
        return res.send(JSON.stringify({ error: "Parametros invalidos" }), 400, CORS_HEADERS);
      }
      if (!customerName || !customerCpf) {
        return res.send(JSON.stringify({ error: "Nome e CPF sao obrigatorios" }), 400, CORS_HEADERS);
      }

      const price = PLAN_PRICES[plan];
      const token = await getEfiToken(EFI_CLIENT_ID, EFI_CLIENT_SECRET);

      // Validade do link: 7 dias
      const expireAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        .toISOString().split("T")[0];

      // One-step: cria cobrança + link em uma única chamada
      const chargeRes = await fetch(`${EFI_BASE}/v1/charge/one-step/link`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          items: [{
            name: price.label,
            value: price.amountCents,
            amount: 1,
          }],
          customer: {
            name: customerName,
            cpf: customerCpf.replace(/\D/g, ""),
            ...(customerEmail ? { email: customerEmail } : {}),
          },
          metadata: {
            custom_id: `${userId}|${plan}`,
            notification_url: `${FUNCTION_URL}/webhook`,
          },
          settings: {
            payment_method: "all",
            expire_at: expireAt,
            return_url: `${APP_URL}/payment-success?plan=${plan}&userId=${userId}`,
          },
        }),
      });

      const chargeText = await chargeRes.text();
      log("EFI charge raw response: " + chargeText.slice(0, 500));

      if (chargeText.trim().startsWith("<")) {
        error("EFI retornou HTML: " + chargeText.slice(0, 300));
        return res.send(JSON.stringify({ error: "EFI retornou HTML - verifique credenciais e endpoint" }), 500, CORS_HEADERS);
      }

      const chargeData = JSON.parse(chargeText);
      log("EFI charge parsed: " + JSON.stringify(chargeData));

      if (!chargeRes.ok) {
        error("EFI charge error: " + JSON.stringify(chargeData));
        return res.send(JSON.stringify({
          error: "Erro ao criar cobranca EFI",
          detail: chargeData
        }), 500, CORS_HEADERS);
      }

      const paymentUrl = chargeData.data?.payment_url;
      const chargeId   = chargeData.data?.charge_id;

      if (!paymentUrl) {
        error("EFI sem payment_url: " + JSON.stringify(chargeData));
        return res.send(JSON.stringify({ error: "EFI nao retornou link de pagamento" }), 500, CORS_HEADERS);
      }

      log(`Link criado: charge_id=${chargeId} userId=${userId} plano=${plan}`);
      return res.send(JSON.stringify({ chargeId, paymentUrl }), 200, CORS_HEADERS);

    } catch (e) {
      error("create-charge error: " + e.message);
      return res.send(JSON.stringify({ error: "Erro interno: " + e.message }), 500, CORS_HEADERS);
    }
  }

  // ── Webhook EFI ──────────────────────────────────────────────────────────
  if (req.method === "POST" && req.path === "/webhook") {
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      log("Webhook EFI: " + JSON.stringify(body));

      const chargeId = body?.charge_id || body?.data?.charge_id;
      const status   = body?.status    || body?.data?.status;

      if (!chargeId || status !== "paid") {
        return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);
      }

      const token = await getEfiToken(EFI_CLIENT_ID, EFI_CLIENT_SECRET);
      const detailRes = await fetch(`${EFI_BASE}/v1/charge/${chargeId}`, {
        headers: { "Authorization": `Bearer ${token}` },
      });
      const detail = await detailRes.json();
      const customId = detail.data?.metadata?.custom_id || "";
      const [userId, plan] = customId.split("|");

      if (!userId || !plan || !PLAN_PRICES[plan]) {
        error("custom_id invalido: " + customId);
        return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);
      }

      const months = PLAN_PRICES[plan].months;
      const expiresAt = new Date();
      expiresAt.setMonth(expiresAt.getMonth() + months);

      const profiles = await db.listDocuments(DB_ID, COL_PROFILES, [
        Query.equal("userId", userId),
        Query.limit(1),
      ]);

      if (profiles.documents.length === 0) {
        error("Perfil nao encontrado: " + userId);
        return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);
      }

      await db.updateDocument(DB_ID, COL_PROFILES, profiles.documents[0].$id, {
        planStatus: "pro",
        planExpiresAt: expiresAt.toISOString(),
        updatedAt: new Date().toISOString(),
      });

      log(`Plano PRO ativado: userId=${userId} ate ${expiresAt.toISOString()}`);
      return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);

    } catch (e) {
      error("webhook error: " + e.message);
      return res.send(JSON.stringify({ error: "Erro interno" }), 500, CORS_HEADERS);
    }
  }

  // ── Verificar plano ──────────────────────────────────────────────────────
  if (req.method === "GET" && req.path === "/check-plan") {
    try {
      const userId = req.query?.userId;
      if (!userId) return res.send(JSON.stringify({ error: "userId obrigatorio" }), 400, CORS_HEADERS);

      const profiles = await db.listDocuments(DB_ID, COL_PROFILES, [
        Query.equal("userId", userId),
        Query.limit(1),
      ]);

      if (profiles.documents.length === 0) {
        return res.send(JSON.stringify({ planStatus: "free", planExpiresAt: null }), 200, CORS_HEADERS);
      }

      const doc = profiles.documents[0];
      const now = new Date();
      const expiresAt = doc.planExpiresAt ? new Date(doc.planExpiresAt) : null;

      if (doc.planStatus === "pro" && expiresAt && expiresAt < now) {
        await db.updateDocument(DB_ID, COL_PROFILES, doc.$id, {
          planStatus: "free",
          updatedAt: now.toISOString(),
        });
        return res.send(JSON.stringify({ planStatus: "free", planExpiresAt: null }), 200, CORS_HEADERS);
      }

      return res.send(JSON.stringify({
        planStatus: doc.planStatus || "free",
        planExpiresAt: doc.planExpiresAt || null,
      }), 200, CORS_HEADERS);

    } catch (e) {
      error("check-plan error: " + e.message);
      return res.send(JSON.stringify({ error: "Erro interno" }), 500, CORS_HEADERS);
    }
  }

  return res.send(JSON.stringify({ error: "Rota nao encontrada", path: req.path }), 404, CORS_HEADERS);
};
