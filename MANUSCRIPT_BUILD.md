# Unified manuscript build

The audited manuscript master is `shortest_path_anisotropy_unified_v2.tex`.
Build it from the repository root with Tectonic:

```powershell
New-Item -ItemType Directory -Force .\output\pdf | Out-Null
tectonic --keep-logs --keep-intermediates --outdir .\output\pdf .\shortest_path_anisotropy_unified_v2.tex
```

If Tectonic is not on `PATH`, replace `tectonic` with the full path to the
executable. The expected deliverable is
`output/pdf/shortest_path_anisotropy_unified_v2.pdf`.

Before accepting the build, inspect the log for undefined references, missing
figures, multiply defined labels, and overfull or underfull boxes. Render every
PDF page to an image for visual inspection. The construction-sensitivity figures
are generated from the checked-in 50-row result table by:

```powershell
wolframscript -file .\scripts\analyze_construction_seed_pairs.wls
```

This analysis consumes existing results only; it does not generate new graphs or
rerun simulations.
