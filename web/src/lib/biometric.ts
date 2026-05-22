/**
 * biometric.ts — Acesso rápido via biometria (WebAuthn/Passkeys)
 *
 * Funciona em mobile e desktop modernos (Android, iOS 16+, Windows Hello).
 * Não substitui o login — é um atalho após o primeiro login bem-sucedido.
 * As credenciais ficam no dispositivo; o app armazena apenas o userId no localStorage.
 */

const RP_ID = window.location.hostname;
const RP_NAME = "Bloquinho Digital";
const STORAGE_KEY = "biometric_credential_id";
const USER_KEY = "biometric_user_id";

/** Verifica se o dispositivo suporta WebAuthn com autenticador de plataforma (biometria) */
export async function isBiometricAvailable(): Promise<boolean> {
  if (!window.PublicKeyCredential) return false;
  try {
    return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
  } catch {
    return false;
  }
}

/** Verifica se já existe uma credencial biométrica registrada neste dispositivo */
export function hasBiometricCredential(): boolean {
  return !!localStorage.getItem(STORAGE_KEY);
}

/** Retorna o userId associado à credencial biométrica salva */
export function getBiometricUserId(): string | null {
  return localStorage.getItem(USER_KEY);
}

/**
 * Registra a biometria do dispositivo para o usuário logado.
 * Deve ser chamado após um login bem-sucedido com email/senha.
 */
export async function registerBiometric(userId: string, userName: string): Promise<boolean> {
  try {
    const challenge = crypto.getRandomValues(new Uint8Array(32));
    const userIdBytes = new TextEncoder().encode(userId);

    const credential = await navigator.credentials.create({
      publicKey: {
        rp: { id: RP_ID, name: RP_NAME },
        user: {
          id: userIdBytes,
          name: userName,
          displayName: userName,
        },
        challenge,
        pubKeyCredParams: [
          { type: "public-key", alg: -7 },   // ES256
          { type: "public-key", alg: -257 },  // RS256
        ],
        authenticatorSelection: {
          authenticatorAttachment: "platform",
          userVerification: "required",
          residentKey: "preferred",
        },
        timeout: 60000,
      },
    }) as PublicKeyCredential | null;

    if (!credential) return false;

    // Salva o ID da credencial e o userId no localStorage
    const credId = btoa(String.fromCharCode(...new Uint8Array(credential.rawId)));
    localStorage.setItem(STORAGE_KEY, credId);
    localStorage.setItem(USER_KEY, userId);
    return true;
  } catch {
    return false;
  }
}

/**
 * Autentica via biometria.
 * Retorna o userId se bem-sucedido, null se falhar ou cancelar.
 */
export async function authenticateWithBiometric(): Promise<string | null> {
  const credIdB64 = localStorage.getItem(STORAGE_KEY);
  const userId = localStorage.getItem(USER_KEY);
  if (!credIdB64 || !userId) return null;

  try {
    const credIdBytes = Uint8Array.from(atob(credIdB64), c => c.charCodeAt(0));
    const challenge = crypto.getRandomValues(new Uint8Array(32));

    const assertion = await navigator.credentials.get({
      publicKey: {
        challenge,
        rpId: RP_ID,
        allowCredentials: [{ type: "public-key", id: credIdBytes }],
        userVerification: "required",
        timeout: 60000,
      },
    });

    return assertion ? userId : null;
  } catch {
    return null;
  }
}

/** Remove a credencial biométrica salva neste dispositivo */
export function removeBiometricCredential(): void {
  localStorage.removeItem(STORAGE_KEY);
  localStorage.removeItem(USER_KEY);
}
