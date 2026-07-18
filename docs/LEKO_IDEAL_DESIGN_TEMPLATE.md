# Leko Ideal Design Template

Last updated: 2026-06-17

## Design North Star

Leko should feel like a calm daily money companion.

The core promise:

> Know what is safe to spend today, understand why, and turn messy money inputs into reviewed actions.

Every screen should support one of these jobs:

- Decide what is safe to spend.
- Review what changed.
- Add or confirm a money event.
- Protect a goal.
- Understand a pattern.
- Ask Leaf for help.

## Product Position

Leko should not copy one competitor directly.

- From Wealthsimple: calm confidence, minimal charts, simple goal progress.
- From YNAB: a clear budgeting philosophy and explainable math.
- From Monarch: full money picture, household-ready structure, strong categories.
- From Rocket Money: proactive drift detection, subscriptions, bill variance.
- From Cleo: AI-first interaction, but with a calmer and more trusted tone.
- From award-winning apps: fewer words, stronger motion, clearer moments of delight, excellent accessibility.

Leko's lane:

> A premium AI-first daily finance app that shows what is safe to spend, catches drift early, and routes every imported or AI-created transaction through user review.

## Visual System

### Personality

Use these traits as the design filter:

- Calm, not sleepy.
- Premium, not flashy.
- Helpful, not chatty.
- Trustworthy, not clinical.
- Warm, not cute.

### Color Roles

Use the existing Leko palette as the base.

- Canvas: warm cream or cool light gray, never decorative gradients.
- Primary surface: white.
- Primary action: deep teal/navy.
- AI/Leaf accent: Leko logo mark and jade accent.
- Positive state: muted forest green.
- Warning state: earthy orange.
- Error/overspend: muted red.
- Money text: dark, readable, never low-contrast gray on white.

Avoid:

- Full-page gradients.
- Decorative orbs.
- Overuse of teal as the only color.
- White text on light cards.
- Too many tinted cards competing on the same screen.

### Typography

- Letter spacing should be `0`.
- Large money values should feel stable and readable.
- Use hero-scale type only for the primary financial number.
- Keep compact panels tight: smaller headings, short labels, no paragraph blocks.
- Prefer title case for short UI labels and sentence case for helper text.

### Shape And Spacing

- Cards: 18 to 28px radius depending on size.
- Buttons: 18 to 28px radius.
- Icon buttons: square or circle, stable 44 to 52px touch targets.
- Main screen horizontal padding: 20 to 24px.
- Card internal padding: 16 to 24px.
- Repeated list rows: 12 to 16px vertical rhythm.

## Core App Structure

### Global Navigation

The bottom nav should stay quiet and consistent:

- Home: today and action center.
- Goals: savings progress and goal decisions.
- Leaf: AI assistant with draft actions.
- Reports: trends, drift, forecasts.
- Settings: profile, integrations, privacy, household.

Rules:

- Use the Leko mark for the Leaf tab.
- No labels in the nav unless usability testing shows icon confusion.
- Selected state should be subtle, not loud.

## Ideal Home Template

Home should answer one question first:

> Can I spend money today?

### Layout

1. Greeting and date.
2. Safe-to-spend hero.
3. Review queue strip if anything needs attention.
4. Primary actions: Add Expense, Add Income, Add Goal.
5. Upcoming bills.
6. Goal pace.
7. Recent activity.
8. Tiny insight card.

### Safe-To-Spend Hero

Required content:

- Amount safe to spend today.
- Daily allowance baseline.
- One short status line.
- "Why?" affordance.

Example:

```text
Safe to spend today
$42.80
of $58.00
On pace after bills and goal savings.
```

The "Why?" view should show:

- Starting balance.
- Income counted.
- Bills reserved.
- Goal savings reserved.
- Today's spending.
- Remaining days in cycle.

### Review Queue Strip

Only show when useful.

Examples:

- `3 transactions need review`
- `Receipt ready to confirm`
- `Bank import waiting`
- `Phone bill looks higher than usual`

Actions:

- Review
- Dismiss
- Ask Leaf

## Ideal Leaf Template

Leaf should not feel like a generic chatbot.

Leaf should feel like:

> A finance assistant that creates drafts, explains numbers, and waits for confirmation before changing money records.

### Layout

1. Compact Leaf header with logo mark.
2. Small safe-to-spend card.
3. Horizontal prompt chips.
4. Conversation.
5. Composer with attach, voice, text, send.
6. Pending action bar when a draft exists.

### Leaf Response Types

Leaf should respond with structured UI when possible:

- Transaction draft card.
- Missing info choice card.
- Receipt extraction card.
- Budget recommendation card.
- Spending insight card.
- Forecast card.
- Confirmation card.

### Missing Info Pattern

Never ask vague open-ended questions when choices are known.

Missing category:

```text
What category should I use?
[Food] [Groceries] [Transportation] [Entertainment]
[Bills] [Shopping] [Health] [Other]
```

Missing date:

```text
When was this?
[Today] [Yesterday] [Custom date]
```

Missing recurrence:

```text
Should this repeat?
[One-time] [Weekly] [Biweekly] [Monthly]
```

### Draft Action Card

Every write action should show:

- Amount.
- Merchant/source.
- Category.
- Date.
- Account.
- Attachment if present.
- Confidence or source.
- Confirm and Edit actions.

Example:

```text
Expense draft
$12.50 at Freshii
Food | Today | Chequing
Source: receipt scan

[Confirm] [Edit]
```

## Ideal Onboarding Template

Onboarding should feel short, polished, and production-grade.

### Goals

- Get enough data to make Home useful.
- Avoid fake personalization.
- Avoid asking for data Leko does not immediately use.
- Explain privacy at the exact point it matters.

### Flow

1. Name and display name.
2. Currency.
3. Current chequing balance.
4. Income setup.
5. Bills.
6. First goal.
7. Review and open Leko.

### Rules

- One primary question per step.
- One sentence of helper text maximum.
- No dark input fields unless the whole screen is dark.
- Allow multiple bills before continuing.
- `Open Leko` must navigate once, reliably.
- Do not show goals twice.

## Ideal Goals Template

Goals should feel like named money buckets, not task cards.

### Layout

1. Total saved toward active goals.
2. Primary goal feature card.
3. Savings growth chart.
4. Goal list.
5. Contribution history.

### Goal Card Content

- Category icon or Leko mark fallback.
- Goal name.
- Saved amount.
- Target amount.
- Progress.
- Required weekly contribution.
- Status: on track, ahead, behind.

### Chart Rules

- Smooth line.
- Minimal axes.
- Clear current point.
- Annotate meaningful events: contribution, missed week, target date change.

## Ideal Reports Template

Reports should explain drift, not just display totals.

### Top Cards

- Month forecast.
- Spending pace.
- Income trend.
- Bills variance.

### Dynamic Reports

Required future report modules:

- Subscription drift.
- Bill variance.
- Category anomalies.
- Weekly forecast.
- Monthly forecast.
- Income volatility.

Each report should have:

- What changed.
- Why it matters.
- Suggested next action.
- Ask Leaf action.

## Ideal Import Review Template

All automated or AI-created records should enter a review queue.

Sources:

- Bank aggregator.
- Bank notification.
- Receipt OCR.
- PDF invoice.
- Voice input.
- Leaf text conversation.

### Review Item

Each item should show:

- Source.
- Amount.
- Merchant.
- Date.
- Category suggestion.
- Duplicate warning if any.
- Attachment preview when present.
- Confidence.

Actions:

- Confirm.
- Edit.
- Merge duplicate.
- Ignore.

## Ideal Settings Template

Settings should build trust.

Top sections:

- Profile and currency.
- Accounts and integrations.
- Privacy and permissions.
- Notifications.
- Household.
- Data export/delete.

Integration states:

- Not connected.
- Connected.
- Needs attention.
- Syncing.
- Last synced.

Privacy copy should be plain:

```text
Leko only imports transactions after you connect a provider and approve access.
Imported drafts are reviewed before they change your ledger.
```

## Component Templates

### Financial Hero Card

Use for the most important number on a screen.

Required:

- Eyebrow.
- Large value.
- One-line explanation.
- Optional "Why?" action.

Avoid:

- More than two secondary metrics.
- Long descriptions.
- Multiple competing icons.

### Insight Card

Use when Leko noticed something.

Required:

- Short title.
- One sentence.
- One action.

Example:

```text
Phone bill changed
This bill is $14 higher than last month.
[Review]
```

### Empty State

Use production empty states, not demo data.

Required:

- State what is missing.
- Explain the benefit.
- Provide one action.

Example:

```text
No income added yet
Add income so Leko can calculate a daily spending rhythm.
[Add income]
```

### Trust Badge

Use for finance-sensitive states.

Examples:

- Estimated.
- Reviewed.
- Imported.
- Needs review.
- Auto-posted.
- Synced today.

## Motion And Interaction

Use motion to clarify, not decorate.

Ideal motion:

- Card enters softly after data loads.
- Chart line draws once on first view.
- Confirmed transaction card collapses into recent activity.
- Review queue count updates smoothly.
- Leaf draft card morphs into confirmed state.

Accessibility:

- Respect reduce motion.
- Keep contrast high.
- Support dynamic type.
- Make charts understandable with text summaries.
- Every icon-only button needs a tooltip or semantic label.

## Copy Rules

Use short, calm copy.

Prefer:

- `Safe to spend today`
- `Needs review`
- `On pace`
- `Behind by $12/week`
- `Review before importing`
- `Ask Leaf`

Avoid:

- Long education paragraphs.
- Overexplaining obvious controls.
- Professional investment-advice language.
- Shame language around spending.
- Fake certainty.

## Screen Quality Checklist

Before shipping any screen:

- The first visible number has a clear meaning.
- Every money value uses the selected currency.
- Every destructive or financial write action has confirmation or review.
- Empty states use real setup actions, not fake data.
- Text does not overflow on small iPhones.
- No unreadable low-contrast money text.
- No full-page gradients or decorative orbs.
- Leaf has clear next actions when information is missing.
- The screen works without connected bank data.
- The screen has a useful loading, empty, error, and success state.

## Implementation Order

1. Home ideal layout and "Why?" math explainer.
2. Leaf structured response cards.
3. Review queue unification for bank, OCR, notification, voice, and chat drafts.
4. Goal growth chart with contribution history.
5. Reports drift modules.
6. Settings trust and integration states.
7. Accessibility and motion polish.
8. Household mode once individual budgeting is stable.

## Definition Of Done

Leko feels ready for a serious App Store beta when:

- A new user can onboard and understand their first daily spend number.
- A user can add expense, income, bill, and goal without confusion.
- Leaf can create and confirm transaction drafts.
- Imported or detected transactions never change the ledger without review.
- Home explains the math behind safe-to-spend.
- Reports identify at least one actionable drift pattern.
- Settings clearly explains privacy, integrations, and permissions.
- The UI feels consistent across every visible screen.
