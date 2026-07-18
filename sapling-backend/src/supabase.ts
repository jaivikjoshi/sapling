export interface SupabaseEnv {
  SUPABASE_URL?: string;
  SUPABASE_PUBLISHABLE_KEY?: string;
  SUPABASE_SECRET_KEY?: string;
}

export interface AuthenticatedUser {
  id: string;
}

export class HttpError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code: string,
  ) {
    super(message);
  }
}

export async function authenticateUser(
  request: Request,
  env: SupabaseEnv,
  fetchImpl: typeof fetch,
): Promise<AuthenticatedUser> {
  const authorization = request.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) {
    throw new HttpError('Sign in to manage a bank connection.', 401, 'bank_auth_required');
  }
  const url = requiredEnv(env.SUPABASE_URL, 'SUPABASE_URL');
  const publishableKey = requiredEnv(
    env.SUPABASE_PUBLISHABLE_KEY,
    'SUPABASE_PUBLISHABLE_KEY',
  );
  const response = await fetchImpl(`${url.replace(/\/$/, '')}/auth/v1/user`, {
    headers: {
      apikey: publishableKey,
      authorization,
    },
  });
  if (!response.ok) {
    throw new HttpError('Your session has expired. Sign in again.', 401, 'bank_auth_invalid');
  }
  const payload = objectOrEmpty(await response.json());
  const id = optionalText(payload.id);
  if (!id) {
    throw new HttpError('Could not identify the signed-in user.', 401, 'bank_auth_invalid');
  }
  return { id };
}

export class SupabaseRest {
  constructor(
    private readonly env: SupabaseEnv,
    private readonly fetchImpl: typeof fetch,
  ) {}

  async select<T>(table: string, query: URLSearchParams): Promise<T[]> {
    return this.request<T[]>(table, { query });
  }

  async insert<T>(table: string, rows: unknown): Promise<T[]> {
    return this.request<T[]>(table, {
      method: 'POST',
      body: rows,
      prefer: 'return=representation',
    });
  }

  async upsert<T>(
    table: string,
    rows: unknown,
    onConflict: string,
  ): Promise<T[]> {
    const query = new URLSearchParams({ on_conflict: onConflict });
    return this.request<T[]>(table, {
      method: 'POST',
      query,
      body: rows,
      prefer: 'resolution=merge-duplicates,return=representation',
    });
  }

  async update<T>(
    table: string,
    query: URLSearchParams,
    values: unknown,
  ): Promise<T[]> {
    return this.request<T[]>(table, {
      method: 'PATCH',
      query,
      body: values,
      prefer: 'return=representation',
    });
  }

  async delete(table: string, query: URLSearchParams): Promise<void> {
    await this.request<unknown>(table, { method: 'DELETE', query });
  }

  private async request<T>(
    table: string,
    options: {
      method?: string;
      query?: URLSearchParams;
      body?: unknown;
      prefer?: string;
    },
  ): Promise<T> {
    const base = requiredEnv(this.env.SUPABASE_URL, 'SUPABASE_URL');
    const secret = requiredEnv(this.env.SUPABASE_SECRET_KEY, 'SUPABASE_SECRET_KEY');
    const url = new URL(`${base.replace(/\/$/, '')}/rest/v1/${table}`);
    if (options.query) url.search = options.query.toString();
    const response = await this.fetchImpl(url, {
      method: options.method ?? 'GET',
      headers: {
        apikey: secret,
        'content-type': 'application/json',
        ...(options.prefer ? { prefer: options.prefer } : {}),
      },
      ...(options.body == null ? {} : { body: JSON.stringify(options.body) }),
    });
    if (!response.ok) {
      console.error(
        'Supabase bank storage request failed',
        response.status,
        table,
      );
      throw new HttpError(
        'Bank storage is temporarily unavailable.',
        503,
        'bank_storage_unavailable',
      );
    }
    if (response.status === 204) return undefined as T;
    const text = await response.text();
    return (text ? JSON.parse(text) : undefined) as T;
  }
}

export function eq(value: string): string {
  return `eq.${value}`;
}

export function isNull(): string {
  return 'is.null';
}

export function gt(value: string): string {
  return `gt.${value}`;
}

function requiredEnv(value: string | undefined, name: string): string {
  const normalized = value?.trim();
  if (!normalized) {
    throw new HttpError(
      `Bank backend is missing ${name}.`,
      503,
      'bank_not_configured',
    );
  }
  return normalized;
}

function objectOrEmpty(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object'
    ? (value as Record<string, unknown>)
    : {};
}

function optionalText(value: unknown): string | undefined {
  const text = value == null ? '' : String(value).trim();
  return text || undefined;
}
