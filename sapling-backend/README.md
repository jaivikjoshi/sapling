# Sapling Leaf Backend

Cloudflare Worker backend for Leaf. It exposes the two routes the Flutter app already expects:

- `POST /assistant/message`
- `POST /assistant/respond`
- `GET /bank/status`
- `POST /bank/connect`
- `GET /bank/transactions/drafts`
- `GET /bank/transactions/preview`
- `POST /bank/transactions/review`
- `POST /bank/transactions/import`
- `POST /bank/accounts/select`
- `DELETE /bank/connection`
- `GET /bank/callback`
- `POST /bank/webhook`

## What it does

- Keeps the Gemini API key off-device
- Turns Leaf chat messages into `LeafAssistantEnvelope` JSON
- Writes short post-action follow-up messages after local execution succeeds or fails
- Starts a Canada-first Flinks bank connection flow behind the existing review-first import contract
- Normalizes Flinks account-detail transactions into mobile `ImportedTransactionDraft` objects
- Validates Supabase user sessions on every user-facing bank request
- Encrypts each stored Flinks `loginId` with AES-256-GCM
- Persists connection metadata, account selection, drafts, review decisions, and import audit records in Supabase
- Uses single-use callback state, authenticated webhooks, and provider-side deletion

## Local setup

Use Node.js 22 or newer; current Wrangler releases require it.

For a web client, configure `CORS_ALLOWED_ORIGINS` to a comma-separated list
of exact trusted origins. The Worker does not send permissive CORS headers by
default; native iOS and Android calls do not require CORS.

1. Copy `.dev.vars.example` to `.dev.vars`.
2. Add your Gemini API key:

```bash
cp .dev.vars.example .dev.vars
```

3. Edit `.dev.vars`:

```bash
GEMINI_API_KEY="your-real-key"
GEMINI_MODEL="gemini-2.5-flash"
LEAF_DEV_MODE="live"
```

For local smoke tests without calling Gemini, set:

```bash
LEAF_DEV_MODE="mock"
```

For local bank smoke tests without Flinks credentials, set:

```bash
BANK_DEV_MODE="mock"
BANK_PROVIDER="flinks"
```

## Run locally

```bash
npm install
npm run dev
```

Wrangler will print a local URL such as `http://127.0.0.1:8787`.

## Test

```bash
npm test
npm run typecheck
```

## Curl examples

```bash
curl -X POST http://127.0.0.1:8787/assistant/message \
  -H "Content-Type: application/json" \
  -d '{
    "message": "How much can I spend today?",
    "context": {
      "greeting_name": "Jaivik",
      "allowance_mode": "paycheck",
      "balance": 1000,
      "daily_allowance": 88.24,
      "remaining_today": 42.12,
      "today_spend": 46.12,
      "primary_goal_name": "Vacation",
      "next_bill_name": "Internet/Phone"
    }
  }'
```

Bank mock preview:

```bash
curl http://127.0.0.1:8787/bank/transactions/preview
```

Flinks connection intent:

```bash
curl -X POST http://127.0.0.1:8787/bank/connect
```

```bash
curl -X POST http://127.0.0.1:8787/assistant/respond \
  -H "Content-Type: application/json" \
  -d '{
    "action": {
      "intent": "add_expense",
      "confidence": 0.91,
      "requires_confirmation": true,
      "is_read_only": false,
      "missing_fields": [],
      "reason": "User wants to log an expense.",
      "data": {
        "amount": 25,
        "category_name": "Dining Out"
      }
    },
    "success": true,
    "result": {
      "amount": 25,
      "category_name": "Dining Out"
    },
    "context": {
      "greeting_name": "Jaivik",
      "allowance_mode": "paycheck"
    }
  }'
```

## Flutter connection

Point the app to the Worker base URL through `LEAF_API_BASE_URL`.

Example:

```bash
LEAF_API_BASE_URL="http://127.0.0.1:8787" ./run_dev.sh -d "iPhone 16"
```

Or put it into `sapling/run_dev.sh` with:

```bash
INLINE_LEAF_API_BASE_URL="http://127.0.0.1:8787"
```

Point bank imports at the same Worker through `LEKO_BANK_API_BASE_URL`:

```bash
flutter run \
  --dart-define=LEAF_API_BASE_URL=http://127.0.0.1:8787 \
  --dart-define=LEKO_BANK_API_BASE_URL=http://127.0.0.1:8787 \
  --dart-define=LEKO_BANK_REGION=CA
```

## Production bank architecture

The mobile app sends its Supabase access token in `Authorization: Bearer <jwt>`.
The Worker validates that session with Supabase Auth and uses a Worker-only
Supabase secret key for the private bank tables. `anon` and `authenticated`
roles have no direct table grants.

Apply the migration before enabling live mode:

```bash
supabase db push
```

The migration is in `../supabase/migrations/` and creates:

- `bank_connections`
- `bank_connection_sessions`
- `bank_accounts`
- `bank_transaction_imports`

## Flinks configuration

The bank routes default to Flinks. Use `BANK_DEV_MODE="mock"` until sandbox credentials are ready.

Live/sandbox variables:

```bash
BANK_PROVIDER="flinks"
SUPABASE_URL="https://<project-ref>.supabase.co"
SUPABASE_PUBLISHABLE_KEY="sb_publishable_..."
FLINKS_API_BASE_URL="https://<instance>-api.private.fin.ag"
FLINKS_CONNECT_URL="https://<instance>-iframe.private.fin.ag/v2/"
FLINKS_CUSTOMER_ID="..."
FLINKS_SANDBOX="false"
FLINKS_REDIRECT_URL="https://your-worker/bank/callback"
FLINKS_APP_RETURN_URL="com.jaivik.leko://bank-callback"
```

Store these values as Worker secrets, never plain `vars`:

```bash
wrangler secret put SUPABASE_SECRET_KEY
wrangler secret put BANK_TOKEN_ENCRYPTION_KEY
wrangler secret put FLINKS_SECRET_KEY
wrangler secret put FLINKS_X_API_KEY
wrangler secret put FLINKS_WEBHOOK_HMAC_SECRET
```

Generate the encryption key once with `openssl rand -base64 32`. Rotating it
requires decrypting and re-encrypting existing connection records first.

Flinks must whitelist the production `FLINKS_REDIRECT_URL`. Webhooks require a
Flinks support ticket and cannot be tested in their sandbox. Until those are
approved, keep `BANK_DEV_MODE="mock"` or use the Flinks toolbox sandbox.

## Deploy

Set Worker secrets:

```bash
npx wrangler secret put GEMINI_API_KEY
npx wrangler secret put SUPABASE_SECRET_KEY
npx wrangler secret put BANK_TOKEN_ENCRYPTION_KEY
npx wrangler secret put FLINKS_SECRET_KEY
npx wrangler secret put FLINKS_X_API_KEY
npx wrangler secret put FLINKS_WEBHOOK_HMAC_SECRET
```

Then deploy:

```bash
npm run deploy
```
