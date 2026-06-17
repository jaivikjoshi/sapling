import type { LeafAttachment, LeafHistoryTurn } from './schemas';

export interface GeminiEnv {
  GEMINI_API_KEY?: string;
  GEMINI_MODEL?: string;
}

export interface GenerateJsonOptions {
  systemInstruction: string;
  userPrompt: string;
  schemaDescription: string;
  history?: LeafHistoryTurn[];
  attachments?: LeafAttachment[];
}

interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string;
      }>;
    };
  }>;
}

type GeminiPart =
  | { text: string }
  | { inlineData: { mimeType: string; data: string } };

interface GeminiContent {
  role: 'user' | 'model';
  parts: GeminiPart[];
}

export async function generateGeminiJson(
  env: GeminiEnv,
  options: GenerateJsonOptions,
  fetchImpl: typeof fetch,
): Promise<unknown> {
  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY is not configured.');
  }

  const model = env.GEMINI_MODEL?.trim() || 'gemini-2.5-flash';
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${encodeURIComponent(model)}:generateContent`;

  const contents = buildContents(options);

  const response = await fetchImpl(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-goog-api-key': env.GEMINI_API_KEY,
    },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: options.systemInstruction }],
      },
      contents,
      generationConfig: {
        temperature: 0.3,
        responseMimeType: 'application/json',
      },
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini request failed (${response.status}): ${text}`);
  }

  const payload = (await response.json()) as GeminiResponse;
  const text = payload.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? '')
    .join('')
    .trim();

  if (!text) {
    throw new Error('Gemini returned no text payload.');
  }

  return JSON.parse(text);
}

function buildContents(options: GenerateJsonOptions): GeminiContent[] {
  const contents: GeminiContent[] = [];

  // Replay conversation history as alternating user/model turns. Gemini is
  // forgiving about exact interleaving as long as we label roles correctly.
  for (const turn of options.history ?? []) {
    if (!turn.text.trim()) continue;
    contents.push({
      role: turn.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: turn.text }],
    });
  }

  const latestParts: GeminiPart[] = [
    {
      text: `${options.userPrompt}\n\nReturn JSON matching: ${options.schemaDescription}`,
    },
  ];

  for (const attachment of options.attachments ?? []) {
    latestParts.push({
      inlineData: {
        mimeType: attachment.mime,
        data: attachment.data,
      },
    });
  }

  contents.push({ role: 'user', parts: latestParts });
  return contents;
}
