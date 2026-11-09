import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_history_repository.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return InMemoryHistoryRepository.instance;
});

/// Sumber daftar riwayat untuk UI. invalidate() = refresh setelah entri baru.
final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final result = await ref.watch(historyRepositoryProvider).getHistory();
  final failure = result.failure;
  if (failure != null) throw StateError(failure.message);
  return result.items;
});
