# Numerical consistency and provenance audit

The manuscript mixed two incompatible correlation pipelines:

1. legacy seed-level or vertex-level correlations from the original calibrated workflow, often reported for `C_log` with negative radial signs; and
2. the canonical construction audit, which computes Pearson correlations from paired BH/flat mean `C_log` profiles formed by `commonRadialBinnedComparison` on 12 common radial bins.

The stored repository contains complete raw rows only for the canonical Schwarzschild construction audit. No raw seed tables or source figures were supplied for the legacy RN, Bardeen, Hayward, cross-family, Forman, Ollivier, diagnostic-heatmap, or non-black-hole numerical results. Their exact values therefore cannot be reconciled with the common-bin audit, and their old numerical claims are removed from the revised evidence set. Their geometry definitions, methodological motivation, and status as future reruns are retained.

The current quantitative evidence is regenerated from:

- `results/construction_audit_multiseed/schwarzschild_five_protocols_N1000_seeds10_raw.csv`;
- the corresponding summary, quality-control, validation, configuration, and checkpoint files; and
- `scripts/analyze_construction_seed_pairs.wls` for paired contrasts, medians, IQRs, and seed-level figures.

No new graph simulation was performed for the manuscript consistency revision. The paired analysis is a deterministic recalculation from the existing 50-row raw table.
