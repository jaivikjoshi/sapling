import { describe, expect, it } from 'vitest';

import {
  decryptSecret,
  encryptSecret,
  sha256,
  verifyHmacSha256,
} from '../src/security';

describe('bank credential security', () => {
  it('encrypts and decrypts provider identifiers with AES-256-GCM', async () => {
    const key = btoa(String.fromCharCode(...new Uint8Array(32).fill(7)));
    const encrypted = await encryptSecret('login-id-sensitive', key);

    expect(encrypted).not.toContain('login-id-sensitive');
    expect(await decryptSecret(encrypted, key)).toBe('login-id-sensitive');
  });

  it('validates Flinks webhook HMAC signatures without string comparison', async () => {
    const body = '{"ResponseType":"GetAccountsDetail"}';
    const secret = 'webhook-secret';
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign'],
    );
    const bytes = new Uint8Array(
      await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body)),
    );
    const signature = [...bytes]
      .map((byte) => byte.toString(16).padStart(2, '0'))
      .join('');

    expect(await verifyHmacSha256(body, signature, secret)).toBe(true);
    expect(await verifyHmacSha256(`${body} `, signature, secret)).toBe(false);
  });

  it('hashes callback state deterministically', async () => {
    expect(await sha256('state')).toHaveLength(64);
    expect(await sha256('state')).toBe(await sha256('state'));
  });
});
