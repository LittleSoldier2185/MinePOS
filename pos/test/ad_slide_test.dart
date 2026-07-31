import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/manager/services/ad_service.dart';

void main() {
  final future = DateTime.now().add(const Duration(days: 7));
  final past = DateTime.now().subtract(const Duration(days: 1));

  AdSlideInfo slide({String? name, DateTime? expiresAt}) => AdSlideInfo(
        id: '1',
        type: 'image',
        url: '/ads/1/file',
        name: name,
        expiresAt: expiresAt,
      );

  test('isExpired is false with no expiry, false in the future, true in the past', () {
    expect(slide().isExpired, isFalse);
    expect(slide(expiresAt: future).isExpired, isFalse);
    expect(slide(expiresAt: past).isExpired, isTrue);
  });

  test('copyWith leaves fields untouched by default', () {
    final s = slide(name: 'BOGO Latte', expiresAt: future);
    final copy = s.copyWith(muted: true);
    expect(copy.name, 'BOGO Latte');
    expect(copy.expiresAt, future);
  });

  test('copyWith clearName/clearExpiry explicitly wipe those fields', () {
    final s = slide(name: 'BOGO Latte', expiresAt: future);
    final cleared = s.copyWith(clearName: true, clearExpiry: true);
    expect(cleared.name, isNull);
    expect(cleared.expiresAt, isNull);
  });

  test('copyWith sets a new name/expiresAt when given', () {
    final s = slide();
    final updated = s.copyWith(name: 'New Name', expiresAt: future);
    expect(updated.name, 'New Name');
    expect(updated.expiresAt, future);
  });

  group('AdTransition', () {
    test('fromWire round-trips every known value', () {
      expect(AdTransition.fromWire('none'), AdTransition.none);
      expect(AdTransition.fromWire('fade'), AdTransition.fade);
      expect(AdTransition.fromWire('slideLeft'), AdTransition.slideLeft);
    });

    test('fromWire falls back to fade for null/unknown values', () {
      expect(AdTransition.fromWire(null), AdTransition.fade);
      expect(AdTransition.fromWire('bogus'), AdTransition.fade);
    });

    test('.name matches the wire value fromWire expects (round-trip)', () {
      for (final t in AdTransition.values) {
        expect(AdTransition.fromWire(t.name), t);
      }
    });
  });

  test('fromJson reads transition, defaulting to fade when absent', () {
    final withTransition = AdSlideInfo.fromJson({
      'id': '1',
      'type': 'image',
      'url': '/ads/1/file',
      'transition': 'slideLeft',
    });
    expect(withTransition.transition, AdTransition.slideLeft);

    final withoutTransition = AdSlideInfo.fromJson({
      'id': '1',
      'type': 'image',
      'url': '/ads/1/file',
    });
    expect(withoutTransition.transition, AdTransition.fade);
  });

  test('copyWith updates transition and durationSeconds when given', () {
    final s = AdSlideInfo(
      id: '1',
      type: 'image',
      url: '/ads/1/file',
      durationSeconds: 8,
      transition: AdTransition.fade,
    );
    final updated = s.copyWith(transition: AdTransition.none, durationSeconds: 12);
    expect(updated.transition, AdTransition.none);
    expect(updated.durationSeconds, 12);
  });
}
