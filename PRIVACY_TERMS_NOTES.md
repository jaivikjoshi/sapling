# Leko Privacy and Terms Notes

Last updated: 2026-07-17

## Plain-Language Privacy Commitments

- Leko uses financial data such as balances, income, expenses, bills, goals, categories, and settings to calculate budgets and show insights.
- Leaf chat attachments can include receipts, bills, screenshots, images, and PDFs. These should be associated with the conversation or transaction draft and parsed only when the user provides them.
- Future notification reading for bank alerts must be opt-in. Leko should ask for permission, explain what is read, store only necessary transaction details, and allow the user to disable it.
- Bank connections are opt-in and handled by Flinks Connect. Leko does not receive or store the user's bank username or password. The backend stores an encrypted Flinks connection identifier, selected account metadata, balances, and transaction drafts needed to provide the feature.
- Bank transaction data is not sent to analytics. Logs must not include merchant descriptions, account masks, balances, provider identifiers, or raw bank payloads.
- Disconnecting asks Flinks to delete the linked card data and removes Leko's connection metadata and unimported review records. Transactions already approved into the Leko ledger remain until the user deletes them or their account.
- Imported bank, notification, receipt, PDF, and voice-detected transactions should stay in a review queue until the user approves them.
- Voice input should only start after microphone permission and should route the transcript through the same Leaf draft-action flow as typed messages.
- Leaf can give practical budgeting suggestions, but it is not a professional financial, investment, tax, or legal adviser.

## Implementation Expectations

- Store attachment metadata separately from transaction ids until the user confirms the transaction.
- Keep imported transactions in a reviewable draft state before writing to the ledger.
- Log import source ids to prevent duplicate transaction creation.
- Keep provider boundaries clean through `BankProvider`, `NotificationProvider`, and `TransactionImporter`.
- Add platform-specific permission copy before enabling notification access.
- Explain trusted aggregator consent before opening bank-link flows.
- Keep real Supabase, bank aggregator, OCR, speech, and notification provider credentials out of source control.
- Add account deletion, data export, and retention language before App Store submission.
- List Flinks and Supabase as financial-data subprocessors and document the production retention/deletion SLA after legal review.
