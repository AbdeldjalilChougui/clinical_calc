import 'dart:math' as math;

import 'errors.dart';

/// Heart-rate correction formulas for the QT interval.
enum QtcFormula {
  /// `QT / sqrt(RR)`.
  bazett('Bazett HC. An analysis of the time-relations of electrocardiograms. '
      'Heart 1920;7:353-370.'),

  /// `QT / cbrt(RR)`.
  fridericia('Fridericia LS. Die Systolendauer im Elektrokardiogramm bei '
      'normalen Menschen und bei Herzkranken. Acta Med Scand 1920;53:469-486.'),

  /// `QT + 154 ms x (1 - RR)`.
  framingham('Sagie A, Larson MG, Goldberg RJ, Bengtson JR, Levy D. An '
      'improved method for adjusting the QT interval for heart rate (the '
      'Framingham Heart Study). Am J Cardiol 1992;70(7):797-801.');

  const QtcFormula(this.citation);

  /// Original publication.
  final String citation;
}

/// Corrected QT interval (QTc), in milliseconds.
///
/// RR is derived from the heart rate as `60 / HR` seconds. Accepted ranges:
/// QT > 100 and <= 1000 ms, heart rate > 20 and <= 300 bpm.
abstract final class Qtc {
  /// QTc using [formula] (Bazett by default).
  static double correct({
    required double qtMs,
    required double heartRateBpm,
    QtcFormula formula = QtcFormula.bazett,
  }) {
    switch (formula) {
      case QtcFormula.bazett:
        return bazett(qtMs: qtMs, heartRateBpm: heartRateBpm);
      case QtcFormula.fridericia:
        return fridericia(qtMs: qtMs, heartRateBpm: heartRateBpm);
      case QtcFormula.framingham:
        return framingham(qtMs: qtMs, heartRateBpm: heartRateBpm);
    }
  }

  /// Bazett (1920): `QT / sqrt(RR_s)`.
  static double bazett({required double qtMs, required double heartRateBpm}) =>
      _qt(qtMs) / math.sqrt(_rr(heartRateBpm));

  /// Fridericia (1920): `QT / RR_s^(1/3)`.
  static double fridericia(
          {required double qtMs, required double heartRateBpm}) =>
      _qt(qtMs) / math.pow(_rr(heartRateBpm), 1 / 3);

  /// Framingham, Sagie et al. (1992): `QT + 154 x (1 - RR_s)`.
  static double framingham(
          {required double qtMs, required double heartRateBpm}) =>
      _qt(qtMs) + 154 * (1 - _rr(heartRateBpm));

  static double _qt(double qtMs) =>
      checkRange('qtMs', qtMs, min: 100, max: 1000);

  static double _rr(double hr) =>
      60 / checkRange('heartRateBpm', hr, min: 20, max: 300);
}
