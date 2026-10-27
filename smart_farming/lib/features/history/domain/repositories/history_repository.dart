import '../../../../core/failures.dart';
import '../entities/history_entry.dart';

/// Kontrak penyimpanan riwayat prediksi.
/// Keputusan arsitektur (dokumen Week 7): TANPA use case terpisah —
/// CRUD satu-baris, repository langsung sudah cukup (hindari over-engineering).
abstract class HistoryRepository {
  Future<({List<HistoryEntry> items, Failure? failure})> getHistory();
  Future<({bool saved, Failure? failure})> addEntry(HistoryEntry entry);
}
