// Dosing arithmetic is exact algebra, so tolerances are 1e-9 unless noted.
import 'package:clinical_calc/clinical_calc.dart';
import 'package:test/test.dart';

void main() {
  const tol = 1e-9;

  group('dose', () {
    test('per kg: 15 mg/kg x 20 kg = 300 mg', () {
      expect(Dosing.doseForWeight(mgPerKg: 15, weight: Weight.kg(20)),
          closeTo(300, tol));
    });
    test('per m2: 100 mg/m2 x 1.8 m2 = 180 mg', () {
      expect(Dosing.doseForBsa(mgPerM2: 100, bsaM2: 1.8), closeTo(180, tol));
    });
    test('per m2: 50 mg/m2 x 1.5 m2 = 75 mg', () {
      expect(Dosing.doseForBsa(mgPerM2: 50, bsaM2: 1.5), closeTo(75, tol));
    });
    test('zero dose rate is allowed, negative is not', () {
      expect(Dosing.doseForBsa(mgPerM2: 0, bsaM2: 1.5), 0);
      expect(() => Dosing.doseForBsa(mgPerM2: -1, bsaM2: 1.5),
          throwsA(isA<InvalidInputException>()));
      expect(() => Dosing.doseForBsa(mgPerM2: 10, bsaM2: 0),
          throwsA(isA<InvalidInputException>()));
      expect(() => Dosing.doseForBsa(mgPerM2: 10, bsaM2: 6),
          throwsA(isA<InvalidInputException>()));
      expect(() => Dosing.doseForWeight(mgPerKg: -1, weight: Weight.kg(20)),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('volume to draw', () {
    test('180 mg at 2 mg/mL = 90 mL', () {
      expect(Dosing.volumeToDraw(doseMg: 180, concentrationMgPerMl: 2),
          closeTo(90, tol));
    });
    test('100 mg at 5 mg/mL = 20 mL', () {
      expect(Dosing.volumeToDraw(doseMg: 100, concentrationMgPerMl: 5),
          closeTo(20, tol));
    });
    test('zero dose gives zero volume', () {
      expect(Dosing.volumeToDraw(doseMg: 0, concentrationMgPerMl: 2), 0);
    });
    test('rejects zero concentration', () {
      expect(() => Dosing.volumeToDraw(doseMg: 100, concentrationMgPerMl: 0),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('concentration', () {
    test('500 mg in 250 mL = 2 mg/mL', () {
      expect(
          Dosing.concentration(amountMg: 500, volumeMl: 250), closeTo(2, tol));
    });
    test('infusion: 180 mg drawn as 90 mL into a 250 mL bag', () {
      expect(
        Dosing.infusionConcentration(
            doseMg: 180, drugVolumeMl: 90, diluentVolumeMl: 250),
        closeTo(180 / 340, tol),
      );
    });
    test('infusion: 100 mg in 50 mL + 100 mL', () {
      expect(
        Dosing.infusionConcentration(
            doseMg: 100, drugVolumeMl: 50, diluentVolumeMl: 100),
        closeTo(0.6666666667, 1e-9),
      );
    });
    test('rejects zero total volume', () {
      expect(
        () => Dosing.infusionConcentration(
            doseMg: 10, drugVolumeMl: 0, diluentVolumeMl: 0),
        throwsA(isA<InvalidInputException>()),
      );
      expect(() => Dosing.concentration(amountMg: 10, volumeMl: 0),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('vials', () {
    test('180 mg, 100 mg vials at 2 mg/mL -> 2 vials, 20 mg / 10 mL left', () {
      final plan = Dosing.vials(
          doseMg: 180, vialContentMg: 100, concentrationMgPerMl: 2);
      expect(plan.vialCount, 2);
      expect(plan.volumeToDrawMl, closeTo(90, tol));
      expect(plan.leftoverMg, closeTo(20, tol));
      expect(plan.leftoverMl, closeTo(10, tol));
    });
    test('200 mg, 50 mg vials at 2 mg/mL -> 4 vials, nothing left', () {
      final plan =
          Dosing.vials(doseMg: 200, vialContentMg: 50, concentrationMgPerMl: 2);
      expect(plan.vialCount, 4);
      expect(plan.leftoverMl, closeTo(0, tol));
    });
    test('floating-point noise does not add a vial (1.1 mg in 0.1 mg vials)',
        () {
      final plan = Dosing.vials(
          doseMg: 1.1, vialContentMg: 0.1, concentrationMgPerMl: 1);
      expect(plan.vialCount, 11);
    });
    test('drug already available in an open vial reduces the count', () {
      final plan = Dosing.vials(
        doseMg: 75,
        vialContentMg: 50,
        concentrationMgPerMl: 5,
        availableMl: 5, // 25 mg left from a previous preparation
      );
      expect(plan.vialCount, 1);
      expect(plan.leftoverMg, closeTo(0, tol));
    });
    test('enough drug already available -> 0 vials', () {
      final plan = Dosing.vials(
        doseMg: 10,
        vialContentMg: 50,
        concentrationMgPerMl: 5,
        availableMl: 4,
      );
      expect(plan.vialCount, 0);
      expect(plan.leftoverMl, closeTo(2, tol));
    });
    test('rejects invalid inputs', () {
      expect(
          () => Dosing.vials(
              doseMg: 10, vialContentMg: 0, concentrationMgPerMl: 1),
          throwsA(isA<InvalidInputException>()));
      expect(
          () => Dosing.vials(
              doseMg: -1, vialContentMg: 10, concentrationMgPerMl: 1),
          throwsA(isA<InvalidInputException>()));
      expect(
          () => Dosing.vials(
              doseMg: 1,
              vialContentMg: 10,
              concentrationMgPerMl: 1,
              availableMl: -2),
          throwsA(isA<InvalidInputException>()));
    });
    test('toString is readable', () {
      final plan = Dosing.vials(
          doseMg: 180, vialContentMg: 100, concentrationMgPerMl: 2);
      expect(plan.toString(), contains('2 vials'));
    });
  });

  group('infusion rate', () {
    test('1000 mL over 8 h = 125 mL/h', () {
      expect(
          Dosing.infusionRateMlPerHour(
              volumeMl: 1000, duration: const Duration(hours: 8)),
          closeTo(125, tol));
    });
    test('100 mL over 30 min = 200 mL/h', () {
      expect(
          Dosing.infusionRateMlPerHour(
              volumeMl: 100, duration: const Duration(minutes: 30)),
          closeTo(200, tol));
    });
    test('drops/min: 1000 mL over 8 h with 20 gtt/mL = 41.67', () {
      expect(
        Dosing.dropsPerMinute(
          volumeMl: 1000,
          duration: const Duration(hours: 8),
          dropFactorPerMl: 20,
        ),
        closeTo(41.6666667, 1e-6),
      );
    });
    test('drops/min: 500 mL over 4 h with 60 gtt/mL (microdrip) = 125', () {
      expect(
        Dosing.dropsPerMinute(
          volumeMl: 500,
          duration: const Duration(hours: 4),
          dropFactorPerMl: 60,
        ),
        closeTo(125, tol),
      );
    });
    test('rejects zero duration and zero drop factor', () {
      expect(
          () => Dosing.infusionRateMlPerHour(
              volumeMl: 100, duration: Duration.zero),
          throwsA(isA<InvalidInputException>()));
      expect(
          () => Dosing.dropsPerMinute(
              volumeMl: 100,
              duration: const Duration(hours: 1),
              dropFactorPerMl: 0),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('stability window', () {
    final prepared = DateTime.utc(2026, 1, 1, 8);
    test('within window', () {
      expect(
        Dosing.isWithinStability(
          preparedAt: prepared,
          stability: const Duration(hours: 4),
          now: DateTime.utc(2026, 1, 1, 10),
        ),
        isTrue,
      );
      expect(
        Dosing.stabilityRemaining(
          preparedAt: prepared,
          stability: const Duration(hours: 4),
          now: DateTime.utc(2026, 1, 1, 10, 30),
        ),
        const Duration(hours: 1, minutes: 30),
      );
    });
    test('expired exactly at the end of the window', () {
      expect(
        Dosing.isWithinStability(
          preparedAt: prepared,
          stability: const Duration(hours: 4),
          now: DateTime.utc(2026, 1, 1, 12),
        ),
        isFalse,
      );
    });
    test('remaining time is clamped at zero after expiry', () {
      expect(
        Dosing.stabilityRemaining(
          preparedAt: prepared,
          stability: const Duration(hours: 24),
          now: DateTime.utc(2026, 1, 3),
        ),
        Duration.zero,
      );
    });
    test('rejects a preparation time in the future and negative stability', () {
      expect(
        () => Dosing.stabilityRemaining(
          preparedAt: prepared,
          stability: const Duration(hours: 4),
          now: DateTime.utc(2026, 1, 1, 7),
        ),
        throwsA(isA<InvalidInputException>()),
      );
      expect(
        () => Dosing.stabilityRemaining(
          preparedAt: prepared,
          stability: const Duration(hours: -4),
          now: DateTime.utc(2026, 1, 1, 9),
        ),
        throwsA(isA<InvalidInputException>()),
      );
    });
  });
}
