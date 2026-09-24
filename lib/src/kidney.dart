import 'dart:math' as math;

import 'body_size.dart';
import 'errors.dart';
import 'sex.dart';
import 'units.dart';

/// A glomerular filtration rate indexed to 1.73 m2 of body surface area
/// (mL/min/1.73 m2), as returned by CKD-EPI, MDRD and Schwartz.
///
/// Keeping it a distinct type prevents mixing it up with an absolute
/// clearance in mL/min (for example Cockcroft-Gault).
final class IndexedGfr {
  /// Wraps a value in mL/min/1.73 m2. Must be finite and >= 0.
  IndexedGfr(num mlPerMinPer173m2)
      : mlPerMinPer173m2 = checkNonNegative('gfr', mlPerMinPer173m2);

  /// Value in mL/min/1.73 m2.
  final double mlPerMinPer173m2;

  /// De-indexes to an absolute GFR in mL/min for a patient with the given
  /// body surface area: `value x bsa / 1.73`.
  double deindex(double bsaM2) =>
      mlPerMinPer173m2 * checkPositive('bsaM2', bsaM2) / 1.73;

  /// KDIGO 2012 GFR category for this value.
  KdigoGfrCategory get kdigoCategory => KdigoGfrCategory.fromGfr(this);

  @override
  bool operator ==(Object other) =>
      other is IndexedGfr && other.mlPerMinPer173m2 == mlPerMinPer173m2;

  @override
  int get hashCode => Object.hash(IndexedGfr, mlPerMinPer173m2);

  @override
  String toString() =>
      'IndexedGfr(${mlPerMinPer173m2.toStringAsFixed(1)} mL/min/1.73 m2)';
}

/// GFR categories G1 to G5 of the KDIGO 2012 Clinical Practice Guideline for
/// the Evaluation and Management of Chronic Kidney Disease
/// (Kidney Int Suppl 2013;3(1):1-150).
///
/// A GFR category alone does not establish CKD: KDIGO also requires markers
/// of kidney damage or a duration above 3 months.
enum KdigoGfrCategory {
  /// GFR >= 90.
  g1('G1', 'Normal or high'),

  /// GFR 60-89.
  g2('G2', 'Mildly decreased'),

  /// GFR 45-59.
  g3a('G3a', 'Mildly to moderately decreased'),

  /// GFR 30-44.
  g3b('G3b', 'Moderately to severely decreased'),

  /// GFR 15-29.
  g4('G4', 'Severely decreased'),

  /// GFR < 15.
  g5('G5', 'Kidney failure');

  const KdigoGfrCategory(this.label, this.description);

  /// Short KDIGO label, e.g. `G3a`.
  final String label;

  /// KDIGO wording of the category.
  final String description;

  /// Category of an indexed GFR.
  static KdigoGfrCategory fromGfr(IndexedGfr gfr) {
    final v = gfr.mlPerMinPer173m2;
    if (v >= 90) return g1;
    if (v >= 60) return g2;
    if (v >= 45) return g3a;
    if (v >= 30) return g3b;
    if (v >= 15) return g4;
    return g5;
  }
}

/// Which body weight Cockcroft-Gault should use.
enum CockcroftGaultWeight {
  /// Total (actual) body weight, as in the original 1976 publication.
  actual,

  /// Devine ideal body weight (needs height).
  ideal,

  /// Adjusted body weight, `IBW + 0.4 x (actual - IBW)` (needs height).
  adjusted,
}

/// Kidney function equations.
abstract final class Kidney {
  /// CKD-EPI 2021 creatinine equation, without a race coefficient.
  ///
  /// `142 x min(Scr/k, 1)^a x max(Scr/k, 1)^-1.200 x 0.9938^age
  /// x 1.012 [female]`, with k = 0.7 (F) / 0.9 (M) and
  /// a = -0.241 (F) / -0.302 (M). Scr in mg/dL (IDMS-traceable).
  ///
  /// Inker LA, Eneanya ND, Coresh J, et al. New creatinine- and cystatin
  /// C-based equations to estimate GFR without race.
  /// N Engl J Med 2021;385(19):1737-1749.
  ///
  /// Validated in adults only: throws [OutOfValidatedRangeException] when
  /// [ageYears] < 18.
  static IndexedGfr ckdEpi2021Creatinine({
    required Creatinine creatinine,
    required num ageYears,
    required Sex sex,
  }) {
    final age = _adultAge(ageYears, 'CKD-EPI 2021');
    final female = sex == Sex.female;
    final k = female ? 0.7 : 0.9;
    final a = female ? -0.241 : -0.302;
    final ratio = creatinine.mgPerDl / k;
    final gfr = 142 *
        _pow(math.min(ratio, 1), a) *
        _pow(math.max(ratio, 1), -1.200) *
        _pow(0.9938, age) *
        (female ? 1.012 : 1.0);
    return IndexedGfr(gfr);
  }

  /// CKD-EPI 2021 creatinine-cystatin C equation, without a race coefficient.
  ///
  /// `135 x min(Scr/k, 1)^a x max(Scr/k, 1)^-0.544
  /// x min(Scys/0.8, 1)^-0.323 x max(Scys/0.8, 1)^-0.778 x 0.9961^age
  /// x 0.963 [female]`, with k = 0.7 (F) / 0.9 (M) and
  /// a = -0.219 (F) / -0.144 (M).
  ///
  /// Inker LA, et al. N Engl J Med 2021;385(19):1737-1749.
  ///
  /// Throws [OutOfValidatedRangeException] when [ageYears] < 18.
  static IndexedGfr ckdEpi2021CreatinineCystatinC({
    required Creatinine creatinine,
    required CystatinC cystatinC,
    required num ageYears,
    required Sex sex,
  }) {
    final age = _adultAge(ageYears, 'CKD-EPI 2021');
    final female = sex == Sex.female;
    final k = female ? 0.7 : 0.9;
    final a = female ? -0.219 : -0.144;
    final scr = creatinine.mgPerDl / k;
    final scys = cystatinC.mgPerL / 0.8;
    final gfr = 135 *
        _pow(math.min(scr, 1), a) *
        _pow(math.max(scr, 1), -0.544) *
        _pow(math.min(scys, 1), -0.323) *
        _pow(math.max(scys, 1), -0.778) *
        _pow(0.9961, age) *
        (female ? 0.963 : 1.0);
    return IndexedGfr(gfr);
  }

  /// MDRD Study 4-variable equation re-expressed for IDMS-traceable
  /// creatinine (constant 175).
  ///
  /// `175 x Scr^-1.154 x age^-0.203 x 0.742 [female] x 1.212 [black]`.
  ///
  /// Levey AS, Coresh J, Greene T, et al. Using standardized serum creatinine
  /// values in the Modification of Diet in Renal Disease study equation for
  /// estimating glomerular filtration rate. Ann Intern Med
  /// 2006;145(4):247-254.
  ///
  /// [black] applies the published 1.212 race coefficient and defaults to
  /// false. Current KDIGO/NKF-ASN guidance prefers the race-free CKD-EPI 2021
  /// equation; MDRD is provided for continuity with legacy reports.
  ///
  /// Throws [OutOfValidatedRangeException] when [ageYears] < 18.
  static IndexedGfr mdrd4({
    required Creatinine creatinine,
    required num ageYears,
    required Sex sex,
    bool black = false,
  }) {
    final age = _adultAge(ageYears, 'MDRD');
    final gfr = 175 *
        _pow(creatinine.mgPerDl, -1.154) *
        _pow(age, -0.203) *
        (sex == Sex.female ? 0.742 : 1.0) *
        (black ? 1.212 : 1.0);
    return IndexedGfr(gfr);
  }

  /// Cockcroft-Gault creatinine clearance, in **mL/min** (not indexed).
  ///
  /// `(140 - age) x weight_kg / (72 x Scr_mg/dL) x 0.85 [female]`.
  ///
  /// Cockcroft DW, Gault MH. Prediction of creatinine clearance from serum
  /// creatinine. Nephron 1976;16(1):31-41.
  ///
  /// [weightBasis] selects actual, Devine ideal or adjusted (factor 0.4)
  /// body weight; the latter two need [height] and throw
  /// [InvalidInputException] without it. The original study used actual
  /// weight and a non-IDMS creatinine assay.
  ///
  /// Throws [OutOfValidatedRangeException] when [ageYears] < 18.
  static double cockcroftGault({
    required Creatinine creatinine,
    required num ageYears,
    required Sex sex,
    required Weight weight,
    Height? height,
    CockcroftGaultWeight weightBasis = CockcroftGaultWeight.actual,
  }) {
    final age = _adultAge(ageYears, 'Cockcroft-Gault');
    final double kg;
    switch (weightBasis) {
      case CockcroftGaultWeight.actual:
        kg = weight.kg;
      case CockcroftGaultWeight.ideal:
        kg = BodySize.idealBodyWeight(_needHeight(height, weightBasis), sex).kg;
      case CockcroftGaultWeight.adjusted:
        final ibw =
            BodySize.idealBodyWeight(_needHeight(height, weightBasis), sex);
        kg = BodySize.adjustedBodyWeight(actual: weight, ideal: ibw).kg;
    }
    final crcl = (140 - age) * kg / (72 * creatinine.mgPerDl);
    return crcl * (sex == Sex.female ? 0.85 : 1.0);
  }

  /// Bedside Schwartz equation for children:
  /// `0.413 x height_cm / Scr_mg/dL`, in mL/min/1.73 m2.
  ///
  /// Schwartz GJ, Munoz A, Schneider MF, et al. New equations to estimate GFR
  /// in children with CKD. J Am Soc Nephrol 2009;20(3):629-637.
  ///
  /// Developed in children aged 1 to 16 years with CKD and an enzymatic,
  /// IDMS-traceable creatinine assay.
  static IndexedGfr bedsideSchwartz({
    required Height height,
    required Creatinine creatinine,
  }) =>
      IndexedGfr(0.413 * height.cm / creatinine.mgPerDl);

  static double _adultAge(num ageYears, String formula) {
    final age = checkAge(ageYears);
    if (age < 18) {
      throw OutOfValidatedRangeException(
          'ageYears', ageYears, '$formula is validated for adults (>= 18 y)');
    }
    return age;
  }

  static Height _needHeight(Height? height, CockcroftGaultWeight basis) {
    if (height == null) {
      throw InvalidInputException(
          'height', null, 'is required for the ${basis.name} weight basis');
    }
    return height;
  }

  static double _pow(num x, num exponent) => math.pow(x, exponent).toDouble();
}
