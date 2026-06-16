import { describe, expect, it, vi } from 'vitest';

import { createLeafWorker, type Env } from '../src/index';

const baseContext = {
  greeting_name: 'Jaivik',
  allowance_mode: 'paycheck' as const,
  balance: 1000,
  daily_allowance: 88.24,
  remaining_today: 42.12,
  today_spend: 46.12,
  primary_goal_name: 'Vacation',
  next_bill_name: 'Internet/Phone',
};

describe('Leaf Worker', () => {
  it('returns a read-only allowance answer in mock mode', async () => {
    const worker = createLeafWorker();

    const response = await invoke(worker, {
      url: 'https://leaf.test/assistant/message',
      body: {
        message: 'How much can I spend today?',
        context: baseContext,
      },
      env: { LEAF_DEV_MODE: 'mock' },
    });

    expect(response.status).toBe(200);
    const body = await response.json<{ type: string; intent: string }>();
    expect(body.type).toBe('assistant_message');
    expect(body.intent).toBe('get_allowance_status');
  });

  it('returns an expense preview in mock mode when the category is obvious', async () => {
    const worker = createLeafWorker();

    const response = await invoke(worker, {
      url: 'https://leaf.test/assistant/message',
      body: {
        message: 'Add my $25 dinner',
        context: {
          ...baseContext,
          categories: [
            { id: 'cat-dining', name: 'Dining Out' },
            { id: 'cat-groceries', name: 'Groceries' },
          ],
        },
      },
      env: { LEAF_DEV_MODE: 'mock' },
    });

    const body = await response.json<{
      type: string;
      action?: {
        intent: string;
        missing_fields: string[];
        data?: { category_id?: string; category_name?: string };
      };
    }>();
    expect(body.type).toBe('action_preview');
    expect(body.action?.intent).toBe('add_expense');
    expect(body.action?.missing_fields).toEqual([]);
    expect(body.action?.data?.category_id).toBe('cat-dining');
  });

  it('returns tappable category options when the category is ambiguous', async () => {
    const worker = createLeafWorker();

    const response = await invoke(worker, {
      url: 'https://leaf.test/assistant/message',
      body: {
        message: 'Add $20 I spent',
        context: {
          ...baseContext,
          categories: [
            { id: 'cat-misc', name: 'Misc' },
            { id: 'cat-personal', name: 'Personal' },
          ],
        },
      },
      env: { LEAF_DEV_MODE: 'mock' },
    });

    const body = await response.json<{
      type: string;
      clarification_field?: string;
      clarification_options?: Array<{ id: string; label: string; patch: Record<string, unknown> }>;
      action?: { missing_fields: string[] };
    }>();
    expect(body.type).toBe('clarification_request');
    expect(body.clarification_field).toBe('category_id');
    expect(body.clarification_options?.length).toBeGreaterThan(0);
    expect(body.clarification_options?.[0].patch.category_id).toBeDefined();
    expect(body.action?.missing_fields).toContain('category_name');
  });

  it('serves budgeting advice in mock mode', async () => {
    const worker = createLeafWorker();

    const response = await invoke(worker, {
      url: 'https://leaf.test/assistant/message',
      body: {
        message: 'Got any advice for saving more?',
        context: baseContext,
      },
      env: { LEAF_DEV_MODE: 'mock' },
    });

    const body = await response.json<{ type: string; intent: string }>();
    expect(body.type).toBe('assistant_message');
    expect(body.intent).toBe('advice');
  });

  it('accepts a request with history and attachments without throwing', async () => {
    const worker = createLeafWorker();

    const response = await invoke(worker, {
      url: 'https://leaf.test/assistant/message',
      body: {
        message: 'log it',
        context: baseContext,
        history: [
          { role: 'user', text: 'Remember I had dinner' },
          { role: 'assistant', text: 'Sure, how much was it?' },
        ],
        attachments: [
          { name: 'receipt.jpg', mime: 'image/jpeg', data: 'AAAA' },
        ],
      },
      env: { LEAF_DEV_MODE: 'mock' },
    });

    expect(response.status).toBe(200);
    const body = await response.json<{ type: string }>();
    expect(body.type).toBeDefined();
  });

  it('returns a clarification when a write request is missing the amount', async () => {
    const worker = createLeafWorker();

    const response = await invoke(worker, {
      url: 'https://leaf.test/assistant/message',
      body: {
        message: 'Add my dinner',
        context: baseContext,
      },
      env: { LEAF_DEV_MODE: 'mock' },
    });

    const body = await response.json<{
      type: string;
      action?: { missing_fields: string[] };
    }>();
    expect(body.type).toBe('clarification_request');
    expect(body.action?.missing_fields).toContain('amount');
  });

  it('falls back safely when Gemini returns invalid envelope JSON', async () => {
    const fetchImpl = vi.fn<typeof fetch>().mockResolvedValue(
      geminiResponse({
        not_an_envelope: true,
      }),
    );
    const worker = createLeafWorker({ fetchImpl });

    const response = await invoke(worker, {
      url: 'https://leaf.test/assistant/message',
      body: {
        message: 'How much can I spend today?',
        context: baseContext,
      },
      env: liveEnv(),
    });

    const body = await response.json<{ type: string; intent: string }>();
    expect(body.type).toBe('assistant_message');
    expect(body.intent).toBe('unknown');
  });

  it('builds success and failure execution follow-ups', async () => {
    const fetchImpl = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(
        geminiResponse({
          assistant_message: 'Added that expense and your budget is up to date.',
        }),
      )
      .mockResolvedValueOnce(
        geminiResponse({
          assistant_message: 'I could not match that bill to anything in your list.',
        }),
      );
    const worker = createLeafWorker({ fetchImpl });

    const successResponse = await invoke(worker, {
      url: 'https://leaf.test/assistant/respond',
      body: {
        action: {
          intent: 'add_expense',
          confidence: 0.9,
          requires_confirmation: true,
          is_read_only: false,
          missing_fields: [],
          reason: 'User wants to log an expense.',
          data: { amount: 25, category_name: 'Dining Out' },
        },
        success: true,
        result: { amount: 25, category_name: 'Dining Out' },
        context: baseContext,
      },
      env: liveEnv(),
    });

    const failureResponse = await invoke(worker, {
      url: 'https://leaf.test/assistant/respond',
      body: {
        action: {
          intent: 'mark_bill_paid',
          confidence: 0.9,
          requires_confirmation: true,
          is_read_only: false,
          missing_fields: [],
          reason: 'User wants to mark a bill paid.',
          data: { bill_name: 'Internet/Phone' },
        },
        success: false,
        error_message: 'I could not match that bill to anything in your list.',
        context: baseContext,
      },
      env: liveEnv(),
    });

    const successBody = await successResponse.json<{ assistant_message: string }>();
    const failureBody = await failureResponse.json<{ assistant_message: string }>();
    expect(successBody.assistant_message).toContain('Added that expense');
    expect(failureBody.assistant_message).toContain('could not match');
  });
});

function jsonRequest(url: string, body: unknown): Request {
  return new Request(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
  });
}

function geminiResponse(payload: unknown): Response {
  return new Response(
    JSON.stringify({
      candidates: [
        {
          content: {
            parts: [{ text: JSON.stringify(payload) }],
          },
        },
      ],
    }),
    {
      status: 200,
      headers: {
        'content-type': 'application/json',
      },
    },
  );
}

function liveEnv(): Env {
  return {
    GEMINI_API_KEY: 'test-key',
    GEMINI_MODEL: 'gemini-2.5-flash',
  };
}

async function invoke(
  worker: ReturnType<typeof createLeafWorker>,
  options: {
    url: string;
    body: unknown;
    env: Env;
  },
): Promise<Response> {
  return worker.fetch!(
    jsonRequest(options.url, options.body) as never,
    options.env,
    {} as ExecutionContext,
  );
}
