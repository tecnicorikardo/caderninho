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

// Obtém token OAuth2 da EFI (produção)
async function getEfiToken(clientId, clientSecret) {
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
  const res = await fetch("https://api.efipay.com.br/v1/authorize", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ grant_type: "client_credentials" }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error("EFI auth error: " + JSON.stringify(data));
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
  const DB_ID       = process.env.APPWRITE_DATABASE_ID;
  const COL_PROFILES = process.env.APPWRITE_COLLECTION_PROFILES;
  const EFI_CLIENT_ID     = process.env.EFI_CLIENT_ID;
  const EFI_CLIENT_SECRET = process.env.EFI_CLIENT_SECRET;
  const APP_URL = process.env.APP_BASE_URL || "https://bloquinhodigital.web.app";

  log(`${req.method} ${req.path}`);

  // ── Criar cobrança EFI ───────────────────────────────────────────────────
  if (req.method === "POST" && req.path === "/create-charge") {
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      const { userId, plan, customerName, customerCpf, customerEmail, customerPhone } = body || {};

      if (!userId || !plan || !PLAN_PRICES[plan]) {
        return res.send(JSON.stringify({ error: "Parametros invalidos" }), 400, CORS_HEADERS);
      }
      if (!customerName || !customerCpf) {
        return res.send(JSON.stringify({ error: "Nome e CPF sao obrigatorios" }), 400, CORS_HEADERS);
      }

      const price = PLAN_PRICES[plan];
      const token = await getEfiToken(EFI_CLIENT_ID, EFI_CLIENT_SECRET);

      // Criar cobrança com link de pagamento (boleto + pix + cartão)
      const chargeRes = await fetch("https://api.efipay.com.br/v1/charge", {
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
          metadata: {
            custom_id: `${userId}|${plan}`,
            notification_url: `${process.env.FUNCTION_URL}/webhook`,
          },
          settings: {
            payment_method: "all",
            return_url: `${APP_URL}/payment-success?plan=${plan}&userId=${userId}`,
          },
        }),
      });

      const chargeData = await chargeRes.json();
      if (!chargeRes.ok) {
        error("EFI charge error: " + JSON.stringify(chargeData));
        return res.send(JSON.stringify({ error: "Erro ao criar cobranca EFI", detail: chargeData }), 500, CORS_HEADERS);
      }

      const chargeId = chargeData.data?.charge_id;

      // Gerar link de pagamento
      const linkRes = await fetch(`https://api.efipay.com.br/v1/charge/${chargeId}/link`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          billet_discount: 0,
          card_discount: 0,
          conditional_discount: { type: "percentage", value: 0, until_date: "" },
          message: "",
          expire_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split("T")[0],
          request_delivery_address: false,
          payment_method: "all",
        }),
      });

      const linkData = await linkRes.json();
      if (!linkRes.ok) {
        error("EFI link error: " + JSON.stringify(linkData));
        return res.send(JSON.stringify({ error: "Erro ao gerar link de pagamento", detail: linkData }), 500, CORS_HEADERS);
      }

      log(`Cobranca criada: charge_id=${chargeId} userId=${userId} plano=${plan}`);
      return res.send(JSON.stringify({
        chargeId,
        paymentUrl: linkData.data?.payment_url,
        status: chargeData.data?.status,
      }), 200, CORS_HEADERS);

    } catch (e) {
      error("create-charge error: " + e.message);
      return res.send(JSON.stringify({ error: "Erro interno: " + e.message }), 500, CORS_HEADERS);
    }
  }

  // ── Webhook EFI ──────────────────────────────────────────────────────────
  if (req.method === "POST" && req.path === "/webhook") {
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      log("Webhook EFI recebido: " + JSON.stringify(body));

      const chargeId = body?.charge_id || body?.data?.charge_id;
      const status   = body?.status    || body?.data?.status;

      if (!chargeId || status !== "paid") {
        return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);
      }

      // Buscar detalhes da cobrança para pegar o custom_id (userId|plan)
      const token = await getEfiToken(EFI_CLIENT_ID, EFI_CLIENT_SECRET);
      const detailRes = await fetch(`https://api.efipay.com.br/v1/charge/${chargeId}`, {
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
