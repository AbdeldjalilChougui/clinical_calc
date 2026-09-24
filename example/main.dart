// For use by qualified professionals; not a medical device; verify results.
import 'package:clinical_calc/clinical_calc.dart';

void main() {
  // Units are explicit: a creatinine in umol/L cannot be passed as mg/dL.
  final scr = Creatinine.umolPerL(106);
  final height = Height.cm(172);
  final weight = Weight.kg(84);

  final egfr = Kidney.ckdEpi2021Creatinine(
    creatinine: scr,
    ageYears: 67,
    sex: Sex.male,
  );
  final bsa = BodySize.bsaMosteller(height, weight);
  print('CKD-EPI 2021: ${egfr.mlPerMinPer173m2.toStringAsFixed(1)} '
      'mL/min/1.73 m2 (${egfr.kdigoCategory.label})');
  print('De-indexed:   ${egfr.deindex(bsa).toStringAsFixed(1)} mL/min '
      '(BSA ${bsa.toStringAsFixed(2)} m2)');

  final crcl = Kidney.cockcroftGault(
    creatinine: scr,
    ageYears: 67,
    sex: Sex.male,
    weight: weight,
    height: height,
    weightBasis: CockcroftGaultWeight.adjusted,
  );
  print('Cockcroft-Gault (adjusted weight): ${crcl.toStringAsFixed(1)} mL/min');

  // Dosing arithmetic for a prescription the clinician has already chosen.
  final dose = Dosing.doseForBsa(mgPerM2: 75, bsaM2: bsa);
  final plan = Dosing.vials(
    doseMg: dose,
    vialContentMg: 80,
    concentrationMgPerMl: 20,
  );
  print('Dose ${dose.toStringAsFixed(1)} mg -> $plan');

  print('QTc Fridericia: '
      '${Qtc.fridericia(qtMs: 440, heartRateBpm: 88).toStringAsFixed(0)} ms');

  try {
    Creatinine.mgPerDl(-1);
  } on InvalidInputException catch (e) {
    print('Rejected: $e');
  }
}
