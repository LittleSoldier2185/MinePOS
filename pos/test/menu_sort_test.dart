import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/services/app_settings_service.dart';
import 'package:pos/features/cashier/models/menu_item.dart';

const _en = Locale('en');

MenuItem _item(String name, double price) =>
    MenuItem(id: name, name: name, category: 'c', price: price);

void main() {
  final items = [_item('Banana', 30), _item('Apple', 50), _item('Cherry', 10)];

  test('defaultOrder leaves the list untouched', () {
    expect(sortMenuItems(items, MenuSortMode.defaultOrder, _en), same(items));
  });

  test('nameAsc/nameDesc sort alphabetically', () {
    expect(
      sortMenuItems(items, MenuSortMode.nameAsc, _en).map((i) => i.name),
      ['Apple', 'Banana', 'Cherry'],
    );
    expect(
      sortMenuItems(items, MenuSortMode.nameDesc, _en).map((i) => i.name),
      ['Cherry', 'Banana', 'Apple'],
    );
  });

  test('priceAsc/priceDesc sort by price', () {
    expect(
      sortMenuItems(items, MenuSortMode.priceAsc, _en).map((i) => i.price),
      [10, 30, 50],
    );
    expect(
      sortMenuItems(items, MenuSortMode.priceDesc, _en).map((i) => i.price),
      [50, 30, 10],
    );
  });

  group('resolveComboItems', () {
    test('resolves bundle ids to items, in bundle order', () {
      final resolved = resolveComboItems(['Cherry', 'Apple'], items);
      expect(resolved.map((i) => i.name), ['Cherry', 'Apple']);
    });

    test('silently skips a bundled id with no matching available item', () {
      final resolved = resolveComboItems(['Apple', 'Durian', 'Banana'], items);
      expect(resolved.map((i) => i.name), ['Apple', 'Banana']);
    });
  });
}
