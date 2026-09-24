/// Base type of every exception thrown by `clinical_calc`.
///
/// Catch this to handle all input problems in one place.
sealed class ClinicalCalcException implements Exception {
  const ClinicalCalcException(this.parameter, this.value, this.message);

  /// Name of the offending parameter, for example `creatinine`.
  final String parameter;

  /// The rejected value, as passed by the caller.
  final Object? value;

  /// Human-readable explanation.
  final String message;
}

/// Thrown when a value is negative, zero where zero is meaningless, not
/// finite, or outside the physiologically plausible range.
final class InvalidInputException extends ClinicalCalcException {
  /// Creates an [InvalidInputException].
  const InvalidInputException(super.parameter, super.value, super.message);

  @override
  String toString() => 'InvalidInputException($parameter = $value): $message';
}

/// Thrown when a value is physiologically possible but outside the population
/// in which the formula was developed or validated (for example CKD-EPI in a
/// patient younger than 18 years).
final class OutOfValidatedRangeException extends ClinicalCalcException {
  /// Creates an [OutOfValidatedRangeException].
  const OutOfValidatedRangeException(
      super.parameter, super.value, super.message);

  @override
  String toString() =>
      'OutOfValidatedRangeException($parameter = $value): $message';
}

/// Returns [value] if it is finite and within `[min, max]`
/// (`(min, max]` when [minExclusive] is true); throws
/// [InvalidInputException] otherwise.
double checkRange(
  String parameter,
  num value, {
  required double min,
  required double max,
  bool minExclusive = true,
}) {
  final v = value.toDouble();
  if (!v.isFinite) {
    throw InvalidInputException(parameter, value, 'must be a finite number');
  }
  final tooLow = minExclusive ? v <= min : v < min;
  if (tooLow || v > max) {
    final lower = minExclusive ? '> $min' : '>= $min';
    throw InvalidInputException(parameter, value, 'must be $lower and <= $max');
  }
  return v;
}

/// Returns [value] if it is finite and strictly positive.
double checkPositive(String parameter, num value) =>
    checkRange(parameter, value, min: 0, max: double.maxFinite);

/// Returns [value] if it is finite and zero or positive.
double checkNonNegative(String parameter, num value) =>
    checkRange(parameter, value,
        min: 0, max: double.maxFinite, minExclusive: false);

/// Validates an age in years (0 to 130 inclusive).
double checkAge(num ageYears) =>
    checkRange('ageYears', ageYears, min: 0, max: 130, minExclusive: false);
