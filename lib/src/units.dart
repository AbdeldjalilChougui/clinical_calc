import 'errors.dart';

/// Micromoles per litre of creatinine in 1 mg/dL (molar mass 113.12 g/mol).
///
/// The rounded clinical factor 88.4 is used by NKF, KDIGO and most
/// laboratories.
const double creatinineUmolPerMgDl = 88.4;

/// Millimoles per litre of glucose in 1 mg/dL is `1 / 18.0156`
/// (molar mass of glucose 180.156 g/mol).
const double glucoseMgDlPerMmolL = 18.0156;

/// Milligrams of urea nitrogen in 1 mmol of urea (2 N x 14.007 g/mol).
const double bunMgDlPerUreaMmolL = 2.8014;

/// Molar mass of urea, g/mol.
const double ureaMolarMass = 60.06;

/// mg/dL of calcium in 1 mmol/L (molar mass 40.078 g/mol).
const double calciumMgDlPerMmolL = 4.0078;

/// Micromoles per litre of bilirubin in 1 mg/dL (molar mass 584.66 g/mol,
/// rounded clinical factor).
const double bilirubinUmolPerMgDl = 17.1;

/// Centimetres per inch (exact, international inch).
const double cmPerInch = 2.54;

/// Kilograms per avoirdupois pound (exact).
const double kgPerPound = 0.45359237;

/// Serum or plasma creatinine concentration.
///
/// Accepted range: greater than 0 and at most 40 mg/dL (3536 umol/L).
final class Creatinine {
  Creatinine._(num mgDl, [num? original])
      : _mgDl = _canon('creatinine', mgDl, original, 0, 40, true);

  /// Creatinine in milligrams per decilitre (IDMS-traceable assay expected
  /// by every eGFR equation in this package).
  factory Creatinine.mgPerDl(num value) {
    return Creatinine._(value, value);
  }

  /// Creatinine in micromoles per litre (divided by 88.4).
  factory Creatinine.umolPerL(num value) {
    return Creatinine._(value / creatinineUmolPerMgDl, value);
  }

  /// Creatinine in milligrams per litre (divided by 10).
  factory Creatinine.mgPerL(num value) {
    return Creatinine._(value / 10, value);
  }

  final double _mgDl;

  /// Value in mg/dL.
  double get mgPerDl => _mgDl;

  /// Value in umol/L.
  double get umolPerL => _mgDl * creatinineUmolPerMgDl;

  /// Value in mg/L.
  double get mgPerL => _mgDl * 10;

  @override
  bool operator ==(Object other) => other is Creatinine && other._mgDl == _mgDl;

  @override
  int get hashCode => Object.hash(Creatinine, _mgDl);

  @override
  String toString() => 'Creatinine(${_mgDl.toStringAsFixed(3)} mg/dL)';
}

/// Serum cystatin C concentration (IFCC/ERM-DA471 standardised assay).
///
/// Accepted range: greater than 0 and at most 20 mg/L.
final class CystatinC {
  /// Cystatin C in milligrams per litre.
  CystatinC.mgPerL(num value)
      : _mgL = checkRange('cystatinC', value, min: 0, max: 20);

  final double _mgL;

  /// Value in mg/L.
  double get mgPerL => _mgL;

  @override
  bool operator ==(Object other) => other is CystatinC && other._mgL == _mgL;

  @override
  int get hashCode => Object.hash(CystatinC, _mgL);

  @override
  String toString() => 'CystatinC($_mgL mg/L)';
}

/// Plasma or serum glucose concentration.
///
/// Accepted range: greater than 0 and at most 3000 mg/dL (166.5 mmol/L).
final class Glucose {
  Glucose._(num mgDl, [num? original])
      : _mgDl = _canon('glucose', mgDl, original, 0, 3000, true);

  /// Glucose in mg/dL.
  factory Glucose.mgPerDl(num value) {
    return Glucose._(value, value);
  }

  /// Glucose in mmol/L (multiplied by 18.0156).
  factory Glucose.mmolPerL(num value) {
    return Glucose._(value * glucoseMgDlPerMmolL, value);
  }

  final double _mgDl;

  /// Value in mg/dL.
  double get mgPerDl => _mgDl;

  /// Value in mmol/L.
  double get mmolPerL => _mgDl / glucoseMgDlPerMmolL;

  @override
  bool operator ==(Object other) => other is Glucose && other._mgDl == _mgDl;

  @override
  int get hashCode => Object.hash(Glucose, _mgDl);

  @override
  String toString() => 'Glucose(${_mgDl.toStringAsFixed(1)} mg/dL)';
}

/// Serum urea, expressible as urea (mmol/L, g/L, mg/dL) or as blood urea
/// nitrogen (BUN, mg/dL).
///
/// Accepted range: greater than 0 and at most 150 mmol/L.
final class Urea {
  Urea._(num mmolL, [num? original])
      : _mmolL = _canon('urea', mmolL, original, 0, 150, true);

  /// Urea in mmol/L (identical to "urea nitrogen" in mmol/L).
  factory Urea.mmolPerL(num value) {
    return Urea._(value, value);
  }

  /// Blood urea nitrogen in mg/dL (divided by 2.8014).
  factory Urea.bunMgPerDl(num value) {
    return Urea._(value / bunMgDlPerUreaMmolL, value);
  }

  /// Urea mass concentration in g/L (common in French-speaking labs).
  factory Urea.gPerL(num value) {
    return Urea._(value * 1000 / ureaMolarMass, value);
  }

  /// Urea mass concentration in mg/dL.
  factory Urea.mgPerDl(num value) {
    return Urea._(value * 10 / ureaMolarMass, value);
  }

  final double _mmolL;

  /// Value in mmol/L.
  double get mmolPerL => _mmolL;

  /// Blood urea nitrogen in mg/dL.
  double get bunMgPerDl => _mmolL * bunMgDlPerUreaMmolL;

  /// Urea in g/L.
  double get gPerL => _mmolL * ureaMolarMass / 1000;

  /// Urea in mg/dL.
  double get mgPerDl => _mmolL * ureaMolarMass / 10;

  @override
  bool operator ==(Object other) => other is Urea && other._mmolL == _mmolL;

  @override
  int get hashCode => Object.hash(Urea, _mmolL);

  @override
  String toString() => 'Urea(${_mmolL.toStringAsFixed(2)} mmol/L)';
}

/// Body height (length for infants).
///
/// Accepted range: greater than 20 cm and at most 275 cm.
final class Height {
  Height._(num cm, [num? original])
      : _cm = _canon('height', cm, original, 20, 275, true);

  /// Height in centimetres.
  factory Height.cm(num value) {
    return Height._(value, value);
  }

  /// Height in metres.
  factory Height.m(num value) {
    return Height._(value * 100, value);
  }

  /// Height in inches (2.54 cm).
  factory Height.inches(num value) {
    return Height._(value * cmPerInch, value);
  }

  /// Height in feet plus inches; [inches] must be in `[0, 12)`.
  factory Height.feetInches(num feet, num inches) {
    checkNonNegative('feet', feet);
    final i = checkNonNegative('inches', inches);
    if (i >= 12) {
      throw InvalidInputException('inches', inches, 'must be < 12');
    }
    return Height._((feet * 12 + i) * cmPerInch, feet * 12 + i);
  }

  final double _cm;

  /// Value in cm.
  double get cm => _cm;

  /// Value in m.
  double get m => _cm / 100;

  /// Value in inches.
  double get inches => _cm / cmPerInch;

  @override
  bool operator ==(Object other) => other is Height && other._cm == _cm;

  @override
  int get hashCode => Object.hash(Height, _cm);

  @override
  String toString() => 'Height(${_cm.toStringAsFixed(1)} cm)';
}

/// Body weight (mass).
///
/// Accepted range: greater than 0.2 kg and at most 700 kg.
final class Weight {
  Weight._(num kg, [num? original])
      : _kg = _canon('weight', kg, original, 0.2, 700, true);

  /// Weight in kilograms.
  factory Weight.kg(num value) {
    return Weight._(value, value);
  }

  /// Weight in avoirdupois pounds (0.45359237 kg).
  factory Weight.lb(num value) {
    return Weight._(value * kgPerPound, value);
  }

  /// Weight in grams.
  factory Weight.g(num value) {
    return Weight._(value / 1000, value);
  }

  final double _kg;

  /// Value in kg.
  double get kg => _kg;

  /// Value in pounds.
  double get lb => _kg / kgPerPound;

  /// Value in grams.
  double get g => _kg * 1000;

  @override
  bool operator ==(Object other) => other is Weight && other._kg == _kg;

  @override
  int get hashCode => Object.hash(Weight, _kg);

  @override
  String toString() => 'Weight(${_kg.toStringAsFixed(2)} kg)';
}

/// Total serum calcium concentration.
///
/// Accepted range: greater than 0 and at most 30 mg/dL (7.5 mmol/L).
final class Calcium {
  Calcium._(num mgDl, [num? original])
      : _mgDl = _canon('calcium', mgDl, original, 0, 30, true);

  /// Calcium in mg/dL.
  factory Calcium.mgPerDl(num value) {
    return Calcium._(value, value);
  }

  /// Calcium in mmol/L (multiplied by 4.0078).
  factory Calcium.mmolPerL(num value) {
    return Calcium._(value * calciumMgDlPerMmolL, value);
  }

  final double _mgDl;

  /// Value in mg/dL.
  double get mgPerDl => _mgDl;

  /// Value in mmol/L.
  double get mmolPerL => _mgDl / calciumMgDlPerMmolL;

  @override
  bool operator ==(Object other) => other is Calcium && other._mgDl == _mgDl;

  @override
  int get hashCode => Object.hash(Calcium, _mgDl);

  @override
  String toString() => 'Calcium(${_mgDl.toStringAsFixed(2)} mg/dL)';
}

/// Serum albumin concentration.
///
/// Accepted range: greater than 0 and at most 10 g/dL (100 g/L).
final class Albumin {
  Albumin._(num gDl, [num? original])
      : _gDl = _canon('albumin', gDl, original, 0, 10, true);

  /// Albumin in g/dL.
  factory Albumin.gPerDl(num value) {
    return Albumin._(value, value);
  }

  /// Albumin in g/L.
  factory Albumin.gPerL(num value) {
    return Albumin._(value / 10, value);
  }

  final double _gDl;

  /// Value in g/dL.
  double get gPerDl => _gDl;

  /// Value in g/L.
  double get gPerL => _gDl * 10;

  @override
  bool operator ==(Object other) => other is Albumin && other._gDl == _gDl;

  @override
  int get hashCode => Object.hash(Albumin, _gDl);

  @override
  String toString() => 'Albumin(${_gDl.toStringAsFixed(2)} g/dL)';
}

/// Total serum bilirubin concentration.
///
/// Accepted range: 0 to 100 mg/dL (1710 umol/L) inclusive.
final class Bilirubin {
  Bilirubin._(num mgDl, [num? original])
      : _mgDl = _canon('bilirubin', mgDl, original, 0, 100, false);

  /// Bilirubin in mg/dL.
  factory Bilirubin.mgPerDl(num value) {
    return Bilirubin._(value, value);
  }

  /// Bilirubin in umol/L (divided by 17.1).
  factory Bilirubin.umolPerL(num value) {
    return Bilirubin._(value / bilirubinUmolPerMgDl, value);
  }

  final double _mgDl;

  /// Value in mg/dL.
  double get mgPerDl => _mgDl;

  /// Value in umol/L.
  double get umolPerL => _mgDl * bilirubinUmolPerMgDl;

  @override
  bool operator ==(Object other) => other is Bilirubin && other._mgDl == _mgDl;

  @override
  int get hashCode => Object.hash(Bilirubin, _mgDl);

  @override
  String toString() => 'Bilirubin(${_mgDl.toStringAsFixed(2)} mg/dL)';
}

double _canon(String parameter, num canonical, num? original, double min,
    double max, bool minExclusive) {
  final shown = original ?? canonical;
  if (!shown.isFinite) {
    throw InvalidInputException(parameter, shown, 'must be a finite number');
  }
  if (shown < 0) {
    throw InvalidInputException(parameter, shown, 'must not be negative');
  }
  final v = canonical.toDouble();
  final tooLow = minExclusive ? v <= min : v < min;
  if (tooLow || v > max) {
    throw InvalidInputException(parameter, shown,
        'is outside the accepted range (${minExclusive ? '>' : '>='} $min and <= $max in the canonical unit)');
  }
  return v;
}
