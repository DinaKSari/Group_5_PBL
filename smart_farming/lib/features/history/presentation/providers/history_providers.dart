import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/http_history_repository.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HttpHistoryRepository();
});

/// Sumber daftar riwayat untuk UI. invalidate() = refresh setelah entri baru.
final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final result = await ref.watch(historyRepositoryProvider).getHistory();
  final failure = result.failure;
  // Failure dilempar apa adanya supaya UI bisa menampilkan pesan aslinya
  // ("Masuk untuk melihat riwayat", "server mati"), bukan sekadar "Gagal".
  if (failure != null) throw failure;
  return result.items;
});
