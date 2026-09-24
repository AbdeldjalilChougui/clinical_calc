// See test/kidney_test.dart for what "MedCalc-Bench row N" and "derived" mean.
import 'package:clinical_calc/clinical_calc.dart';
import 'package:test/test.dart';

void main() {
  group('Corrected calcium (Payne 1973)', () {
    // Tolerance 1e-6 mg/dL: the published examples are exact to 2 decimals.
    test('MedCalc-Bench row 101: Ca 8.6 mg/dL, albumin 3.1 g/dL -> 9.32', () {
      final ca = Chemistry.correctedCalcium(
          calcium: Calcium.mgPerDl(8.6), albumin: Albumin.gPerDl(3.1));
      expect(ca.mgPerDl, closeTo(9.32, 1e-6));
    });
    test('MedCalc-Bench row 104: Ca 10.3 mg/dL, albumin 2.9 g/dL -> 11.18', () {
      final ca = Chemistry.correctedCalcium(
          calcium: Calcium.mgPerDl(10.3), albumin: Albumin.gPerDl(2.9));
      expect(ca.mgPerDl, closeTo(11.18, 1e-6));
    });
    test('SI input: 2.0 mmol/L with albumin 30 g/L -> ~2.20 mmol/L', () {
      final ca = Chemistry.correctedCalcium(
          calcium: Calcium.mmolPerL(2.0), albumin: Albumin.gPerL(30));
      // 0.8 mg/dL per g/dL == 0.01996 mmol/L per g/L (vs. rounded 0.02).
      expect(ca.mmolPerL, closeTo(2.2, 1e-3));
    });
    test('custom normal albumin', () {
      final ca = Chemistry.correctedCalcium(
        calcium: Calcium.mgPerDl(8),
        albumin: Albumin.gPerDl(3),
        normalAlbumin: Albumin.gPerDl(4.4),
      );
      expect(ca.mgPerDl, closeTo(9.12, 1e-9));
    });
  });

  group('Anion gap', () {
    test('MedCalc-Bench row 521: Na 139, Cl 104, HCO3 20 -> 15', () {
      expect(
          Chemistry.anionGap(
              sodiumMmolPerL: 139,
              chlorideMmolPerL: 104,
              bicarbonateMmolPerL: 20),
          closeTo(15, 1e-9));
    });
    test('MedCalc-Bench row 524: Na 140, Cl 101, HCO3 9 -> 30', () {
      expect(
          Chemistry.anionGap(
              sodiumMmolPerL: 140,
              chlorideMmolPerL: 101,
              bicarbonateMmolPerL: 9),
          closeTo(30, 1e-9));
    });
    test('optional potassium is added to the cations', () {
      expect(
          Chemistry.anionGap(
            sodiumMmolPerL: 140,
            chlorideMmolPerL: 101,
            bicarbonateMmolPerL: 9,
            potassiumMmolPerL: 4,
          ),
          closeTo(34, 1e-9));
    });
    test('rejects non-physiological electrolytes', () {
      expect(
          () => Chemistry.anionGap(
              sodiumMmolPerL: 14,
              chlorideMmolPerL: 101,
              bicarbonateMmolPerL: 9),
          throwsA(isA<InvalidInputException>()));
      expect(
          () => Chemistry.anionGap(
              sodiumMmolPerL: 140,
              chlorideMmolPerL: -1,
              bicarbonateMmolPerL: 9),
          throwsA(isA<InvalidInputException>()));
      expect(
          () => Chemistry.anionGap(
              sodiumMmolPerL: 140,
              chlorideMmolPerL: 101,
              bicarbonateMmolPerL: 90),
          throwsA(isA<InvalidInputException>()));
      expect(
          () => Chemistry.anionGap(
              sodiumMmolPerL: 140,
              chlorideMmolPerL: 101,
              bicarbonateMmolPerL: 20,
              potassiumMmolPerL: 30),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('Albumin-corrected anion gap (Figge 1998)', () {
    test('MedCalc-Bench row 824: Na 138, Cl 102, HCO3 15, alb 2.6 -> 24.5', () {
      final ag = Chemistry.anionGap(
          sodiumMmolPerL: 138, chlorideMmolPerL: 102, bicarbonateMmolPerL: 15);
      expect(
          Chemistry.albuminCorrectedAnionGap(
              anionGap: ag, albumin: Albumin.gPerDl(2.6)),
          closeTo(24.5, 1e-9));
    });
    test('MedCalc-Bench row 822: Na 130, Cl 105, HCO3 27, alb 20 g/L -> 3.0',
        () {
      final ag = Chemistry.anionGap(
          sodiumMmolPerL: 130, chlorideMmolPerL: 105, bicarbonateMmolPerL: 27);
      expect(
          Chemistry.albuminCorrectedAnionGap(
              anionGap: ag, albumin: Albumin.gPerL(20)),
          closeTo(3.0, 1e-9));
    });
  });

  group('Corrected sodium for hyperglycaemia', () {
    test('Hillier, MedCalc-Bench row 381: Na 107, glucose 169 -> 108.656', () {
      expect(
          Chemistry.correctedSodium(
              sodiumMmolPerL: 107, glucose: Glucose.mgPerDl(169)),
          closeTo(108.656, 1e-6));
    });
    test('Hillier, MedCalc-Bench row 383: Na 116, glucose 1010 -> 137.84', () {
      expect(
          Chemistry.correctedSodium(
              sodiumMmolPerL: 116,
              glucose: Glucose.mgPerDl(1010),
              method: SodiumCorrection.hillier),
          closeTo(137.84, 1e-6));
    });
    test('Katz: Na 116, glucose 1010 -> 116 + 1.6 x 9.1 = 130.56', () {
      expect(
          Chemistry.correctedSodium(
              sodiumMmolPerL: 116,
              glucose: Glucose.mgPerDl(1010),
              method: SodiumCorrection.katz),
          closeTo(130.56, 1e-6));
    });
    test('glucose in mmol/L gives the same result', () {
      expect(
          Chemistry.correctedSodium(
              sodiumMmolPerL: 130, glucose: Glucose.mmolPerL(30)),
          closeTo(130 + 0.024 * (30 * 18.0156 - 100), 1e-9));
    });
    test('method citations', () {
      expect(SodiumCorrection.katz.citation, contains('Katz'));
      expect(SodiumCorrection.hillier.citation, contains('Hillier'));
    });
  });
}
