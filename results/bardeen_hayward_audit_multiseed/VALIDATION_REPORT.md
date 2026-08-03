# Canonical Bardeen and Hayward validation report

Configuration: `M=1/2`, `N=1000`, `k=16`, graph-shell radius `3`, 12 common radial bins, seeds 1--10, calibrated radius factor `1.15`.

## Final validation

- Family scans: 80/80 rows (two families, four parameters, ten seeds).
- Five-protocol anchors: 100/100 rows (two families, ten seeds, five protocols).
- No family, parameter, seed, or protocol is missing.
- All runs have 12 common bins and numeric primary and secondary correlations.
- Maximum `XYMismatch`: `1.3322676295501878e-15` (scan) and `8.881784197001252e-16` (anchor).
- Complete vertex sets, connectivity metadata, and valid-estimator fractions are present.
- Mutual-KNN subset checks pass for black-hole and flat graphs.
- Edge-matched differences are exact or tie-explained.
- CSV headers are explicit and stable.
- Bardeen `g=0` and Hayward `ell=0` reproduce Schwarzschild row by row: maximum numeric difference `0`, tolerance `1e-12`; coordinate and common-profile hashes agree.

The machine-readable record is `bardeen_hayward_N1000_seeds10_validation.json`.

## Reproduction commands

```powershell
wolframscript -file .\scripts\run_broader_family_audit.wls static
wolframscript -file .\scripts\run_broader_family_audit.wls full-family-scans
wolframscript -file .\scripts\run_broader_family_audit.wls full-anchor-audits
wolframscript -file .\scripts\run_broader_family_audit.wls aggregate
wolframscript -file .\scripts\run_broader_family_audit.wls validate
wolframscript -file .\scripts\analyze_bardeen_hayward_results.wls
tectonic --keep-logs --keep-intermediates --outdir output\pdf construction_sensitivity_updated_multiseed.tex
```

The runner checkpoints every family/parameter/seed immediately and skips valid completed checkpoints when restarted.
