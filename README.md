# clinical_calc

Validated clinical formulas for pharmacy and medical apps in pure Dart: eGFR,
body size, unit conversion, dosing arithmetic, QTc and bedside risk scores. The
API uses explicit units, rejects impossible inputs with typed errors, and cites
the original publication for every formula.

[![pub package](https://img.shields.io/pub/v/clinical_calc.svg)](https://pub.dev/packages/clinical_calc)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> **⚠️ Disclaimer: for use by qualified professionals; not a medical device;
> verify results.**
>
> This package provides formulas only. It contains no drug-dosing tables and
> makes no recommendations. Results can be wrong if inputs are wrong or if a
> formula is used outside the population it was developed in. Always check
> results independently before making any clinical decision. The software is
> provided "as is", without warranty of any kind (see [LICENSE](LICENSE)).

## Features

| Area | Formulas |
| --- | --- |
| Kidney | CKD-EPI 2021 creatinine (race-free), CKD-EPI 2021 creatinine-cystatin C, MDRD 4-variable IDMS (175), Cockcroft-Gault (actual / ideal / adjusted weight), bedside Schwartz, KDIGO G1-G5, de-indexing to mL/min |
| Body size | BSA (Mosteller, DuBois, Haycock, Gehan-George, Boyd), BMI + WHO categories, ideal body weight (Devine), adjusted body weight, lean body weight (Janmahasatian) |
| Units | Creatinine (mg/dL, µmol/L, mg/L; factor 88.4), glucose (mg/dL, mmol/L), urea / BUN (mmol/L, g/L, mg/dL, BUN mg/dL), calcium, albumin, bilirubin, height (cm, m, in, ft+in), weight (kg, lb, g) |
| Dosing arithmetic | Dose per kg and per m², volume to draw, vial count with leftover, infusion rate (mL/h), drip rate (drops/min), concentration, infusion concentration, stability window |
| Other | Corrected calcium, anion gap, albumin-corrected anion gap, corrected sodium (Katz, Hillier), QTc (Bazett, Fridericia, Framingham), Child-Pugh, CHA2DS2-VASc, HAS-BLED |

* **Explicit units.** Quantities are value types built with a named unit:
  `Creatinine.mgPerDl(1.2)`, `Creatinine.umolPerL(106)`, `Height.cm(172)`,
  `Weight.lb(180)`. Indexed eGFR (`IndexedGfr`, mL/min/1.73 m²) is a separate
  type from absolute clearance (mL/min).
* **Typed errors.** `InvalidInputException` for negative, non-finite or
  non-physiological values; `OutOfValidatedRangeException` when a formula is
  used outside its validated population (for example CKD-EPI below 18 years).
  Both extend `ClinicalCalcException` and carry `parameter`, `value` and
  `message`.
* **Pure Dart, no dependencies.** Works in Flutter, on the server and on the
  web.

## Install

```sh
dart pub add clinical_calc
```

## Usage

```dart
import 'package:clinical_calc/clinical_calc.dart';

void main() {
  final scr = Creatinine.umolPerL(106);
  final height = Height.cm(172);
  final weight = Weight.kg(84);

  final egfr = Kidney.ckdEpi2021Creatinine(
    creatinine: scr,
    ageYears: 67,
    sex: Sex.male,
  );
  print(egfr.mlPerMinPer173m2); // mL/min/1.73 m2
  print(egfr.kdigoCategory.label); // G2

  final bsa = BodySize.bsaMosteller(height, weight);
  print(egfr.deindex(bsa)); // absolute GFR, mL/min

  final crcl = Kidney.cockcroftGault(
    creatinine: scr,
    ageYears: 67,
    sex: Sex.male,
    weight: weight,
    height: height,
    weightBasis: CockcroftGaultWeight.adjusted,
  );
  print(crcl); // mL/min

  final dose = Dosing.doseForBsa(mgPerM2: 75, bsaM2: bsa);
  final plan = Dosing.vials(
    doseMg: dose,
    vialContentMg: 80,
    concentrationMgPerMl: 20,
  );
  print(plan.vialCount);
  print(plan.leftoverMl);

  print(Qtc.fridericia(qtMs: 440, heartRateBpm: 88));

  try {
    Creatinine.mgPerDl(-1);
  } on InvalidInputException catch (e) {
    print(e.parameter); // creatinine
  }
}
```

See [example/main.dart](example/main.dart) for a runnable version.

## Formulas and citations

Every formula also cites its source in its API doc comment.

### Kidney

| API | Formula | Source |
| --- | --- | --- |
| `Kidney.ckdEpi2021Creatinine` | 142 × min(Scr/κ,1)^α × max(Scr/κ,1)^-1.200 × 0.9938^age × 1.012 [F]; κ 0.7 F / 0.9 M; α -0.241 F / -0.302 M | Inker LA et al. *N Engl J Med* 2021;385:1737-1749 |
| `Kidney.ckdEpi2021CreatinineCystatinC` | 135 × min(Scr/κ,1)^α × max(Scr/κ,1)^-0.544 × min(Scys/0.8,1)^-0.323 × max(Scys/0.8,1)^-0.778 × 0.9961^age × 0.963 [F]; α -0.219 F / -0.144 M | Inker LA et al. *N Engl J Med* 2021;385:1737-1749 |
| `Kidney.mdrd4` | 175 × Scr^-1.154 × age^-0.203 × 0.742 [F] × 1.212 [black, opt-in] | Levey AS et al. *Ann Intern Med* 2006;145:247-254 |
| `Kidney.cockcroftGault` | (140 - age) × weight / (72 × Scr) × 0.85 [F] | Cockcroft DW, Gault MH. *Nephron* 1976;16:31-41 |
| `Kidney.bedsideSchwartz` | 0.413 × height (cm) / Scr | Schwartz GJ et al. *J Am Soc Nephrol* 2009;20:629-637 |
| `KdigoGfrCategory` | G1 ≥ 90, G2 60-89, G3a 45-59, G3b 30-44, G4 15-29, G5 < 15 | KDIGO 2012 CKD guideline. *Kidney Int Suppl* 2013;3:1-150 |
| `IndexedGfr.deindex` | eGFR × BSA / 1.73 | Definition of indexing to 1.73 m² |

### Body size

| API | Formula | Source |
| --- | --- | --- |
| `BodySize.bsaMosteller` | √(H × W / 3600) | Mosteller RD. *N Engl J Med* 1987;317:1098 |
| `BodySize.bsaDuBois` | 0.007184 × H^0.725 × W^0.425 | Du Bois D, Du Bois EF. *Arch Intern Med* 1916;17:863-871 |
| `BodySize.bsaHaycock` | 0.024265 × H^0.3964 × W^0.5378 | Haycock GB et al. *J Pediatr* 1978;93:62-66 |
| `BodySize.bsaGehanGeorge` | 0.0235 × H^0.42246 × W^0.51456 | Gehan EA, George SL. *Cancer Chemother Rep* 1970;54:225-235 |
| `BodySize.bsaBoyd` | 0.0003207 × H^0.3 × Wg^(0.7285 - 0.0188 log10 Wg), weight in grams | Boyd E. *The Growth of the Surface Area of the Human Body*, 1935 |
| `BodySize.bmi`, `BmiCategory` | W / H² ; < 18.5, 18.5-24.9, 25-29.9, 30-34.9, 35-39.9, ≥ 40 | WHO Technical Report Series 894, 2000 |
| `BodySize.idealBodyWeight` | 50 kg (M) / 45.5 kg (F) + 2.3 kg per inch over 60 in | Devine BJ. *Drug Intell Clin Pharm* 1974;8:650-655 |
| `BodySize.adjustedBodyWeight` | IBW + 0.4 × (TBW - IBW), factor configurable | Bauer LA et al. *Eur J Clin Pharmacol* 1983;24:643-647 |
| `BodySize.leanBodyWeight` | 9270 × W / (6680 + 216 × BMI) M; 9270 × W / (8780 + 244 × BMI) F | Janmahasatian S et al. *Clin Pharmacokinet* 2005;44:1051-1065 |

H in cm, W in kg.

### Chemistry, ECG and scores

| API | Formula | Source |
| --- | --- | --- |
| `Chemistry.correctedCalcium` | Ca + 0.8 × (4.0 - albumin g/dL), mg/dL | Payne RB et al. *Br Med J* 1973;4:643-646 |
| `Chemistry.anionGap` | Na - (Cl + HCO3), optional + K | Emmett M, Narins RG. *Medicine* 1977;56:38-54 |
| `Chemistry.albuminCorrectedAnionGap` | AG + 2.5 × (4.0 - albumin g/dL) | Figge J et al. *Crit Care Med* 1998;26:1807-1810 |
| `Chemistry.correctedSodium` (Katz) | Na + 0.016 × (glucose mg/dL - 100) | Katz MA. *N Engl J Med* 1973;289:843-844 |
| `Chemistry.correctedSodium` (Hillier, default) | Na + 0.024 × (glucose mg/dL - 100) | Hillier TA et al. *Am J Med* 1999;106:399-403 |
| `Qtc.bazett` | QT / √RR | Bazett HC. *Heart* 1920;7:353-370 |
| `Qtc.fridericia` | QT / ∛RR | Fridericia LS. *Acta Med Scand* 1920;53:469-486 |
| `Qtc.framingham` | QT + 154 × (1 - RR) | Sagie A et al. *Am J Cardiol* 1992;70:797-801 |
| `ChildPugh.score` | bilirubin, albumin, INR, ascites, encephalopathy; A 5-6, B 7-9, C 10-15 | Pugh RN et al. *Br J Surg* 1973;60:646-649 (after Child & Turcotte 1964) |
| `Cha2ds2Vasc.score` | C1 H1 A₂2 D1 S₂2 V1 A1 Sc1 | Lip GY et al. *Chest* 2010;137:263-272 |
| `HasBled.score` | H A A S B L E D D, one point each; elderly > 65 y, alcohol ≥ 8 drinks/week | Pisters R et al. *Chest* 2010;138:1093-1100 |

### Unit conversion factors

| Quantity | Factor |
| --- | --- |
| Creatinine | 1 mg/dL = 88.4 µmol/L = 10 mg/L |
| Glucose | 1 mmol/L = 18.0156 mg/dL (180.156 g/mol) |
| Urea / BUN | 1 mmol/L urea = 2.8014 mg/dL BUN = 6.006 mg/dL urea = 0.06006 g/L urea |
| Calcium | 1 mmol/L = 4.0078 mg/dL |
| Bilirubin | 1 mg/dL = 17.1 µmol/L |
| Height / weight | 1 in = 2.54 cm; 1 lb = 0.45359237 kg |

## Validation

The test suite (160 tests) checks every formula against worked examples with
explicit tolerances:

* **External reference values.** MDCalc-derived worked examples published in
  MedCalc-Bench v1.0 (Khandekar N. et al., *NeurIPS 2024 Datasets and
  Benchmarks*; [github.com/ncbi-nlp/MedCalc-Bench](https://github.com/ncbi-nlp/MedCalc-Bench),
  `datasets/test_data.csv`) for CKD-EPI 2021, MDRD, Cockcroft-Gault, Mosteller
  BSA, BMI, Devine IBW, adjusted body weight, corrected calcium, anion gap,
  albumin-corrected anion gap, Hillier sodium, the three QTc formulas,
  Child-Pugh, CHA2DS2-VASc and HAS-BLED. Each test names the dataset row, and
  each value was re-checked by hand against the original equation. Rows whose
  values were wrong because the dataset converted units inaccurately were not
  used.
* **Derived reference values.** CKD-EPI creatinine-cystatin C, bedside
  Schwartz, DuBois, Haycock, Gehan-George, Boyd, Janmahasatian, Katz and
  branch/boundary cases were checked against values computed independently
  from the published equations in double precision. No public worked example
  was available for these, so the tests confirm the equation as written but
  do not prove it against a third-party calculator.
* **Tolerances** are stated in each test group, typically 0.001 mL/min/1.73 m²
  for eGFR, 1e-4 m² for BSA, 0.001-0.01 ms for QTc, and exact equality for
  scores.

## Limitations

* **Formulas only.** No drug monographs, renal dose-adjustment tables,
  thresholds for action or treatment recommendations. Score results are
  numbers or classes; interpreting them is up to the clinician and current
  guidelines.
* **Validated populations.** CKD-EPI, MDRD and Cockcroft-Gault throw
  `OutOfValidatedRangeException` below 18 years. Bedside Schwartz was developed
  in children aged 1-16 with CKD. Devine IBW is undefined below 152.4 cm (60
  in) and throws. eGFR equations assume steady-state, IDMS-traceable creatinine
  and are unreliable in acute kidney injury, extremes of muscle mass,
  amputation, pregnancy and similar situations.
* **MDRD race coefficient.** MDRD includes its published 1.212 coefficient
  only when `black: true` is passed. Current KDIGO and NKF-ASN guidance
  recommends the race-free CKD-EPI 2021 equations.
* **Child-Pugh** uses the widely adopted INR cut-offs (< 1.7, 1.7-2.3, > 2.3)
  instead of Pugh's prothrombin-time prolongation in seconds, and bilirubin
  cut-offs for non-cholestatic disease.
* **Accepted input ranges** (for example creatinine up to 40 mg/dL, height
  20-275 cm, weight 0.2-700 kg, heart rate 20-300 bpm) reject impossible data
  entry. They are not clinical reference ranges.
* **Rounding.** Results are returned at full double precision. Round for
  display only.

## Data sources

The package bundles no datasets. The test suite quotes a small number of
numeric inputs and expected results (no patient notes) from MedCalc-Bench v1.0
(Khandekar N. et al., 2024, released under CC BY-SA 4.0), with attribution
by row number in each test. Formula coefficients come from the original
publications listed above. The CKD-EPI 2021 coefficients were also checked
against the NIDDK and National Kidney Foundation equation pages.

## License

MIT. See [LICENSE](LICENSE).

Made by [Abdeldjalil Chougui](https://abdeldjalilchougui.biz/).
