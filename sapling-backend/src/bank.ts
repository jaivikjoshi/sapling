import {
  bankAccountSelectionSchema,
  bankImportRequestSchema,
  bankReviewRequestSchema,
} from './bankSchemas';
import { BankStore } from './bankStore';
import {
  buildFlinksConnectionIntent,
  deleteFlinksConnection,
  fetchFlinksAccountData,
  flinksAppReturnUrl,
  FlinksNeedsReauthError,
  FlinksPendingError,
  hasFlinksConfig,
  isBankMockMode,
  normalizeFlinksAccountDetails,
  type FlinksEnv,
} from './flinks';
import {
  decryptSecret,
  encryptSecret,
  randomState,
  sha256,
  verifyHmacSha256,
} from './security';
import {
  authenticateUser,
  HttpError,
  SupabaseRest,
  type SupabaseEnv,
} from './supabase';

export interface BankEnv extends FlinksEnv, SupabaseEnv {
  BANK_PROVIDER?: string;
  BANK_TOKEN_ENCRYPTION_KEY?: string;
}

interface BankDeps {
  fetchImpl: typeof fetch;
}

export async function handleBankRoute(
  request: Request,
  env: BankEnv,
  deps: BankDeps,
): Promise<Response | null> {
  const url = new URL(request.url);
  if (!url.pathname.startsWith('/bank/')) return null;
  const provider = env.BANK_PROVIDER?.toLowerCase() || 'flinks';
  if (provider !== 'flinks') {
    return jsonResponse(
      { error: 'bank_provider_unsupported', message: 'Configured bank provider is unsupported.' },
      503,
    );
  }

  try {
    if (isBankMockMode(env)) {
      return handleMockRoute(request, env, deps);
    }
    if (request.method === 'GET' && url.pathname === '/bank/callback') {
      return handleConnectCallback(request, env, deps);
    }
    if (request.method === 'POST' && url.pathname === '/bank/webhook') {
      return handleWebhook(request, env, deps);
    }
    if (!hasFlinksConfig(env)) {
      return jsonResponse(
        { status: 'unavailable', error: 'bank_not_configured' },
        url.pathname === '/bank/status' ? 200 : 503,
      );
    }

    const user = await authenticateUser(request, env, deps.fetchImpl);
    const store = new BankStore(new SupabaseRest(env, deps.fetchImpl));

    if (request.method === 'GET' && url.pathname === '/bank/status') {
      return statusResponse(await store.connectionForUser(user.id), store);
    }

    if (request.method === 'POST' && url.pathname === '/bank/connect') {
      const state = randomState();
      await store.createSession(user.id, await sha256(state));
      return jsonResponse(
        await buildFlinksConnectionIntent(request, env, state, deps),
      );
    }

    if (request.method === 'GET' && url.pathname === '/bank/transactions/drafts') {
      const connection = await requireConnection(store, user.id);
      return jsonResponse({
        drafts: await store.reviewableDrafts(user.id, connection.id),
      });
    }

    if (request.method === 'GET' && url.pathname === '/bank/transactions/preview') {
      return previewTransactions(user.id, env, deps, store);
    }

    if (request.method === 'POST' && url.pathname === '/bank/transactions/review') {
      const parsed = bankReviewRequestSchema.safeParse(await readJson(request));
      if (!parsed.success) return validationError(parsed.error.flatten());
      const updated = await Promise.all(
        parsed.data.decisions.map((decision) =>
          store.setReviewStatus(user.id, decision.sourceId, decision.reviewStatus),
        ),
      );
      return jsonResponse({ updatedCount: updated.filter(Boolean).length });
    }

    if (request.method === 'POST' && url.pathname === '/bank/transactions/import') {
      const parsed = bankImportRequestSchema.safeParse(await readJson(request));
      if (!parsed.success) return validationError(parsed.error.flatten());
      const imported = await Promise.all(
        parsed.data.drafts.map((draft) =>
          store.markImported(
            user.id,
            draft.sourceId,
            draft.ledgerTransactionId,
          ),
        ),
      );
      const createdCount = imported.filter(Boolean).length;
      return jsonResponse({
        createdCount,
        skippedCount: imported.length - createdCount,
        message: `Recorded ${createdCount} reviewed bank import${createdCount === 1 ? '' : 's'}.`,
      });
    }

    if (request.method === 'POST' && url.pathname === '/bank/accounts/select') {
      const parsed = bankAccountSelectionSchema.safeParse(await readJson(request));
      if (!parsed.success) return validationError(parsed.error.flatten());
      const connection = await requireConnection(store, user.id);
      const available = new Set(
        (await store.accounts(connection.id)).map(
          (account) => account.provider_account_id,
        ),
      );
      if (parsed.data.selectedAccountIds.some((id) => !available.has(id))) {
        throw new HttpError('Unknown bank account selection.', 400, 'invalid_bank_account');
      }
      await store.setSelectedAccounts(
        connection.id,
        new Set(parsed.data.selectedAccountIds),
      );
      return statusResponse(connection, store);
    }

    if (request.method === 'DELETE' && url.pathname === '/bank/connection') {
      const connection = await requireConnection(store, user.id);
      const encryptionKey = requiredEncryptionKey(env);
      const loginId = await decryptSecret(
        connection.provider_login_ciphertext!,
        encryptionKey,
      );
      await deleteFlinksConnection(env, loginId, deps);
      await store.deleteConnection(connection.id);
      return jsonResponse({ ok: true, status: 'disconnected' });
    }

    return null;
  } catch (error) {
    if (error instanceof HttpError) {
      return jsonResponse({ error: error.code, message: error.message }, error.status);
    }
    console.error('Bank route failed', error);
    return jsonResponse(
      {
        error: 'bank_request_failed',
        message: 'The bank connection could not complete. Try again shortly.',
      },
      502,
    );
  }
}

async function handleMockRoute(
  request: Request,
  env: BankEnv,
  deps: BankDeps,
): Promise<Response | null> {
  const url = new URL(request.url);
  const snapshot = await fetchFlinksAccountData(env, 'mock', undefined, [], deps);
  if (request.method === 'GET' && url.pathname === '/bank/status') {
    return jsonResponse({
      status: 'connected',
      providerId: 'flinks',
      displayName: 'Flinks Connect',
      institutionName: snapshot.institutionName,
      accounts: snapshot.accounts.map((account) => ({
        id: account.providerAccountId,
        name: account.name,
        mask: account.mask,
        type: account.type,
        currency: account.currency,
        currentBalance: account.currentBalance,
        availableBalance: account.availableBalance,
        isSelected: true,
      })),
    });
  }
  if (request.method === 'POST' && url.pathname === '/bank/connect') {
    return jsonResponse(
      await buildFlinksConnectionIntent(request, env, 'mock-state', deps),
    );
  }
  if (
    request.method === 'GET' &&
    (url.pathname === '/bank/transactions/preview' ||
      url.pathname === '/bank/transactions/drafts')
  ) {
    return jsonResponse({ drafts: snapshot.drafts });
  }
  if (request.method === 'POST' && url.pathname === '/bank/transactions/review') {
    const parsed = bankReviewRequestSchema.safeParse(await readJson(request));
    if (!parsed.success) return validationError(parsed.error.flatten());
    return jsonResponse({ updatedCount: parsed.data.decisions.length });
  }
  if (request.method === 'POST' && url.pathname === '/bank/transactions/import') {
    const parsed = bankImportRequestSchema.safeParse(await readJson(request));
    if (!parsed.success) return validationError(parsed.error.flatten());
    return jsonResponse({
      createdCount: parsed.data.drafts.length,
      skippedCount: 0,
      message: 'Mock bank imports recorded.',
    });
  }
  if (request.method === 'POST' && url.pathname === '/bank/accounts/select') {
    return jsonResponse({ status: 'connected' });
  }
  if (request.method === 'DELETE' && url.pathname === '/bank/connection') {
    return jsonResponse({ ok: true, status: 'disconnected' });
  }
  if (request.method === 'GET' && url.pathname === '/bank/callback') {
    return Response.redirect(flinksAppReturnUrl(env, 'connected'), 302);
  }
  return null;
}

async function handleConnectCallback(
  request: Request,
  env: BankEnv,
  deps: BankDeps,
): Promise<Response> {
  const url = new URL(request.url);
  const state = url.searchParams.get('state')?.trim();
  const loginId =
    url.searchParams.get('loginId')?.trim() ||
    url.searchParams.get('LoginId')?.trim();
  const providerError = url.searchParams.get('error');
  if (!state) {
    throw new HttpError('Missing bank connection state.', 400, 'invalid_bank_callback');
  }
  const store = new BankStore(new SupabaseRest(env, deps.fetchImpl));
  const session = await store.consumeSession(await sha256(state));
  if (!session) {
    throw new HttpError(
      'This bank connection link expired or was already used.',
      400,
      'invalid_bank_callback',
    );
  }
  if (providerError || !loginId) {
    return Response.redirect(
      flinksAppReturnUrl(env, providerError ? 'error' : 'cancelled'),
      302,
    );
  }

  const connection = await store.saveConnectedLogin({
    userId: session.user_id,
    loginCiphertext: await encryptSecret(loginId, requiredEncryptionKey(env)),
    loginHash: await sha256(loginId),
  });
  try {
    const snapshot = await fetchFlinksAccountData(env, loginId, undefined, [], deps);
    await store.saveSnapshot(connection, snapshot);
  } catch (error) {
    if (error instanceof FlinksPendingError) {
      await store.updateConnection(connection.id, {
        sync_cursor: error.requestId,
        status: 'connecting',
      });
    } else if (error instanceof FlinksNeedsReauthError) {
      await store.updateConnection(connection.id, {
        status: 'needs_reauth',
        last_error_code: 'reauth_required',
      });
    } else {
      await store.updateConnection(connection.id, {
        last_error_code: 'initial_sync_failed',
      });
    }
  }
  return Response.redirect(flinksAppReturnUrl(env, 'connected'), 302);
}

async function previewTransactions(
  userId: string,
  env: BankEnv,
  deps: BankDeps,
  store: BankStore,
): Promise<Response> {
  const connection = await requireConnection(store, userId);
  if (connection.status === 'needs_reauth') {
    throw new HttpError(
      'Reconnect your bank before syncing again.',
      409,
      'bank_reauth_required',
    );
  }
  const accounts = await store.accounts(connection.id);
  if (
    connection.last_sync_at &&
    !connection.sync_cursor &&
    Date.now() - new Date(connection.last_sync_at).getTime() < 60_000
  ) {
    return jsonResponse({
      drafts: await store.reviewableDrafts(userId, connection.id),
      syncedAt: connection.last_sync_at,
      cached: true,
    });
  }
  const selectedAccountIds = accounts
    .filter((account) => account.is_selected)
    .map((account) => account.provider_account_id);
  const loginId = await decryptSecret(
    connection.provider_login_ciphertext!,
    requiredEncryptionKey(env),
  );
  try {
    const snapshot = await fetchFlinksAccountData(
      env,
      loginId,
      connection.sync_cursor ?? undefined,
      selectedAccountIds,
      deps,
    );
    return jsonResponse({
      drafts: await store.saveSnapshot(connection, snapshot),
      syncedAt: new Date().toISOString(),
    });
  } catch (error) {
    if (error instanceof FlinksPendingError) {
      await store.updateConnection(connection.id, {
        sync_cursor: error.requestId,
        status: 'connecting',
      });
      return jsonResponse(
        {
          status: 'processing',
          retryAfterSeconds: 10,
          message: 'Your bank is still preparing transaction data.',
        },
        202,
      );
    }
    if (error instanceof FlinksNeedsReauthError) {
      await store.updateConnection(connection.id, {
        status: 'needs_reauth',
        last_error_code: 'reauth_required',
      });
      throw new HttpError(error.message, 409, 'bank_reauth_required');
    }
    throw error;
  }
}

async function handleWebhook(
  request: Request,
  env: BankEnv,
  deps: BankDeps,
): Promise<Response> {
  const secret = env.FLINKS_WEBHOOK_HMAC_SECRET?.trim();
  const signature = request.headers.get('flinks-authenticity-key')?.trim();
  if (!secret || !signature) {
    throw new HttpError('Webhook authentication is unavailable.', 401, 'invalid_webhook');
  }
  const rawBody = await request.text();
  if (!(await verifyHmacSha256(rawBody, signature, secret))) {
    throw new HttpError('Invalid webhook signature.', 401, 'invalid_webhook');
  }
  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(rawBody) as Record<string, unknown>;
  } catch {
    throw new HttpError('Webhook body is not valid JSON.', 400, 'invalid_webhook');
  }
  const login = payload.Login as Record<string, unknown> | undefined;
  const loginId = login?.Id == null ? undefined : String(login.Id).trim();
  if (!loginId) {
    throw new HttpError('Webhook is missing Login.Id.', 400, 'invalid_webhook');
  }
  const store = new BankStore(new SupabaseRest(env, deps.fetchImpl));
  const connection = await store.connectionByLoginHash(await sha256(loginId));
  if (connection) {
    await store.saveSnapshot(connection, normalizeFlinksAccountDetails(payload));
  }
  return jsonResponse({ ok: true });
}

async function statusResponse(
  connection: Awaited<ReturnType<BankStore['connectionForUser']>>,
  store: BankStore,
): Promise<Response> {
  if (!connection) return jsonResponse({ status: 'disconnected' });
  const accounts = await store.accounts(connection.id);
  return jsonResponse({
    status: toApiStatus(connection.status),
    providerId: connection.provider,
    displayName: 'Flinks Connect',
    institutionName: connection.institution_name,
    lastSyncAt: connection.last_sync_at,
    errorCode: connection.last_error_code,
    accounts: accounts.map((account) => ({
      id: account.provider_account_id,
      name: account.name,
      mask: account.mask,
      type: account.type,
      subtype: account.subtype,
      currency: account.currency,
      currentBalance: account.current_balance,
      availableBalance: account.available_balance,
      isSelected: account.is_selected,
    })),
  });
}

async function requireConnection(
  store: BankStore,
  userId: string,
) {
  const connection = await store.connectionForUser(userId);
  if (!connection?.provider_login_ciphertext) {
    throw new HttpError('Connect a bank before syncing.', 409, 'bank_not_connected');
  }
  return connection;
}

function toApiStatus(status: string): string {
  if (status === 'needs_reauth') return 'needsReauth';
  return status;
}

function requiredEncryptionKey(env: BankEnv): string {
  const key = env.BANK_TOKEN_ENCRYPTION_KEY?.trim();
  if (!key) {
    throw new HttpError(
      'Bank credential encryption is not configured.',
      503,
      'bank_not_configured',
    );
  }
  return key;
}

async function readJson(request: Request): Promise<unknown> {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

function validationError(details: unknown): Response {
  return jsonResponse({ error: 'invalid_request', details }, 400);
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload, null, 2), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}
