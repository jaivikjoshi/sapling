#!/usr/bin/env bash
# Copy to run_dev.sh and fill INLINE_* (run_dev.sh is gitignored when it contains secrets).
# After restoring a paused project: https://supabase.com/dashboard → Project → Settings → API
# Or export SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY in your shell instead.
# If you run the Leaf backend locally, point INLINE_LEAF_API_BASE_URL at the Worker base URL
# (for example http://127.0.0.1:8787 on the iPhone simulator).
set -euo pipefail
cd "$(dirname "$0")"

INLINE_URL=""
INLINE_KEY=""
INLINE_LEAF_API_BASE_URL=""
INLINE_BANK_API_BASE_URL=""
SUPABASE_URL="${SUPABASE_URL:-$INLINE_URL}"
SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-${SUPABASE_ANON_KEY:-$INLINE_KEY}}"
LEAF_API_BASE_URL="${LEAF_API_BASE_URL:-$INLINE_LEAF_API_BASE_URL}"
LEKO_BANK_API_BASE_URL="${LEKO_BANK_API_BASE_URL:-$INLINE_BANK_API_BASE_URL}"

if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_PUBLISHABLE_KEY" ]]; then
  echo "Set INLINE_URL and INLINE_KEY in run_dev.sh (from Dashboard → Settings → API), or export"
  echo "SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY. Restore the project first if it was paused."
  exit 1
fi

flutter_args=(
  --dart-define=SUPABASE_URL="$SUPABASE_URL"
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
)

if [[ -n "$LEAF_API_BASE_URL" ]]; then
  flutter_args+=(--dart-define=LEAF_API_BASE_URL="$LEAF_API_BASE_URL")
fi

if [[ -n "$LEKO_BANK_API_BASE_URL" ]]; then
  flutter_args+=(--dart-define=LEKO_BANK_API_BASE_URL="$LEKO_BANK_API_BASE_URL")
  flutter_args+=(--dart-define=LEKO_BANK_REGION="CA")
fi

exec flutter run "${flutter_args[@]}" "$@"
