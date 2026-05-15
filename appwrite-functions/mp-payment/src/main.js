import { Client, Databases, Query } from "node-appwrite";

const PLAN_PRICES = {
  monthly: { amountCents: 2990, label: "Plano Pro — Mensal", months: 1 },
  yearly:  { amountCents: 29990, label: "Plano Pro — Anual (12 meses)", months: 12 },
};

// Headers CORS para permitir chamadas do frontend
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

export default async ({ req, res, log, error }) => {
  // Responde preflight OPTIONS imediatamente
  if (req.method === "OPTIONS") {
    return res.send("", 204, CORS_HEADERS);
  }

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const db = new Databases(client);
  const DB_ID = process.env.APPWRITE_DATABASE_ID;
  const COL_PROFILES = process.env.APPWRITE_COLLECTION_PROFILES;
  const MP_TOKEN = process.env.MP_ACCESS_TOKEN;
  const APP_URL = process.env.APP_BASE_URL || "https://bloquinhodigital.web.app";
  const FUNCTION_URL = process.env.FUNCTION_URL || "";

  log(`${req.method} ${req.path}`);

  // ── Criar preferência de pagamento ──────────────────────────────────────
  if (req.method === "POST" && req.path === "/create-preference") {
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      const { userId, plan } = body || {};

      if (!userId || !plan || !PLAN_PRICES[plan]) {
        return res.send(JSON.stringify({ error: "Parâmetros inválidos" }), 400, CORS_HEADERS);
      }

      const price = PLAN_PRICES[plan];

      const mpRes = await fetch("https://api.mercadopago.com/checkout/preferences", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${MP_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          items: [{
            title: price.label,
            quantity: 1,
            unit_price: price.amountCents / 100,
            currency_id: "BRL",
          }],
          back_urls: {
            success: `${APP_URL}/payment-success?plan=${plan}&userId=${userId}`,
            failure: `${APP_URL}/plans?error=payment_failed`,
            pending: `${APP_URL}/plans?status=pending`,
          },
          auto_return: "approved",
          external_reference: `${userId}|${plan}`,
          notification_url: `${FUNCTION_URL}/webhook`,
          statement_descriptor: "BLOQUINHO DIGITAL",
        }),
      });

      const mpData = await mpRes.json();
      if (!mpRes.ok) {
        error("MP error: " + JSON.stringify(mpData));
        return res.send(JSON.stringify({ error: "Erro ao criar preferência MP" }), 500, CORS_HEADERS);
      }

      log(`Preferência criada: ${mpData.id} para userId=${userId} plano=${plan}`);
      return res.send(JSON.stringify({
        preferenceId: mpData.id,
        initPoint: mpData.init_point,
        sandboxInitPoint: mpData.sandbox_init_point,
      }), 200, CORS_HEADERS);

    } catch (e) {
      error("create-preference error: " + e.message);
      return res.send(JSON.stringify({ error: "Erro interno: " + e.message }), 500, CORS_HEADERS);
    }
  }

  // ── Webhook do Mercado Pago ──────────────────────────────────────────────
  if (req.method === "POST" && req.path === "/webhook") {
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      const { type, data } = body || {};
      log(`Webhook recebido: type=${type} id=${data?.id}`);

      if (type !== "payment") return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);

      const payRes = await fetch(`https://api.mercadopago.com/v1/payments/${data.id}`, {
        headers: { "Authorization": `Bearer ${MP_TOKEN}` },
      });
      const payment = await payRes.json();

      log(`Pagamento ${data.id}: status=${payment.status} ref=${payment.external_reference}`);

      if (payment.status !== "approved") {
        return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);
      }

      const [userId, plan] = (payment.external_reference || "").split("|");
      if (!userId || !plan || !PLAN_PRICES[plan]) {
        error("external_reference inválido: " + payment.external_reference);
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
        error("Perfil não encontrado para userId: " + userId);
        return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);
      }

      await db.updateDocument(DB_ID, COL_PROFILES, profiles.documents[0].$id, {
        planStatus: "pro",
        planExpiresAt: expiresAt.toISOString(),
        updatedAt: new Date().toISOString(),
      });

      log(`✅ Plano PRO ativado para userId=${userId} até ${expiresAt.toISOString()}`);
      return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);

    } catch (e) {
      error("webhook error: " + e.message);
      return res.send(JSON.stringify({ error: "Erro interno" }), 500, CORS_HEADERS);
    }
  }

  // ── Verificar status do plano ────────────────────────────────────────────
  if (req.method === "GET" && req.path === "/check-plan") {
    try {
      const userId = req.query?.userId;
      if (!userId) {
        return res.send(JSON.stringify({ error: "userId obrigatório" }), 400, CORS_HEADERS);
      }

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

  return res.send(JSON.stringify({ error: "Rota não encontrada", path: req.path, method: req.method }), 404, CORS_HEADERS);
};
