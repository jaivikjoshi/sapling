import type { ImportedTransactionDraft } from './bankSchemas';

export interface FlinksEnv {
  BANK_DEV_MODE?: string;
  FLINKS_API_BASE_URL?: string;
  FLINKS_CONNECT_URL?: string;
  FLINKS_CUSTOMER_ID?: string;
  FLINKS_SECRET_KEY?: string;
  FLINKS_X_API_KEY?: string;
  FLINKS_REDIRECT_URL?: string;
  FLINKS_APP_RETURN_URL?: string;
  FLINKS_SANDBOX?: string;
  FLINKS_WEBHOOK_HMAC_SECRET?: string;
}

interface FlinksDeps {
  fetchImpl: typeof fetch;
}

export interface BankConnectionIntent {
  providerId: string;
  displayName: string;
  consentCopy: string;
  authorizationUrl?: string;
}

export interface FlinksAccountSnapshot {
  institutionName?: string;
  requestId?: string;
  accounts: Array<{
    providerAccountId: string;
    name: string;
    mask?: string;
    type?: string;
    subtype?: string;
    currency?: string;
    currentBalance?: number;
    availableBalance?: number;
  }>;
  drafts: ImportedTransactionDraft[];
}

export class FlinksPendingError extends Error {
  constructor(readonly requestId: string) {
    super('Flinks is still preparing account data.');
  }
}

export class FlinksNeedsReauthError extends Error {
  constructor(readonly requestId?: string) {
    super('Your bank needs you to reconnect before Leko can refresh transactions.');
  }
}

export function isBankMockMode(env: FlinksEnv): boolean {
  return env.BANK_DEV_MODE?.toLowerCase() === 'mock';
}

export function hasFlinksConfig(env: FlinksEnv): boolean {
  return Boolean(
    env.FLINKS_API_BASE_URL?.trim() &&
      env.FLINKS_CONNECT_URL?.trim() &&
      env.FLINKS_CUSTOMER_ID?.trim() &&
      env.FLINKS_SECRET_KEY?.trim() &&
      env.FLINKS_X_API_KEY?.trim(),
  );
}

export async function buildFlinksConnectionIntent(
  request: Request,
  env: FlinksEnv,
  state: string,
  deps: FlinksDeps,
): Promise<BankConnectionIntent> {
  const callback = new URL(
    env.FLINKS_REDIRECT_URL?.trim() ||
      `${new URL(request.url).origin}/bank/callback`,
  );
  callback.searchParams.set('state', state);
  const authorizeToken = isBankMockMode(env)
    ? 'mock-authorize-token'
    : await generateAuthorizeToken(env, deps);
  const connectUrl = buildFlinksConnectUrl(env, callback.toString(), authorizeToken);
  return {
    providerId: 'flinks',
    displayName: 'Flinks Connect',
    consentCopy:
      'Leko sends you to Flinks Connect to link a Canadian bank. Leko never receives your bank username or password. Transactions remain review drafts until you approve them.',
    authorizationUrl: connectUrl,
  };
}

export async function fetchFlinksAccountData(
  env: FlinksEnv,
  loginId: string,
  pendingRequestId: string | undefined,
  selectedAccountIds: string[],
  deps: FlinksDeps,
): Promise<FlinksAccountSnapshot> {
  if (isBankMockMode(env)) return mockSnapshot();
  assertFlinksConfigured(env);

  let requestId = pendingRequestId;
  let response: Response;
  if (requestId) {
    response = await deps.fetchImpl(
      `${bankingServicesBase(env)}/GetAccountsDetailAsync/${encodeURIComponent(requestId)}`,
      { headers: dataHeaders(env) },
    );
  } else {
    requestId = await authorizeLogin(env, loginId, deps);
    response = await deps.fetchImpl(`${bankingServicesBase(env)}/GetAccountsDetail`, {
      method: 'POST',
      headers: dataHeaders(env),
      body: JSON.stringify({
        RequestId: requestId,
        WithAccountIdentity: false,
        WithKYC: false,
        WithTransactions: true,
        DaysOfTransactions: 'Days90',
        ...(selectedAccountIds.length > 0
          ? { AccountsFilter: selectedAccountIds }
          : {}),
      }),
    });
  }

  if (response.status === 202) throw new FlinksPendingError(requestId);
  if (response.status === 203 || response.status === 401) {
    throw new FlinksNeedsReauthError(requestId);
  }
  if (!response.ok) {
    throw new Error(`Flinks account request failed with ${response.status}.`);
  }
  return normalizeFlinksAccountDetails(await response.json());
}

export async function deleteFlinksConnection(
  env: FlinksEnv,
  loginId: string,
  deps: FlinksDeps,
): Promise<void> {
  if (isBankMockMode(env)) return;
  assertFlinksConfigured(env);
  const response = await deps.fetchImpl(
    `${bankingServicesBase(env)}/DeleteCard/${encodeURIComponent(loginId)}`,
    { method: 'DELETE', headers: dataHeaders(env) },
  );
  if (!response.ok && response.status !== 404) {
    throw new Error(`Flinks deletion failed with ${response.status}.`);
  }
}

export function normalizeFlinksAccountDetails(
  payload: unknown,
): FlinksAccountSnapshot {
  const root = objectOrEmpty(payload);
  const accounts = extractAccounts(root);
  const normalizedAccounts: FlinksAccountSnapshot['accounts'] = [];
  const drafts: ImportedTransactionDraft[] = [];

  for (const account of accounts) {
    const providerAccountId =
      optionalText(account.Id ?? account.AccountId) ??
      stableAccountId(account);
    const accountName =
      optionalText(account.Title ?? account.AccountName ?? account.Name) ??
      'Bank account';
    const balance = objectOrEmpty(account.Balance);
    const accountNumber = optionalText(
      account.LastFourDigits ?? account.Mask ?? account.AccountNumber,
    );
    normalizedAccounts.push({
      providerAccountId,
      name: accountName,
      mask: accountNumber ? accountNumber.slice(-4) : undefined,
      type: optionalText(account.Type ?? account.Category),
      subtype: optionalText(account.AccountType),
      currency: optionalText(account.Currency),
      currentBalance: optionalNumber(balance.Current ?? account.CurrentBalance),
      availableBalance: optionalNumber(
        balance.Available ?? account.AvailableBalance,
      ),
    });

    const transactions = arrayOfObjects(
      account.Transactions ?? account.transactions ?? account.Transaction,
    );
    for (const transaction of transactions) {
      const amount = signedAmount(transaction);
      if (amount === 0) continue;
      const providerTransactionId =
        optionalText(
          transaction.Id ??
            transaction.TransactionId ??
            transaction.ReferenceNumber,
        ) ?? stableSourceId(transaction, providerAccountId);
      const merchant =
        optionalText(
          transaction.MerchantName ??
            transaction.Merchant ??
            transaction.Description ??
            transaction.Name,
        ) ?? 'Bank transaction';
      const categorySuggestion = optionalText(
        transaction.Category ??
          transaction.CategoryName ??
          transaction.SubCategory ??
          transaction.Type,
      );
      const pending = isPendingTransaction(transaction);
      drafts.push({
        sourceId: `${providerAccountId}:${providerTransactionId}`,
        source: 'bank_aggregator',
        amount: Math.abs(amount),
        date: transactionDate(transaction),
        type: amount < 0 ? 'expense' : 'income',
        merchant,
        categorySuggestion,
        note: `Flinks • ${accountName}${normalizedAccounts.at(-1)?.mask ? ` ••••${normalizedAccounts.at(-1)?.mask}` : ''}`,
        reviewStatus: 'pending',
        confidence: pending ? 0.55 : categorySuggestion ? 0.86 : 0.72,
        accountId: providerAccountId,
        accountName,
        pending,
      });
    }
  }

  return {
    institutionName: optionalText(root.InstitutionName ?? root.Institution),
    requestId: optionalText(root.RequestId),
    accounts: normalizedAccounts,
    drafts,
  };
}

export function flinksAppReturnUrl(
  env: FlinksEnv,
  status: 'connected' | 'cancelled' | 'error',
  message?: string,
): string {
  const url = new URL(
    env.FLINKS_APP_RETURN_URL?.trim() ||
      'com.jaivik.leko://bank-callback',
  );
  url.searchParams.set('status', status);
  if (message) url.searchParams.set('message', message.slice(0, 200));
  return url.toString();
}

async function authorizeLogin(
  env: FlinksEnv,
  loginId: string,
  deps: FlinksDeps,
): Promise<string> {
  const authorizeToken = await generateAuthorizeToken(env, deps);
  const response = await deps.fetchImpl(`${bankingServicesBase(env)}/Authorize`, {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
      'flinks-auth-key': authorizeToken,
    },
    body: JSON.stringify({
      LoginId: loginId,
      MostRecentCached: true,
      Save: true,
    }),
  });
  const payload = objectOrEmpty(await response.json());
  if (response.status === 203) {
    throw new FlinksNeedsReauthError(optionalText(payload.RequestId));
  }
  if (!response.ok) {
    throw new Error(`Flinks authorization failed with ${response.status}.`);
  }
  const requestId = optionalText(payload.RequestId);
  if (!requestId) throw new Error('Flinks did not return a RequestId.');
  return requestId;
}

async function generateAuthorizeToken(
  env: FlinksEnv,
  deps: FlinksDeps,
): Promise<string> {
  assertFlinksConfigured(env);
  const response = await deps.fetchImpl(
    `${bankingServicesBase(env)}/GenerateAuthorizeToken`,
    {
      method: 'POST',
      headers: {
        accept: 'application/json',
        'content-type': 'application/json',
        'flinks-auth-key': env.FLINKS_SECRET_KEY!.trim(),
      },
    },
  );
  if (!response.ok) {
    throw new Error(`Flinks token generation failed with ${response.status}.`);
  }
  const token = optionalText(objectOrEmpty(await response.json()).Token);
  if (!token) throw new Error('Flinks did not return an authorize token.');
  return token;
}

function buildFlinksConnectUrl(
  env: FlinksEnv,
  redirectUrl: string,
  authorizeToken: string,
): string {
  const base = env.FLINKS_CONNECT_URL?.trim() ||
    'https://toolbox-iframe.private.fin.ag/v2/';
  const url = new URL(base);
  url.searchParams.set('redirectURL', redirectUrl);
  url.searchParams.set('authorizeToken', authorizeToken);
  url.searchParams.set('accountSelectorEnable', 'true');
  url.searchParams.set('accountSelectorMultiple', 'true');
  url.searchParams.set('tag', 'leko-bank-review');
  if (env.FLINKS_SANDBOX?.toLowerCase() === 'true') {
    url.searchParams.set('demo', 'true');
  }
  return url.toString();
}

function bankingServicesBase(env: FlinksEnv): string {
  const base = env.FLINKS_API_BASE_URL!.trim().replace(/\/$/, '');
  if (/\/BankingServices$/i.test(base)) return base;
  return `${base}/v3/${encodeURIComponent(env.FLINKS_CUSTOMER_ID!.trim())}/BankingServices`;
}

function dataHeaders(env: FlinksEnv): HeadersInit {
  return {
    accept: 'application/json',
    'content-type': 'application/json',
    'x-api-key': env.FLINKS_X_API_KEY!.trim(),
  };
}

function assertFlinksConfigured(env: FlinksEnv): void {
  if (!hasFlinksConfig(env)) {
    throw new Error('Flinks production credentials are not configured.');
  }
}

function extractAccounts(
  root: Record<string, unknown>,
): Array<Record<string, unknown>> {
  return arrayOfObjects(
    root.Accounts ??
      root.accounts ??
      root.AccountsDetail ??
      root.AccountDetails ??
      root.Data,
  );
}

function signedAmount(transaction: Record<string, unknown>): number {
  const debit = optionalNumber(transaction.Debit ?? transaction.debit);
  const credit = optionalNumber(transaction.Credit ?? transaction.credit);
  if (debit != null && debit > 0) return -debit;
  if (credit != null && credit > 0) return credit;
  return optionalNumber(transaction.Amount ?? transaction.amount) ?? 0;
}

function transactionDate(transaction: Record<string, unknown>): string {
  const raw =
    optionalText(
      transaction.PostedDate ??
        transaction.Date ??
        transaction.TransactionDate ??
        transaction.AuthorizedDate ??
        transaction.OperationDate,
    ) ?? new Date().toISOString();
  return raw.includes('T') ? raw.split('T')[0] : raw;
}

function isPendingTransaction(transaction: Record<string, unknown>): boolean {
  if (transaction.Pending === true || transaction.IsPending === true) return true;
  const status = optionalText(transaction.Status)?.toLowerCase();
  return status === 'pending' || status === 'authorized';
}

function stableAccountId(account: Record<string, unknown>): string {
  return [
    'flinks-account',
    optionalText(account.Title ?? account.Name) ?? 'account',
    optionalText(account.Type ?? account.Category) ?? 'type',
    optionalText(account.Currency) ?? 'currency',
  ].join(':');
}

function stableSourceId(
  transaction: Record<string, unknown>,
  accountId: string,
): string {
  return [
    'flinks',
    accountId,
    optionalText(transaction.Date ?? transaction.TransactionDate) ?? 'date',
    optionalText(transaction.Description ?? transaction.Name) ?? 'txn',
    optionalNumber(transaction.Amount ?? transaction.Debit ?? transaction.Credit) ?? 0,
  ].join(':');
}

function optionalText(value: unknown): string | undefined {
  if (value == null) return undefined;
  const text = String(value).trim();
  return text.length === 0 ? undefined : text;
}

function optionalNumber(value: unknown): number | undefined {
  if (typeof value === 'number') return Number.isFinite(value) ? value : undefined;
  if (typeof value !== 'string') return undefined;
  const parsed = Number(value.replace(/[$,]/g, '').trim());
  return Number.isFinite(parsed) ? parsed : undefined;
}

function objectOrEmpty(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object'
    ? (value as Record<string, unknown>)
    : {};
}

function arrayOfObjects(value: unknown): Array<Record<string, unknown>> {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (item): item is Record<string, unknown> =>
      Boolean(item) && typeof item === 'object',
  );
}

function mockSnapshot(): FlinksAccountSnapshot {
  return {
    institutionName: 'Flinks Capital',
    accounts: [
      {
        providerAccountId: 'flinks_mock_chequing',
        name: 'Chequing',
        mask: '1234',
        type: 'Chequing',
        currency: 'CAD',
        currentBalance: 2450.18,
        availableBalance: 2350.18,
      },
    ],
    drafts: [
      {
        sourceId: 'flinks_mock_chequing:flinks_mock_1',
        source: 'bank_aggregator',
        amount: 18.42,
        date: new Date().toISOString().split('T')[0],
        type: 'expense',
        merchant: 'Tim Hortons',
        categorySuggestion: 'Dining Out',
        note: 'Flinks • Chequing ••••1234',
        reviewStatus: 'pending',
        confidence: 0.88,
        accountId: 'flinks_mock_chequing',
        accountName: 'Chequing',
        pending: false,
      },
      {
        sourceId: 'flinks_mock_chequing:flinks_mock_2',
        source: 'bank_aggregator',
        amount: 1250,
        date: new Date(Date.now() - 3 * 86_400_000).toISOString().split('T')[0],
        type: 'income',
        merchant: 'Payroll deposit',
        categorySuggestion: 'Income',
        note: 'Flinks • Chequing ••••1234',
        reviewStatus: 'pending',
        confidence: 0.82,
        accountId: 'flinks_mock_chequing',
        accountName: 'Chequing',
        pending: false,
      },
    ],
  };
}
