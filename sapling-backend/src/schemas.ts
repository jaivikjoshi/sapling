import { z } from 'zod';

export const leafIntentSchema = z.enum([
  'add_expense',
  'add_income',
  'mark_bill_paid',
  'create_goal',
  'set_primary_goal',
  'add_recurring_income',
  'set_allowance_mode',
  'set_cycle_reset',
  'set_spending_baseline',
  'reconcile_balance',
  'create_recovery_plan',
  'get_allowance_status',
  'get_spending_summary',
  'get_goal_progress',
  'get_bills_due',
  'get_recovery_status',
  'get_transactions',
  'clarify',
  'advice',
  'unsupported',
  'small_talk',
  'unknown',
]);

export const leafEnvelopeTypeSchema = z.enum([
  'assistant_message',
  'clarification_request',
  'action_preview',
  'execution_result',
  'error',
]);

const recordSchema = z.record(z.string(), z.unknown());

export const leafEntityRefSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  amount: z.number().optional(),
  due_date: z.string().optional(),
});

export const leafContextSchema = z.object({
  greeting_name: z.string().default(''),
  allowance_mode: z.enum(['paycheck', 'goal']),
  balance: z.number().nullable().optional(),
  daily_allowance: z.number().nullable().optional(),
  remaining_today: z.number().nullable().optional(),
  today_spend: z.number().nullable().optional(),
  primary_goal_name: z.string().nullable().optional(),
  next_bill_name: z.string().nullable().optional(),
  categories: z.array(leafEntityRefSchema).max(40).optional(),
  upcoming_bills: z.array(leafEntityRefSchema).max(20).optional(),
  goals: z.array(leafEntityRefSchema).max(20).optional(),
});

export const leafPendingActionSchema = z.object({
  intent: leafIntentSchema,
  confidence: z.number().min(0).max(1),
  requires_confirmation: z.boolean(),
  is_read_only: z.boolean(),
  missing_fields: z.array(z.string()),
  reason: z.string(),
  data: recordSchema,
});

export const leafClarificationOptionSchema = z.object({
  id: z.string().min(1),
  label: z.string().min(1),
  subtitle: z.string().optional(),
  patch: recordSchema.default({}),
});

export const leafEnvelopeSchema = z
  .object({
    type: leafEnvelopeTypeSchema,
    assistant_message: z.string().min(1),
    intent: leafIntentSchema.optional(),
    action: leafPendingActionSchema.optional(),
    success: z.boolean().optional(),
    result: recordSchema.optional(),
    error_code: z.string().optional(),
    suggested_prompts: z.array(z.string().min(1)).max(4).optional(),
    clarification_field: z.string().optional(),
    clarification_options: z.array(leafClarificationOptionSchema).max(10).optional(),
  })
  .superRefine((value, ctx) => {
    if (
      (value.type === 'clarification_request' ||
        value.type === 'action_preview') &&
      !value.action
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Clarification and preview responses require an action.',
        path: ['action'],
      });
    }
  });

export const leafHistoryTurnSchema = z.object({
  role: z.enum(['user', 'assistant']),
  text: z.string(),
});

export const leafAttachmentSchema = z.object({
  name: z.string().optional(),
  mime: z.string().min(1),
  // Base64-encoded bytes. We cap size server-side to keep Gemini payloads sane.
  data: z.string().min(1).max(9_000_000),
});

export const assistantMessageRequestSchema = z.object({
  message: z.string().min(1),
  context: leafContextSchema,
  history: z.array(leafHistoryTurnSchema).max(20).optional(),
  attachments: z.array(leafAttachmentSchema).max(3).optional(),
});

export const executionResponseRequestSchema = z.object({
  action: leafPendingActionSchema,
  success: z.boolean(),
  result: recordSchema.nullable().optional(),
  error_message: z.string().nullable().optional(),
  context: leafContextSchema,
});

export const assistantRespondSchema = z.object({
  assistant_message: z.string().min(1),
});

export type LeafContext = z.infer<typeof leafContextSchema>;
export type LeafPendingAction = z.infer<typeof leafPendingActionSchema>;
export type LeafEnvelope = z.infer<typeof leafEnvelopeSchema>;
export type LeafClarificationOption = z.infer<typeof leafClarificationOptionSchema>;
export type LeafHistoryTurn = z.infer<typeof leafHistoryTurnSchema>;
export type LeafAttachment = z.infer<typeof leafAttachmentSchema>;
export type AssistantMessageRequest = z.infer<typeof assistantMessageRequestSchema>;
export type ExecutionResponseRequest = z.infer<
  typeof executionResponseRequestSchema
>;
