import 'errors.dart';
import 'units.dart';

/// Result of [Dosing.vials].
final class VialPlan {
  /// Creates a plan. Normally obtained from [Dosing.vials].
  const VialPlan({
    required this.vialCount,
    required this.volumeToDrawMl,
    required this.leftoverMg,
    required this.leftoverMl,
  });

  /// Number of new vials to open.
  final int vialCount;

  /// Volume of solution to draw for the dose, in mL.
  final double volumeToDrawMl;

  /// Drug left over after drawing the dose (new vials plus any drug that was
  /// already available), in mg.
  final double leftoverMg;

  /// Same leftover expressed in mL at the vial concentration.
  final double leftoverMl;

  @override
  String toString() => 'VialPlan($vialCount vials, draw '
      '${volumeToDrawMl.toStringAsFixed(2)} mL, leftover '
      '${leftoverMg.toStringAsFixed(2)} mg / '
      '${leftoverMl.toStringAsFixed(2)} mL)';
}

/// Dosing arithmetic: dose scaling, volumes, vials, infusion rates and
/// stability windows.
///
/// These are plain algebraic identities; no drug-specific dose, limit or
/// recommendation is included.
abstract final class Dosing {
  /// Largest body surface area accepted, m2.
  static const double maxBsaM2 = 5;

  /// Dose in mg for a weight-based prescription: `mgPerKg x weight_kg`.
  static double doseForWeight(
          {required double mgPerKg, required Weight weight}) =>
      checkNonNegative('mgPerKg', mgPerKg) * weight.kg;

  /// Dose in mg for a BSA-based prescription: `mgPerM2 x bsa_m2`.
  ///
  /// [bsaM2] must be in `(0, 5]`.
  static double doseForBsa({required double mgPerM2, required double bsaM2}) =>
      checkNonNegative('mgPerM2', mgPerM2) *
      checkRange('bsaM2', bsaM2, min: 0, max: maxBsaM2);

  /// Volume in mL that contains [doseMg] at [concentrationMgPerMl].
  static double volumeToDraw({
    required double doseMg,
    required double concentrationMgPerMl,
  }) =>
      checkNonNegative('doseMg', doseMg) /
      checkPositive('concentrationMgPerMl', concentrationMgPerMl);

  /// Concentration in mg/mL of [amountMg] dissolved in [volumeMl].
  static double concentration({
    required double amountMg,
    required double volumeMl,
  }) =>
      checkNonNegative('amountMg', amountMg) /
      checkPositive('volumeMl', volumeMl);

  /// Final concentration in mg/mL after adding [drugVolumeMl] containing
  /// [doseMg] to [diluentVolumeMl] of diluent (for example an infusion bag):
  /// `dose / (drugVolume + diluentVolume)`.
  static double infusionConcentration({
    required double doseMg,
    required double drugVolumeMl,
    required double diluentVolumeMl,
  }) {
    final total = checkNonNegative('drugVolumeMl', drugVolumeMl) +
        checkNonNegative('diluentVolumeMl', diluentVolumeMl);
    if (total <= 0) {
      throw InvalidInputException(
          'drugVolumeMl + diluentVolumeMl', total, 'must be > 0');
    }
    return checkNonNegative('doseMg', doseMg) / total;
  }

  /// Number of vials to open for [doseMg], and what is left over.
  ///
  /// Each vial contains [vialContentMg] at [concentrationMgPerMl] (after
  /// reconstitution if applicable), so one vial holds
  /// `vialContentMg / concentrationMgPerMl` mL. [availableMl] is solution of
  /// the same concentration already available (for example a still-stable
  /// opened vial) and is used first.
  ///
  /// The vial count is `ceil((dose - available) / vialContent)`, computed
  /// with a 1e-9 tolerance on the vial ratio so that floating-point noise such as
  /// `1.1 / 0.1 = 11.000000000000002` does not add a vial.
  static VialPlan vials({
    required double doseMg,
    required double vialContentMg,
    required double concentrationMgPerMl,
    double availableMl = 0,
  }) {
    final dose = checkNonNegative('doseMg', doseMg);
    final content = checkPositive('vialContentMg', vialContentMg);
    final conc = checkPositive('concentrationMgPerMl', concentrationMgPerMl);
    final availableMg = checkNonNegative('availableMl', availableMl) * conc;

    final missingMg = dose - availableMg;
    final count = missingMg <= 0 ? 0 : (missingMg / content - 1e-9).ceil();
    var leftoverMg = count * content + availableMg - dose;
    if (leftoverMg.abs() < 1e-9 * (dose + content)) leftoverMg = 0;
    return VialPlan(
      vialCount: count,
      volumeToDrawMl: dose / conc,
      leftoverMg: leftoverMg,
      leftoverMl: leftoverMg / conc,
    );
  }

  /// Infusion rate in mL/h to deliver [volumeMl] over [duration].
  static double infusionRateMlPerHour({
    required double volumeMl,
    required Duration duration,
  }) =>
      checkNonNegative('volumeMl', volumeMl) / _hours(duration);

  /// Gravity-infusion drip rate in drops/min:
  /// `volume_mL x dropFactor / minutes`.
  ///
  /// [dropFactorPerMl] is the giving-set calibration (typically 10, 15 or 20
  /// drops/mL for macrodrip sets, 60 for microdrip sets).
  static double dropsPerMinute({
    required double volumeMl,
    required Duration duration,
    required double dropFactorPerMl,
  }) =>
      checkNonNegative('volumeMl', volumeMl) *
      checkPositive('dropFactorPerMl', dropFactorPerMl) /
      (_hours(duration) * 60);

  /// Time left before a prepared solution reaches the end of its
  /// [stability] window, clamped at [Duration.zero].
  ///
  /// [now] is explicit so the function stays pure and testable.
  /// Throws [InvalidInputException] if [preparedAt] is after [now] or
  /// [stability] is negative.
  static Duration stabilityRemaining({
    required DateTime preparedAt,
    required Duration stability,
    required DateTime now,
  }) {
    if (stability.isNegative) {
      throw InvalidInputException('stability', stability, 'must be >= 0');
    }
    if (preparedAt.isAfter(now)) {
      throw InvalidInputException(
          'preparedAt', preparedAt, 'must not be after now');
    }
    final left = stability - now.difference(preparedAt);
    return left.isNegative ? Duration.zero : left;
  }

  /// Whether a solution prepared at [preparedAt] is still inside its
  /// [stability] window at [now] (the end of the window is excluded).
  static bool isWithinStability({
    required DateTime preparedAt,
    required Duration stability,
    required DateTime now,
  }) =>
      stabilityRemaining(
          preparedAt: preparedAt, stability: stability, now: now) >
      Duration.zero;

  static double _hours(Duration d) {
    if (d <= Duration.zero) {
      throw InvalidInputException('duration', d, 'must be > 0');
    }
    return d.inMicroseconds / Duration.microsecondsPerHour;
  }
}
