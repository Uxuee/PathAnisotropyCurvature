# Canonical Bardeen and Hayward rerun

Run from the repository root on branch `broader-black-hole-canonical-reruns`.
The official paper master is `construction_sensitivity_updated_multiseed.tex`;
its protected pre-rerun source is
`construction_sensitivity_updated_multiseed_PRE_CANONICAL_FAMILY_RERUN_BACKUP.tex`.

The runner preserves `M=1/2`, `N=1000`, `k=16`, graph-shell radius 3,
12 common radial bins, seeds 1 through 10, and the calibrated
`distanceMatrixRadius` factor 1.15. Each curved graph and matched-flat control
reuse the same seeded radial-angular sample.

## Tests and timing

```powershell
wolframscript -file .\scripts\run_broader_family_audit.wls static
wolframscript -file .\scripts\run_broader_family_audit.wls smoke
wolframscript -file .\scripts\run_broader_family_audit.wls timing
```

The smoke test produces 16 fixed-protocol scan rows and 20 anchor-audit rows.
It covers every Bardeen and Hayward parameter, both smoke seeds, and every
anchor protocol. It compares both zero-parameter families with the existing
Schwarzschild rows seed by seed, including coordinate and common-profile hashes.

## Full resumable calculation

```powershell
wolframscript -file .\scripts\run_broader_family_audit.wls full-family-scans
wolframscript -file .\scripts\run_broader_family_audit.wls full-anchor-audits
wolframscript -file .\scripts\run_broader_family_audit.wls aggregate
wolframscript -file .\scripts\run_broader_family_audit.wls validate
```

The final fixed-protocol scans contain 80 rows: two families, four parameters,
and ten seeds. The anchor audits contain 100 rows: two families, ten seeds, and
five protocols. The combined program produces exactly 180 accepted rows and 100
independently resumable checkpoints.

## Output paths

Smoke outputs: `results/bardeen_hayward_audit_smoke/`

Timing outputs: `results/bardeen_hayward_audit_timing_N1000/`

Final outputs: `results/bardeen_hayward_audit_multiseed/`, including:

- `bardeen_hayward_N1000_seeds10_family_scans_raw.csv`
- `bardeen_hayward_N1000_seeds10_family_scans_summary.csv`
- `bardeen_hayward_N1000_seeds10_anchor_audits_raw.csv`
- `bardeen_hayward_N1000_seeds10_anchor_audits_summary.csv`
- `bardeen_hayward_N1000_seeds10_config.json`
- `bardeen_hayward_N1000_seeds10_validation.json`
- `checkpoints/scan/<family>/<parameter>/seed_XX.mx`
- `checkpoints/anchor/<family>/<parameter>/seed_XX.mx`

Measured v3 N=1000 original-protocol times were 140.80 seconds for Bardeen and
123.54 seconds for Hayward. Full execution is resumable and never changes graph
definitions for speed.
