# Leko Release Readiness Audit

Last updated: 2026-06-16

## Current Status

Leko is in a stronger internal-beta state after this bug-squash pass. The core Flutter app now analyzes cleanly, the automated test suite passes, Android debug builds, and iOS simulator builds.

It is not App Store-ready yet. The remaining work is mostly production packaging, real provider connections, legal/privacy review, manual device QA, and App Store identity/sign-in hardening.

## Verification Results

- `flutter analyze`: passed, no issues found.
- `flutter test`: passed, 237 tests.
- `flutter test test/features/app_flow_smoke_test.dart`: passed.
- `flutter build apk --debug --dart-define=SUPABASE_URL=https://placeholder.supabase.co --dart-define=SUPABASE_ANON_KEY=placeholder`: passed.
- `flutter build ios --simulator --debug --dart-define=SUPABASE_URL=https://placeholder.supabase.co --dart-define=SUPABASE_ANON_KEY=placeholder`: passed.
- `flutter build web --release ...`: failed because the current database path imports native Drift/sqlite `dart:ffi`, which is unavailable on web.

I also launched the iOS simulator build successfully during the flow audit. Manual tapping automation was limited by local tooling: Maestro, `idb`, `ios-deploy`, and `cliclick` were not installed, and macOS denied assistive-control scripting through `osascript`. Widget smoke tests now cover the main navigable surfaces.

## Issues Fixed In This Pass

- Raised iOS deployment target to 15.5 so the ML Kit OCR dependency can compile on iOS.
- Added simulator architecture handling for the local iOS build path.
- Fixed guest/offline provider construction so signed-out app screens do not read `Supabase.instance.client` before Supabase is initialized.
- Fixed Add Income direct-route save crashes by falling back to `/home` when there is no back stack.
- Fixed Add Expense direct-route close/save exits the same way.
- Fixed Add Expense spending-label chip overflow on phone-width screens.
- Fixed Nightly Closeout streak headline overflow.
- Added production-flow widget smoke tests for Home quick actions, primary tabs, utility screens, Add Expense validation, and Add Income ledger writes.
- Preserved mobile app group setup while guarding `HomeWidget.setAppGroupId` to mobile platforms.
- Added macOS initialization support for local notification settings.
- Added a canonical `FinanceSummaryService` foundation for balance, cycle totals, daily allowance, safe-to-spend, and explainable inputs.
- Added privacy-first Sentry observability wiring behind `SENTRY_DSN`.
- Added a RevenueCat subscription/paywall scaffold behind public SDK dart-defines.
- Added GitHub Actions mobile CI for analyze, tests, and Android debug build.
- Added production growth, analytics, and monetization setup docs.

## Flow Coverage

- Welcome/auth shell: responsive test exists for compact phones.
- Home: smoke-tested with empty production state and quick actions to Expense, Income, and Goal.
- Add Expense: smoke-tested for required amount and category before saving.
- Add Income: smoke-tested for valid one-time income write to the ledger.
- Goals: route and Add Goal sheet smoke-tested.
- Leaf: route smoke-tested and assistant response tests pass.
- Reports, Settings, Bills, Transactions, Categories, Recurring Income, Imports, Household, Splits, Closeout, Recovery: route smoke-tested with empty production state.

## Product/Integration Status

- Bank connection: backend/provider boundary exists, but no real trusted aggregator flow is connected in production yet.
- Notification-based expense detection: provider-backed placeholder exists; real platform permissions/imports still need implementation and device QA.
- OCR: ML Kit OCR wiring exists for image receipts, but PDF parsing and production-grade extraction still need provider hardening.
- Voice input: Leaf voice provider and typed-flow routing exist, but platform speech permission and device behavior need production QA.
- Local badges: foundation exists and Home surfaces local activity badges.
- Household mode: staged as a later shared-budgeting surface, not a complete shared ledger.
- Savings chart: goal progress visualization exists; explicit contribution-history backing should be added next.
- Dynamic reports: report checks exist for drift/anomaly/forecast concepts, but need more real-world calibration.

## Release Blockers

- App identity still needs final production review: bundle identifiers, display name, icons, launch assets, screenshots, and App Store metadata must say Leko consistently.
- Real Supabase production configuration must be supplied through environment/CI/App Store build settings, not source-controlled scripts.
- Sign in with Apple must be real if the app offers Apple sign-in in production. A button that only routes to email sign-up would be an App Review and trust issue.
- Privacy policy and terms need legal review and must cover financial data, attachments, OCR, notifications, bank aggregation, voice input, retention, deletion, and user consent.
- Data export/delete account flows should be verified before launch.
- Real iPhone and iPad device QA is still required for onboarding, auth, notifications, OCR, speech, deep links, and offline/poor-network behavior.
- The web target is not release-ready until the Drift database layer is split to a web-compatible implementation.
- Sentry, RevenueCat, App Store Connect, and provider keys must be configured outside source control before public beta.

## Next Changes

1. Finish production auth and app identity.
   - Confirm App Store bundle id and app name.
   - Implement or remove any non-functional Apple sign-in UI.
   - Add production Supabase config through secure build settings.

2. Finish manual device QA.
   - Test onboarding from fresh install.
   - Test Add Expense, Add Income, Add Goal, Bills, Leaf attachment, Leaf voice, and import review on a real iPhone.
   - Test notification permission and scheduled reminders.

3. Harden integrations.
   - Connect a trusted bank aggregator backend.
   - Keep all imported drafts in transaction review before ledger import.
   - Add real notification permission/import handling on supported platforms.
   - Finish OCR/PDF extraction for amount, merchant, date, tax, and category suggestion.

4. Tighten finance correctness.
   - Add more regression tests for recurring bill auto-posting, payday posting, duplicate prevention, and currency display.
   - Move remaining money displays to setting-aware currency formatting.
   - Add seeded empty-state QA without fake/demo financial transactions.

5. Prepare App Store release.
   - Add crash/error reporting.
   - Finalize privacy nutrition labels.
   - Produce App Store screenshots from production-like empty and real-user-entered flows.
   - Run TestFlight with a clean production backend.
   - Configure RevenueCat products and the `premium` entitlement.
   - Track activation, retention, import review, and subscription funnels without sending personal financial details.
