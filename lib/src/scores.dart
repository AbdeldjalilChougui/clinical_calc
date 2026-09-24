import 'errors.dart';
import 'sex.dart';
import 'units.dart';

/// Ascites grading for [ChildPugh].
enum Ascites {
  /// Absent (1 point).
  none,

  /// Slight / mild, or controlled with diuretics (2 points).
  slight,

  /// Moderate to severe, or refractory (3 points).
  moderateToSevere,
}

/// Hepatic encephalopathy grading (West Haven) for [ChildPugh].
enum HepaticEncephalopathy {
  /// None (1 point).
  none,

  /// Grade 1-2, or suppressed with medication (2 points).
  grade1to2,

  /// Grade 3-4, or refractory (3 points).
  grade3to4,
}

/// Child-Pugh class.
enum ChildPughClass {
  /// 5-6 points.
  a,

  /// 7-9 points.
  b,

  /// 10-15 points.
  c;

  /// `A`, `B` or `C`.
  String get label => name.toUpperCase();
}

/// Result of [ChildPugh.score], with the points of each component.
final class ChildPughResult {
  /// Creates a result. Normally obtained from [ChildPugh.score].
  const ChildPughResult({
    required this.bilirubinPoints,
    required this.albuminPoints,
    required this.inrPoints,
    required this.ascitesPoints,
    required this.encephalopathyPoints,
  });

  /// Points for total bilirubin (1-3).
  final int bilirubinPoints;

  /// Points for serum albumin (1-3).
  final int albuminPoints;

  /// Points for INR (1-3).
  final int inrPoints;

  /// Points for ascites (1-3).
  final int ascitesPoints;

  /// Points for hepatic encephalopathy (1-3).
  final int encephalopathyPoints;

  /// Total score, 5 to 15.
  int get points =>
      bilirubinPoints +
      albuminPoints +
      inrPoints +
      ascitesPoints +
      encephalopathyPoints;

  /// Class A (5-6), B (7-9) or C (10-15).
  ChildPughClass get childPughClass {
    final p = points;
    if (p <= 6) return ChildPughClass.a;
    if (p <= 9) return ChildPughClass.b;
    return ChildPughClass.c;
  }

  @override
  String toString() =>
      'ChildPughResult($points, class ${childPughClass.label})';
}

/// Child-Pugh score for cirrhosis.
///
/// Child CG, Turcotte JG. Surgery and portal hypertension. In: Child CG, ed.
/// The Liver and Portal Hypertension. Philadelphia: Saunders; 1964:50-64.
/// Pugh RN, Murray-Lyon IM, Dawson JL, Pietroni MC, Williams R. Transection
/// of the oesophagus for bleeding oesophageal varices. Br J Surg
/// 1973;60(8):646-649.
///
/// Pugh graded prothrombin time in seconds of prolongation; this
/// implementation uses the widely adopted INR equivalents
/// (< 1.7, 1.7-2.3, > 2.3). Bilirubin thresholds are for non-cholestatic
/// disease (< 2, 2-3, > 3 mg/dL); albumin thresholds are > 3.5, 2.8-3.5,
/// < 2.8 g/dL.
abstract final class ChildPugh {
  /// Scores the five components. [inr] must be > 0 and <= 20.
  static ChildPughResult score({
    required Bilirubin bilirubin,
    required Albumin albumin,
    required double inr,
    required Ascites ascites,
    required HepaticEncephalopathy encephalopathy,
  }) {
    final i = _round(checkRange('inr', inr, min: 0, max: 20));
    final bili = _round(bilirubin.mgPerDl);
    final alb = _round(albumin.gPerDl);
    return ChildPughResult(
      bilirubinPoints: bili < 2 ? 1 : (bili <= 3 ? 2 : 3),
      albuminPoints: alb > 3.5 ? 1 : (alb >= 2.8 ? 2 : 3),
      inrPoints: i < 1.7 ? 1 : (i <= 2.3 ? 2 : 3),
      ascitesPoints: ascites.index + 1,
      encephalopathyPoints: encephalopathy.index + 1,
    );
  }

  // Unit conversion leaves noise such as 51.3 / 17.1 = 3.0000000000000004;
  // round to 1e-6 so values on a threshold fall on the documented side.
  static double _round(double v) => (v * 1e6).roundToDouble() / 1e6;
}

/// CHA2DS2-VASc stroke-risk score for atrial fibrillation (0-9).
///
/// Lip GY, Nieuwlaat R, Pisters R, Lane DA, Crijns HJ. Refining clinical risk
/// stratification for predicting stroke and thromboembolism in atrial
/// fibrillation using a novel risk factor-based approach: the Euro Heart
/// Survey on atrial fibrillation. Chest 2010;137(2):263-272.
///
/// Only the score is returned; its interpretation and any treatment decision
/// belong to current guidelines and the clinician.
abstract final class Cha2ds2Vasc {
  /// C (1), H (1), A2 age >= 75 (2), D (1), S2 stroke/TIA/thromboembolism
  /// (2), V vascular disease (1), A age 65-74 (1), Sc female sex (1).
  static int score({
    required bool congestiveHeartFailure,
    required bool hypertension,
    required num ageYears,
    required bool diabetes,
    required bool strokeTiaOrThromboembolism,
    required bool vascularDisease,
    required Sex sex,
  }) {
    final age = checkAge(ageYears);
    return (congestiveHeartFailure ? 1 : 0) +
        (hypertension ? 1 : 0) +
        (age >= 75 ? 2 : (age >= 65 ? 1 : 0)) +
        (diabetes ? 1 : 0) +
        (strokeTiaOrThromboembolism ? 2 : 0) +
        (vascularDisease ? 1 : 0) +
        (sex == Sex.female ? 1 : 0);
  }
}

/// HAS-BLED major-bleeding risk score (0-9).
///
/// Pisters R, Lane DA, Nieuwlaat R, de Vos CB, Crijns HJ, Lip GY. A novel
/// user-friendly score (HAS-BLED) to assess 1-year risk of major bleeding in
/// patients with atrial fibrillation: the Euro Heart Survey.
/// Chest 2010;138(5):1093-1100.
///
/// Only the score is returned; no recommendation is made.
abstract final class HasBled {
  /// One point each: H uncontrolled hypertension (systolic > 160 mmHg),
  /// A abnormal renal function, A abnormal liver function, S stroke,
  /// B bleeding history or predisposition, L labile INR, E elderly
  /// (age > 65), D drugs predisposing to bleeding (antiplatelets, NSAIDs),
  /// D alcohol use (>= 8 drinks per week).
  static int score({
    required bool uncontrolledHypertension,
    required bool abnormalRenalFunction,
    required bool abnormalLiverFunction,
    required bool stroke,
    required bool bleedingHistoryOrPredisposition,
    required bool labileInr,
    required num ageYears,
    required bool bleedingPredisposingDrugs,
    required int alcoholDrinksPerWeek,
  }) {
    final age = checkAge(ageYears);
    final drinks = checkRange('alcoholDrinksPerWeek', alcoholDrinksPerWeek,
        min: 0, max: 500, minExclusive: false);
    return (uncontrolledHypertension ? 1 : 0) +
        (abnormalRenalFunction ? 1 : 0) +
        (abnormalLiverFunction ? 1 : 0) +
        (stroke ? 1 : 0) +
        (bleedingHistoryOrPredisposition ? 1 : 0) +
        (labileInr ? 1 : 0) +
        (age > 65 ? 1 : 0) +
        (bleedingPredisposingDrugs ? 1 : 0) +
        (drinks >= 8 ? 1 : 0);
  }
}
