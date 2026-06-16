# Sapling Leaf Backend

Cloudflare Worker backend for Leaf. It exposes the two routes the Flutter app already expects:

- `POST /assistant/message`
- `POST /assistant/respond`

## What it does

- Keeps the Gemini API key off-device
- Turns Leaf chat messages into `LeafAssistantEnvelope` JSON
- Writes short post-action follow-up messages after local execution succeeds or fails

## Local setup

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

## Deploy

Set Worker secrets:

```bash
npx wrangler secret put GEMINI_API_KEY
```

Then deploy:

```bash
npm run deploy
```
