import { Client, Databases, Query } from "node-appwrite";
import https from "https";

const PLAN_PRICES = {
  monthly: { amountCents: 29.90, label: "Bloquinho Digital - Plano Pro Mensal", months: 1  },
  yearly:  { amountCents: 299.90, label: "Bloquinho Digital - Plano Pro Anual",  months: 12 },
};

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json",
};

// URL base da API Pix EFI (producao)
const EFI_PIX_BASE = "https://pix.api.efipay.com.br";

/**
 * Cria um agente HTTPS com o certificado mTLS (.p12 em base64).
 * A API Pix da EFI exige autenticacao mutua TLS em todas as requisicoes.
 */
function createTlsAgent(certBase64, passphrase = "") {
  const pfx = Buffer.from(certBase64, "base64");
  return new https.Agent({ pfx, passphrase, rejectUnauthorized: true });
}

/**
 * Faz uma requisicao HTTPS com suporte a mTLS usando o modulo nativo do Node.
 * O fetch nativo nao suporta mTLS, por isso usamos http.request diretamente.
 */
function httpsRequest(url, options, body, agent) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const reqOptions = {
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      method: options.method || "GET",
      headers: options.headers || {},
      agent,
    };

    const req = https.request(reqOptions, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, text: data }));
    });

    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

/**
 * Obtem o access_token da API Pix EFI via OAuth2 com mTLS.
 */
async function getPixToken(clientId, clientSecret, agent, logFn) {
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

  const result = await httpsRequest(
    `${EFI_PIX_BASE}/oauth/token`,
    {
      method: "POST",
      headers: {
        "Authorization": `Basic ${credentials}`,
        "Content-Type": "application/json",
      },
    },
    JSON.stringify({ grant_type: "client_credentials" }),
    agent
  );

  logFn(`Pix auth status=${result.status} body=${result.text.slice(0, 200)}`);

  if (result.status !== 200) {
    throw new Error(`EFI Pix auth falhou (${result.status}): ${result.text.slice(0, 300)}`);
  }

  let data;
  try { data = JSON.parse(result.text); } catch {
    throw new Error("EFI Pix auth parse error: " + result.text.slice(0, 300));
  }
  if (!data.access_token) throw new Error("EFI Pix sem access_token: " + result.text.slice(0, 300));
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
  const EFI_CERT_BASE64   = process.env.EFI_CERT_BASE64;
  const APP_URL      = process.env.APP_BASE_URL || "https://bloquinhodigital.web.app";
  const FUNCTION_URL = process.env.FUNCTION_URL || "";

  log(`${req.method} ${req.path}`);
  log(`EFI_CLIENT_ID presente: ${!!EFI_CLIENT_ID} | tamanho: ${EFI_CLIENT_ID?.length ?? 0}`);
  log(`EFI_CLIENT_SECRET presente: ${!!EFI_CLIENT_SECRET} | tamanho: ${EFI_CLIENT_SECRET?.length ?? 0}`);
  log(`EFI_CERT_BASE64 presente: ${!!EFI_CERT_BASE64} | tamanho: ${EFI_CERT_BASE64?.length ?? 0}`);

  if (!EFI_CERT_BASE64) {
    error("EFI_CERT_BASE64 nao configurado");
    return res.send(JSON.stringify({ error: "Certificado EFI nao configurado" }), 500, CORS_HEADERS);
  }

  // ── Criar cobranca Pix ───────────────────────────────────────────────────
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
      const agent = createTlsAgent(EFI_CERT_BASE64);
      const token = await getPixToken(EFI_CLIENT_ID, EFI_CLIENT_SECRET, agent, log);

      // Validade da cobranca Pix: 30 minutos (em segundos)
      const expiracao = 1800;

      const cobPayload = {
        calendario: { expiracao },
        devedor: {
          cpf: customerCpf.replace(/\D/g, ""),
          nome: customerName,
        },
        valor: {
          original: price.amountCents.toFixed(2),
        },
        chave: process.env.EFI_PIX_KEY, // chave Pix cadastrada na conta EFI
        solicitacaoPagador: price.label,
        infoAdicionais: [
          { nome: "userId", valor: userId },
          { nome: "plano",  valor: plan   },
        ],
      };

      log("Pix cob payload: " + JSON.stringify(cobPayload));

      const cobResult = await httpsRequest(
        `${EFI_PIX_BASE}/v2/cob`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        },
        JSON.stringify(cobPayload),
        agent
      );

      log("Pix cob status: " + cobResult.status);
      log("Pix cob response: " + cobResult.text.slice(0, 500));

      let cobData;
      try { cobData = JSON.parse(cobResult.text); } catch {
        error("Pix cob parse error: " + cobResult.text.slice(0, 300));
        return res.send(JSON.stringify({ error: "Resposta inesperada da EFI Pix: " + cobResult.text.slice(0, 200) }), 500, CORS_HEADERS);
      }

      if (cobResult.status !== 201) {
        error("Pix cob error: " + JSON.stringify(cobData));
        return res.send(JSON.stringify({ error: "Erro ao criar cobranca Pix", detail: cobData }), 500, CORS_HEADERS);
      }

      const txid = cobData.txid;
      const pixCopiaECola = cobData.pixCopiaECola;

      // Gera o QR Code da cobranca
      const qrResult = await httpsRequest(
        `${EFI_PIX_BASE}/v2/loc/${cobData.loc.id}/qrcode`,
        {
          method: "GET",
          headers: { "Authorization": `Bearer ${token}` },
        },
        null,
        agent
      );

      log("Pix QR status: " + qrResult.status);

      let qrData = {};
      try { qrData = JSON.parse(qrResult.text); } catch { /* ignora */ }

      const qrCodeImage = qrData.imagemQrcode || null;
      const qrCodeText  = qrData.qrcode || pixCopiaECola;

      log(`Pix criado: txid=${txid} userId=${userId} plano=${plan}`);

      return res.send(JSON.stringify({
        txid,
        pixCopiaECola: qrCodeText,
        qrCodeImage,
        expiresIn: expiracao,
      }), 200, CORS_HEADERS);

    } catch (e) {
      error("create-charge error: " + e.message);
      return res.send(JSON.stringify({ error: "Erro interno: " + e.message }), 500, CORS_HEADERS);
    }
  }

  // ── Webhook Pix EFI ──────────────────────────────────────────────────────
  // A EFI envia POST /webhook com o corpo: { "pix": [{ "txid", "valor", "horario", ... }] }
  if (req.method === "POST" && req.path === "/webhook") {
    try {
      const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
      log("Webhook Pix: " + JSON.stringify(body));

      const pixList = body?.pix || [];
      if (pixList.length === 0) {
        return res.send(JSON.stringify({ ok: true }), 200, CORS_HEADERS);
      }

      const agent = createTlsAgent(EFI_CERT_BASE64);
      const token = await getPixToken(EFI_CLIENT_ID, EFI_CLIENT_SECRET, agent, log);

      for (const pix of pixList) {
        const txid = pix.txid;
        if (!txid) continue;

        // Consulta a cobranca para pegar as infoAdicionais (userId e plano)
        const cobResult = await httpsRequest(
          `${EFI_PIX_BASE}/v2/cob/${txid}`,
          {
            method: "GET",
            headers: { "Authorization": `Bearer ${token}` },
          },
          null,
          agent
        );

        let cobData;
        try { cobData = JSON.parse(cobResult.text); } catch { continue; }

        if (cobData.status !== "CONCLUIDA") continue;

        const infos = cobData.infoAdicionais || [];
        const userId = infos.find(i => i.nome === "userId")?.valor;
        const plan   = infos.find(i => i.nome === "plano")?.valor;

        if (!userId || !plan || !PLAN_PRICES[plan]) {
          error("Webhook Pix: userId/plano invalido txid=" + txid);
          continue;
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
          continue;
        }

        await db.updateDocument(DB_ID, COL_PROFILES, profiles.documents[0].$id, {
          planStatus: "pro",
          planExpiresAt: expiresAt.toISOString(),
          updatedAt: new Date().toISOString(),
        });

        log(`Plano PRO ativado via Pix: userId=${userId} ate ${expiresAt.toISOString()}`);
      }

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
