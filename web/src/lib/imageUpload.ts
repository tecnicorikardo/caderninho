/**
 * imageUpload.ts
 *
 * Compressão de imagem no cliente + armazenamento como Base64 no Firestore.
 * Compatível com Firebase plano Spark (sem Firebase Storage).
 *
 * Fluxo:
 *   1. Usuário seleciona arquivo (JPG, PNG ou WebP)
 *   2. compressImage() reduz para ≤ 300KB e ≤ 800px usando Web Worker
 *   3. imageToBase64() converte para string Base64
 *   4. A string é salva diretamente no documento Firestore do produto
 */

import imageCompression from "browser-image-compression";

// Formatos aceitos
const ACCEPTED_TYPES = ["image/jpeg", "image/png", "image/webp"];

export class ImageUploadError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ImageUploadError";
  }
}

/**
 * Valida o tipo do arquivo antes de processar.
 */
export function validateImageFile(file: File): void {
  if (!ACCEPTED_TYPES.includes(file.type)) {
    throw new ImageUploadError("Formato inválido. Use JPG, PNG ou WebP.");
  }
}

/**
 * Comprime a imagem no cliente usando Web Worker.
 * Garante: ≤ 300KB, ≤ 800px de largura/altura, proporção mantida.
 */
export async function compressImage(file: File): Promise<File> {
  validateImageFile(file);

  const compressed = await imageCompression(file, {
    maxSizeMB: 0.3,          // 300KB
    maxWidthOrHeight: 800,   // px
    useWebWorker: true,      // não trava a interface
    fileType: file.type as "image/jpeg" | "image/png" | "image/webp",
    initialQuality: 0.8,
  });

  return compressed;
}

/**
 * Converte um File/Blob para string Base64 (data URL).
 * Ex: "data:image/jpeg;base64,/9j/4AAQ..."
 */
export function imageToBase64(file: File | Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(new ImageUploadError("Erro ao ler o arquivo."));
    reader.readAsDataURL(file);
  });
}

/**
 * Pipeline completo: valida → comprime → converte para Base64.
 * Retorna a string Base64 pronta para salvar no Firestore.
 *
 * @param file - Arquivo selecionado pelo usuário
 * @param onProgress - Callback opcional com status textual
 */
export async function processImageForStorage(
  file: File,
  onProgress?: (status: string) => void
): Promise<string> {
  validateImageFile(file);

  onProgress?.("Comprimindo imagem…");
  const compressed = await compressImage(file);

  onProgress?.("Preparando upload…");
  const base64 = await imageToBase64(compressed);

  return base64;
}
