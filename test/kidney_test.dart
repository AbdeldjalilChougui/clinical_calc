// Reference values
// ----------------
// "MedCalc-Bench row N" refers to the MDCalc-derived worked examples published
// in MedCalc-Bench v1.0 (Khandekar et al., NeurIPS 2024 Datasets & Benchmarks,
// github.com/ncbi-nlp/MedCalc-Bench, datasets/test_data.csv). Each example was
// re-checked by hand against the equation in the original publication.
// "Derived" values were computed independently from the published equation
// (Python, double precision) to cover branches the external examples miss.
import 'package:clinical_calc/clinical_calc.dart';
import 'package:test/test.dart';

void main() {
  group('CKD-EPI 2021 creatinine (Inker 2021)', () {
    // Tolerance 0.001 mL/min/1.73 m2: the published examples carry 5 decimals.
    const tol = 1e-3;

    double egfr(num scr, num age, Sex sex) => Kidney.ckdEpi2021Creatinine(
          creatinine: Creatinine.mgPerDl(scr),
          ageYears: age,
          sex: sex,
        ).mlPerMinPer173m2;

    test('MedCalc-Bench row 23: F 51 y, 1.33 mg/dL -> 48.44101', () {
      expect(egfr(1.33, 51, Sex.female), closeTo(48.44101, tol));
    });
    test('MedCalc-Bench row 26: M 35 y, 1.35 mg/dL -> 70.21721', () {
      expect(egfr(1.35, 35, Sex.male), closeTo(70.21721, tol));
    });
    test('MedCalc-Bench row 35: F 33 y, 1.1 mg/dL -> 68.04278', () {
      expect(egfr(1.1, 33, Sex.female), closeTo(68.04278, tol));
    });
    test('MedCalc-Bench row 38: M 45 y, 1.9 mg/dL -> 43.78544', () {
      expect(egfr(1.9, 45, Sex.male), closeTo(43.78544, tol));
    });
    test('derived, below-kappa branch: F 40 y, 0.6 mg/dL -> 116.295', () {
      expect(egfr(0.6, 40, Sex.female), closeTo(116.2955, tol));
    });
    test('derived, below-kappa branch: M 30 y, 0.7 mg/dL -> 127.122', () {
      expect(egfr(0.7, 30, Sex.male), closeTo(127.1217, tol));
    });
    test('SI input gives the same result (106.08 umol/L == 1.2 mg/dL)', () {
      final r = Kidney.ckdEpi2021Creatinine(
        creatinine: Creatinine.umolPerL(106.08),
        ageYears: 60,
        sex: Sex.male,
      );
      expect(r.mlPerMinPer173m2, closeTo(69.2311, tol));
    });
    test('rejects age < 18 as outside validated range', () {
      expect(() => egfr(1.0, 17, Sex.male),
          throwsA(isA<OutOfValidatedRangeException>()));
    });
    test('rejects negative or absurd age', () {
      expect(
          () => egfr(1.0, -1, Sex.male), throwsA(isA<InvalidInputException>()));
      expect(() => egfr(1.0, 200, Sex.male),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('CKD-EPI 2021 creatinine-cystatin C (Inker 2021)', () {
    const tol = 1e-3;
    double egfr(num scr, num cys, num age, Sex sex) =>
        Kidney.ckdEpi2021CreatinineCystatinC(
          creatinine: Creatinine.mgPerDl(scr),
          cystatinC: CystatinC.mgPerL(cys),
          ageYears: age,
          sex: sex,
        ).mlPerMinPer173m2;

    test('derived: M 50 y, Scr 1.0, Scys 1.0 -> 88.144', () {
      expect(egfr(1.0, 1.0, 50, Sex.male), closeTo(88.1440, tol));
    });
    test('derived, both below thresholds: F 40 y, Scr 0.6, Scys 0.7', () {
      expect(egfr(0.6, 0.7, 40, Sex.female), closeTo(120.0799, tol));
    });
    test('derived, both above thresholds: F 70 y, Scr 1.5, Scys 1.8', () {
      expect(egfr(1.5, 1.8, 70, Sex.female), closeTo(34.7622, tol));
    });
    test('derived, mixed branches: M 65 y, Scr 0.8, Scys 1.2', () {
      expect(egfr(0.8, 1.2, 65, Sex.male), closeTo(77.6948, tol));
    });
    test('rejects age < 18', () {
      expect(() => egfr(1, 1, 12, Sex.female),
          throwsA(isA<OutOfValidatedRangeException>()));
    });
  });

  group('MDRD 4-variable IDMS-traceable (Levey 2006)', () {
    const tol = 1e-3;
    double egfr(num scr, num age, Sex sex, {bool black = false}) =>
        Kidney.mdrd4(
          creatinine: Creatinine.mgPerDl(scr),
          ageYears: age,
          sex: sex,
          black: black,
        ).mlPerMinPer173m2;

    test('MedCalc-Bench row 141: F 55 y, 2.25 mg/dL -> 22.5803', () {
      expect(egfr(2.25, 55, Sex.female), closeTo(22.5803, tol));
    });
    test('MedCalc-Bench row 142: M 73 y, 1.4 mg/dL -> 49.67659', () {
      expect(egfr(1.4, 73, Sex.male), closeTo(49.67659, tol));
    });
    test('MedCalc-Bench row 159: M 60 y, 2.8 mg/dL -> 23.2302', () {
      expect(egfr(2.8, 60, Sex.male), closeTo(23.2302, tol));
    });
    test('published race coefficient 1.212 is applied only when requested', () {
      expect(
          egfr(1.4, 73, Sex.male, black: true), closeTo(49.67659 * 1.212, tol));
    });
    test('rejects age < 18', () {
      expect(() => egfr(1, 10, Sex.male),
          throwsA(isA<OutOfValidatedRangeException>()));
    });
  });

  group('Cockcroft-Gault (Cockcroft & Gault 1976)', () {
    // Tolerance 0.01 mL/min: MedCalc-Bench converts cm to inches with
    // 0.393701 instead of the exact 1/2.54.
    const tol = 0.01;

    test('MedCalc-Bench row 2: M 83 y, 67.2 kg, 1.4 mg/dL -> 38.0', () {
      final r = Kidney.cockcroftGault(
        creatinine: Creatinine.mgPerDl(1.4),
        ageYears: 83,
        sex: Sex.male,
        weight: Weight.kg(67.2),
      );
      expect(r, closeTo(38.0, tol));
    });
    test('MedCalc-Bench row 5, ideal weight: F 45 y, 58 kg, 156 cm, 0.7 mg/dL',
        () {
      final r = Kidney.cockcroftGault(
        creatinine: Creatinine.mgPerDl(0.7),
        ageYears: 45,
        sex: Sex.female,
        weight: Weight.kg(58),
        height: Height.cm(156),
        weightBasis: CockcroftGaultWeight.ideal,
      );
      expect(r, closeTo(78.12231, tol));
    });
    test('MedCalc-Bench row 4, adjusted weight: F 42 y, 105 kg, 160 cm', () {
      final r = Kidney.cockcroftGault(
        creatinine: Creatinine.mgPerDl(0.8),
        ageYears: 42,
        sex: Sex.female,
        weight: Weight.kg(105),
        height: Height.cm(160),
        weightBasis: CockcroftGaultWeight.adjusted,
      );
      expect(r, closeTo(106.19185, tol));
    });
    test('female factor 0.85', () {
      double cg(Sex s) => Kidney.cockcroftGault(
            creatinine: Creatinine.mgPerDl(1),
            ageYears: 40,
            sex: s,
            weight: Weight.kg(72),
          );
      expect(cg(Sex.male), closeTo(100, 1e-9));
      expect(cg(Sex.female), closeTo(85, 1e-9));
    });
    test('ideal/adjusted basis without height is rejected', () {
      expect(
        () => Kidney.cockcroftGault(
          creatinine: Creatinine.mgPerDl(1),
          ageYears: 40,
          sex: Sex.male,
          weight: Weight.kg(80),
          weightBasis: CockcroftGaultWeight.ideal,
        ),
        throwsA(isA<InvalidInputException>()),
      );
    });
    test('rejects age < 18 and age >= 140', () {
      expect(
        () => Kidney.cockcroftGault(
          creatinine: Creatinine.mgPerDl(1),
          ageYears: 15,
          sex: Sex.male,
          weight: Weight.kg(60),
        ),
        throwsA(isA<OutOfValidatedRangeException>()),
      );
      expect(
        () => Kidney.cockcroftGault(
          creatinine: Creatinine.mgPerDl(1),
          ageYears: 140,
          sex: Sex.male,
          weight: Weight.kg(60),
        ),
        throwsA(isA<ClinicalCalcException>()),
      );
    });
  });

  group('Bedside Schwartz (Schwartz 2009)', () {
    test('0.413 x 120 cm / 0.5 mg/dL = 99.12', () {
      final r = Kidney.bedsideSchwartz(
        height: Height.cm(120),
        creatinine: Creatinine.mgPerDl(0.5),
      );
      expect(r.mlPerMinPer173m2, closeTo(99.12, 1e-9));
    });
    test('0.413 x 95 cm / 0.4 mg/dL = 98.0875', () {
      final r = Kidney.bedsideSchwartz(
        height: Height.cm(95),
        creatinine: Creatinine.mgPerDl(0.4),
      );
      expect(r.mlPerMinPer173m2, closeTo(98.0875, 1e-9));
    });
  });

  group('IndexedGfr', () {
    test('de-index to absolute mL/min: 90 x 1.9 / 1.73', () {
      expect(IndexedGfr(90).deindex(1.9), closeTo(98.8439, 1e-4));
    });
    test('de-index rejects non-positive BSA', () {
      expect(() => IndexedGfr(90).deindex(0),
          throwsA(isA<InvalidInputException>()));
    });
    test('rejects negative values', () {
      expect(() => IndexedGfr(-1), throwsA(isA<InvalidInputException>()));
    });
    test('exposes its KDIGO category', () {
      expect(IndexedGfr(50).kdigoCategory, KdigoGfrCategory.g3a);
    });
  });

  group('KDIGO 2012 GFR categories', () {
    KdigoGfrCategory cat(double v) => KdigoGfrCategory.fromGfr(IndexedGfr(v));
    test('boundaries', () {
      expect(cat(120), KdigoGfrCategory.g1);
      expect(cat(90), KdigoGfrCategory.g1);
      expect(cat(89.9), KdigoGfrCategory.g2);
      expect(cat(60), KdigoGfrCategory.g2);
      expect(cat(59.9), KdigoGfrCategory.g3a);
      expect(cat(45), KdigoGfrCategory.g3a);
      expect(cat(44.9), KdigoGfrCategory.g3b);
      expect(cat(30), KdigoGfrCategory.g3b);
      expect(cat(29.9), KdigoGfrCategory.g4);
      expect(cat(15), KdigoGfrCategory.g4);
      expect(cat(14.9), KdigoGfrCategory.g5);
      expect(cat(0), KdigoGfrCategory.g5);
    });
    test('labels', () {
      expect(KdigoGfrCategory.g3a.label, 'G3a');
      expect(KdigoGfrCategory.g1.description, 'Normal or high');
      expect(KdigoGfrCategory.g5.description, 'Kidney failure');
    });
  });
}
