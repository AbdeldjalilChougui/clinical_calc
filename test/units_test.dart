import 'package:clinical_calc/clinical_calc.dart';
import 'package:test/test.dart';

void main() {
  group('Creatinine (factor 88.4 umol/L per mg/dL)', () {
    test('mg/dL to umol/L', () {
      expect(Creatinine.mgPerDl(1.0).umolPerL, closeTo(88.4, 1e-9));
      expect(Creatinine.mgPerDl(1.2).umolPerL, closeTo(106.08, 1e-9));
    });

    test('umol/L to mg/dL', () {
      expect(Creatinine.umolPerL(88.4).mgPerDl, closeTo(1.0, 1e-12));
      expect(Creatinine.umolPerL(176.8).mgPerDl, closeTo(2.0, 1e-12));
    });

    test('mg/L (10 mg/L = 1 mg/dL)', () {
      expect(Creatinine.mgPerL(12).mgPerDl, closeTo(1.2, 1e-12));
      expect(Creatinine.mgPerDl(0.9).mgPerL, closeTo(9, 1e-12));
    });

    test('rejects zero, negative, NaN and non-physiological values', () {
      expect(
          () => Creatinine.mgPerDl(0), throwsA(isA<InvalidInputException>()));
      expect(
          () => Creatinine.mgPerDl(-1), throwsA(isA<InvalidInputException>()));
      expect(() => Creatinine.mgPerDl(double.nan),
          throwsA(isA<InvalidInputException>()));
      expect(() => Creatinine.mgPerDl(double.infinity),
          throwsA(isA<InvalidInputException>()));
      expect(
          () => Creatinine.mgPerDl(45), throwsA(isA<InvalidInputException>()));
      expect(() => Creatinine.umolPerL(5000),
          throwsA(isA<InvalidInputException>()));
    });

    test('error carries parameter name and value', () {
      try {
        Creatinine.mgPerDl(-2);
        fail('expected exception');
      } on InvalidInputException catch (e) {
        expect(e.parameter, 'creatinine');
        expect(e.value, -2);
        expect(e.toString(), contains('creatinine'));
      }
    });

    test('value equality', () {
      expect(Creatinine.mgPerDl(1), Creatinine.umolPerL(88.4));
      expect(
          Creatinine.mgPerDl(1).hashCode, Creatinine.umolPerL(88.4).hashCode);
    });
  });

  group('CystatinC', () {
    test('mg/L round-trip', () {
      expect(CystatinC.mgPerL(1.1).mgPerL, 1.1);
    });
    test('rejects invalid values', () {
      expect(() => CystatinC.mgPerL(0), throwsA(isA<InvalidInputException>()));
      expect(() => CystatinC.mgPerL(25), throwsA(isA<InvalidInputException>()));
    });
  });

  group('Glucose (molar mass 180.156 g/mol)', () {
    test('mg/dL to mmol/L', () {
      expect(Glucose.mgPerDl(180.156).mmolPerL, closeTo(10.0, 1e-9));
      expect(Glucose.mgPerDl(100).mmolPerL, closeTo(5.5508, 1e-4));
    });
    test('mmol/L to mg/dL', () {
      expect(Glucose.mmolPerL(5.5).mgPerDl, closeTo(99.086, 1e-3));
    });
    test('rejects invalid values', () {
      expect(() => Glucose.mgPerDl(-5), throwsA(isA<InvalidInputException>()));
      expect(
          () => Glucose.mgPerDl(5000), throwsA(isA<InvalidInputException>()));
    });
  });

  group('Urea / BUN', () {
    test('BUN mg/dL to urea mmol/L (divide by 2.8014)', () {
      expect(Urea.bunMgPerDl(28.014).mmolPerL, closeTo(10.0, 1e-9));
    });
    test('urea mmol/L to BUN mg/dL', () {
      expect(Urea.mmolPerL(7.0).bunMgPerDl, closeTo(19.61, 0.01));
    });
    test('urea mass concentration (60.06 g/mol)', () {
      expect(Urea.gPerL(0.6006).mmolPerL, closeTo(10.0, 1e-9));
      expect(Urea.mmolPerL(10).gPerL, closeTo(0.6006, 1e-9));
      expect(Urea.mmolPerL(10).mgPerDl, closeTo(60.06, 1e-9));
      expect(Urea.mgPerDl(60.06).mmolPerL, closeTo(10.0, 1e-9));
    });
    test('BUN 10 mg/dL equals urea 21.44 mg/dL', () {
      expect(Urea.bunMgPerDl(10).mgPerDl, closeTo(21.44, 0.01));
    });
    test('rejects invalid values', () {
      expect(() => Urea.mmolPerL(-1), throwsA(isA<InvalidInputException>()));
    });
  });

  group('Height', () {
    test('cm, m, inches, feet+inches', () {
      expect(Height.m(1.75).cm, closeTo(175, 1e-9));
      expect(Height.inches(70).cm, closeTo(177.8, 1e-9));
      expect(Height.feetInches(5, 10).cm, closeTo(177.8, 1e-9));
      expect(Height.cm(152.4).inches, closeTo(60, 1e-9));
      expect(Height.cm(180).m, closeTo(1.8, 1e-12));
    });
    test('rejects invalid values', () {
      expect(() => Height.cm(0), throwsA(isA<InvalidInputException>()));
      expect(() => Height.cm(-170), throwsA(isA<InvalidInputException>()));
      expect(() => Height.cm(320), throwsA(isA<InvalidInputException>()));
      expect(() => Height.feetInches(5, -1),
          throwsA(isA<InvalidInputException>()));
      expect(() => Height.feetInches(5, 12),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('Weight', () {
    test('kg, lb, g', () {
      expect(Weight.lb(154).kg, closeTo(69.853, 1e-3));
      expect(Weight.kg(1).lb, closeTo(2.20462, 1e-5));
      expect(Weight.g(3500).kg, closeTo(3.5, 1e-12));
      expect(Weight.kg(3.5).g, closeTo(3500, 1e-9));
    });
    test('rejects invalid values', () {
      expect(() => Weight.kg(0), throwsA(isA<InvalidInputException>()));
      expect(() => Weight.kg(-3), throwsA(isA<InvalidInputException>()));
      expect(() => Weight.kg(800), throwsA(isA<InvalidInputException>()));
    });
  });

  group('Calcium (40.078 g/mol)', () {
    test('mg/dL <-> mmol/L', () {
      expect(Calcium.mmolPerL(2.5).mgPerDl, closeTo(10.02, 0.001));
      expect(Calcium.mgPerDl(10.0195).mmolPerL, closeTo(2.5, 1e-4));
    });
    test('rejects invalid values', () {
      expect(() => Calcium.mgPerDl(0), throwsA(isA<InvalidInputException>()));
      expect(() => Calcium.mgPerDl(40), throwsA(isA<InvalidInputException>()));
    });
  });

  group('Albumin', () {
    test('g/dL <-> g/L', () {
      expect(Albumin.gPerL(35).gPerDl, closeTo(3.5, 1e-12));
      expect(Albumin.gPerDl(4).gPerL, closeTo(40, 1e-12));
    });
    test('rejects invalid values', () {
      expect(() => Albumin.gPerDl(-1), throwsA(isA<InvalidInputException>()));
      expect(() => Albumin.gPerDl(12), throwsA(isA<InvalidInputException>()));
    });
  });

  group('Bilirubin (17.1 umol/L per mg/dL)', () {
    test('mg/dL <-> umol/L', () {
      expect(Bilirubin.mgPerDl(2).umolPerL, closeTo(34.2, 1e-9));
      expect(Bilirubin.umolPerL(51.3).mgPerDl, closeTo(3.0, 1e-9));
    });
    test('zero is allowed, negative is not', () {
      expect(Bilirubin.mgPerDl(0).mgPerDl, 0);
      expect(
          () => Bilirubin.mgPerDl(-0.1), throwsA(isA<InvalidInputException>()));
    });
  });
}
