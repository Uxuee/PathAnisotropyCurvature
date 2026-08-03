# PathAnisotropyCurvature

PathAnisotropyCurvature studies how a shell-based shortest-path multiplicity
diagnostic behaves on spatial geometric graphs sampled from black-hole
embedding surfaces. The release uses Schwarzschild/Flamm, Bardeen, and Hayward
geometries as controlled benchmarks. Its purpose is methodological: to separate
reproducibility within a fixed graph protocol from sensitivity across graph
construction and matched-control choices.

The canonical conclusion is conservative:

> The black-hole/control separation is reproducible only under a fully
> specified diagnostic--construction--control protocol and is not invariant
> under graph construction.

The diagnostic is not claimed to be a graph-independent curvature scalar or a
universal discrete Kretschmann invariant.

## Canonical v1.0.0 analysis

The archived calculation uses:

- Schwarzschild/Flamm, Bardeen, and Hayward embedding surfaces;
- `M = 1/2`, `N = 1000`, `k = 16`;
- graph-shell radius `r_g = 3`;
- 12 common radial bins;
- seeds 1 through 10;
- calibrated `distanceMatrixRadius` factor 1.15;
- one radial-angular sample per family, parameter, and seed, reused by its flat
  control; and
- Pearson common-bin radial correlation as the primary statistic, with signed
  and absolute black-hole/control differences reported.

The Bardeen scan uses `g = {0, 0.1, 0.2, 0.3}` and the Hayward scan uses
`ell = {0, 0.1, 0.2, 0.3}` under the original matched-flat protocol. The
Bardeen `g=0.2` and Hayward `ell=0.2` anchors use five protocols: original
matched-flat KNN, strict radius, pure KNN, mutual KNN, and edge-matched radius.

Expected final outputs:

- 50 Schwarzschild construction-audit rows;
- 80 Bardeen/Hayward family-scan rows;
- 100 Bardeen/Hayward anchor-audit rows;
- 100 Bardeen/Hayward checkpoint units; and
- exact row-by-row Bardeen `g=0` and Hayward `ell=0` recovery of Schwarzschild.

## Repository structure

```text
code/                                      Core Wolfram Language package
notebooks/                                 Audited notebook/package sources
scripts/                                   Headless runners and analysis scripts
results/construction_audit_multiseed/      Schwarzschild data and validation
results/bardeen_hayward_audit_multiseed/   Family data, checkpoints, validation
results/figures/                           Manuscript and supporting figures
construction_sensitivity_latex_project/    Portable LaTeX manuscript project
submission_jcn/                            Journal submission materials
```

See [ARCHIVE_MANIFEST.md](ARCHIVE_MANIFEST.md) for the complete archive map.

## Reproduce and validate

Wolfram Language with `wolframscript` is required for numerical execution.
Tectonic or another LaTeX engine is required for the manuscript, and Poppler is
useful for PDF inspection.

Static checks:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls static
wolframscript -file .\scripts\run_broader_family_audit.wls static
```

Validate completed outputs without changing graph definitions:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls aggregate
wolframscript -file .\scripts\run_broader_family_audit.wls aggregate
wolframscript -file .\scripts\run_broader_family_audit.wls validate
wolframscript -file .\scripts\analyze_bardeen_hayward_results.wls
```

Run the resumable full calculations only when regeneration is intended:

```powershell
wolframscript -file .\scripts\run_construction_audit.wls full
wolframscript -file .\scripts\run_broader_family_audit.wls full-family-scans
wolframscript -file .\scripts\run_broader_family_audit.wls full-anchor-audits
```

Compile the portable manuscript:

```powershell
Set-Location .\construction_sensitivity_latex_project
tectonic main.tex
```

The manuscript source is
[`construction_sensitivity_latex_project/main.tex`](construction_sensitivity_latex_project/main.tex),
with the compiled preview at
[`construction_sensitivity_latex_project/compiled_preview.pdf`](construction_sensitivity_latex_project/compiled_preview.pdf).

## Validation summary

The archived validation records confirm:

- all expected rows, parameters, seeds, and protocols are present;
- all accepted rows contain 12 common bins;
- all required primary and secondary correlations are numeric;
- maximum `XYMismatch` is `1.3322676295501878e-15`;
- zero-parameter maximum difference is exactly zero at tolerance `1e-12`;
- complete vertex sets and connectivity metadata are retained;
- mutual-KNN subset checks pass for black-hole and flat graphs; and
- edge-matched differences are exact or explained by threshold ties.

## Citation and license

Citation metadata are provided in [`CITATION.cff`](CITATION.cff). GitHub's
**Cite this repository** control can render the recommended software citation.
The archival DOI must be added after Zenodo creates it; no DOI is fabricated in
this repository.

This project is licensed under the [MIT License](LICENSE).

## Relationship to the earlier preprint

An earlier version appeared as arXiv:2606.27248 and reported fixed-protocol and
single-realization results. Release v1.0.0 replaces that construction analysis
with paired ten-seed audits, adds canonical Bardeen and Hayward calculations,
and removes quantitative claims that did not survive multi-seed validation.
The arXiv identifier denotes the related earlier manuscript version, not the
DOI of this software/data release.
