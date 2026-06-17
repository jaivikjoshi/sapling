import { z } from 'zod';

import { generateGeminiJson, type GeminiEnv } from './gemini';
import {
  buildMockMessageResponse,
  buildMockRespondResponse,
} from './mock';
import {
  buildMessageSystemPrompt,
  buildMessageUserPrompt,
  buildRespondSystemPrompt,
  buildRespondUserPrompt,
} from './prompts';
import {
  assistantMessageRequestSchema,
  assistantRespondSchema,
  executionResponseRequestSchema,
  leafEnvelopeSchema,
  type AssistantMessageRequest,
  type ExecutionResponseRequest,
  type LeafEnvelope,
} from './schemas';

export interface Env extends GeminiEnv {
  LEAF_DEV_MODE?: string;
}

interface WorkerDeps {
  fetchImpl?: typeof fetch;
}

export function createLeafWorker(deps: WorkerDeps = {}): ExportedHandler<Env> {
  const fetchImpl = deps.fetchImpl ?? fetch;

  return {
    async fetch(request, env): Promise<Response> {
      const url = new URL(request.url);

      if (request.method === 'OPTIONS') {
        return withCors(new Response(null, { status: 204 }));
      }

      if (request.method === 'GET' && url.pathname === '/health') {
        return jsonResponse({
          ok: true,
          mode: isMockMode(env) ? 'mock' : 'live',
        });
      }

      if (request.method === 'POST' && url.pathname === '/assistant/message') {
        return handleAssistantMessage(request, env, fetchImpl);
      }

      if (request.method === 'POST' && url.pathname === '/assistant/respond') {
        return handleAssistantRespond(request, env, fetchImpl);
      }

      return jsonResponse(
        {
          error: 'Not found',
          available_routes: [
            'GET /health',
            'POST /assistant/message',
            'POST /assistant/respond',
          ],
        },
        404,
      );
    },
  };
}

async function handleAssistantMessage(
  request: Request,
  env: Env,
  fetchImpl: typeof fetch,
): Promise<Response> {
  const parsed = assistantMessageRequestSchema.safeParse(await readJson(request));
  if (!parsed.success) {
    return validationError(parsed.error);
  }

  const payload = parsed.data;

  try {
    const envelope = isMockMode(env)
      ? buildMockMessageResponse(payload)
      : await buildLiveMessageResponse(payload, env, fetchImpl);

    return jsonResponse(normalizeEnvelope(envelope));
  } catch (error) {
    console.error('Leaf message route failed', error);
    return jsonResponse(defaultEnvelope(), 200);
  }
}

async function handleAssistantRespond(
  request: Request,
  env: Env,
  fetchImpl: typeof fetch,
): Promise<Response> {
  const parsed = executionResponseRequestSchema.safeParse(await readJson(request));
  if (!parsed.success) {
    return validationError(parsed.error);
  }

  try {
    const response = isMockMode(env)
      ? buildMockRespondResponse(parsed.data)
      : await buildLiveRespondResponse(parsed.data, env, fetchImpl);

    return jsonResponse(response);
  } catch (error) {
    console.error('Leaf respond route failed', error);
    return jsonResponse({
      assistant_message: parsed.data.success
        ? 'Done.'
        : parsed.data.error_message ??
          'That did not go through. Check the details and try again.',
    });
  }
}

async function buildLiveMessageResponse(
  request: AssistantMessageRequest,
  env: Env,
  fetchImpl: typeof fetch,
): Promise<LeafEnvelope> {
  const raw = await generateGeminiJson(
    env,
    {
      systemInstruction: buildMessageSystemPrompt(),
      userPrompt: buildMessageUserPrompt(request),
      schemaDescription:
        'Leaf assistant envelope JSON for the mobile app, with snake_case keys.',
      history: request.history,
      attachments: request.attachments,
    },
    fetchImpl,
  );

  const parsed = leafEnvelopeSchema.safeParse(raw);
  if (!parsed.success) {
    console.warn('Invalid Gemini envelope payload', parsed.error.flatten());
    return defaultEnvelope();
  }

  return normalizeEnvelope(parsed.data);
}

async function buildLiveRespondResponse(
  request: ExecutionResponseRequest,
  env: Env,
  fetchImpl: typeof fetch,
): Promise<{ assistant_message: string }> {
  const raw = await generateGeminiJson(
    env,
    {
      systemInstruction: buildRespondSystemPrompt(),
      userPrompt: buildRespondUserPrompt(request),
      schemaDescription: '{"assistant_message":"string"}',
    },
    fetchImpl,
  );

  const parsed = assistantRespondSchema.safeParse(raw);
  if (!parsed.success) {
    console.warn('Invalid Gemini respond payload', parsed.error.flatten());
    return {
      assistant_message: request.success
        ? 'Done.'
        : request.error_message ??
          'That did not go through. Check the details and try again.',
    };
  }

  return parsed.data;
}

async function readJson(request: Request): Promise<unknown> {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

function normalizeEnvelope(envelope: LeafEnvelope): LeafEnvelope {
  return {
    ...envelope,
    intent: envelope.intent ?? envelope.action?.intent,
    suggested_prompts:
      envelope.suggested_prompts && envelope.suggested_prompts.length > 0
        ? envelope.suggested_prompts
        : defaultPrompts,
  };
}

function defaultEnvelope(): LeafEnvelope {
  return {
    type: 'assistant_message',
    assistant_message:
      'I didn’t quite catch that. Ask about spending today, bills, your goal, or tell me what to record.',
    intent: 'unknown',
    suggested_prompts: defaultPrompts,
  };
}

function validationError(error: z.ZodError): Response {
  return jsonResponse(
    {
      error: 'Invalid request body',
      details: error.flatten(),
    },
    400,
  );
}

function jsonResponse(payload: unknown, status = 200): Response {
  return withCors(
    new Response(JSON.stringify(payload, null, 2), {
      status,
      headers: {
        'content-type': 'application/json; charset=utf-8',
      },
    }),
  );
}

function withCors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set('access-control-allow-origin', '*');
  headers.set('access-control-allow-methods', 'GET,POST,OPTIONS');
  headers.set('access-control-allow-headers', 'content-type');
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function isMockMode(env: Env): boolean {
  return env.LEAF_DEV_MODE?.toLowerCase() === 'mock';
}

const defaultPrompts = [
  'How much can I spend today?',
  'What bills are coming up?',
  'Give me a budgeting tip',
  'Add my $25 dinner',
];

export default createLeafWorker();
