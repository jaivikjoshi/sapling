import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/theme/leko_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/daily_snapshot.dart';

/// Debug screen: shows last snapshot written for the widget (from App Group).
class WidgetPreviewScreen extends ConsumerStatefulWidget {
  const WidgetPreviewScreen({super.key});

  @override
  ConsumerState<WidgetPreviewScreen> createState() => _WidgetPreviewScreenState();
}

class _WidgetPreviewScreenState extends ConsumerState<WidgetPreviewScreen> {
  static const _key = 'leko_daily_snapshot';
  DailySnapshot? _snapshot;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _snapshot = null;
      _error = null;
    });
    try {
      final jsonString = await HomeWidget.getWidgetData<String>(_key, defaultValue: null);
      if (jsonString == null || jsonString.isEmpty) {
        setState(() => _error = 'No snapshot stored');
        return;
      }
      final map = jsonDecode(jsonString) as Map<String, dynamic>?;
      setState(() => _snapshot = DailySnapshot.fromJson(map));
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget snapshot preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: LekoColors.labelRed),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (_snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _snapshot!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Allowance today', style: TextStyle(color: LekoColors.textSecondary)),
                const SizedBox(height: 4),
                Text(formatCurrency(s.todayAllowance), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('Behind', style: TextStyle(color: LekoColors.textSecondary)),
                const SizedBox(height: 4),
                Text(formatCurrency(s.behindAmount), style: TextStyle(color: s.behindAmount > 0 ? LekoColors.labelRed : null)),
                if (s.primaryGoalProgress != null) ...[
                  const SizedBox(height: 12),
                  Text('Goal progress', style: TextStyle(color: LekoColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${(s.primaryGoalProgress! * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium),
                ],
                const SizedBox(height: 12),
                Text('Tree stage', style: TextStyle(color: LekoColors.textSecondary)),
                const SizedBox(height: 4),
                Text(s.treeStage, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Closeout', style: TextStyle(color: LekoColors.textSecondary)),
                const SizedBox(height: 4),
                Text(s.closeoutStatus),
                const SizedBox(height: 12),
                Text('Updated', style: TextStyle(color: LekoColors.textSecondary)),
                const SizedBox(height: 4),
                Text(s.timestamp.toIso8601String()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
