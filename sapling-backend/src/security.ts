const encoder = new TextEncoder();
const decoder = new TextDecoder();

export async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(value));
  return toHex(new Uint8Array(digest));
}

export async function encryptSecret(
  plaintext: string,
  base64Key: string,
): Promise<string> {
  const key = await importAesKey(base64Key, ['encrypt']);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: asArrayBuffer(iv) },
    key,
    asArrayBuffer(encoder.encode(plaintext)),
  );
  return `v1.${toBase64(iv)}.${toBase64(new Uint8Array(ciphertext))}`;
}

export async function decryptSecret(
  value: string,
  base64Key: string,
): Promise<string> {
  const [version, ivRaw, ciphertextRaw] = value.split('.');
  if (version !== 'v1' || !ivRaw || !ciphertextRaw) {
    throw new Error('Unsupported encrypted bank credential format.');
  }
  const key = await importAesKey(base64Key, ['decrypt']);
  const plaintext = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: asArrayBuffer(fromBase64(ivRaw)) },
    key,
    asArrayBuffer(fromBase64(ciphertextRaw)),
  );
  return decoder.decode(plaintext);
}

export function randomState(): string {
  return toBase64(crypto.getRandomValues(new Uint8Array(32)))
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}

export async function verifyHmacSha256(
  body: string,
  providedSignature: string,
  secret: string,
): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const expected = new Uint8Array(
    await crypto.subtle.sign('HMAC', key, encoder.encode(body)),
  );
  const normalized = providedSignature.replace(/^sha256=/i, '').trim();
  let provided: Uint8Array;
  try {
    provided = /^[0-9a-f]+$/i.test(normalized)
      ? fromHex(normalized)
      : fromBase64(normalized);
  } catch {
    return false;
  }
  return timingSafeEqual(expected, provided);
}

function timingSafeEqual(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) return false;
  let result = 0;
  for (let index = 0; index < left.length; index += 1) {
    result |= left[index] ^ right[index];
  }
  return result === 0;
}

async function importAesKey(
  base64Key: string,
  usages: KeyUsage[],
): Promise<CryptoKey> {
  const bytes = fromBase64(base64Key);
  if (bytes.length !== 32) {
    throw new Error('BANK_TOKEN_ENCRYPTION_KEY must be a base64-encoded 32-byte key.');
  }
  return crypto.subtle.importKey(
    'raw',
    asArrayBuffer(bytes),
    'AES-GCM',
    false,
    usages,
  );
}

function asArrayBuffer(value: Uint8Array): ArrayBuffer {
  return value.buffer.slice(
    value.byteOffset,
    value.byteOffset + value.byteLength,
  ) as ArrayBuffer;
}

function toBase64(value: Uint8Array): string {
  let binary = '';
  for (const byte of value) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function fromBase64(value: string): Uint8Array {
  const normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
  const binary = atob(padded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function toHex(value: Uint8Array): string {
  return [...value].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

function fromHex(value: string): Uint8Array {
  if (value.length % 2 !== 0) return new Uint8Array();
  return Uint8Array.from(
    value.match(/.{2}/g) ?? [],
    (byte) => Number.parseInt(byte, 16),
  );
}
