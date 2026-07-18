import { z } from 'zod';

export const importedTransactionDraftSchema = z.object({
  sourceId: z.string().min(1),
  source: z.literal('bank_aggregator'),
  amount: z.number().positive(),
  date: z.string().min(1),
  type: z.enum(['expense', 'income']),
  merchant: z.string().optional(),
  categorySuggestion: z.string().optional(),
  note: z.string().optional(),
  reviewStatus: z.enum(['pending', 'approved', 'rejected', 'imported']).default('pending'),
  confidence: z.number().min(0).max(1).optional(),
  accountId: z.string().optional(),
  accountName: z.string().optional(),
  pending: z.boolean().default(false),
  ledgerTransactionId: z.string().optional(),
});

export const bankImportRequestSchema = z.object({
  drafts: z
    .array(
      importedTransactionDraftSchema.extend({
        reviewStatus: z.literal('approved').or(z.literal('imported')),
        ledgerTransactionId: z.string().min(1),
      }),
    )
    .max(250),
});

export const bankReviewRequestSchema = z.object({
  decisions: z
    .array(
      z.object({
        sourceId: z.string().min(1),
        reviewStatus: z.enum(['approved', 'rejected']),
      }),
    )
    .min(1)
    .max(250),
});

export const bankAccountSelectionSchema = z.object({
  selectedAccountIds: z.array(z.string().min(1)).min(1).max(50),
});

export type ImportedTransactionDraft = z.infer<
  typeof importedTransactionDraftSchema
>;
export type BankImportRequest = z.infer<typeof bankImportRequestSchema>;
export type BankReviewRequest = z.infer<typeof bankReviewRequestSchema>;
