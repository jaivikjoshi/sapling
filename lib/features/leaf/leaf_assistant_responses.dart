import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../domain/models/enums.dart';
import 'leaf_context.dart';

String _money(LeafContext ctx, double amount) {
  return formatCurrency(amount);
}

String _cycleRange(LeafContext ctx) {
  final w = switch (ctx.allowanceMode) {
    AllowanceMode.paycheck => ctx.paycheck?.cycleWindow,
    AllowanceMode.goal => ctx.goal?.cycleWindow,
  };
  if (w == null) return 'this cycle';
  final fmt = DateFormat.MMMd();
  return '${fmt.format(w.start)} – ${fmt.format(w.end)}';
}

int? _daysLeftInCycle(LeafContext ctx) {
  return switch (ctx.allowanceMode) {
    AllowanceMode.paycheck => ctx.paycheck?.daysLeft,
    AllowanceMode.goal => ctx.goal?.daysToGoal,
  };
}

/// Hero briefing for the top card (calm, specific).
String buildHeroBriefing(LeafContext ctx) {
  final name = ctx.greetingName.isEmpty ? 'there' : ctx.greetingName;
  final modeLabel =
      ctx.allowanceMode == AllowanceMode.paycheck ? 'paycheck rhythm' : 'goal pace';

  if (ctx.settings == null) {
    return '$name, finish setup in Settings and I’ll mirror your allowance here.';
  }

  final daily = ctx.dailyAllowance;
  final left = ctx.remainingToday;
  final spent = ctx.todaySpend;

  if (daily == null || left == null || spent == null) {
    return '$name, I’m lining up your $modeLabel. One moment while balances and bills sync.';
  }

  final allowanceStr = _money(ctx, daily);
  final leftStr = _money(ctx, left.abs());
  final tone = left >= 0
      ? 'Stay within $allowanceStr today and you keep the cycle feeling easy.'
      : 'You’re about $leftStr over today’s allowance — small pulls for the rest of the day will help.';

  if (ctx.allowanceMode == AllowanceMode.goal && ctx.goal != null) {
    final g = ctx.goal!.goal.name;
    final target = DateFormat.MMMd().format(ctx.goal!.goal.targetDate);
    return '$name, you’re guiding toward “$g” by $target. $tone';
  }

  return '$name, you’re in ${_cycleRange(ctx)} on $modeLabel. $tone';
}

String responseForKind(LeafContext ctx, LeafQueryKind kind) {
  return switch (kind) {
    LeafQueryKind.spendingToday => _spendingToday(ctx),
    LeafQueryKind.bills => _bills(ctx),
    LeafQueryKind.goal => _goal(ctx),
    LeafQueryKind.thisCycle => _thisCycle(ctx),
  };
}

/// Deterministic parsing for free text (keyword order matters).
String responseForFreeText(LeafContext ctx, String raw) {
  final q = raw.toLowerCase().trim();
  if (q.isEmpty) {
    return 'Ask me about spending today, bills, your goal, or this cycle — I’ll use your live Leko data.';
  }

  if (RegExp(r'\b(bill|bills|due|payment)\b').hasMatch(q)) {
    return _bills(ctx);
  }
  if (RegExp(r'\b(goal|saving|target)\b').hasMatch(q)) {
    return _goal(ctx);
  }
  if (RegExp(
          r'\b(spend|spending|allowance|left|remaining|today|coffee|budget)\b')
      .hasMatch(q)) {
    return _spendingToday(ctx);
  }
  if (RegExp(r'\b(cycle|paycheck|month|rhythm|window)\b').hasMatch(q)) {
    return _thisCycle(ctx);
  }
  if (RegExp(r'\b(balance|overview|summary|how am i|status)\b').hasMatch(q)) {
    return _overview(ctx);
  }

  return _overview(ctx);
}

String _spendingToday(LeafContext ctx) {
  if (ctx.settings == null) {
    return 'Once settings are loaded, I can read today’s allowance and what you’ve already spent.';
  }
  final daily = ctx.dailyAllowance;
  final left = ctx.remainingToday;
  final spent = ctx.todaySpend;
  if (daily == null || left == null || spent == null) {
    return 'I don’t have today’s allowance snapshot yet. Open Home for a second to let data sync, then ask again.';
  }

  final mode = ctx.allowanceMode == AllowanceMode.paycheck
      ? 'paycheck-based daily allowance'
      : 'goal-based daily allowance';
  final line = left >= 0
      ? 'You can still spend about ${_money(ctx, left)} today (${_money(ctx, spent)} used of ${_money(ctx, daily)}).'
      : 'Today you’re roughly ${_money(ctx, left.abs())} past the ${_money(ctx, daily)} $mode line, with ${_money(ctx, spent)} spent so far.';

  return 'Using your $mode: $line';
}

String _bills(LeafContext ctx) {
  if (ctx.upcomingBills.isEmpty) {
    return 'No bills in the upcoming window I can see. If you expect one, add it under Bills so I can warn you ahead of time.';
  }
  final count = ctx.upcomingBills.length;
  final next = ctx.nextBill!;
  final due = DateFormat.MMMd().format(next.nextDueDate);
  return 'You have $count bill${count == 1 ? '' : 's'} coming up in the next stretch. Next: “${next.name}” on $due for ${_money(ctx, next.amount)}.';
}

String _goal(LeafContext ctx) {
  if (ctx.allowanceMode == AllowanceMode.goal && ctx.goal != null) {
    final g = ctx.goal!.goal;
    final due = DateFormat.MMMd().format(g.targetDate);
    return 'You’re in goal mode toward “${g.name}” (target ${_money(ctx, g.targetAmount)} by $due). Your daily allowance is tuned to that finish line.';
  }
  if (ctx.primaryGoal != null) {
    final g = ctx.primaryGoal!;
    final due = DateFormat.MMMd().format(g.targetDate);
    return 'Your primary focus is “${g.name}” (${_money(ctx, g.targetAmount)} by $due). Switch to goal allowance mode on Home if you want every day framed around it.';
  }
  return 'You don’t have a primary goal selected yet. Pick one in Goals and optionally set allowance mode to Goal for day-to-day guidance around it.';
}

String _thisCycle(LeafContext ctx) {
  if (ctx.settings == null) {
    return 'I need your settings to describe this spending cycle.';
  }
  final range = _cycleRange(ctx);
  final days = _daysLeftInCycle(ctx);
  final bal = ctx.balance;
  final pool = switch (ctx.allowanceMode) {
    AllowanceMode.paycheck => ctx.paycheck?.spendablePool,
    AllowanceMode.goal => ctx.goal?.spendablePool,
  };

  final parts = <String>['We’re in $range.'];
  if (days != null) {
    parts.add(
      ctx.allowanceMode == AllowanceMode.paycheck
          ? 'About $days day${days == 1 ? '' : 's'} left in this cycle.'
          : 'About $days day${days == 1 ? '' : 's'} mapped to your goal horizon.',
    );
  }
  if (bal != null) {
    parts.add('Posted balance is ${_money(ctx, bal)}.');
  }
  if (pool != null) {
    parts.add('Spendable pool (after projected income and bills in view) is around ${_money(ctx, pool)}.');
  }
  return parts.join(' ');
}

String _overview(LeafContext ctx) {
  if (ctx.settings == null) {
    return 'Finish setup in Settings and I’ll summarize balance, allowance, bills, and goals from your live data.';
  }

  final lines = <String>[];
  final modeWord =
      ctx.allowanceMode == AllowanceMode.paycheck ? 'Paycheck' : 'Goal';
  lines.add('$modeWord mode · ${_cycleRange(ctx)}.');

  if (ctx.balance != null) {
    lines.add('Balance ${_money(ctx, ctx.balance!)}.');
  }

  final daily = ctx.dailyAllowance;
  final left = ctx.remainingToday;
  if (daily != null && left != null) {
    lines.add(
      left >= 0
          ? 'Today ~${_money(ctx, left)} left on a ${_money(ctx, daily)} daily allowance.'
          : 'Today ~${_money(ctx, left.abs())} past a ${_money(ctx, daily)} daily allowance.',
    );
  }

  if (ctx.upcomingBills.isEmpty) {
    lines.add('No bills in my upcoming window.');
  } else {
    final n = ctx.nextBill!;
    lines.add(
      'Next bill: “${n.name}” on ${DateFormat.MMMd().format(n.nextDueDate)}.',
    );
  }

  if (ctx.primaryGoal != null) {
    lines.add('Primary goal: “${ctx.primaryGoal!.name}”.');
  } else if (ctx.allowanceMode == AllowanceMode.goal && ctx.goal != null) {
    lines.add('Tracking toward “${ctx.goal!.goal.name}”.');
  } else {
    lines.add('No primary goal pinned — optional in Goals.');
  }

  return lines.join(' ');
}

// ── Compact copy for insight cards (UI layer consumes) ──

String leafInsightAllowanceSubtitle(LeafContext ctx) {
  final left = ctx.remainingToday;
  final daily = ctx.dailyAllowance;
  if (left == null || daily == null) {
    return 'Syncing allowance…';
  }
  if (left >= 0) {
    return '${_money(ctx, left)} left · ${_money(ctx, daily)} daily';
  }
  return '${_money(ctx, left.abs())} over · ${_money(ctx, daily)} target';
}

String leafInsightBillsSubtitle(LeafContext ctx) {
  if (ctx.upcomingBills.isEmpty) return 'Nothing due in view';
  final n = ctx.nextBill!;
  final count = ctx.upcomingBills.length;
  return '$count upcoming · next ${DateFormat.MMMd().format(n.nextDueDate)}';
}

String leafInsightGoalSubtitle(LeafContext ctx) {
  if (ctx.allowanceMode == AllowanceMode.goal && ctx.goal != null) {
    return '“${ctx.goal!.goal.name}”';
  }
  if (ctx.primaryGoal != null) {
    return '“${ctx.primaryGoal!.name}”';
  }
  return 'No primary focus set';
}

String leafInsightActivitySubtitle(LeafContext ctx) {
  if (ctx.recentTransactions.isEmpty) return 'No recent entries';
  final t = ctx.recentTransactions.first;
  final note = (t.note?.trim().isNotEmpty ?? false) ? t.note!.trim() : t.type;
  final sign = t.type == 'income' ? '+' : '−';
  return '$sign${_money(ctx, t.amount)} · $note';
}
