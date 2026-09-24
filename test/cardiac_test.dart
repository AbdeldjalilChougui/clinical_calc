// See test/kidney_test.dart for what "MedCalc-Bench row N" means.
import 'package:clinical_calc/clinical_calc.dart';
import 'package:test/test.dart';

void main() {
  // Tolerance 1e-3 ms: the published values carry 4-5 decimals and
  // MedCalc-Bench rounds RR to 5 decimals before correcting.
  const tol = 1e-3;

  group('QTc Bazett (1920)', () {
    test('MedCalc-Bench row 181: HR 158, QT 402 -> 652.34474', () {
      expect(
          Qtc.bazett(qtMs: 402, heartRateBpm: 158), closeTo(652.34474, 0.01));
    });
    test('MedCalc-Bench row 184: HR 140, QT 217 -> 331.47353', () {
      expect(
          Qtc.bazett(qtMs: 217, heartRateBpm: 140), closeTo(331.47353, 0.01));
    });
    test('at 60 bpm QTc equals QT', () {
      expect(Qtc.bazett(qtMs: 400, heartRateBpm: 60), closeTo(400, 1e-9));
    });
  });

  group('QTc Fridericia (1920)', () {
    test('MedCalc-Bench row 663: HR 55, QT 469 -> 455.59247', () {
      expect(Qtc.fridericia(qtMs: 469, heartRateBpm: 55),
          closeTo(455.59247, 0.01));
    });
    test('MedCalc-Bench row 664: HR 91, QT 317 -> 364.21357', () {
      expect(Qtc.fridericia(qtMs: 317, heartRateBpm: 91),
          closeTo(364.21357, 0.01));
    });
  });

  group('QTc Framingham (Sagie 1992)', () {
    test('MedCalc-Bench row 681: HR 110, QT 490 -> 560.0007', () {
      expect(
          Qtc.framingham(qtMs: 490, heartRateBpm: 110), closeTo(560.0007, tol));
    });
    test('MedCalc-Bench row 684: HR 56, QT 453 -> 441.99978', () {
      expect(
          Qtc.framingham(qtMs: 453, heartRateBpm: 56), closeTo(441.99978, tol));
    });
  });

  group('dispatch and validation', () {
    test('Qtc.correct dispatches on QtcFormula', () {
      expect(Qtc.correct(qtMs: 400, heartRateBpm: 75),
          Qtc.bazett(qtMs: 400, heartRateBpm: 75));
      expect(
          Qtc.correct(
              qtMs: 400, heartRateBpm: 75, formula: QtcFormula.fridericia),
          Qtc.fridericia(qtMs: 400, heartRateBpm: 75));
      expect(
          Qtc.correct(
              qtMs: 400, heartRateBpm: 75, formula: QtcFormula.framingham),
          Qtc.framingham(qtMs: 400, heartRateBpm: 75));
    });
    test('citations', () {
      expect(QtcFormula.framingham.citation, contains('Sagie'));
    });
    test('rejects non-physiological heart rate and QT', () {
      expect(() => Qtc.bazett(qtMs: 400, heartRateBpm: 0),
          throwsA(isA<InvalidInputException>()));
      expect(() => Qtc.bazett(qtMs: 400, heartRateBpm: 400),
          throwsA(isA<InvalidInputException>()));
      expect(() => Qtc.bazett(qtMs: -1, heartRateBpm: 60),
          throwsA(isA<InvalidInputException>()));
      expect(() => Qtc.bazett(qtMs: 2000, heartRateBpm: 60),
          throwsA(isA<InvalidInputException>()));
    });
  });
}
