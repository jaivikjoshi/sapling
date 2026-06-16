# Leko Privacy and Terms Notes

Last updated: 2026-06-16

## Plain-Language Privacy Commitments

- Leko uses financial data such as balances, income, expenses, bills, goals, categories, and settings to calculate budgets and show insights.
- Leaf chat attachments can include receipts, bills, screenshots, images, and PDFs. These should be associated with the conversation or transaction draft and parsed only when the user provides them.
- Future notification reading for bank alerts must be opt-in. Leko should ask for permission, explain what is read, store only necessary transaction details, and allow the user to disable it.
- Future bank connections must be opt-in and handled through a trusted provider or backend flow. The app should not store bank credentials directly.
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
