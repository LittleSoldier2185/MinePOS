import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/cashier/services/menu_service.dart';

void main() {
  test('setCategoryOrder reorders categories, unlisted ones fall back to the end', () async {
    final svc = MenuService.instance;
    svc.reset(); // clean default items, no custom order

    expect(svc.categories, ['Coffee', 'Tea', 'Cold', 'Food']);

    await svc.setCategoryOrder(['Food', 'Coffee', 'Tea', 'Cold']);
    expect(svc.categories, ['Food', 'Coffee', 'Tea', 'Cold']);

    svc.reset();
  });
}
