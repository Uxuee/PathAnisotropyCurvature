# Archive manifest for v1.0.0

## Main code

- `code/CurvatureEstimator.wl` -- estimator definitions, geometric builders,
  graph constructions, common-bin comparisons, and plotting helpers.
- `notebooks/ConstructionSensitivityMultiSeedAudit.wl` -- audited
  Schwarzschild multi-protocol implementation.

## Headless runners and analysis

- `scripts/run_construction_audit.wls` -- resumable Schwarzschild runner,
  aggregation, and validation modes.
- `scripts/run_broader_family_audit.wls` -- resumable Bardeen/Hayward family
  scans and anchor audits.
- `scripts/analyze_construction_seed_pairs.wls` -- paired Schwarzschild
  contrasts and seed-level figures.
- `scripts/analyze_bardeen_hayward_results.wls` -- family summaries,
  contrasts, quality-control exports, runtime report, and figures.

## Raw data, summaries, and configurations

- `results/construction_audit_multiseed/` -- 50-row Schwarzschild raw table,
  protocol summaries, quality control, configuration, runtime materials, and
  per-seed checkpoints.
- `results/bardeen_hayward_audit_multiseed/` -- 80-row family-scan table,
  100-row anchor-audit table, detailed summaries, paired contrasts,
  quality-control table, runtime files, configuration, and 100 resumable
  checkpoint units.

## Validation

- `results/construction_audit_multiseed/*validation*` -- Schwarzschild
  aggregation and validation records.
- `results/bardeen_hayward_audit_multiseed/bardeen_hayward_N1000_seeds10_validation.json`
  -- machine-readable family and zero-limit validation.
- `results/bardeen_hayward_audit_multiseed/VALIDATION_REPORT.md` -- human-readable
  validation summary and reproduction commands.

## Figures

- `results/figures/` -- manuscript figures and supporting benchmark figures in
  PDF and PNG formats.

## Manuscript and submission materials

- `construction_sensitivity_latex_project/` -- portable manuscript source,
  nine PDF figure assets, README, and compiled preview.
- `submission_jcn/` -- Journal of Complex Networks manuscript, cover letter,
  supplementary reproducibility note, and figures.
- `submission_jcn.zip` -- journal-upload package; this is not a repository
  source archive.

## Reproducibility documentation

- `README.md` -- scientific scope, canonical configuration, commands, expected
  outputs, citation, and release relationship.
- `BROADER_FAMILY_RERUN_RUNBOOK.md` and `CONSTRUCTION_AUDIT_RUNBOOK.md` --
  operational runbooks.
- `CITATION.cff` -- software and preferred manuscript citation metadata.
- `RELEASE_NOTES_v1.0.0.md` -- release scope and methodological conclusion.
