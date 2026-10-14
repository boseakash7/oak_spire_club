import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/models/collection_item_display.dart';
import 'package:oakspire_club/app/data/models/collection_item_model.dart';
import 'package:oakspire_club/app/data/repositories/collection_repository.dart';

CollectionItemModel row(
  String id, {
  required String fill,
  String bottle = '7',
  String? qty,
  String? paid,
  String? createdAt,
}) {
  return CollectionItemModel(
    id: id,
    type: 'normal',
    createdAt: createdAt,
    quantity: qty,
    fill: fill,
    pricePaid: paid,
    bluebook: {'id': bottle},
  );
}

void main() {
  group('CollectionRepository.groupItems', () {
    test('averages every bottle fill and keeps each bottle', () {
      final out = CollectionRepository.groupItems([
        row('1', fill: '100', paid: '460', createdAt: '1760000000'),
        row('2', fill: '60', paid: '370', createdAt: '1758000000'),
        row('3', fill: '45', paid: '370', createdAt: '1758000000'),
      ]);

      expect(out, hasLength(1));
      final item = out.single;
      expect(item.quantity, '3');
      expect(item.fill, '68'); // (100 + 60 + 45) / 3 = 68.3
      expect(item.pricePaid, '400.00'); // (460 + 370 + 370) / 3
      expect(item.bottles, hasLength(3));
      expect(item.bottles!.map((b) => b.fill), [100, 60, 45]);
      expect(item.bottles!.map((b) => b.id), ['1', '2', '3']);
      expect(item.bottles!.map((b) => b.isOpened), [false, true, true]);
      expect(item.openedBottleCount, 2);
    });

    test('weights a row by its quantity', () {
      final out = CollectionRepository.groupItems([
        row('1', fill: '100', qty: '3'),
        row('2', fill: '40', qty: '1'),
      ]);

      // (100 * 3 + 40) / 4 = 85
      expect(out.single.fill, '85');
    });

    test('a single row still carries its bottle', () {
      final out = CollectionRepository.groupItems([
        row('9', fill: '80', paid: '120.5', createdAt: '1760000000'),
      ]);

      final bottle = out.single.bottles!.single;
      expect(bottle.id, '9');
      expect(bottle.fill, 80);
      expect(bottle.pricePaid, 120.5);
      expect(bottle.createdAt, 1760000000);
    });

    test('keeps different bottles apart and survives a second pass', () {
      final once = CollectionRepository.groupItems([
        row('1', fill: '100', bottle: 'a'),
        row('2', fill: '50', bottle: 'a'),
        row('3', fill: '70', bottle: 'b'),
      ]);
      final twice = CollectionRepository.groupItems(once);

      expect(twice, hasLength(2));
      expect(twice.first.bottles, hasLength(2));
      expect(twice.first.fill, once.first.fill);
    });

    test('bottles survive the cache round trip', () {
      final item = CollectionRepository.groupItems([
        row('1', fill: '100', createdAt: '10'),
        row('2', fill: '30', createdAt: '20'),
      ]).single;

      final back = CollectionItemModel.fromJson(item.toJson());

      expect(back.bottles!.map((b) => (b.id, b.fill, b.createdAt)), [
        ('1', 100, 10),
        ('2', 30, 20),
      ]);
    });
  });
}
