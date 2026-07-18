# Leko Product Roadmap

Last reviewed: 2026-06-16

## Product Position

Leko is a calm personal finance app built around daily spending clarity. Leaf, the AI assistant, should feel practical and conversational: it helps log transactions, explain budgets, surface bills, protect savings goals, and reduce the mental math around money.

Leaf should avoid sounding like a professional financial adviser. Use language such as "you could consider" and "based on your spending patterns" for recommendations.

## What Leko Already Does Well

- Daily allowance logic is central to the product instead of hidden in reports.
- Leaf can preview write actions before changing data.
- Recurring bills, recurring income, payday automation, goals, closeout, recovery plans, splits, and reports already exist as real app concepts.
- Attachments are scaffolded in chat for receipts, bills, screenshots, and PDFs.
- The product tone is calmer than many budgeting apps and can become a strong differentiator.

## Competitor Notes

- Wealthsimple leans into simple goal buckets and "pay yourself first" habits, which supports Leko's goal-progress-first direction. Source: [Wealthsimple budgeting guide](https://www.wealthsimple.com/en-ca/learn/what-is-budgeting).
- YNAB emphasizes intentional planning through giving every dollar a job and checking the plan before spending. Source: [YNAB Method](https://www.ynab.com/ynab-method).
- Monarch emphasizes account aggregation, flexible/category budgeting, dashboard progress, custom categories, and shared planning. Sources: [Monarch](https://www.monarch.com/), [Monarch for Couples](https://www.monarch.com/for-couples).
- Rocket Money emphasizes subscription management, bills, spending tracking, budget customization, and bill-lowering workflows. Sources: [Rocket Money](https://www.rocketmoney.com/), [What is Rocket Money](https://www.rocketmoney.com/learn/personal-finance/what-is-rocket-money).
- Cleo differentiates with an AI-first chat interface that tracks spending, calls out habits, supports goals, and answers money questions conversationally. Sources: [Cleo](https://web.meetcleo.com/), [Cleo app listing](https://apps.apple.com/us/app/cleo-ai-cash-advance-budget/id1447274646).
- Trusted aggregators such as Plaid and Flinks can provide transaction and account connectivity without Leko storing raw bank credentials. Sources: [Plaid Transactions](https://plaid.com/docs/transactions/), [Flinks Connect](https://www.flinks.com/products/connect).

## Product Strategy Pull-Through

- Use a review-first import queue. Whether a draft comes from a bank aggregator, bank notification, receipt OCR, or Leaf voice, the user should approve it before it changes the ledger.
- Treat daily spend like the front door, but treat goals like named buckets. The Home screen should answer "Can I spend today?" while Goals answers "What is this money for?"
- Make reports explain drift, not just totals: subscription changes, bill variance, category anomalies, and weekly/monthly forecast deltas.
- Keep household mode later, but model roles early so shared budgeting does not require rewriting core data contracts.

## MVP Priorities

1. Make daily budget math trustworthy everywhere.
   - Use one money/date utility layer for balances, daily allowance, expenses, income, goal progress, and bill deductions.
   - Add regression tests for duplicate bill posting, payday posting, daily allowance, and currency display.

2. Make Leaf transaction creation feel complete.
   - Maintain draft action state across turns.
   - Always show explicit choices for missing category, date, account, recurrence, and bill selection.
   - Add receipt/PDF attachment metadata to transactions once the transaction is confirmed.

3. Strengthen income handling.
   - Keep fixed, hourly, and variable income paths separate in the UI.
   - For variable income, show recent average, trend, and conservative estimate rather than forcing an expected amount.
   - Make paycheck auto-posting visible on Home and Reports.

4. Polish Home.
   - Keep the hero focused on safe-to-spend today.
   - Show Add Expense, Add Income, and Add Goal as first-class actions.
   - Add a simple balance breakdown: chequing, savings, income this period, expenses this period.

5. Make privacy and integrations clear.
   - Keep notification reading and bank connections opt-in.
   - Add provider interfaces before wiring real providers.
   - Never store bank credentials directly in the app.

## Later Release

- Bank connection through a trusted aggregator with transaction review before import.
- Notification-based expense detection on supported platforms.
- OCR extraction for receipts and PDFs: amount, merchant, date, tax, and category suggestions.
- Voice input for Leaf using platform speech-to-text, routed through the same draft-action flow as typed input.
- Local/personal badges: first expense, first goal, tracking streak, under budget today, saved this week, bill paid on time.
- Shared budgeting or household mode after individual budgeting is stable.
- Wealthsimple-style savings growth chart with smooth goal progress and contribution history.
- More dynamic reports: recurring subscription drift, bill variance, category anomalies, and weekly/monthly forecast.

## Implementation Started

- `lib/domain/integrations/transaction_importer.dart` now models bank aggregator drafts, bank notification drafts, OCR drafts, voice transcripts, review status, dedupe keys, consent copy, and unsupported platform fallbacks.
- `lib/domain/integrations/product_foundations.dart` now contains first-pass contracts for local badges, household roles, savings growth series, and dynamic report request types.
- `lib/core/providers/integration_providers.dart` exposes unsupported default providers so UI can be wired without unsafe credentials or platform-specific code.
- `test/domain/integrations/product_foundations_test.dart` covers transaction review dedupe/approval, OCR-to-draft conversion, local badge awards, and savings growth progress.
- `lib/features/imports/import_review_screen.dart` provides a review-first screen for bank, notification, OCR, and future aggregator drafts before import.
- Leaf attachments now attempt OCR-to-review-draft conversion through `ReceiptOcrProvider`, and Leaf voice input routes through `VoiceInputProvider` before using the same typed-message draft flow.
- Home now shows local/personal badges from real app activity.
- Goals now include a smooth savings-progress sparkline that can later be backed by explicit contribution history.
- Reports now surface dynamic checks for bill variance, subscription drift, category anomalies, and weekly/monthly forecast.
- `lib/features/household/household_screen.dart` stages shared budgeting roles without enabling shared ledgers before the individual flow is stable.
- `FinanceSummaryService` now provides a single production-facing summary for balances, cycle totals, daily allowance, and safe-to-spend explanations.
- `ProductionObservability` and the analytics event contract now prepare Leko for privacy-first beta measurement.
- RevenueCat subscription scaffolding and the `/premium` screen now define the freemium path without requiring production keys in source.

## Technical Notes

- Keep `TransactionImporter`, `BankProvider`, `NotificationProvider`, `ReceiptOcrProvider`, and `VoiceInputProvider` as the boundary for future import features.
- Attachments should get durable ids before being linked to transactions; current chat payloads are enough for assistant parsing but not long-term storage.
- Currency should move from ad hoc `formatCurrency()` calls toward a setting-aware formatter/provider so CAD and USD are respected consistently.
- Add widget tests for onboarding first page, Leaf category clarification, Home daily hero, and Add Income navigation.
- Consider a dedicated `MoneyMath` or `FinanceSummaryService` to prevent screens from reimplementing totals.

## Current Product Gaps

- Currency selection exists, but not every money display is setting-aware yet.
- Attachment upload exists in Leaf, but transaction-level persistence, PDF parsing, and production-grade OCR extraction are not complete.
- Voice input has provider wiring and routes into the Leaf draft flow, but still needs platform permission hardening and real-device QA.
- Bank aggregator and notification import paths have contracts and review-first UI, but real production providers are not connected yet.
- Gamification and goal icons need a small, cohesive design pass.
- The mobile app builds for iOS simulator and Android debug; web is not ready until Drift/sqlite native FFI is split behind a web-compatible database implementation.
- Sentry and RevenueCat are wired as optional production services, but real project keys, App Store products, and entitlement setup still need to be completed outside the repo.
