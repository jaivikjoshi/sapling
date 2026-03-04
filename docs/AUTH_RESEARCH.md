# Auth Research for Sapling

## Current state

- **No auth today**: Splash checks `onboardingCompleted` and goes to `/home` or `/onboarding`. All data is local (Drift SQLite).
- **No backend**: No Firebase, Supabase, or custom server. Single device, no sync.

So “auth” for Sapling means **who can open this app on this device**, not “who is this user in the cloud.”

---

## Two directions

| Goal | What you need | When to choose |
|------|----------------|----------------|
| **Lock the app on this device** | PIN and/or biometric (Face ID / fingerprint) | You want to prevent others from opening the app. Fits current local-only setup. |
| **Accounts + sync / multi-device** | Backend (e.g. Firebase Auth, Supabase) + optional biometric on top | You plan to add cloud sync or “log in on another phone.” |

For Sapling as it is now (local-only), **device lock (PIN + biometric)** is the right fit. You can add account-based auth later if you add a backend.

---

## Recommended: local app lock (PIN + biometric)

### Idea

- User sets a **PIN** (and optionally enables **biometric**) in Settings.
- After that, opening the app (or returning from background) shows a **lock screen**.
- Unlock by: **biometric** (if enabled and available) or **PIN**.
- No server, no accounts; everything stays on the device.

### Packages

| Package | Role |
|--------|------|
| **local_auth** | Show system biometric (Face ID / fingerprint) and/or device PIN/passcode. `authenticate(localizedReason: 'Unlock Sapling')`. |
| **flutter_secure_storage** | Store a **hash of the PIN** (and a flag “lock enabled”) in Keychain/KeyStore. Never store the raw PIN. |

### Security

- **PIN**: Store only a hash (e.g. SHA-256) in secure storage. On unlock, hash the entered PIN and compare. Use a salt if you want (e.g. device-specific).
- **Biometric**: Used only to “release” the fact that the user is allowed in; you can store a short secret in secure storage and only read it after biometric success, then treat that as “unlocked” for this session.
- **Drift DB**: Stays as-is; optional extra step later is to encrypt the DB file with a key derived from PIN (more work, usually not required for “someone else can’t open the app” goal).

### Flow (high level)

1. **First launch / no lock set**  
   - Same as now: Splash → onboarding or home.  
   - In Settings: “App lock” → set PIN, toggle “Use Face ID / fingerprint.”

2. **Lock set**  
   - Splash (or a dedicated “lock screen” route) checks secure storage:
     - If “lock enabled” and no “unlocked this session” → show **lock screen** (PIN entry + “Use biometric” button).
     - On success (PIN match or biometric + stored secret) → set “unlocked this session” and go to onboarding or home.

3. **Return from background**  
   - Optional: after N minutes in background, require unlock again (clear “unlocked this session” or check timestamp).

4. **Settings**  
   - “Change PIN”, “Turn off app lock” (verify with current PIN or biometric).

### Where it fits your app

- **Splash**  
  - After reading `onboardingCompleted`, if app lock is enabled and not unlocked this session → `context.go('/lock')` and show PIN/biometric screen.  
  - On unlock → continue to `/home` or `/onboarding`.

- **Router**  
  - Add route `/lock` that shows the lock screen.  
  - Lock screen reads from Riverpod (e.g. `authStateProvider`: locked / unlocked) and calls `local_auth` + PIN check.

- **Settings**  
  - New section “Security” or “App lock”: “Enable app lock”, “Change PIN”, “Use biometric”.  
  - Writes “lock enabled” and PIN hash into `flutter_secure_storage`; biometric preference can be a simple flag there too.

### Minimal code shape

- **Auth service** (e.g. `lib/domain/auth/local_auth_service.dart`):
  - `isLockEnabled()` → read from secure storage.
  - `setPin(String pin)` → hash PIN, write hash + “lock enabled” to secure storage.
  - `validatePin(String pin)` → hash input, compare with stored hash.
  - `authenticateWithBiometric()` → call `local_auth.authenticate(...)`; if success, treat as unlocked.
  - `unlockedThisSession` → in-memory or short-lived secure value; clear on app background after timeout if you want.

- **Lock screen** (`lib/features/auth/lock_screen.dart`):
  - PIN pad or text field + “Use Face ID / fingerprint” button.
  - On success → set unlocked, `context.go('/home')` or wherever Splash would have gone.

- **Splash**  
  - If lock enabled and not unlocked → go to `/lock` (and pass “intended” route if you want).  
  - Else → current logic (onboarding vs home).

---

## If you add accounts later (e.g. sync)

Then you add a **second layer**:

- **Account auth** (Firebase Auth, Supabase Auth, or custom): sign in with email/password or OAuth; get a token; use it for API/sync.
- **App lock** can stay as-is: first unlock the device app (PIN/biometric), then the app can use the stored token to sync. Optionally “re-auth” with backend after long idle.

So: implement **local app lock** now; keep **account auth** in mind only when you introduce a backend.

---

## Summary

| Question | Answer |
|----------|--------|
| What should Sapling use **right now**? | **Local app lock**: PIN (stored as hash in `flutter_secure_storage`) + optional biometric (`local_auth`). |
| Where does it hook in? | Splash checks lock; if locked → `/lock` screen; after unlock → existing flow. Settings to enable/disable lock and set/change PIN. |
| Which packages? | `local_auth`, `flutter_secure_storage`. |
| Do we need Firebase/backend? | No, for “lock the app on this device” only. Yes, only when you add accounts/sync. |

If you want, next step can be a concrete task list (e.g. “add packages → AuthService → lock screen → Splash + Settings”) and small code snippets for PIN hash and `local_auth.authenticate`.
