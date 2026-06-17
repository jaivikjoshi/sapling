import type {
  AssistantMessageRequest,
  ExecutionResponseRequest,
  LeafClarificationOption,
  LeafEnvelope,
} from './schemas';

export function buildMockMessageResponse(
  request: AssistantMessageRequest,
): LeafEnvelope {
  const message = request.message.trim();
  const lower = message.toLowerCase();
  const name = request.context.greeting_name.trim() || 'there';

  if (/\b(hi|hey|hello|yo)\b/.test(lower)) {
    return {
      type: 'assistant_message',
      assistant_message: `Hey ${name}. Ask about spending, bills, or your goal — or tell me something to record and I can log it.`,
      intent: 'small_talk',
      suggested_prompts: defaultPrompts,
    };
  }

  if (/\b(advice|tips|suggest|how should|should i|recommend)\b/.test(lower)) {
    return {
      type: 'assistant_message',
      assistant_message:
        'A simple starting point: cover your bills and goal contribution first, then let the daily allowance govern day-to-day spending. Want me to look at your current pace?',
      intent: 'advice',
      suggested_prompts: ['How am I pacing this week?', 'What should I cut back on?'],
    };
  }

  if (/\b(spend|allowance|today|budget|left)\b/.test(lower)) {
    const left = request.context.remaining_today;
    const daily = request.context.daily_allowance;
    return {
      type: 'assistant_message',
      assistant_message:
        left != null && daily != null
          ? `You have about $${left.toFixed(2)} left today on a $${daily.toFixed(2)} allowance.`
          : 'I can answer that once your allowance data is available.',
      intent: 'get_allowance_status',
      suggested_prompts: defaultPrompts,
    };
  }

  if (/\b(bill|bills|due|payment)\b/.test(lower)) {
    return {
      type: 'assistant_message',
      assistant_message: request.context.next_bill_name
        ? `Your next bill in view is ${request.context.next_bill_name}.`
        : 'I do not have a next bill in view yet.',
      intent: 'get_bills_due',
      suggested_prompts: defaultPrompts,
    };
  }

  const amountMatch = request.message.match(/\$?\s?(\d+(?:\.\d{1,2})?)/);
  const writeWords = /\b(add|log|spent|bought|paid)\b/.test(lower);

  if (writeWords && !amountMatch) {
    return {
      type: 'clarification_request',
      assistant_message:
        'I can log that, but I still need the amount before I preview it.',
      intent: 'add_expense',
      action: {
        intent: 'add_expense',
        confidence: 0.61,
        requires_confirmation: true,
        is_read_only: false,
        missing_fields: ['amount'],
        reason: 'User appears to be logging an expense but did not include an amount.',
        data: {
          merchant: request.message.trim(),
        },
      },
      clarification_field: 'amount',
      clarification_options: [],
      suggested_prompts: defaultPrompts,
    };
  }

  if (writeWords && amountMatch) {
    const amount = Number(amountMatch[1]);
    const guessedCategory = guessCategory(request, lower);
    const categories = (request.context.categories ?? []).slice(0, 6);

    if (guessedCategory || categories.length === 0) {
      return {
        type: 'action_preview',
        assistant_message: guessedCategory
          ? `I can log $${amount.toFixed(2)} to ${guessedCategory.name}. Want me to add it?`
          : `I can log $${amount.toFixed(2)} as an expense. Want me to add it?`,
        intent: 'add_expense',
        action: {
          intent: 'add_expense',
          confidence: guessedCategory ? 0.88 : 0.8,
          requires_confirmation: true,
          is_read_only: false,
          missing_fields: [],
          reason: 'User wants to log an expense.',
          data: {
            amount,
            merchant: request.message.trim(),
            category_id: guessedCategory?.id,
            category_name: guessedCategory?.name,
          },
        },
        suggested_prompts: defaultPrompts,
      };
    }

    const options: LeafClarificationOption[] = categories.map((category) => ({
      id: category.id,
      label: category.name,
      patch: {
        category_id: category.id,
        category_name: category.name,
      },
    }));

    return {
      type: 'clarification_request',
      assistant_message: `I can log $${amount.toFixed(2)} for that. Which category fits it best?`,
      intent: 'add_expense',
      action: {
        intent: 'add_expense',
        confidence: 0.72,
        requires_confirmation: true,
        is_read_only: false,
        missing_fields: ['category_name'],
        reason: 'User wants to log an expense but has not named a category.',
        data: {
          amount,
          merchant: request.message.trim(),
        },
      },
      clarification_field: 'category_id',
      clarification_options: options,
      suggested_prompts: defaultPrompts,
    };
  }

  if (request.attachments && request.attachments.length > 0) {
    return {
      type: 'assistant_message',
      assistant_message:
        'I received your attachment. In dev mode I cannot parse it, but live mode will read receipts and statements for you.',
      intent: 'small_talk',
      suggested_prompts: defaultPrompts,
    };
  }

  return {
    type: 'assistant_message',
    assistant_message:
      'I can help with budgeting advice, your allowance, bills, goals, or record something you spent. What would you like to dig into?',
    intent: 'advice',
    suggested_prompts: defaultPrompts,
  };
}

function guessCategory(
  request: AssistantMessageRequest,
  lower: string,
): { id: string; name: string } | null {
  const categories = request.context.categories ?? [];
  if (categories.length === 0) return null;

  // Exact name match first
  for (const category of categories) {
    if (lower.includes(category.name.toLowerCase())) {
      return { id: category.id, name: category.name };
    }
  }

  const heuristics: Array<[RegExp, string]> = [
    [/dinner|lunch|coffee|restaurant|dining|brunch/, 'dining'],
    [/grocer|whole foods|trader joe|market/, 'grocer'],
    [/uber|lyft|train|bus|gas|fuel|transit/, 'transport'],
    [/spotify|netflix|subscription|apple|prime/, 'subscription'],
    [/amazon|shopping|store/, 'shop'],
  ];

  for (const [pattern, token] of heuristics) {
    if (!pattern.test(lower)) continue;
    const match = categories.find((category) =>
      category.name.toLowerCase().includes(token),
    );
    if (match) return { id: match.id, name: match.name };
  }

  return null;
}

export function buildMockRespondResponse(
  request: ExecutionResponseRequest,
): { assistant_message: string } {
  if (!request.success) {
    return {
      assistant_message:
        request.error_message ??
        'That did not go through. Check the details and try again.',
    };
  }

  return {
    assistant_message: 'Done. I updated that in your budget.',
  };
}

const defaultPrompts = [
  'How much can I spend today?',
  'What bills are coming up?',
  'Give me a budgeting tip',
  'Add my $25 dinner',
];
