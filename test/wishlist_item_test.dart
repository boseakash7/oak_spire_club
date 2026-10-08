import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/models/wishlist_item.dart';
import 'package:oakspire_club/app/modules/wishlist/wishlist_controller.dart';

WishlistItem _item({Object? added, Object? target, Object? average = '100'}) =>
    WishlistItem.fromJson({
      'id': 1,
      'bottle_id': 9,
      'added_price': added,
      'target_price': target,
      'note': 'null',
      'created_at': 1791429514,
      'bluebook': {'id': '9', 'bottle_name': 'Weller 12', 'average': average},
    })!;

void main() {
  test('parses the row and its bottle', () {
    final item = _item(added: 80, target: '90.5');
    expect(item.bottleId, '9');
    expect(item.bottle.bottleName, 'Weller 12');
    expect(item.addedPrice, 80);
    expect(item.targetPrice, 90.5);
    expect(item.note, isNull);
    expect(item.createdAt, isNotNull);
    expect(WishlistItem.fromJson({'id': 1}), isNull);
  });

  test('change since added runs from the added price to today', () {
    expect(_item(added: 80).changeSinceAdded, closeTo(25, 1e-9));
    expect(_item(added: null).changeSinceAdded, isNull);
    expect(_item(added: 80, average: '0').changeSinceAdded, isNull);
  });

  test('target: met at or under it, distance above it, near within 10%', () {
    expect(_item(target: 100).atTarget, isTrue);
    expect(_item(target: 100).aboveTargetPercent, isNull);

    final above = _item(target: 80);
    expect(above.atTarget, isFalse);
    expect(above.aboveTargetPercent, closeTo(25, 1e-9));
    expect(above.nearTarget, isFalse);
    expect(_item(target: 95).nearTarget, isTrue);

    expect(_item().atTarget, isFalse);
    expect(_item(target: 100, average: null).atTarget, isFalse);
  });

  test('filters: at target, falling, rising', () {
    final atTarget = _item(added: 120, target: 100);
    final rising = _item(added: 80);
    expect(WishlistFilter.atTarget.matches(atTarget), isTrue);
    expect(WishlistFilter.atTarget.matches(rising), isFalse);
    expect(WishlistFilter.falling.matches(atTarget), isTrue);
    expect(WishlistFilter.rising.matches(rising), isTrue);
    expect(WishlistFilter.rising.matches(_item()), isFalse);
    expect(WishlistFilter.all.matches(_item()), isTrue);
  });
}
