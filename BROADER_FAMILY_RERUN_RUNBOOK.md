# Canonical broader black-hole rerun

Run all commands from the repository root on branch
`broader-black-hole-canonical-reruns`.

The runner preserves the audited conventions: `M=1/2`, `N=1000`, `k=16`,
graph-shell radius 3, 12 common radial bins, seeds 1 through 10, and the default
`distanceMatrixRadius` factor 1.15. Each geometry is built from one seeded Flamm
radial-angular sample, which is reused by its matched-flat control.

## First-phase checks

```powershell
wolframscript -file .\scripts\run_broader_family_audit.wls static
wolframscript -file .\scripts\run_broader_family_audit.wls smoke
wolframscript -file .\scripts\run_broader_family_audit.wls timing
```

The smoke test produces 26 original-protocol scan rows and 30 anchor-audit rows.
It covers every requested family parameter and both smoke seeds. It also compares
all three zero-parameter families with the existing Schwarzschild rows seed by
seed, not only after averaging.

## Full resumable calculation

Do not start these commands until the committed smoke validation has been
reviewed. The two compute modes can be run separately and restarted at any time:

```powershell
wolframscript -file .\scripts\run_broader_family_audit.wls full-family-scans
wolframscript -file .\scripts\run_broader_family_audit.wls full-anchor-audits
wolframscript -file .\scripts\run_broader_family_audit.wls aggregate
wolframscript -file .\scripts\run_broader_family_audit.wls validate
```

The final family scan has 130 rows: 13 family/parameter combinations times ten
seeds under the original protocol. The anchor audit has 150 rows: three anchors
times ten seeds times five protocols. The combined program therefore produces
280 scientific rows and 160 independently resumable checkpoints.

## Expected outputs

Smoke outputs are under `results/broader_family_audit_smoke/`. Timing outputs are
under `results/broader_family_audit_timing_N1000/`. Final outputs will be under
`results/broader_family_audit_multiseed/`, including:

- `broader_families_N1000_seeds10_family_scans_raw.csv`
- `broader_families_N1000_seeds10_family_scans_summary.csv`
- `broader_families_N1000_seeds10_anchor_audits_raw.csv`
- `broader_families_N1000_seeds10_anchor_audits_summary.csv`
- `broader_families_N1000_seeds10_config.json`
- `broader_families_N1000_seeds10_validation.json`
- `checkpoints/scan/<family>/<parameter>/seed_XX.mx`
- `checkpoints/anchor/<family>/<parameter>/seed_XX.mx`

Measured N=1000 original-protocol times under the final v2 schema were 153.15
seconds for RN, 209.38 seconds for Bardeen, and 214.80 seconds for Hayward. Using
those measurements and the observed N=250 anchor/original ratio gives a
conservative total estimate of approximately 11--13 hours for both full modes on
this machine. The checkpoints
contain result rows rather than graph objects; projected final disk use is below
5 MB, excluding any later manuscript figures.
