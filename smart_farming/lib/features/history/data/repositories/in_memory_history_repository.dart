import '../../../../core/failures.dart';
import '../../../prediction/domain/entities/prediction_request.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

/// Penyimpanan riwayat sementara di memori (in-process).
/// TODO(persistensi): ganti ke sqflite / API backend tanpa mengubah domain.
class InMemoryHistoryRepository implements HistoryRepository {
  InMemoryHistoryRepository._();

  static final InMemoryHistoryRepository instance = InMemoryHistoryRepository._();

  final List<HistoryEntry> _items = [
    HistoryEntry(
      location: 'Greenhouse Blok A – Rak 1',
      inputDate: DateTime(2026, 9, 14),
      daysLeft: 12,
      parameters: PredictionRequest(plantAge: 22, temperature: 23, humidity: 78, tds: 710, ph: 6.2),
    ),
    HistoryEntry(
      location: 'NFT Sayur Sehat – Modul 3',
      inputDate: DateTime(2026, 9, 12),
      daysLeft: 8,
      parameters: PredictionRequest(plantAge: 31, temperature: 24.5, humidity: 74, tds: 880, ph: 6.4),
    ),
    HistoryEntry(
      location: 'DFT Blok C – Lajur 2',
      inputDate: DateTime(2026, 9, 10),
      daysLeft: 21,
      parameters: PredictionRequest(plantAge: 15, temperature: 22, humidity: 80, tds: 650, ph: 6.0),
    ),
    HistoryEntry(
      location: 'Greenhouse Blok B – Rak 4',
      inputDate: DateTime(2026, 9, 8),
      daysLeft: 0,
      parameters: PredictionRequest(plantAge: 37, temperature: 25, humidity: 72, tds: 800, ph: 6.1),
    ),
  ];

  @override
  Future<({List<HistoryEntry> items, Failure? failure})> getHistory() async {
    return (items: List<HistoryEntry>.unmodifiable(_items), failure: null);
  }

  @override
  Future<({bool saved, Failure? failure})> addEntry(HistoryEntry entry) async {
    _items.insert(0, entry);
    return (saved: true, failure: null);
  }
}
