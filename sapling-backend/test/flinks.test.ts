import { describe, expect, it, vi } from 'vitest';

import {
  buildFlinksConnectionIntent,
  fetchFlinksAccountData,
} from '../src/flinks';

const liveEnv = {
  FLINKS_API_BASE_URL: 'https://toolbox-api.private.fin.ag',
  FLINKS_CONNECT_URL: 'https://toolbox-iframe.private.fin.ag/v2/',
  FLINKS_CUSTOMER_ID: 'customer-1',
  FLINKS_SECRET_KEY: 'secret-1',
  FLINKS_X_API_KEY: 'data-key-1',
  FLINKS_SANDBOX: 'true',
};

describe('Flinks production adapter', () => {
  it('generates a one-time token before building a state-bound Connect URL', async () => {
    const fetchImpl = vi.fn<typeof fetch>().mockResolvedValue(
      Response.json({ Token: 'authorize-token-1' }),
    );

    const intent = await buildFlinksConnectionIntent(
      new Request('https://api.leko.test/bank/connect'),
      liveEnv,
      'state-1',
      { fetchImpl },
    );

    expect(fetchImpl).toHaveBeenCalledWith(
      'https://toolbox-api.private.fin.ag/v3/customer-1/BankingServices/GenerateAuthorizeToken',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({ 'flinks-auth-key': 'secret-1' }),
      }),
    );
    const url = new URL(intent.authorizationUrl!);
    expect(url.searchParams.get('authorizeToken')).toBe('authorize-token-1');
    expect(url.searchParams.get('demo')).toBe('true');
    expect(url.searchParams.get('accountSelectorMultiple')).toBe('true');
    expect(url.searchParams.get('redirectURL')).toContain('state=state-1');
  });

  it('authorizes the loginId and requests only account/transaction data', async () => {
    const fetchImpl = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(Response.json({ Token: 'authorize-token-2' }))
      .mockResolvedValueOnce(
        Response.json({ RequestId: 'request-1', InstitutionName: 'Flinks Capital' }),
      )
      .mockResolvedValueOnce(
        Response.json({
          InstitutionName: 'Flinks Capital',
          Accounts: [
            {
              Id: 'account-1',
              Title: 'Chequing',
              AccountNumber: '00001234',
              Currency: 'CAD',
              Transactions: [
                {
                  Id: 'transaction-1',
                  Date: '2026-07-16',
                  Description: 'Grocer',
                  Debit: 25.4,
                },
              ],
            },
          ],
        }),
      );

    const snapshot = await fetchFlinksAccountData(
      liveEnv,
      'login-1',
      undefined,
      ['account-1'],
      { fetchImpl },
    );

    const authorizeCall = fetchImpl.mock.calls[1];
    expect(authorizeCall[0]).toContain('/Authorize');
    expect(JSON.parse(String((authorizeCall[1] as RequestInit).body))).toMatchObject({
      LoginId: 'login-1',
      MostRecentCached: true,
      Save: true,
    });
    const detailsCall = fetchImpl.mock.calls[2];
    const detailsBody = JSON.parse(String((detailsCall[1] as RequestInit).body));
    expect(detailsBody).toMatchObject({
      RequestId: 'request-1',
      WithAccountIdentity: false,
      WithKYC: false,
      WithTransactions: true,
      AccountsFilter: ['account-1'],
    });
    expect(snapshot.accounts).toHaveLength(1);
    expect(snapshot.accounts[0].mask).toBe('1234');
    expect(snapshot.drafts[0].sourceId).toBe('account-1:transaction-1');
  });

  it('surfaces a RequestId when account data is still processing', async () => {
    const fetchImpl = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(Response.json({ Token: 'authorize-token-3' }))
      .mockResolvedValueOnce(Response.json({ RequestId: 'request-pending' }))
      .mockResolvedValueOnce(new Response(null, { status: 202 }));

    await expect(
      fetchFlinksAccountData(liveEnv, 'login-2', undefined, [], { fetchImpl }),
    ).rejects.toMatchObject({ requestId: 'request-pending' });
  });
});
