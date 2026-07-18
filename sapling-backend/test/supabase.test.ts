import { describe, expect, it, vi } from 'vitest';

import { authenticateUser, SupabaseRest } from '../src/supabase';

const env = {
  SUPABASE_URL: 'https://project.supabase.co',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
  SUPABASE_SECRET_KEY: 'sb_secret_test',
};

describe('Supabase bank gateway', () => {
  it('rejects unauthenticated callers before making a network request', async () => {
    const fetchImpl = vi.fn<typeof fetch>();

    await expect(
      authenticateUser(new Request('https://api.test/bank/status'), env, fetchImpl),
    ).rejects.toMatchObject({
      status: 401,
      code: 'bank_auth_required',
    });
    expect(fetchImpl).not.toHaveBeenCalled();
  });

  it('validates the user JWT with the publishable key', async () => {
    const fetchImpl = vi.fn<typeof fetch>().mockResolvedValue(
      Response.json({ id: 'user-1' }),
    );
    const request = new Request('https://api.test/bank/status', {
      headers: { authorization: 'Bearer user-jwt' },
    });

    expect(await authenticateUser(request, env, fetchImpl)).toEqual({ id: 'user-1' });
    expect(fetchImpl).toHaveBeenCalledWith(
      'https://project.supabase.co/auth/v1/user',
      {
        headers: {
          apikey: 'sb_publishable_test',
          authorization: 'Bearer user-jwt',
        },
      },
    );
  });

  it('uses the Worker-only secret as an apikey, never as a bearer token', async () => {
    const fetchImpl = vi.fn<typeof fetch>().mockResolvedValue(
      Response.json([{ id: 'connection-1' }]),
    );
    const gateway = new SupabaseRest(env, fetchImpl);

    await gateway.select('bank_connections', new URLSearchParams({ select: '*' }));

    const headers = (fetchImpl.mock.calls[0][1] as RequestInit).headers as Record<
      string,
      string
    >;
    expect(headers.apikey).toBe('sb_secret_test');
    expect(headers.authorization).toBeUndefined();
  });
});
