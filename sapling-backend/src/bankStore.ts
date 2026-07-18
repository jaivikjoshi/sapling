import type { ImportedTransactionDraft } from './bankSchemas';
import type { FlinksAccountSnapshot } from './flinks';
import { sha256 } from './security';
import { eq, gt, isNull, SupabaseRest } from './supabase';

export interface BankConnectionRow {
  id: string;
  user_id: string;
  provider: string;
  provider_login_ciphertext: string | null;
  provider_login_hash: string | null;
  institution_name: string | null;
  status: string;
  sync_cursor: string | null;
  last_sync_at: string | null;
  last_error_code: string | null;
  created_at: string;
  updated_at: string;
}

export interface BankAccountRow {
  id: string;
  connection_id: string;
  provider_account_id: string;
  name: string;
  mask: string | null;
  type: string | null;
  subtype: string | null;
  currency: string | null;
  current_balance: number | null;
  available_balance: number | null;
  is_selected: boolean;
}

interface BankSessionRow {
  id: string;
  user_id: string;
  state_hash: string;
}

interface BankDraftRow {
  id: string;
  provider_transaction_id: string;
  account_id: string | null;
  amount: number;
  transaction_date: string;
  transaction_type: 'expense' | 'income';
  merchant: string | null;
  category_suggestion: string | null;
  note: string | null;
  review_status: 'pending' | 'approved' | 'rejected' | 'imported';
  confidence: number | null;
  is_pending: boolean;
  ledger_transaction_id: string | null;
}

export class BankStore {
  constructor(private readonly db: SupabaseRest) {}

  async createSession(userId: string, stateHash: string): Promise<void> {
    await this.db.delete(
      'bank_connection_sessions',
      new URLSearchParams({ user_id: eq(userId) }),
    );
    const expiresAt = new Date(Date.now() + 15 * 60_000).toISOString();
    await this.db.insert('bank_connection_sessions', {
      user_id: userId,
      state_hash: stateHash,
      expires_at: expiresAt,
    });
  }

  async consumeSession(stateHash: string): Promise<BankSessionRow | undefined> {
    const query = new URLSearchParams({
      select: 'id,user_id,state_hash',
      state_hash: eq(stateHash),
      consumed_at: isNull(),
      expires_at: gt(new Date().toISOString()),
      limit: '1',
    });
    const [session] = await this.db.select<BankSessionRow>(
      'bank_connection_sessions',
      query,
    );
    if (!session) return undefined;
    const updated = await this.db.update<BankSessionRow>(
      'bank_connection_sessions',
      new URLSearchParams({ id: eq(session.id), consumed_at: isNull() }),
      { consumed_at: new Date().toISOString() },
    );
    return updated.length === 1 ? session : undefined;
  }

  async connectionForUser(
    userId: string,
    provider = 'flinks',
  ): Promise<BankConnectionRow | undefined> {
    const [connection] = await this.db.select<BankConnectionRow>(
      'bank_connections',
      new URLSearchParams({
        select: '*',
        user_id: eq(userId),
        provider: eq(provider),
        limit: '1',
      }),
    );
    return connection;
  }

  async connectionByLoginHash(
    loginHash: string,
  ): Promise<BankConnectionRow | undefined> {
    const [connection] = await this.db.select<BankConnectionRow>(
      'bank_connections',
      new URLSearchParams({
        select: '*',
        provider_login_hash: eq(loginHash),
        provider: eq('flinks'),
        limit: '1',
      }),
    );
    return connection;
  }

  async saveConnectedLogin(input: {
    userId: string;
    loginCiphertext: string;
    loginHash: string;
    institutionName?: string;
  }): Promise<BankConnectionRow> {
    const [connection] = await this.db.upsert<BankConnectionRow>(
      'bank_connections',
      {
        user_id: input.userId,
        provider: 'flinks',
        provider_login_ciphertext: input.loginCiphertext,
        provider_login_hash: input.loginHash,
        institution_name: input.institutionName ?? null,
        status: 'connected',
        sync_cursor: null,
        last_error_code: null,
      },
      'user_id,provider',
    );
    return connection;
  }

  async updateConnection(
    id: string,
    values: Partial<BankConnectionRow>,
  ): Promise<void> {
    await this.db.update('bank_connections', new URLSearchParams({ id: eq(id) }), {
      ...values,
      updated_at: new Date().toISOString(),
    });
  }

  async accounts(connectionId: string): Promise<BankAccountRow[]> {
    return this.db.select<BankAccountRow>(
      'bank_accounts',
      new URLSearchParams({
        select: '*',
        connection_id: eq(connectionId),
        order: 'name.asc',
      }),
    );
  }

  async setSelectedAccounts(
    connectionId: string,
    selectedAccountIds: Set<string>,
  ): Promise<void> {
    const accounts = await this.accounts(connectionId);
    await Promise.all(
      accounts.map((account) =>
        this.db.update(
          'bank_accounts',
          new URLSearchParams({ id: eq(account.id) }),
          { is_selected: selectedAccountIds.has(account.provider_account_id) },
        ),
      ),
    );
  }

  async saveSnapshot(
    connection: BankConnectionRow,
    snapshot: FlinksAccountSnapshot,
  ): Promise<ImportedTransactionDraft[]> {
    const priorAccounts = await this.accounts(connection.id);
    const selectedByProviderId = new Map(
      priorAccounts.map((account) => [
        account.provider_account_id,
        account.is_selected,
      ]),
    );
    if (snapshot.accounts.length > 0) {
      await this.db.upsert(
        'bank_accounts',
        snapshot.accounts.map((account) => ({
          connection_id: connection.id,
          provider_account_id: account.providerAccountId,
          name: account.name,
          mask: account.mask ?? null,
          type: account.type ?? null,
          subtype: account.subtype ?? null,
          currency: account.currency ?? null,
          current_balance: account.currentBalance ?? null,
          available_balance: account.availableBalance ?? null,
          is_selected:
            selectedByProviderId.get(account.providerAccountId) ?? true,
        })),
        'connection_id,provider_account_id',
      );
    }

    const existing = await this.db.select<BankDraftRow>(
      'bank_transaction_imports',
      new URLSearchParams({
        select: '*',
        user_id: eq(connection.user_id),
        connection_id: eq(connection.id),
      }),
    );
    const existingById = new Map(
      existing.map((draft) => [draft.provider_transaction_id, draft]),
    );
    const accounts = await this.accounts(connection.id);
    const accountRowByProviderId = new Map(
      accounts.map((account) => [account.provider_account_id, account]),
    );
    const now = new Date().toISOString();
    const rows = await Promise.all(
      snapshot.drafts.map(async (draft) => {
        const accountRow = draft.accountId
          ? accountRowByProviderId.get(draft.accountId)
          : undefined;
        let prior = existingById.get(draft.sourceId);
        if (!prior && !draft.pending) {
          prior = existing.find(
            (candidate) =>
              candidate.is_pending &&
              candidate.account_id === (accountRow?.id ?? null) &&
              Number(candidate.amount) === draft.amount &&
              candidate.transaction_date === draft.date &&
              candidate.transaction_type === draft.type &&
              normalizedMerchant(candidate.merchant) ===
                  normalizedMerchant(draft.merchant),
          );
          if (prior) {
            await this.db.delete(
              'bank_transaction_imports',
              new URLSearchParams({ id: eq(prior.id) }),
            );
          }
        }
        return {
          user_id: connection.user_id,
          connection_id: connection.id,
          account_id: accountRow?.id ?? null,
          provider_transaction_id: draft.sourceId,
          amount: draft.amount,
          transaction_date: draft.date,
          transaction_type: draft.type,
          merchant: draft.merchant ?? null,
          category_suggestion: draft.categorySuggestion ?? null,
          note: draft.note ?? null,
          review_status: prior?.review_status ?? 'pending',
          confidence: draft.confidence ?? null,
          is_pending: draft.pending ?? false,
          raw_hash: await sha256(JSON.stringify(draft)),
          last_seen_at: now,
        };
      }),
    );
    if (rows.length > 0) {
      await this.db.upsert(
        'bank_transaction_imports',
        rows,
        'connection_id,provider_transaction_id',
      );
    }

    await this.updateConnection(connection.id, {
      institution_name: snapshot.institutionName ?? connection.institution_name,
      status: 'connected',
      sync_cursor: null,
      last_sync_at: now,
      last_error_code: null,
    });
    return this.reviewableDrafts(connection.user_id, connection.id);
  }

  async reviewableDrafts(
    userId: string,
    connectionId: string,
  ): Promise<ImportedTransactionDraft[]> {
    const accounts = await this.accounts(connectionId);
    const accountById = new Map(accounts.map((account) => [account.id, account]));
    const rows = await this.db.select<BankDraftRow>(
      'bank_transaction_imports',
      new URLSearchParams({
        select: '*',
        user_id: eq(userId),
        connection_id: eq(connectionId),
        review_status: 'in.(pending,approved)',
        order: 'transaction_date.desc',
        limit: '250',
      }),
    );
    return rows
      .filter((row) => {
        if (!row.account_id) return true;
        return accountById.get(row.account_id)?.is_selected === true;
      })
      .map((row) => {
        const account = row.account_id ? accountById.get(row.account_id) : undefined;
        return {
          sourceId: row.provider_transaction_id,
          source: 'bank_aggregator',
          amount: Number(row.amount),
          date: row.transaction_date,
          type: row.transaction_type,
          merchant: row.merchant ?? undefined,
          categorySuggestion: row.category_suggestion ?? undefined,
          note: row.note ?? undefined,
          reviewStatus: row.review_status,
          confidence:
            row.confidence == null ? undefined : Number(row.confidence),
          accountId: account?.provider_account_id,
          accountName: account?.name,
          pending: row.is_pending,
          ledgerTransactionId: row.ledger_transaction_id ?? undefined,
        };
      });
  }

  async setReviewStatus(
    userId: string,
    sourceId: string,
    status: 'approved' | 'rejected',
  ): Promise<boolean> {
    const rows = await this.db.update<BankDraftRow>(
      'bank_transaction_imports',
      new URLSearchParams({
        user_id: eq(userId),
        provider_transaction_id: eq(sourceId),
        review_status: 'in.(pending,approved)',
      }),
      { review_status: status, reviewed_at: new Date().toISOString() },
    );
    return rows.length === 1;
  }

  async markImported(
    userId: string,
    sourceId: string,
    ledgerTransactionId: string,
  ): Promise<boolean> {
    const rows = await this.db.update<BankDraftRow>(
      'bank_transaction_imports',
      new URLSearchParams({
        user_id: eq(userId),
        provider_transaction_id: eq(sourceId),
        review_status: eq('approved'),
      }),
      {
        review_status: 'imported',
        ledger_transaction_id: ledgerTransactionId,
        imported_at: new Date().toISOString(),
      },
    );
    return rows.length === 1;
  }

  async deleteConnection(connectionId: string): Promise<void> {
    await this.db.delete(
      'bank_connections',
      new URLSearchParams({ id: eq(connectionId) }),
    );
  }
}

function normalizedMerchant(value: string | undefined | null): string {
  return (value ?? '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}
