const https = require("https");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { createClient } = require("@supabase/supabase-js");

const PRICE_PER_MONTH = 29.90;
const MAX_MONTHS = 12;
const EFI_PIX_BASE = "https://pix.api.efipay.com.br";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const MP_PAYMENT_SECRETS = [
  "SUPABASE_SERVICE_ROLE_KEY",
  "EFI_CLIENT_ID",
  "EFI_CLIENT_SECRET",
  "EFI_CERT_BASE64",
  "EFI_PIX_KEY",
];

let supabaseAdmin = null;

function getSupabaseAdmin() {
  if (supabaseAdmin) return supabaseAdmin;

  const url = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY precisam estar configurados.");
  }

  supabaseAdmin = createClient(url, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
  return supabaseAdmin;
}

function sendJson(res, status, payload) {
  Object.entries(CORS_HEADERS).forEach(([key, value]) => res.set(key, value));
  return res.status(status).json(payload);
}

function getRoutePath(req) {
  const rawPath = req.path || new URL(req.url, "http://localhost").pathname || "/";
  return rawPath.replace(/^\/mpPayment(?=\/|$)/, "") || "/";
}

function createTlsAgent(certBase64, passphrase = "") {
  const pfx = Buffer.from(certBase64, "base64");
  return new https.Agent({ pfx, passphrase, rejectUnauthorized: true });
}

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

    const request = https.request(reqOptions, response => {
      let data = "";
      response.on("data", chunk => {
        data += chunk;
      });
      response.on("end", () => {
        resolve({ status: response.statusCode, headers: response.headers, text: data });
      });
    });

    request.on("error", reject);
    if (body) request.write(body);
    request.end();
  });
}

async function getPixToken(clientId, clientSecret, agent) {
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
  const result = await httpsRequest(
    `${EFI_PIX_BASE}/oauth/token`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${credentials}`,
        "Content-Type": "application/json",
      },
    },
    JSON.stringify({ grant_type: "client_credentials" }),
    agent
  );

  logger.info(`Pix auth status=${result.status}`);
  if (result.status !== 200) {
    throw new Error(`EFI Pix auth falhou (${result.status}): ${result.text.slice(0, 300)}`);
  }

  const data = JSON.parse(result.text);
  if (!data.access_token) {
    throw new Error("EFI Pix nao retornou access_token.");
  }
  return data.access_token;
}

function requirePixEnv() {
  const config = {
    clientId: process.env.EFI_CLIENT_ID,
    clientSecret: process.env.EFI_CLIENT_SECRET,
    certBase64: process.env.EFI_CERT_BASE64,
    pixKey: process.env.EFI_PIX_KEY,
  };

  const missing = Object.entries(config)
    .filter(([, value]) => !value)
    .map(([key]) => key);

  if (missing.length > 0) {
    throw new Error(`Variaveis EFI ausentes: ${missing.join(", ")}`);
  }

  return config;
}

async function createCharge(req, res) {
  const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
  const { userId, months, customerName, customerCpf } = body || {};
  const parsedMonths = Number.parseInt(months, 10);

  if (!userId || !parsedMonths || parsedMonths < 1 || parsedMonths > MAX_MONTHS) {
    return sendJson(res, 400, { error: "Parametros invalidos" });
  }

  if (!customerName || !customerCpf) {
    return sendJson(res, 400, { error: "Nome e CPF sao obrigatorios" });
  }

  const pixEnv = requirePixEnv();
  const agent = createTlsAgent(pixEnv.certBase64);
  const token = await getPixToken(pixEnv.clientId, pixEnv.clientSecret, agent);
  const totalValue = (PRICE_PER_MONTH * parsedMonths).toFixed(2);
  const label = parsedMonths === 1
    ? "Bloquinho Digital - Plano Pro 1 mes"
    : `Bloquinho Digital - Plano Pro ${parsedMonths} meses`;

  const cobPayload = {
    calendario: { expiracao: 1800 },
    devedor: {
      cpf: customerCpf.replace(/\D/g, ""),
      nome: customerName,
    },
    valor: { original: totalValue },
    chave: pixEnv.pixKey,
    solicitacaoPagador: label,
    infoAdicionais: [
      { nome: "userId", valor: userId },
      { nome: "meses", valor: String(parsedMonths) },
    ],
  };

  const cobResult = await httpsRequest(
    `${EFI_PIX_BASE}/v2/cob`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    },
    JSON.stringify(cobPayload),
    agent
  );

  const cobData = JSON.parse(cobResult.text);
  if (cobResult.status !== 201) {
    logger.error("Pix cob error", cobData);
    return sendJson(res, 500, { error: "Erro ao criar cobranca Pix", detail: cobData });
  }

  const qrResult = await httpsRequest(
    `${EFI_PIX_BASE}/v2/loc/${cobData.loc.id}/qrcode`,
    {
      method: "GET",
      headers: { Authorization: `Bearer ${token}` },
    },
    null,
    agent
  );

  let qrData = {};
  try {
    qrData = JSON.parse(qrResult.text);
  } catch {
    qrData = {};
  }

  return sendJson(res, 200, {
    txid: cobData.txid,
    pixCopiaECola: qrData.qrcode || cobData.pixCopiaECola,
    qrCodeImage: qrData.imagemQrcode || null,
    expiresIn: 1800,
  });
}

async function activatePlanFromPix(req, res) {
  const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
  const pixList = body?.pix || [];
  if (pixList.length === 0) {
    return sendJson(res, 200, { ok: true });
  }

  const pixEnv = requirePixEnv();
  const agent = createTlsAgent(pixEnv.certBase64);
  const token = await getPixToken(pixEnv.clientId, pixEnv.clientSecret, agent);
  const supabase = getSupabaseAdmin();
  const profilesTable = process.env.SUPABASE_PROFILES_TABLE || "users_profiles";

  for (const pix of pixList) {
    const txid = pix.txid;
    if (!txid) continue;

    const cobResult = await httpsRequest(
      `${EFI_PIX_BASE}/v2/cob/${txid}`,
      {
        method: "GET",
        headers: { Authorization: `Bearer ${token}` },
      },
      null,
      agent
    );

    let cobData;
    try {
      cobData = JSON.parse(cobResult.text);
    } catch {
      logger.warn(`Webhook Pix sem JSON valido para txid=${txid}`);
      continue;
    }

    if (cobData.status !== "CONCLUIDA") continue;

    const infos = cobData.infoAdicionais || [];
    const userId = infos.find(info => info.nome === "userId")?.valor;
    const months = Number.parseInt(infos.find(info => info.nome === "meses")?.valor || "0", 10);
    if (!userId || !months || months < 1) {
      logger.error(`Webhook Pix com userId/meses invalidos txid=${txid}`);
      continue;
    }

    const expiresAt = new Date();
    expiresAt.setMonth(expiresAt.getMonth() + months);

    const { data: profiles, error: selectError } = await supabase
      .from(profilesTable)
      .select("id")
      .eq("userId", userId)
      .limit(1);

    if (selectError) throw selectError;
    if (!profiles || profiles.length === 0) {
      logger.error(`Perfil nao encontrado para userId=${userId}`);
      continue;
    }

    const { error: updateError } = await supabase
      .from(profilesTable)
      .update({
        planStatus: "pro",
        planExpiresAt: expiresAt.toISOString(),
        updatedAt: new Date().toISOString(),
      })
      .eq("id", profiles[0].id);

    if (updateError) throw updateError;
    logger.info(`Plano PRO ativado via Pix: userId=${userId} meses=${months}`);
  }

  return sendJson(res, 200, { ok: true });
}

async function checkPlan(req, res) {
  const userId = req.query?.userId;
  if (!userId) {
    return sendJson(res, 400, { error: "userId obrigatorio" });
  }

  const supabase = getSupabaseAdmin();
  const profilesTable = process.env.SUPABASE_PROFILES_TABLE || "users_profiles";
  const { data: profiles, error: selectError } = await supabase
    .from(profilesTable)
    .select("id, planStatus, planExpiresAt")
    .eq("userId", userId)
    .limit(1);

  if (selectError) throw selectError;
  if (!profiles || profiles.length === 0) {
    return sendJson(res, 200, { planStatus: "free", planExpiresAt: null });
  }

  const profile = profiles[0];
  const now = new Date();
  const expiresAt = profile.planExpiresAt ? new Date(profile.planExpiresAt) : null;

  if (profile.planStatus === "pro" && expiresAt && expiresAt < now) {
    const { error: updateError } = await supabase
      .from(profilesTable)
      .update({
        planStatus: "free",
        updatedAt: now.toISOString(),
      })
      .eq("id", profile.id);

    if (updateError) throw updateError;
    return sendJson(res, 200, { planStatus: "free", planExpiresAt: null });
  }

  return sendJson(res, 200, {
    planStatus: profile.planStatus || "free",
    planExpiresAt: profile.planExpiresAt || null,
  });
}

exports.hello = onRequest((_req, res) => {
  res.status(200).send("bloquinhodigital: functions ok");
});

exports.mpPayment = onRequest(
  {
    region: "southamerica-east1",
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: MP_PAYMENT_SECRETS,
  },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      Object.entries(CORS_HEADERS).forEach(([key, value]) => res.set(key, value));
      return res.status(204).send("");
    }

    const routePath = getRoutePath(req);
    logger.info(`${req.method} ${routePath}`);

    try {
      if (req.method === "POST" && routePath === "/create-charge") {
        return await createCharge(req, res);
      }

      if (req.method === "POST" && routePath === "/webhook") {
        return await activatePlanFromPix(req, res);
      }

      if (req.method === "GET" && routePath === "/check-plan") {
        return await checkPlan(req, res);
      }

      return sendJson(res, 404, { error: "Rota nao encontrada", path: routePath });
    } catch (error) {
      logger.error("mpPayment error", error);
      return sendJson(res, 500, {
        error: error instanceof Error ? error.message : "Erro interno",
      });
    }
  }
);
