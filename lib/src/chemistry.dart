import 'errors.dart';
import 'units.dart';

/// Corrections of serum sodium for hyperglycaemia.
enum SodiumCorrection {
  /// +1.6 mmol/L per 100 mg/dL of glucose above 100 mg/dL.
  katz(
      'Katz MA. Hyperglycemia-induced hyponatremia - calculation of '
      'expected serum sodium depression. N Engl J Med 1973;289(16):843-844.',
      0.016),

  /// +2.4 mmol/L per 100 mg/dL of glucose above 100 mg/dL.
  hillier(
      'Hillier TA, Abbott RD, Barrett EJ. Hyponatremia: evaluating the '
      'correction factor for hyperglycemia. Am J Med 1999;106(4):399-403.',
      0.024);

  const SodiumCorrection(this.citation, this.factorPerMgDl);

  /// Original publication.
  final String citation;

  /// Sodium increase (mmol/L) per 1 mg/dL of glucose above 100 mg/dL.
  final double factorPerMgDl;
}

/// Serum chemistry corrections: calcium, anion gap and sodium.
abstract final class Chemistry {
  /// Albumin-corrected total calcium:
  /// `Ca_mg/dL + 0.8 x (normalAlbumin_g/dL - albumin_g/dL)`.
  ///
  /// Payne RB, Little AJ, Williams RB, Milner JR. Interpretation of serum
  /// calcium in patients with abnormal serum proteins. Br Med J
  /// 1973;4(5893):643-646.
  ///
  /// [normalAlbumin] defaults to 4.0 g/dL. The correction is computed in
  /// mg/dL; SI inputs and outputs are converted exactly, so the SI result can
  /// differ by up to 0.0004 mmol/L per g/L from the rounded
  /// "0.02 mmol/L per g/L" rule.
  static Calcium correctedCalcium({
    required Calcium calcium,
    required Albumin albumin,
    Albumin? normalAlbumin,
  }) {
    final normal = normalAlbumin?.gPerDl ?? 4.0;
    return Calcium.mgPerDl(calcium.mgPerDl + 0.8 * (normal - albumin.gPerDl));
  }

  /// Serum anion gap in mmol/L: `Na - (Cl + HCO3)`, or
  /// `(Na + K) - (Cl + HCO3)` when [potassiumMmolPerL] is given.
  ///
  /// Emmett M, Narins RG. Clinical use of the anion gap. Medicine (Baltimore)
  /// 1977;56(1):38-54.
  ///
  /// Accepted ranges (mmol/L): sodium 80-220, chloride 40-180,
  /// bicarbonate > 0 and <= 60, potassium 0.5-15.
  static double anionGap({
    required double sodiumMmolPerL,
    required double chlorideMmolPerL,
    required double bicarbonateMmolPerL,
    double? potassiumMmolPerL,
  }) {
    final na = _sodium(sodiumMmolPerL);
    final cl = checkRange('chloride', chlorideMmolPerL,
        min: 40, max: 180, minExclusive: false);
    final hco3 =
        checkRange('bicarbonate', bicarbonateMmolPerL, min: 0, max: 60);
    final k = potassiumMmolPerL == null
        ? 0.0
        : checkRange('potassium', potassiumMmolPerL,
            min: 0.5, max: 15, minExclusive: false);
    return na + k - cl - hco3;
  }

  /// Albumin-corrected anion gap in mmol/L:
  /// `anionGap + 2.5 x (normalAlbumin_g/dL - albumin_g/dL)`.
  ///
  /// Figge J, Jabor A, Kazda A, Fencl V. Anion gap and hypoalbuminemia.
  /// Crit Care Med 1998;26(11):1807-1810.
  ///
  /// [normalAlbumin] defaults to 4.0 g/dL.
  static double albuminCorrectedAnionGap({
    required double anionGap,
    required Albumin albumin,
    Albumin? normalAlbumin,
  }) {
    final ag = checkRange('anionGap', anionGap,
        min: -100, max: 200, minExclusive: false);
    final normal = normalAlbumin?.gPerDl ?? 4.0;
    return ag + 2.5 * (normal - albumin.gPerDl);
  }

  /// Serum sodium corrected for hyperglycaemia, in mmol/L:
  /// `Na + factor x (glucose_mg/dL - 100)`, with factor 0.024 (Hillier,
  /// default) or 0.016 (Katz). See [SodiumCorrection] for citations.
  static double correctedSodium({
    required double sodiumMmolPerL,
    required Glucose glucose,
    SodiumCorrection method = SodiumCorrection.hillier,
  }) =>
      _sodium(sodiumMmolPerL) + method.factorPerMgDl * (glucose.mgPerDl - 100);

  static double _sodium(double v) =>
      checkRange('sodium', v, min: 80, max: 220, minExclusive: false);
}
