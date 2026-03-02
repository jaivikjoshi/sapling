import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/widget/snapshot_writer.dart';
import 'allowance_providers.dart';
import 'closeout_providers.dart';
import 'goals_providers.dart';
import 'settings_providers.dart';

final snapshotWriterProvider = Provider<SnapshotWriter>((ref) {
  return SnapshotWriter(
    ref.watch(settingsRepositoryProvider),
    ref.watch(allowanceEngineProvider),
    ref.watch(closeoutServiceProvider),
    ref.watch(goalsRepositoryProvider),
  );
});
