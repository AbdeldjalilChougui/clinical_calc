import 'dart:math' as math;

import 'errors.dart';
import 'sex.dart';
import 'units.dart';

/// Body surface area formulas.
enum BsaFormula {
  /// Mosteller RD. Simplified calculation of body-surface area.
  /// N Engl J Med 1987;317:1098.
  mosteller('Mosteller RD. N Engl J Med 1987;317(17):1098.'),

  /// Du Bois D, Du Bois EF. A formula to estimate the approximate surface
  /// area if height and weight be known. Arch Intern Med 1916;17:863-871.
  duBois('Du Bois D, Du Bois EF. Arch Intern Med 1916;17(6):863-871.'),

  /// Haycock GB, Schwartz GJ, Wisotsky DH. Geometric method for measuring
  /// body surface area. J Pediatr 1978;93:62-66.
  haycock('Haycock GB, Schwartz GJ, Wisotsky DH. J Pediatr 1978;93(1):62-66.'),

  /// Gehan EA, George SL. Estimation of human body surface area from height
  /// and weight. Cancer Chemother Rep 1970;54:225-235.
  gehanGeorge('Gehan EA, George SL. Cancer Chemother Rep 1970;54(4):225-235.'),

  /// Boyd E. The Growth of the Surface Area of the Human Body.
  /// University of Minnesota Press, 1935.
  boyd('Boyd E. The Growth of the Surface Area of the Human Body. '
      'University of Minnesota Press; 1935.');

  const BsaFormula(this.citation);

  /// Original publication.
  final String citation;
}

/// WHO adult BMI categories (WHO Technical Report Series 894, 2000).
///
/// These cut-offs apply to adults only; children need age- and sex-specific
/// percentiles, which this package does not provide.
enum BmiCategory {
  /// BMI < 18.5.
  underweight('Underweight'),

  /// 18.5 <= BMI < 25.
  normal('Normal weight'),

  /// 25 <= BMI < 30.
  overweight('Overweight (pre-obese)'),

  /// 30 <= BMI < 35.
  obesityClass1('Obesity class I'),

  /// 35 <= BMI < 40.
  obesityClass2('Obesity class II'),

  /// BMI >= 40.
  obesityClass3('Obesity class III');

  const BmiCategory(this.label);

  /// Human-readable WHO label.
  final String label;

  /// Classifies an adult BMI in kg/m2.
  static BmiCategory fromBmi(double bmiKgPerM2) {
    final b = checkPositive('bmi', bmiKgPerM2);
    if (b < 18.5) return underweight;
    if (b < 25) return normal;
    if (b < 30) return overweight;
    if (b < 35) return obesityClass1;
    if (b < 40) return obesityClass2;
    return obesityClass3;
  }
}

/// Body size: BSA, BMI, ideal, adjusted and lean body weight.
abstract final class BodySize {
  /// Body surface area in m2 using [formula] (Mosteller by default).
  static double bsa(Height height, Weight weight,
      {BsaFormula formula = BsaFormula.mosteller}) {
    switch (formula) {
      case BsaFormula.mosteller:
        return bsaMosteller(height, weight);
      case BsaFormula.duBois:
        return bsaDuBois(height, weight);
      case BsaFormula.haycock:
        return bsaHaycock(height, weight);
      case BsaFormula.gehanGeorge:
        return bsaGehanGeorge(height, weight);
      case BsaFormula.boyd:
        return bsaBoyd(height, weight);
    }
  }

  /// Mosteller (1987): `sqrt(height_cm x weight_kg / 3600)`, in m2.
  static double bsaMosteller(Height height, Weight weight) =>
      math.sqrt(height.cm * weight.kg / 3600);

  /// Du Bois & Du Bois (1916): `0.007184 x H^0.725 x W^0.425`, in m2
  /// (H in cm, W in kg).
  static double bsaDuBois(Height height, Weight weight) =>
      0.007184 *
      math.pow(height.cm, 0.725).toDouble() *
      math.pow(weight.kg, 0.425).toDouble();

  /// Haycock et al. (1978): `0.024265 x H^0.3964 x W^0.5378`, in m2.
  static double bsaHaycock(Height height, Weight weight) =>
      0.024265 *
      math.pow(height.cm, 0.3964).toDouble() *
      math.pow(weight.kg, 0.5378).toDouble();

  /// Gehan & George (1970): `0.0235 x H^0.42246 x W^0.51456`, in m2.
  static double bsaGehanGeorge(Height height, Weight weight) =>
      0.0235 *
      math.pow(height.cm, 0.42246).toDouble() *
      math.pow(weight.kg, 0.51456).toDouble();

  /// Boyd (1935):
  /// `0.0003207 x H^0.3 x Wg^(0.7285 - 0.0188 x log10(Wg))`, in m2,
  /// with H in cm and Wg the weight in **grams**.
  static double bsaBoyd(Height height, Weight weight) {
    final grams = weight.g;
    final exponent = 0.7285 - 0.0188 * (math.log(grams) / math.ln10);
    return 0.0003207 *
        math.pow(height.cm, 0.3).toDouble() *
        math.pow(grams, exponent).toDouble();
  }

  /// Body mass index (Quetelet), `weight_kg / height_m^2`, in kg/m2.
  static double bmi(Height height, Weight weight) =>
      weight.kg / (height.m * height.m);

  /// Ideal body weight by Devine (1974):
  /// 50 kg (male) or 45.5 kg (female) + 2.3 kg per inch over 5 feet.
  ///
  /// Devine BJ. Gentamicin therapy. Drug Intell Clin Pharm 1974;8:650-655.
  ///
  /// Throws [OutOfValidatedRangeException] below 60 inches (152.4 cm), where
  /// the formula is not defined.
  static Weight idealBodyWeight(Height height, Sex sex) {
    final inches = height.inches;
    // Tolerate floating-point noise from Height.inches(60).
    if (inches < 60 - 1e-9) {
      throw OutOfValidatedRangeException('height', height.cm,
          'Devine ideal body weight is defined only for heights >= 152.4 cm');
    }
    final base = sex == Sex.male ? 50.0 : 45.5;
    return Weight.kg(base + 2.3 * math.max(0, inches - 60));
  }

  /// Adjusted body weight: `ideal + factor x (actual - ideal)`.
  ///
  /// The default factor 0.4 is the aminoglycoside dosing-weight correction of
  /// Bauer LA, Edwards WA, Dellinger EP, Simonowitz DA. Influence of weight on
  /// aminoglycoside pharmacokinetics in normal weight and morbidly obese
  /// patients. Eur J Clin Pharmacol 1983;24:643-647.
  /// [factor] must be within `[0, 1]`.
  static Weight adjustedBodyWeight({
    required Weight actual,
    required Weight ideal,
    double factor = 0.4,
  }) {
    final f = checkRange('factor', factor, min: 0, max: 1, minExclusive: false);
    return Weight.kg(ideal.kg + f * (actual.kg - ideal.kg));
  }

  /// Lean body weight (fat-free mass) by Janmahasatian et al. (2005):
  /// male `9270 x W / (6680 + 216 x BMI)`,
  /// female `9270 x W / (8780 + 244 x BMI)`, in kg.
  ///
  /// Janmahasatian S, Duffull SB, Ash S, et al. Quantification of lean
  /// bodyweight. Clin Pharmacokinet 2005;44(10):1051-1065.
  static Weight leanBodyWeight(Height height, Weight weight, Sex sex) {
    final b = bmi(height, weight);
    final denominator = sex == Sex.male ? 6680 + 216 * b : 8780 + 244 * b;
    return Weight.kg(9270 * weight.kg / denominator);
  }
}
