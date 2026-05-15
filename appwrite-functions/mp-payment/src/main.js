import { Client, Databases, Query } from "node-appwrite";

const PLAN_PRICES = {
  monthly: { amountCents: 2990, label: "Plano Pro — Mensal", months: 1 },
  yearly:  { amountCents: 29990, label: "Plano Pro — Anual (12 meses)", months: 12 },
};

export default async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const db = new Databases(client);
  const DB_ID = process.env.APPWRITE_DATABASE_ID;
  const COL_PROFILES = process.env.APPWRITE_COLLECTION_PROFILES;
  const MP_TOKEN = process.env.MP_ACCESS_TOKEN;
  const APP_URL = process.env.APP_BASE_URL || "https://bloquinhodigital.web.app";

  // ── Criar preferência de pagamento ──────────────────────────────────────
  if (req.method === "POST" && req.path === "/create-preference") {
    try {
      const { userId, plan } = req.body;
      if (!userId || !plan || !PLAN_PRICES[plan]) {
        return res.json({ error: "Parâmetros inválidos" }, 400);
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
          notification_url: `${process.env.FUNCTION_URL}/webhook`,
          statement_descriptor: "BLOQUINHO DIGITAL",
          payment_methods: {
            excluded_payment_types: [],
            installments: plan === "monthly" ? 1 : 12,
          },
        }),
      });

      const mpData = await mpRes.json();
      if (!mpRes.ok) {
        error("MP error: " + JSON.stringify(mpData));
        return res.json({ error: "Erro ao criar preferência" }, 500);
      }

      log(`Preferência criada: ${mpData.id} para userId=${userId} plano=${plan}`);
      return res.json({
        preferenceId: mpData.id,
        initPoint: mpData.init_point,
        sandboxInitPoint: mpData.sandbox_init_point,
      });
    } catch (e) {
      error("create-preference error: " + e.message);
      return res.json({ error: "Erro interno" }, 500);
    }
  }

  // ── Webhook do Mercado Pago ──────────────────────────────────────────────
  if (req.method === "POST" && req.path === "/webhook") {
    try {
      const { type, data } = req.body;
      log(`Webhook recebido: type=${type} id=${data?.id}`);

      if (type !== "payment") return res.json({ ok: true });

      // Buscar detalhes do pagamento no MP
      const payRes = await fetch(`https://api.mercadopago.com/v1/payments/${data.id}`, {
        headers: { "Authorization": `Bearer ${MP_TOKEN}` },
      });
      const payment = await payRes.json();

      log(`Pagamento ${data.id}: status=${payment.status} ref=${payment.external_reference}`);

      if (payment.status !== "approved") return res.json({ ok: true });

      // external_reference = "userId|plan"
      const [userId, plan] = (payment.external_reference || "").split("|");
      if (!userId || !plan || !PLAN_PRICES[plan]) {
        error("external_reference inválido: " + payment.external_reference);
        return res.json({ ok: true });
      }

      // Calcular expiração
      const months = PLAN_PRICES[plan].months;
      const expiresAt = new Date();
      expiresAt.setMonth(expiresAt.getMonth() + months);

      // Atualizar perfil no Appwrite
      const profiles = await db.listDocuments(DB_ID, COL_PROFILES, [
        Query.equal("userId", userId),
        Query.limit(1),
      ]);

      if (profiles.documents.length === 0) {
        error("Perfil não encontrado para userId: " + userId);
        return res.json({ ok: true });
      }

      await db.updateDocument(DB_ID, COL_PROFILES, profiles.documents[0].$id, {
        planStatus: "pro",
        planExpiresAt: expiresAt.toISOString(),
        updatedAt: new Date().toISOString(),
      });

      log(`✅ Plano PRO ativado para userId=${userId} até ${expiresAt.toISOString()}`);
      return res.json({ ok: true });
    } catch (e) {
      error("webhook error: " + e.message);
      return res.json({ error: "Erro interno" }, 500);
    }
  }

  // ── Verificar status do plano (chamado pelo frontend após retorno do MP) ─
  if (req.method === "GET" && req.path === "/check-plan") {
    try {
      const userId = req.query?.userId;
      if (!userId) return res.json({ error: "userId obrigatório" }, 400);

      const profiles = await db.listDocuments(DB_ID, COL_PROFILES, [
        Query.equal("userId", userId),
        Query.limit(1),
      ]);

      if (profiles.documents.length === 0) {
        return res.json({ planStatus: "free", planExpiresAt: null });
      }

      const doc = profiles.documents[0];
      const now = new Date();
      const expiresAt = doc.planExpiresAt ? new Date(doc.planExpiresAt) : null;

      // Se expirou, rebaixa para free
      if (doc.planStatus === "pro" && expiresAt && expiresAt < now) {
        await db.updateDocument(DB_ID, COL_PROFILES, doc.$id, {
          planStatus: "free",
          updatedAt: now.toISOString(),
        });
        return res.json({ planStatus: "free", planExpiresAt: null });
      }

      return res.json({
        planStatus: doc.planStatus || "free",
        planExpiresAt: doc.planExpiresAt || null,
      });
    } catch (e) {
      error("check-plan error: " + e.message);
      return res.json({ error: "Erro interno" }, 500);
    }
  }

  return res.json({ error: "Rota não encontrada" }, 404);
};
