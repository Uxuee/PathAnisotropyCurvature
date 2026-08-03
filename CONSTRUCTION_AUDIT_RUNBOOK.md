# Construction-sensitivity audit runbook

Run every command from the repository root on branch `construction-sensitivity-final-audit`.

## Requirements

- WolframScript/Wolfram Engine compatible with the project package.
- `code/CurvatureEstimator.wl` and the two audit files under `notebooks/`.

The package keeps the calibrated `distanceMatrixRadius` factor of 1.15. The runner does not change graph definitions or estimator semantics.

## Commands

Static tests:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls static
```

N=250, seeds `{1,2}` smoke test:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls smoke
```

One-seed N=1000 timing test:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls timing
```

Resumable N=1000, seeds 1 through 10 calculation. After the tenth valid checkpoint, this command automatically aggregates and validates the final 50-row table:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls full
```

Final aggregation and validation can also be rerun independently after all ten checkpoints exist:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls aggregate
```

## Resumption behavior

The full command runs one seed at a time and atomically saves each valid result under:

```text
results/construction_audit_multiseed/checkpoints/seed_01.mx
...
results/construction_audit_multiseed/checkpoints/seed_10.mx
```

On restart, a checkpoint is skipped only when it imports successfully and contains the expected seed, N, k, graph-shell radius, bin count, and all five protocol rows. Invalid checkpoints are ignored and recomputed. Aggregation fails if any checkpoint or protocol is absent, and requires exactly 50 raw rows.

## Expected final outputs

Final files are written under `results/construction_audit_multiseed/` with stem:

```text
schwarzschild_five_protocols_N1000_seeds10
```

This includes raw, summary, and quality-control CSV files with explicit headers; configuration JSON; summary MX; PDF/PNG plots; manuscript-ready text as a separate generated artifact; and `_validation.json`. Generating this artifact does not modify any manuscript source.

The full ten-seed calculation is intentionally not run as part of this branch preparation.
