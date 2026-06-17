# Analytics, Observability, And Monetization Setup

Last updated: 2026-06-17

## Dart Defines

Production builds should supply these values outside source control:

```bash
--dart-define=SUPABASE_URL=https://<project-ref>.supabase.co
--dart-define=SUPABASE_ANON_KEY=<anon-key>
--dart-define=LEKO_ENVIRONMENT=production
--dart-define=LEKO_RELEASE=1.0.0+1
--dart-define=SENTRY_DSN=<sentry-dsn>
--dart-define=LEKO_ANALYTICS_ENABLED=true
--dart-define=REVENUECAT_APPLE_API_KEY=<apple-public-sdk-key>
--dart-define=REVENUECAT_GOOGLE_API_KEY=<google-public-sdk-key>
```

If Sentry or RevenueCat keys are omitted, Leko stays runnable and shows a safe unconfigured state.

## Observability

Implemented:

- `ProductionObservability` initializes Sentry when `SENTRY_DSN` is present.
- Screenshots and default PII are disabled.
- Scheduler failures are captured.
- Analytics events are added as Sentry breadcrumbs when enabled.

Next:

- Add user-safe app version/build tags after release metadata is final.
- Add non-PII breadcrumbs for bank/OCR/voice provider failures.
- Add crash-free session and fatal crash tracking to the release dashboard.

## Analytics Events

Current event contract:

- `app_opened`
- `onboarding_started`
- `onboarding_completed`
- `home_viewed`
- `safe_to_spend_explained`
- `quick_action_started`
- `expense_created`
- `income_created`
- `goal_created`
- `leaf_message_sent`
- `leaf_draft_confirmed`
- `import_draft_approved`
- `import_draft_rejected`
- `paywall_viewed`
- `trial_started`
- `subscription_purchased`
- `subscription_restored`
- `subscription_failed`

Privacy rule:

- Do not send names, emails, merchants, notes, transcripts, raw amounts, receipt images, PDFs, bank account identifiers, or transaction descriptions as analytics properties.
- Use booleans, counts, broad feature names, and status labels.

Critical funnels:

1. Activation
   - onboarding started
   - onboarding completed
   - home viewed
   - income/expense/goal created
   - safe-to-spend explained

2. Leaf value
   - leaf message sent
   - missing-info choice shown
   - draft confirmed
   - draft rejected

3. Automation value
   - import preview started
   - draft approved
   - draft imported
   - provider failed

4. Monetization
   - paywall viewed
   - trial started
   - subscription purchased
   - subscription restored
   - subscription failed

## RevenueCat Checklist

RevenueCat app setup:

- Create Leko project in RevenueCat.
- Add iOS app and Android app.
- Create entitlement: `premium`.
- Create products:
  - `leko_premium_monthly` at $4.99/month.
  - `leko_premium_annual` at $39.99/year.
- Add both products to the default offering.
- Add public SDK keys to production build settings.

App Store Connect:

- Create matching auto-renewable subscription products.
- Add trial only after onboarding and paywall copy are stable.
- Add restore purchases path.
- Add subscription terms in App Store metadata.

Code behavior:

- `/premium` shows live RevenueCat offerings when configured.
- `/premium` falls back to placeholder pricing and a clear setup message when unconfigured.
- Premium entitlement id is `premium`.

## Paywall Copy Principles

Use:

- Clear feature list.
- Restore button.
- Store-managed payment note.
- Calm premium positioning.

Avoid:

- Fake urgency.
- Hidden prices.
- Ads in the finance experience.
- Claims that sound like professional financial advice.

## Release Dashboard Targets

Public beta:

- Crash-free sessions: 99%+.
- Onboarding completion: 35-50%.
- D1 retention: 30%+.
- At least one money event created by 40%+ of onboarded users.

Paid launch:

- Trial start: 3-7% of activated users.
- Trial-to-paid: 25-40%.
- Monthly paid churn: under 7%.
- Support response: under 24 hours.
