# Bank Integration Plan

Last reviewed: 2026-07-17

## Implementation Status

The production architecture in this plan is now implemented in code: Supabase
session authentication, private per-user persistence, encrypted Flinks login
identifiers, the documented authorize/request/poll sequence, durable drafts,
account selection, review auditing, deep-link return handling, HMAC webhooks,
and provider-side disconnect/delete. The remaining gates require external
production configuration and approval: applying the Supabase migration, Flinks
production credentials/redirect whitelisting/webhook enablement, physical-device
TestFlight QA, and legal/App Store privacy review. See `BANK_LAUNCH_RUNBOOK.md`.

## Goal

Add opt-in bank connectivity without changing Leko's core safety model: imported bank transactions become review drafts first, and the user approves them before they touch the ledger.

## Current Starting Point

The app already has the right boundary:

- `TransactionImporter` and `BankProvider` define bank preview/import contracts.
- `HttpBankProvider` calls `/bank/connect`, `/bank/status`, `/bank/transactions/preview`, and `/bank/transactions/import`.
- `TransactionReviewController` dedupes drafts, lets users approve/reject them, and imports approved drafts through `LedgerService`.
- `ImportReviewScreen` already exposes bank preview, notification scan, draft approval, and import approved.

Backend progress started:

- The Cloudflare Worker now exposes `/bank/status`, `/bank/connect`, `/bank/transactions/preview`, `/bank/transactions/import`, and `/bank/callback`.
- `/bank/connect` returns a Flinks Connect intent and authorization URL.
- `/bank/transactions/preview` supports `BANK_DEV_MODE=mock` and a live Flinks `/GetAccountsDetail` preview path when `FLINKS_LOGIN_ID` is configured.
- Flinks account-detail transactions are normalized into `ImportedTransactionDraft` objects.
- The mobile Import Review consent action now opens the returned provider authorization URL.

This means the missing work is mostly production integration, backend persistence, sync, mobile auth return handling, and compliance-grade consent.

## Provider Recommendation

Start with Flinks for a Canada-first MVP, with the backend adapter shaped so Plaid, MX, or Teller can be added later.

Why:

- Flinks is Canada-native and positions Connect/Banking API around Canadian bank connectivity, transactions, balances, account details, and bank statements.
- Flinks says it works directly with banks in Canada to build custom API integrations, which should help reliability for Canadian institutions.
- Leko's current provider abstraction already expects a trusted aggregator and does not require raw credential handling in the app.
- Plaid remains the best US expansion candidate and can also be evaluated as a Canada fallback because it publishes a US/Canada coverage explorer and supports Canadian institutions.

Provider notes from current docs:

- Flinks Connect is intended for user bank linking and can access account details, balances, transactions, and bank statements through the Flinks API.
- Flinks emphasizes Canadian coverage and direct/custom API integrations with Canadian banks.
- Plaid Transactions is intended for user-authorized transaction history across depository and credit accounts, with API docs for Transactions endpoints and webhooks.
- Plaid Link uses backend-created Link tokens; the frontend completes Link and returns a public token that the backend exchanges for an access token.
- Flinks Connect is positioned for safely connecting customer bank accounts and accessing financial data.
- Teller exposes account transaction endpoints with pagination.
- MX Platform API supports aggregation/enhancement across financial institutions and publishes versioned API changes.

## Architecture

### Mobile App

Keep the mobile app as a thin client:

- Request connection intent from `POST /bank/connect`.
- Open aggregator auth UI or web URL.
- Receive app/deep-link callback.
- Trigger preview from `GET /bank/transactions/preview`.
- Show all transactions in `ImportReviewScreen`.
- Import only approved drafts.

Do not store aggregator access tokens, account ids beyond display metadata, or bank credentials on device.

### Backend

Add a bank integration service behind the existing HTTP contract:

- `POST /bank/connect`
  - Creates a provider link/connect token.
  - Returns provider id, display name, consent copy, and authorization URL or mobile link payload.

- `POST /bank/callback`
  - Exchanges public/temporary token for provider access token.
  - Stores encrypted access token server-side.
  - Stores connection metadata only: provider item id, institution name, account display names/last4, selected account ids, sync cursor, status.

- `GET /bank/status`
  - Returns `disconnected`, `connecting`, `connected`, `needsReauth`, or `unavailable`.

- `GET /bank/transactions/preview`
  - Fetches latest provider transactions.
  - Normalizes to `ImportedTransactionDraft`.
  - Excludes already imported provider transaction ids.
  - Returns pending review drafts.

- `POST /bank/transactions/import`
  - Optional backend audit endpoint.
  - For the current app, ledger writes happen locally after approval; if cloud sync becomes canonical, this endpoint can become the server-side importer.

- `POST /bank/webhook`
  - Receives provider transaction update events.
  - Marks a connection as having new transactions.
  - Does not auto-write ledger entries.

### Data Model

Add server-side tables, preferably Supabase with RLS/service-role access split:

- `bank_connections`
  - `id`
  - `user_id`
  - `provider`
  - `provider_item_id`
  - `institution_name`
  - `status`
  - `encrypted_access_token`
  - `sync_cursor`
  - `last_sync_at`
  - `created_at`
  - `updated_at`

- `bank_accounts`
  - `id`
  - `connection_id`
  - `provider_account_id`
  - `name`
  - `mask`
  - `type`
  - `subtype`
  - `is_selected`

- `bank_transaction_imports`
  - `id`
  - `user_id`
  - `provider_transaction_id`
  - `provider_account_id`
  - `dedupe_key`
  - `ledger_transaction_id`
  - `review_status`
  - `raw_hash`
  - `imported_at`

Do not expose `encrypted_access_token` through client-readable RLS policies.

## Normalization Rules

Map provider transaction payloads into `ImportedTransactionDraft`:

- `sourceId`: provider transaction id.
- `source`: `bankAggregator`.
- `amount`: positive user-facing amount.
- `type`: `expense` for outflow, `income` for inflow.
- `date`: posted date, falling back to authorized date only if posted date is absent.
- `merchant`: merchant/enriched name, falling back to raw description.
- `categorySuggestion`: provider category mapped into Leko category names where possible.
- `confidence`: higher for exact category/merchant matches, lower for uncategorized or pending transactions.
- `note`: include account display name and provider provenance.

Pending transactions should be previewable but clearly marked lower confidence. Final posted transactions should replace or dedupe against matching pending drafts.

## UX Flow

1. User opens Transaction Review.
2. Consent card explains: trusted aggregator, user permission, no raw bank credentials stored by Leko, imported drafts require approval.
3. User taps Connect bank.
4. Aggregator Link/Connect opens.
5. User returns to Leko.
6. Leko shows connected institution and selected accounts.
7. User taps Preview bank.
8. New transactions appear as drafts.
9. User approves/rejects each draft.
10. User taps Import approved.
11. Leaf can summarize: "3 new bank drafts need review" or "Imported 2, skipped 1 duplicate."

## Leaf Integration

Leaf should not silently import transactions. It should help review:

- "Any new bank transactions?" opens or triggers preview.
- "Review my bank drafts" summarizes pending drafts by merchant/category/date.
- "Why is this duplicate?" explains dedupe source.
- "Categorize these" suggests categories but still leaves approval to the user.
- "What changed since yesterday?" uses imported/reviewed drafts plus reports.

Future write intent:

- Add `preview_bank_transactions` as a read-only Leaf intent.
- Add `open_import_review` as a navigation/action suggestion if routing supports it.

## Security And Compliance Guardrails

- Never collect or store raw bank usernames/passwords.
- Keep aggregator access tokens only on the backend, encrypted.
- Use short-lived link/connect tokens.
- Require explicit user consent before connection.
- Make disconnection and data deletion available from Settings.
- Add privacy policy language for bank data, transaction history, account metadata, deletion, and third-party processors.
- Log sync events, not raw sensitive payloads.
- Treat bank data as sensitive in analytics; do not send merchant names, account masks, or transaction descriptions to analytics.

This needs legal review before production launch.

## Implementation Phases

### Phase 1: Contract Hardening

- Add typed backend API spec for the existing endpoints.
- Add `BankConnection` and `BankAccount` models.
- Extend `BankConnectionIntent` if needed for mobile Link metadata.
- Add UI states: disconnected, connecting, connected, needs reauth, unavailable.
- Add provider status display to `ImportReviewScreen`.
- Add tests for status handling and unavailable provider copy.

### Phase 2: Flinks Sandbox Backend

- Add backend environment variables for provider client id/secret/environment.
- Implement Flinks Connect session creation.
- Implement login/session completion exchange.
- Store encrypted access token and sync cursor.
- Implement transaction sync/preview.
- Implement webhook endpoint.
- Add sandbox tests with mocked Flinks responses.

### Phase 3: Mobile Connect Return Flow

- Wire deep link/app link callback from aggregator back into Leko.
- Show connected institution/account selection.
- Handle user cancellation, failed auth, and reauth-required states.
- Keep `LEKO_BANK_API_BASE_URL` as the mobile switch for live bank mode.

### Phase 4: Review Quality

- Improve category mapping from provider categories to Leko categories.
- Add duplicate detection using provider id, amount/date/merchant fallback, and existing import notes.
- Support pending-to-posted replacement.
- Add account selector/filter in Import Review.
- Add bulk approve for high-confidence drafts, but keep final import user-confirmed.

### Phase 5: Production Readiness

- Add consent and privacy copy.
- Add delete/disconnect flow.
- Add sync monitoring and alerting.
- Add rate limit handling and retry policy.
- Add App Store review notes for bank aggregation and data handling.
- Run sandbox QA, then limited real-bank beta.

### Phase 6: US / Provider Expansion

- Evaluate Plaid for US expansion and as a Canadian fallback where coverage is better for a specific institution.
- Keep a provider adapter interface on the backend so Plaid/Flinks/MX/Teller normalize into the same `ImportedTransactionDraft`.
- Add provider-specific category mapping tests.

## Canada Build Configuration

The mobile app now defaults live bank builds to Flinks for Canada when `LEKO_BANK_API_BASE_URL` is set.

Recommended Dart defines for a Canada sandbox build:

```sh
--dart-define=LEKO_BANK_API_BASE_URL=https://<your-bank-backend>
--dart-define=LEKO_BANK_REGION=CA
--dart-define=LEKO_BANK_PROVIDER_ID=flinks
--dart-define=LEKO_BANK_PROVIDER_NAME=Flinks Connect
```

`LEKO_BANK_CONSENT_COPY` can override the default Canada consent copy if legal/product wants exact wording.

## Acceptance Criteria

- User can connect a sandbox bank without Leko seeing raw credentials.
- Backend stores provider token securely and never sends it to the app.
- Preview returns normalized drafts.
- Drafts dedupe correctly across repeated previews.
- No bank transaction writes to ledger until approved.
- Imported transactions affect Home, Reports, Leaf coaching, and widgets like manual transactions.
- User can disconnect and request deletion.
- All bank paths have tests for success, cancellation, reauth, duplicate, empty result, provider outage, and malformed provider payload.

## Open Decisions

- Whether ledger import should remain local-first or move server-side once cloud sync is canonical.
- Whether to launch US-only first with Plaid or wait for US + Canada support.
- Whether bank sync is premium-only, trial-gated, or free with limits.
- Whether to import pending transactions or only posted transactions for MVP.
- Whether users can select individual accounts during onboarding or only after initial connection.
