// See test/kidney_test.dart for what "MedCalc-Bench row N" and "derived" mean.
import 'package:clinical_calc/clinical_calc.dart';
import 'package:test/test.dart';

void main() {
  group('BSA', () {
    // Tolerance 1e-4 m2 against 5-decimal published values;
    // 1e-6 m2 for values derived from the formula.
    test('Mosteller, MedCalc-Bench row 741: 176.1 cm, 77.1 kg -> 1.94203', () {
      expect(BodySize.bsaMosteller(Height.cm(176.1), Weight.kg(77.1)),
          closeTo(1.94203, 1e-4));
    });
    test('Mosteller, MedCalc-Bench row 742: 153 cm, 53 kg -> 1.50083', () {
      expect(BodySize.bsaMosteller(Height.cm(153), Weight.kg(53)),
          closeTo(1.50083, 1e-4));
    });

    final h = Height.cm(170);
    final w = Weight.kg(70);
    test('derived, 170 cm / 70 kg, every formula', () {
      expect(BodySize.bsaMosteller(h, w), closeTo(1.818119, 1e-6));
      expect(BodySize.bsaDuBois(h, w), closeTo(1.809708, 1e-6));
      expect(BodySize.bsaHaycock(h, w), closeTo(1.825677, 1e-6));
      expect(BodySize.bsaGehanGeorge(h, w), closeTo(1.831289, 1e-6));
      expect(BodySize.bsaBoyd(h, w), closeTo(1.834670, 1e-6));
    });
    test('derived, child 100 cm / 15 kg, every formula', () {
      final hc = Height.cm(100);
      final wc = Weight.kg(15);
      expect(BodySize.bsaMosteller(hc, wc), closeTo(0.645497, 1e-6));
      expect(BodySize.bsaDuBois(hc, wc), closeTo(0.640037, 1e-6));
      expect(BodySize.bsaHaycock(hc, wc), closeTo(0.646074, 1e-6));
      expect(BodySize.bsaGehanGeorge(hc, wc), closeTo(0.662457, 1e-6));
      expect(BodySize.bsaBoyd(hc, wc), closeTo(0.661476, 1e-6));
    });
    test('bsa() dispatches on BsaFormula', () {
      for (final f in BsaFormula.values) {
        expect(BodySize.bsa(h, w, formula: f), greaterThan(1.8));
      }
      expect(BodySize.bsa(h, w), BodySize.bsaMosteller(h, w));
      expect(
          BodySize.bsa(h, w, formula: BsaFormula.boyd), BodySize.bsaBoyd(h, w));
    });
    test('BsaFormula carries a citation', () {
      expect(BsaFormula.mosteller.citation, contains('Mosteller'));
      expect(BsaFormula.duBois.citation, contains('1916'));
    });
  });

  group('BMI (WHO)', () {
    test('MedCalc-Bench row 81: 159 cm, 70 kg -> 27.68878', () {
      expect(
          BodySize.bmi(Height.cm(159), Weight.kg(70)), closeTo(27.68878, 1e-4));
    });
    test('MedCalc-Bench row 93: 183 cm, 105 kg -> 31.35358', () {
      expect(BodySize.bmi(Height.cm(183), Weight.kg(105)),
          closeTo(31.35358, 1e-4));
    });
    test('categories and boundaries', () {
      expect(BmiCategory.fromBmi(18.49), BmiCategory.underweight);
      expect(BmiCategory.fromBmi(18.5), BmiCategory.normal);
      expect(BmiCategory.fromBmi(24.99), BmiCategory.normal);
      expect(BmiCategory.fromBmi(25), BmiCategory.overweight);
      expect(BmiCategory.fromBmi(30), BmiCategory.obesityClass1);
      expect(BmiCategory.fromBmi(35), BmiCategory.obesityClass2);
      expect(BmiCategory.fromBmi(40), BmiCategory.obesityClass3);
      expect(BmiCategory.fromBmi(55), BmiCategory.obesityClass3);
    });
    test('MedCalc-Bench row 99: 180 cm / 60 kg -> 18.51852 is normal', () {
      final bmi = BodySize.bmi(Height.cm(180), Weight.kg(60));
      expect(bmi, closeTo(18.51852, 1e-4));
      expect(BmiCategory.fromBmi(bmi), BmiCategory.normal);
    });
    test('rejects non-finite or non-positive BMI', () {
      expect(
          () => BmiCategory.fromBmi(0), throwsA(isA<InvalidInputException>()));
      expect(() => BmiCategory.fromBmi(double.nan),
          throwsA(isA<InvalidInputException>()));
    });
    test('label', () {
      expect(BmiCategory.obesityClass2.label, 'Obesity class II');
    });
  });

  group('Ideal body weight, Devine 1974', () {
    // Tolerance 1e-3 kg: MedCalc-Bench uses 0.393701 in/cm.
    test('MedCalc-Bench row 161: male 158 cm -> 55.07095 kg', () {
      expect(BodySize.idealBodyWeight(Height.cm(158), Sex.male).kg,
          closeTo(55.07095, 1e-3));
    });
    test('MedCalc-Bench row 170: female 162 cm -> 54.19299 kg', () {
      expect(BodySize.idealBodyWeight(Height.cm(162), Sex.female).kg,
          closeTo(54.19299, 1e-3));
    });
    test('exactly 60 inches gives the base weight', () {
      expect(BodySize.idealBodyWeight(Height.inches(60), Sex.male).kg,
          closeTo(50, 1e-9));
      expect(BodySize.idealBodyWeight(Height.inches(60), Sex.female).kg,
          closeTo(45.5, 1e-9));
    });
    test('below 60 inches is outside the validated range', () {
      expect(() => BodySize.idealBodyWeight(Height.cm(150), Sex.male),
          throwsA(isA<OutOfValidatedRangeException>()));
    });
  });

  group('Adjusted body weight', () {
    test('MedCalc-Bench row 761: F 168 cm, 80 kg -> 67.77564', () {
      final ibw = BodySize.idealBodyWeight(Height.cm(168), Sex.female);
      expect(BodySize.adjustedBodyWeight(actual: Weight.kg(80), ideal: ibw).kg,
          closeTo(67.77564, 1e-3));
    });
    test('MedCalc-Bench row 763: F 157 cm, 78.8 kg -> 61.31926', () {
      final ibw = BodySize.idealBodyWeight(Height.cm(157), Sex.female);
      expect(
          BodySize.adjustedBodyWeight(actual: Weight.kg(78.8), ideal: ibw).kg,
          closeTo(61.31926, 1e-3));
    });
    test('custom factor', () {
      expect(
        BodySize.adjustedBodyWeight(
          actual: Weight.kg(100),
          ideal: Weight.kg(60),
          factor: 0.3,
        ).kg,
        closeTo(72, 1e-9),
      );
    });
    test('factor must be in [0, 1]', () {
      expect(
        () => BodySize.adjustedBodyWeight(
            actual: Weight.kg(100), ideal: Weight.kg(60), factor: 1.5),
        throwsA(isA<InvalidInputException>()),
      );
    });
  });

  group('Lean body weight, Janmahasatian 2005', () {
    test('derived: male 180 cm, 100 kg -> 69.4555 kg', () {
      expect(
          BodySize.leanBodyWeight(Height.cm(180), Weight.kg(100), Sex.male).kg,
          closeTo(69.455544, 1e-5));
    });
    test('derived: female 165 cm, 70 kg -> 43.1058 kg', () {
      expect(
          BodySize.leanBodyWeight(Height.cm(165), Weight.kg(70), Sex.female).kg,
          closeTo(43.105838, 1e-5));
    });
  });
}
