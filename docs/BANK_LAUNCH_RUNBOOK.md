# Leko Bank Connection Launch Runbook

Last updated: 2026-07-17

## Release Gate

Do not enable `LEKO_BANK_API_BASE_URL` in the App Store build until every item
in the Production Checklist is complete. Builds without that Dart define keep
the bank UI in an unavailable state and do not expose an incomplete live flow.

## Implemented Safety Model

- A signed-in Supabase user is required for every user-facing bank endpoint.
- Flinks Connect owns bank credential entry and MFA. Leko never receives the
  user's bank username or password.
- Flinks `loginId` values are encrypted with AES-256-GCM before storage.
- Connection callbacks use 256-bit, single-use state that expires after 15 minutes.
- Account identity and KYC fields are explicitly disabled in account-detail calls.
- Posted and pending transactions are normalized into a durable review queue.
- Pending transactions cannot be approved until Flinks reports them as posted.
- Ledger writes happen only after explicit approval. Import IDs make retries
  idempotent, and the backend records the resulting ledger transaction ID.
- Disconnect calls Flinks `/DeleteCard` before deleting Leko's bank connection,
  account metadata, and unimported review records.
- Webhook payloads require a valid Flinks HMAC-SHA256 signature.
- Bank tables have RLS enabled and no `anon` or `authenticated` grants. They are
  accessed only through the authenticated Worker using a server secret.

## Production Checklist

### 1. Supabase

- Create a dedicated `sb_secret_...` key for the bank Worker and store it only
  as a Cloudflare Worker secret.
- Confirm the mobile build uses a current `sb_publishable_...` key through
  `SUPABASE_PUBLISHABLE_KEY`. The legacy `SUPABASE_ANON_KEY` define remains a
  temporary fallback for existing development scripts.
- Link the Supabase CLI to the production project and review the target:

  ```bash
  supabase link --project-ref <production-ref>
  supabase migration list
  supabase db push --dry-run
  supabase db push
  supabase db advisors
  ```

- Verify `anon` and `authenticated` cannot select any `bank_*` table and that
  the Worker secret can read/write them.
- Confirm production backups, point-in-time recovery, region, and retention
  settings satisfy the privacy policy and business requirements.

### 2. Flinks

- Obtain production instance URL, customer ID, secret key, x-api-key, and HMAC
  webhook secret from Flinks.
- Ask Flinks to whitelist exactly:

  `https://<production-worker-host>/bank/callback`

- Ask Flinks Support to configure:

  `https://<production-worker-host>/bank/webhook`

- Confirm account selection is enabled for the private Connect instance.
- Confirm `/DeleteCard` is enabled and test deletion with a consenting beta user.
- Confirm the contracted transaction-history window and supported institutions.

### 3. Cloudflare Worker

- Configure non-secret variables:

  - `BANK_DEV_MODE=live`
  - `BANK_PROVIDER=flinks`
  - `SUPABASE_URL`
  - `SUPABASE_PUBLISHABLE_KEY`
  - `FLINKS_API_BASE_URL`
  - `FLINKS_CONNECT_URL`
  - `FLINKS_CUSTOMER_ID`
  - `FLINKS_REDIRECT_URL`
  - `FLINKS_APP_RETURN_URL=com.jaivik.leko://bank-callback`
  - `FLINKS_SANDBOX=false`
  - `CORS_ALLOWED_ORIGINS` only if a browser client is supported; use exact
    trusted HTTPS origins and never `*`. Native mobile traffic does not need it.

- Configure secrets with `wrangler secret put`:

  - `SUPABASE_SECRET_KEY`
  - `BANK_TOKEN_ENCRYPTION_KEY` (generate once with `openssl rand -base64 32`)
  - `FLINKS_SECRET_KEY`
  - `FLINKS_X_API_KEY`
  - `FLINKS_WEBHOOK_HMAC_SECRET`

- Deploy, then verify `/health`. Do not log any secret values during setup.
- Configure alerts for Worker 5xx rates and repeated `bank_reauth_required`,
  `bank_storage_unavailable`, and provider timeout errors. Logs must remain
  metadata-only.

### 4. Mobile/App Store build

- Build with production Supabase configuration and:

  ```bash
  --dart-define=LEKO_BANK_API_BASE_URL=https://<production-worker-host>
  --dart-define=LEKO_BANK_REGION=CA
  --dart-define=LEKO_BANK_PROVIDER_ID=flinks
  --dart-define=LEKO_BANK_PROVIDER_NAME="Flinks Connect"
  ```

- Verify the `com.jaivik.leko://bank-callback` deep link on a physical iPhone
  from both foreground and terminated states.
- Confirm the final App Store bundle ID matches the registered URL scheme.
- Never place the Supabase secret key, Flinks secret, x-api-key, webhook secret,
  or bank encryption key in Dart defines, Xcode build settings, or the app bundle.

### 5. Legal and App Store privacy

Legal counsel must review the final privacy policy and terms. At minimum, cover:

- transaction history, balances, institution/account metadata, and review decisions;
- Flinks and Supabase as service providers/subprocessors;
- the purposes of budgeting, transaction review, categorization, and support;
- retention, disconnect, account deletion, export, incident response, and support;
- the fact that Leko is budgeting software and not a bank or financial adviser.

In App Store Connect, review whether Financial Info and User ID are collected,
linked to the user, and used for App Functionality. Declare that this data is
not used for tracking unless the production implementation changes. Do not
guess the final privacy labels—reconcile them against the deployed data flows
and legal advice immediately before submission.

Suggested App Review note:

> Bank connection is optional. The user explicitly opens Flinks Connect, where
> Flinks handles financial-institution credentials and MFA. Leko receives bank
> account and transaction data only after consent. Transactions remain drafts
> and do not affect the budget until individually approved. The user can
> disconnect and request deletion from the Transaction Review screen.

## TestFlight Matrix

Test on at least one current iPhone and one minimum-supported iPhone/iOS version:

- fresh connect, user cancellation, expired Connect token, and invalid callback state;
- foreground, background, and terminated-app callback handling;
- single account, multiple accounts, deselect/reselect, and unsupported account type;
- posted expense, posted income, pending transaction, pending-to-posted replacement;
- repeat sync, repeat approval, repeat import, and duplicate provider transaction ID;
- 202 processing response, Flinks outage, Supabase outage, slow network, and offline return;
- reauthentication-required flow;
- disconnect and provider deletion, followed by reconnect;
- sign-out/sign-in isolation between two test users;
- accessibility text sizes, VoiceOver labels, compact screen layout, and darkened colors;
- confirmation that Home, Reports, Leaf, widgets, and allowance calculations update
  exactly as they do for manually entered transactions.

## Launch and Rollback

- Start with an allowlisted TestFlight cohort and monitor for at least seven days.
- Roll out gradually only after import duplicate rate, sync failure rate, callback
  completion, reauth rate, and deletion success are understood.
- To disable the feature without an App Store release, configure the Worker to
  return `unavailable` or remove `LEKO_BANK_API_BASE_URL` from the next build.
- Never delete encrypted connection rows as a rollback shortcut. Use the normal
  disconnect path so provider-side data is deleted first.

## Evidence Required Before Public Launch

- Passing Flutter analysis/tests and backend typecheck/tests.
- Successful production Supabase migration and Security Advisor review.
- Successful Flinks production connect, sync, reauth, and `/DeleteCard` evidence.
- Physical-device deep-link and poor-network QA sign-off.
- Legal approval of privacy policy, terms, consent copy, and App Store labels.
- Support playbook and monitored production alerts.
