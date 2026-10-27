import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/features/history/data/repositories/in_memory_history_repository.dart';
import 'package:smart_farming/features/history/domain/entities/history_entry.dart';
import 'package:smart_farming/features/prediction/domain/entities/prediction_request.dart';

void main() {
  HistoryEntry sample({String location = 'Greenhouse Uji', int daysLeft = 10}) => HistoryEntry(
        location: location,
        inputDate: DateTime(2026, 10, 1),
        daysLeft: daysLeft,
        parameters: const PredictionRequest(
          plantAge: 20,
          temperature: 23,
          humidity: 78,
          tds: 720,
          ph: 6.0,
        ),
      );

  group('HistoryEntry entity', () {
    test('harvestDate = inputDate + daysLeft; isReady saat daysLeft 0', () {
      final e = sample();
      expect(e.harvestDate, DateTime(2026, 10, 11));
      expect(e.isReady, isFalse);
      expect(sample(daysLeft: 0).isReady, isTrue);
    });
  });

  group('InMemoryHistoryRepository (contract test)', () {
    test('getHistory mengembalikan seed demo dan addEntry menyisipkan di depan', () async {
      final repo = InMemoryHistoryRepository.instance;
      final before = await repo.getHistory();
      final count = before.items.length;

      final outcome = await repo.addEntry(sample(location: 'Rak Baru'));
      expect(outcome.saved, isTrue);

      final after = await repo.getHistory();
      expect(after.items.length, count + 1);
      expect(after.items.first.location, 'Rak Baru');
    });

    test('getHistory mengembalikan daftar salinan (immutable)', () async {
      final repo = InMemoryHistoryRepository.instance;
      final first = await repo.getHistory();
      final len = first.items.length;
      expect(() => (first.items as List).add(sample()), throwsUnsupportedError);
      final second = await repo.getHistory();
      expect(second.items.length, len);
    });
  });
}
