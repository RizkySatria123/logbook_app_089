import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_089/counter_controller_original.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TEST TERHADAP KODE ORIGINAL (SEBELUM PERBAIKAN)
/// File yang diuji: lib/counter_controller_original.dart
/// Tujuan: Menemukan bug pada source code original
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TC01 | Inisialisasi | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC01 - initial value should be 0', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();

    // (2) exercise (act, operate)
    final actual = controller.value;

    // (3) verify (assert, check)
    final expected = 0;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC02 | updateStep(int) | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC02 - updateStep should change step value', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();

    // (2) exercise (act, operate)
    controller.updateStep(5);

    // (3) verify (assert, check)
    controller.increment();
    final actual = controller.value;
    final expected = 5;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC03 | updateStep(int) | Negatif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC03 - updateStep should ignore negative value', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();
    controller.updateStep(3);

    // (2) exercise (act, operate)
    controller.updateStep(-1);

    // (3) verify (assert, check)
    controller.increment();
    final actual = controller.value;
    final expected = 3;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC04 | increment() | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC04 - increment should add step to counter', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();

    // (2) exercise (act, operate)
    controller.increment();

    // (3) verify (assert, check)
    final actual = controller.value;
    final expected = 1;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC05 | increment() | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC05 - increment with custom step should add correctly', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();
    controller.updateStep(3);

    // (2) exercise (act, operate)
    controller.increment();
    controller.increment();

    // (3) verify (assert, check)
    final actual = controller.value;
    final expected = 6;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC06 | decrement() | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC06 - decrement should subtract step from counter', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();
    controller.updateStep(5);
    controller.increment(); // counter = 5

    // (2) exercise (act, operate)
    controller.updateStep(2);
    controller.decrement(); // 5 - 2 = 3

    // (3) verify (assert, check)
    final actual = controller.value;
    final expected = 3;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC07 | decrement() | Negatif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC07 - decrement should not go below zero', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();
    controller.increment(); // counter = 1

    // (2) exercise (act, operate)
    controller.updateStep(5);
    controller.decrement(); // 1 - 5 = -4 (BUG: tidak di-clamp)

    // (3) verify (assert, check)
    final actual = controller.value;
    final expected = 0;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC08 | reset() | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC08 - reset should set counter to zero', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();
    controller.updateStep(10);
    controller.increment(); // counter = 10

    // (2) exercise (act, operate)
    controller.reset();

    // (3) verify (assert, check)
    final actual = controller.value;
    final expected = 0;
    expect(actual, expected);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC09 | _addHistory | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC09 - history should record actions', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();

    // (2) exercise (act, operate)
    controller.increment();
    controller.decrement();
    controller.reset();

    // (3) verify (assert, check)
    final actualLength = controller.history.length;
    final expectedLength = 3;
    expect(actualLength, expectedLength);

    final actualAction0 = controller.history[0].action;
    final expectedAction0 = HistoryActionOriginal.tambah;
    expect(actualAction0, expectedAction0);

    final actualAction1 = controller.history[1].action;
    final expectedAction1 = HistoryActionOriginal.kurang;
    expect(actualAction1, expectedAction1);

    final actualAction2 = controller.history[2].action;
    final expectedAction2 = HistoryActionOriginal.reset;
    expect(actualAction2, expectedAction2);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TC10 | _addHistory (batasan max 5) | Positif
  // ═══════════════════════════════════════════════════════════════════════════
  test('TC10 - history should keep max 5 entries', () {
    // (1) setup (arrange, build)
    final controller = CounterControllerOriginal();

    // (2) exercise (act, operate)
    for (int i = 0; i < 7; i++) {
      controller.increment();
    }

    // (3) verify (assert, check)
    final actual = controller.history.length;
    final expected = 5;
    expect(actual, expected);
  });
}
