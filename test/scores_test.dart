// See test/kidney_test.dart for what "MedCalc-Bench row N" means.
// Scores are integers, so every comparison is exact.
import 'package:clinical_calc/clinical_calc.dart';
import 'package:test/test.dart';

void main() {
  group('Child-Pugh (Pugh 1973)', () {
    ChildPughResult cp(double bili, double alb, double inr, Ascites a,
            {HepaticEncephalopathy he = HepaticEncephalopathy.none}) =>
        ChildPugh.score(
          bilirubin: Bilirubin.mgPerDl(bili),
          albumin: Albumin.gPerDl(alb),
          inr: inr,
          ascites: a,
          encephalopathy: he,
        );

    test('MedCalc-Bench row 201 -> 9 (class B)', () {
      final r = cp(2.5, 2.8, 1.52, Ascites.moderateToSevere);
      expect(r.points, 9);
      expect(r.childPughClass, ChildPughClass.b);
    });
    test('MedCalc-Bench row 202 -> 7', () {
      expect(cp(4.3, 4.1, 1.43, Ascites.none).points, 7);
    });
    test('MedCalc-Bench row 203 -> 6 (class A)', () {
      final r = cp(0.8, 2.8, 1.51, Ascites.none);
      expect(r.points, 6);
      expect(r.childPughClass, ChildPughClass.a);
    });
    test('MedCalc-Bench row 204 -> 10 (class C)', () {
      final r = cp(3.6, 2.4, 2.2, Ascites.none);
      expect(r.points, 10);
      expect(r.childPughClass, ChildPughClass.c);
    });
    test('MedCalc-Bench row 208 -> 10', () {
      expect(cp(2.97, 3.0, 2.2, Ascites.moderateToSevere).points, 10);
    });
    test('MedCalc-Bench row 209 -> 12', () {
      expect(cp(3.1, 2.2, 1.87, Ascites.moderateToSevere).points, 12);
    });
    test('minimum 5 and maximum 15', () {
      expect(cp(1, 4, 1, Ascites.none).points, 5);
      expect(
          cp(5, 2, 3, Ascites.moderateToSevere,
                  he: HepaticEncephalopathy.grade3to4)
              .points,
          15);
    });
    test('component boundaries', () {
      // Bilirubin: <2 -> 1, 2-3 -> 2, >3 -> 3 (mg/dL).
      expect(cp(1.99, 4, 1, Ascites.none).bilirubinPoints, 1);
      expect(cp(2, 4, 1, Ascites.none).bilirubinPoints, 2);
      expect(cp(3, 4, 1, Ascites.none).bilirubinPoints, 2);
      expect(cp(3.01, 4, 1, Ascites.none).bilirubinPoints, 3);
      // Albumin: >3.5 -> 1, 2.8-3.5 -> 2, <2.8 -> 3 (g/dL).
      expect(cp(1, 3.51, 1, Ascites.none).albuminPoints, 1);
      expect(cp(1, 3.5, 1, Ascites.none).albuminPoints, 2);
      expect(cp(1, 2.8, 1, Ascites.none).albuminPoints, 2);
      expect(cp(1, 2.79, 1, Ascites.none).albuminPoints, 3);
      // INR: <1.7 -> 1, 1.7-2.3 -> 2, >2.3 -> 3.
      expect(cp(1, 4, 1.69, Ascites.none).inrPoints, 1);
      expect(cp(1, 4, 1.7, Ascites.none).inrPoints, 2);
      expect(cp(1, 4, 2.3, Ascites.none).inrPoints, 2);
      expect(cp(1, 4, 2.31, Ascites.none).inrPoints, 3);
    });
    test('SI bilirubin at the exact 51.3 umol/L boundary scores 2', () {
      final r = ChildPugh.score(
        bilirubin: Bilirubin.umolPerL(51.3),
        albumin: Albumin.gPerL(40),
        inr: 1,
        ascites: Ascites.none,
        encephalopathy: HepaticEncephalopathy.none,
      );
      expect(r.bilirubinPoints, 2);
    });
    test('rejects non-physiological INR', () {
      expect(() => cp(1, 4, 0, Ascites.none),
          throwsA(isA<InvalidInputException>()));
      expect(() => cp(1, 4, 30, Ascites.none),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('CHA2DS2-VASc (Lip 2010)', () {
    int score({
      required int age,
      required Sex sex,
      bool chf = false,
      bool htn = false,
      bool dm = false,
      bool stroke = false,
      bool vasc = false,
    }) =>
        Cha2ds2Vasc.score(
          congestiveHeartFailure: chf,
          hypertension: htn,
          ageYears: age,
          diabetes: dm,
          strokeTiaOrThromboembolism: stroke,
          vascularDisease: vasc,
          sex: sex,
        );

    test('MedCalc-Bench row 41: F 38 y, diabetes -> 2', () {
      expect(score(age: 38, sex: Sex.female, dm: true), 2);
    });
    test('MedCalc-Bench row 42: F 68 y, HTN, stroke -> 5', () {
      expect(score(age: 68, sex: Sex.female, htn: true, stroke: true), 5);
    });
    test('MedCalc-Bench row 43: F 86 y, HTN -> 4', () {
      expect(score(age: 86, sex: Sex.female, htn: true), 4);
    });
    test('MedCalc-Bench row 48: M 75 y, vascular disease -> 3', () {
      expect(score(age: 75, sex: Sex.male, vasc: true), 3);
    });
    test('MedCalc-Bench row 54: M 64 y -> 0', () {
      expect(score(age: 64, sex: Sex.male), 0);
    });
    test('MedCalc-Bench row 59: M 42 y, CHF, vascular, DM, HTN -> 4', () {
      expect(
          score(
              age: 42,
              sex: Sex.male,
              chf: true,
              vasc: true,
              dm: true,
              htn: true),
          4);
    });
    test('age bands: 65 -> 1, 74 -> 1, 75 -> 2', () {
      expect(score(age: 65, sex: Sex.male), 1);
      expect(score(age: 74, sex: Sex.male), 1);
      expect(score(age: 75, sex: Sex.male), 2);
    });
    test('maximum is 9', () {
      expect(
          score(
              age: 80,
              sex: Sex.female,
              chf: true,
              htn: true,
              dm: true,
              stroke: true,
              vasc: true),
          9);
    });
    test('rejects invalid age', () {
      expect(() => score(age: -1, sex: Sex.male),
          throwsA(isA<InvalidInputException>()));
    });
  });

  group('HAS-BLED (Pisters 2010)', () {
    int score({
      required int age,
      bool htn = false,
      bool renal = false,
      bool liver = false,
      bool stroke = false,
      bool bleeding = false,
      bool inr = false,
      bool drugs = false,
      int drinks = 0,
    }) =>
        HasBled.score(
          uncontrolledHypertension: htn,
          abnormalRenalFunction: renal,
          abnormalLiverFunction: liver,
          stroke: stroke,
          bleedingHistoryOrPredisposition: bleeding,
          labileInr: inr,
          ageYears: age,
          bleedingPredisposingDrugs: drugs,
          alcoholDrinksPerWeek: drinks,
        );

    test('MedCalc-Bench row 361 -> 5', () {
      expect(
          score(
              age: 72,
              renal: true,
              htn: true,
              drugs: true,
              drinks: 4,
              bleeding: true),
          5);
    });
    test('MedCalc-Bench row 363: 8 drinks/week counts -> 3', () {
      expect(score(age: 54, liver: true, bleeding: true, drinks: 8), 3);
    });
    test('MedCalc-Bench row 373: age 65 is not elderly -> 2', () {
      expect(score(age: 65, liver: true, drinks: 35), 2);
    });
    test('MedCalc-Bench row 369: labile INR, age 70, 10 drinks -> 3', () {
      expect(score(age: 70, inr: true, drinks: 10), 3);
    });
    test('MedCalc-Bench row 366: 6 drinks/week does not count -> 2', () {
      expect(score(age: 61, renal: true, inr: true, drinks: 6), 2);
    });
    test('maximum is 9', () {
      expect(
          score(
              age: 80,
              htn: true,
              renal: true,
              liver: true,
              stroke: true,
              bleeding: true,
              inr: true,
              drugs: true,
              drinks: 20),
          9);
    });
    test('rejects negative drink count', () {
      expect(() => score(age: 50, drinks: -1),
          throwsA(isA<InvalidInputException>()));
    });
  });
}
