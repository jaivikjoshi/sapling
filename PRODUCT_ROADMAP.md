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

- YNAB emphasizes intentional planning through giving every dollar a job and checking the plan before spending. Source: [YNAB Method](https://www.ynab.com/ynab-method).
- Monarch emphasizes account aggregation, flexible/category budgeting, dashboard progress, custom categories, and shared planning. Sources: [Monarch app listing](https://apps.apple.com/us/app/monarch-budget-track-money/id1459319842), [Monarch pricing](https://www.monarch.com/pricing).
- Rocket Money emphasizes subscription management, bills, spending tracking, budget customization, and bill-lowering workflows. Sources: [Rocket Money](https://www.rocketmoney.com/), [What is Rocket Money](https://www.rocketmoney.com/learn/personal-finance/what-is-rocket-money).
- Cleo differentiates with an AI-first chat interface that tracks spending, calls out habits, supports goals, and answers money questions conversationally. Sources: [Cleo](https://web.meetcleo.com/), [Cleo app listing](https://apps.apple.com/us/app/cleo-ai-cash-advance-budget/id1447274646).

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

## Technical Notes

- Keep `TransactionImporter`, `BankProvider`, and `NotificationProvider` as the boundary for future import features.
- Attachments should get durable ids before being linked to transactions; current chat payloads are enough for assistant parsing but not long-term storage.
- Currency should move from ad hoc `formatCurrency()` calls toward a setting-aware formatter/provider so CAD and USD are respected consistently.
- Add widget tests for onboarding first page, Leaf category clarification, Home daily hero, and Add Income navigation.
- Consider a dedicated `MoneyMath` or `FinanceSummaryService` to prevent screens from reimplementing totals.

## Current Product Gaps

- Currency selection exists, but not every money display is setting-aware yet.
- Attachment upload exists in Leaf, but transaction-level persistence and OCR are not complete.
- Voice input is visible as a placeholder, not implemented.
- Bank and notification import are scaffolds only.
- Gamification and goal icons need a small, cohesive design pass.
