# Leko Production Growth Execution Plan

Last updated: 2026-06-17

## Positioning

Leko should be marketed as an AI safe-to-spend app, not a generic budget tracker.

Core promise:

> Know what is safe to spend today, understand why, and turn messy money inputs into reviewed actions.

Launch market: US + Canada.
Monetization: freemium subscription, no ads in the core product.
Initial growth budget: lean, under $500/month until retention is proven.

## Production Readiness Before Public Growth

Do these before pushing beyond a small TestFlight/internal beta:

1. Production identity
   - Confirm bundle id, app display name, app icon, launch screen, and App Store screenshots say Leko consistently.
   - Remove or fully implement any sign-in option that does not work in production.
   - Configure Supabase production URL and anon key through CI/App Store build settings.

2. Trust and compliance
   - Legal review for privacy policy, terms, deletion, export, bank aggregation, notification reading, receipt/PDF attachments, OCR, and voice transcription.
   - App Store privacy nutrition labels must match actual SDKs and data collection.
   - Leko must never store raw bank credentials. Bank connection must run through a trusted aggregator or a backend that delegates to one.

3. Reliability
   - `flutter analyze` and `flutter test` must pass.
   - Android debug/release and iOS simulator/device builds must pass.
   - Crash reporting must be configured before any public beta.
   - Manual real-device QA must cover onboarding, auth, Home, Add Expense, Add Income, Add Goal, Bills, Leaf text, Leaf attachments, Leaf voice, Import Review, Reports, Settings, account deletion, and offline/poor-network states.

4. Money correctness
   - Finance math must flow through one canonical summary layer.
   - Every financial write must be test-covered: manual expense, manual income, recurring bill, recurring income/payday, goal creation, import approval, OCR draft approval, edit, delete, and currency display.
   - Home must explain safe-to-spend from live inputs.

## 0 To 1,000 Users

Goal: prove activation and retention, not scale.

Target audience:

- Students, young professionals, and first-time budgeters who ask "Can I spend today?"
- People paid biweekly, twice-monthly, hourly, or variable income.
- Users who want AI help but do not trust fully automatic financial changes.

Product gates:

- New user reaches Home with a valid safe-to-spend number.
- User can add income, expense, bill, and goal without support.
- Leaf can add a transaction draft and ask for missing category/date/account with buttons.
- Import Review can hold bank/OCR/notification/voice drafts without changing the ledger.

Growth actions:

- Run TestFlight with 25-50 users.
- Ask every tester to record where they got confused in onboarding and first Home screen.
- Post daily short-form clips showing one narrow job:
  - "Can I spend $20 today?"
  - "Receipt to reviewed expense."
  - "Why am I over budget?"
  - "Variable income budget without guessing."
  - "AI budget coach that asks before changing anything."

Metrics:

- Onboarding completion: 35-50%.
- First-session activation: 40%+ of onboarded users add income or opening balance.
- D1 retention: 30%+.
- Crash-free sessions: 99%+.

## 1,000 To 10,000 Users

Goal: validate repeat usage and willingness to pay.

Product gates:

- Real provider-backed observability is enabled.
- RevenueCat is configured with monthly and annual products.
- Privacy/legal copy is final enough for App Store review.
- At least one premium hook works end-to-end: bank review, OCR, voice, or advanced reports.

Growth actions:

- App Store Optimization:
  - Primary terms: daily budget, safe to spend, AI budget planner, expense tracker, receipt tracker.
  - Screenshots should show actual flows, not marketing abstractions.
  - First screenshot should communicate safe-to-spend.
- Content:
  - 30 short videos/month.
  - 10 landing-page/app-store copy experiments/month.
  - 5 creator outreach messages/week to personal finance, student life, and productivity creators.
- Paid:
  - Start Apple Search Ads only after onboarding analytics are trustworthy.
  - Test $5-$10/day campaigns against two or three keyword clusters.
  - Kill any keyword whose activated-user cost is not trending toward sustainable CAC.

Metrics:

- D7 retention: 12-18%.
- Trial start: 3-7% of activated users.
- Trial-to-paid: 25-40% once premium value is real.
- Paid churn: under 7% monthly before scaling ads.
- Support response: under 24 hours.

## 10,000 To 100,000 Users

Goal: scale a proven loop without breaking trust.

Do not chase this stage until retention and conversion are proven.

Product gates:

- Bank connection review-first import is stable in US + Canada.
- OCR handles images and PDFs with confidence scores and editable drafts.
- Voice routes through the same draft-action system as typed Leaf prompts.
- Weekly report catches subscription drift, bill variance, category anomaly, and forecast risk.
- Household mode has explicit roles, consent, invites, and shared-ledger rules.

Growth actions:

- Add referral loop after household mode is stable.
- Build creator partnerships around "safe-to-spend" and "AI money assistant that asks first."
- Add lifecycle campaigns:
  - Abandoned onboarding.
  - No income added.
  - First bill reminder.
  - Weekly recap.
  - Trial ending.
  - Churn survey.
  - Winback when a premium feature improves.

Metrics:

- CAC below 40-60% of first-year LTV.
- Monthly paid churn under 5-7%.
- Crash-free sessions above 99.5%.
- Import approval rate above 70% for high-confidence drafts.
- OCR correction rate trending down over time.

## Monetization

Free tier:

- Manual expense and income tracking.
- Daily safe-to-spend.
- Basic goals.
- Basic reports.
- Limited Leaf usage.

Premium tier:

- Unlimited Leaf usage.
- Bank sync with review before import.
- Receipt/PDF OCR.
- Voice input.
- Advanced reports: subscriptions, bill variance, anomalies, forecasts.
- Goal forecasting and contribution history.
- Household mode later.

Starter pricing:

- Monthly: $4.99.
- Annual: $39.99.
- Trial: 14-30 days once onboarding is stable.

Avoid ads in the core app. Ads undermine financial trust and weaken premium positioning.

## What To Automate

Engineering:

- CI analyze/test/build.
- Dependency and SDK audit.
- Release-note generation.
- App Store metadata linting.
- Screenshot/golden checks for high-risk screens.

QA:

- Leaf prompt regression suites.
- Receipt/PDF parsing fixtures with synthetic documents.
- Money math regression tests.
- Accessibility checks for contrast, dynamic type, and tappable areas.

Growth:

- ASO keyword clustering.
- Short-form script generation.
- Competitor review monitoring.
- Support ticket summarization.
- Churn reason clustering.

Support:

- AI can draft responses, but a human should approve anything involving billing, account deletion, security, or financial-data concerns.

## What Codex Can Own

- Flutter feature implementation.
- Tests and CI.
- Analytics event contracts.
- RevenueCat integration scaffolding.
- Paywall UI.
- Release checklist docs.
- Growth docs, ASO copy, beta surveys, and content scripts.
- Refactors for finance math, import review, Leaf draft flow, OCR/voice/provider boundaries.

## What Requires You Or External Providers

- Apple Developer and App Store Connect setup.
- RevenueCat project, products, entitlements, and API keys.
- Supabase production project and secrets.
- Sentry/Firebase project keys.
- Plaid/Flinks contracts and sandbox credentials.
- Legal review.
- Real beta users.
- App Store submission.
