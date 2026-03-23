import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../features/leaf/leaf_assistant_responses.dart';
import '../../features/leaf/leaf_context.dart';
import 'allowance_providers.dart';
import 'auth_providers.dart';
import 'bills_providers.dart';
import 'goals_providers.dart';
import 'ledger_providers.dart';
import 'profile_providers.dart';
import 'settings_providers.dart';

final leafContextProvider = Provider<LeafContext>((ref) {
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(profileServiceProvider);
  final name = profile.firstName(user).trim();
  final greeting = name.isEmpty ? profile.displayName(user).trim() : name;

  final settings = ref.watch(settingsStreamProvider).valueOrNull;
  final balance = ref.watch(balanceStreamProvider).valueOrNull;
  final mode = ref.watch(effectiveAllowanceModeProvider);
  final paycheck = ref.watch(paycheckAllowanceProvider).valueOrNull;
  final goal = ref.watch(goalAllowanceProvider).valueOrNull;
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];
  final bills = ref.watch(upcomingBillsProvider).valueOrNull ?? const <Bill>[];
  final txns =
      ref.watch(recentTransactionsProvider).valueOrNull ?? const <Transaction>[];

  Goal? primary;
  final pid = settings?.primaryGoalId;
  if (pid != null) {
    for (final g in goals) {
      if (g.id == pid) {
        primary = g;
        break;
      }
    }
  }

  final sortedBills = [...bills]
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  final recent = txns.take(5).toList();

  return LeafContext(
    greetingName: greeting,
    allowanceMode: mode,
    settings: settings,
    balance: balance,
    paycheck: paycheck,
    goal: goal,
    primaryGoal: primary,
    upcomingBills: sortedBills,
    recentTransactions: recent,
  );
});

class LeafChatMessage {
  const LeafChatMessage({
    required this.isUser,
    required this.text,
    required this.at,
  });

  final bool isUser;
  final String text;
  final DateTime at;
}

class LeafConversationState {
  const LeafConversationState({this.messages = const []});

  final List<LeafChatMessage> messages;

  LeafConversationState copyWith({List<LeafChatMessage>? messages}) {
    return LeafConversationState(messages: messages ?? this.messages);
  }
}

class LeafConversationController extends StateNotifier<LeafConversationState> {
  LeafConversationController(this.ref)
      : super(
          LeafConversationState(
            messages: [
              LeafChatMessage(
                isUser: false,
                text:
                    'I’m Leaf — a calm read on your Leko numbers. Tap a prompt or ask in your own words; I don’t call the cloud.',
                at: DateTime.now(),
              ),
            ],
          ),
        );

  final Ref ref;

  LeafContext get _ctx => ref.read(leafContextProvider);

  void clearConversation() {
    state = LeafConversationState(
      messages: [
        LeafChatMessage(
          isUser: false,
          text:
              'Fresh thread. Ask about spending today, bills, your goal, or this cycle.',
          at: DateTime.now(),
        ),
      ],
    );
  }

  void askKind(LeafQueryKind kind) {
    final label = switch (kind) {
      LeafQueryKind.spendingToday => 'Spending today',
      LeafQueryKind.bills => 'Bills',
      LeafQueryKind.goal => 'My goal',
      LeafQueryKind.thisCycle => 'This cycle',
    };
    final reply = responseForKind(_ctx, kind);
    _appendPair(label, reply);
  }

  void submitFreeText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final reply = responseForFreeText(_ctx, trimmed);
    _appendPair(trimmed, reply);
  }

  void _appendPair(String userLine, String assistantLine) {
    final now = DateTime.now();
    state = state.copyWith(
      messages: [
        ...state.messages,
        LeafChatMessage(isUser: true, text: userLine, at: now),
        LeafChatMessage(
          isUser: false,
          text: assistantLine,
          at: now,
        ),
      ],
    );
  }
}

final leafConversationProvider =
    StateNotifierProvider<LeafConversationController, LeafConversationState>(
        (ref) {
  return LeafConversationController(ref);
});

/// Opening line for the hero card; recomputes with context.
final leafHeroBriefingProvider = Provider<String>((ref) {
  return buildHeroBriefing(ref.watch(leafContextProvider));
});
