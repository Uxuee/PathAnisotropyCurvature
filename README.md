# Path Anisotropy Curvature

This repository develops a graph-based curvature diagnostic inspired by geodesic shells, shortest-path statistics, and continuum curvature invariants such as the Schwarzschild Kretschmann scalar.

The project began as an exploratory Wolfram Community / Wolfram Summer School idea about whether a Kretschmann-like scalar could be defined for hypergraphs or graph-based discrete geometries. The current version reformulates that idea more cautiously as a **curvature-sensitive graph diagnostic** based on shortest-path anisotropy.

The goal is **not** to claim that the estimator is a discrete Kretschmann scalar. Instead, the goal is to test whether local shortest-path anisotropy contains curvature-organized information in graph discretizations of continuum geometries.

## Preprint status

This repository supports the manuscript:

**A Shortest-Path Anisotropy Diagnostic for Black-Hole Graph Geometries**  
Ariadna Uxue Palomino Ylla

The manuscript studies graph discretizations of embedded spatial slices of static black-hole geometries, including Schwarzschild/Flamm, Reissner--Nordström, Bardeen, and Hayward benchmarks.

The central claim is conservative:

> The logarithmic path-anisotropy estimator provides a local graph observable whose radial organization is strongly associated with black-hole curvature profiles under a fixed graph-construction and matched-control protocol.

It should not be interpreted as a graph-independent continuum invariant or a universal discrete Kretschmann scalar.

## Summary

This project tests whether local shortest-path anisotropy can act as a curvature-sensitive observable in graph discretizations of continuum geometries.

The estimator is defined on graph-distance shells. For each reference vertex \(p\), we count the number of distinct shortest paths from \(p\) to vertices \(q\) on a graph-distance shell \(S_{r_g}(p)\). The main statistic, `LogCMD`, is the cubic mean deviation of \(\log N_{\mathrm{geo}}(p,q)\) over that shell.

The strongest current results are obtained for embedded black-hole spatial slices. In calibrated graph discretizations of Schwarzschild/Flamm, Reissner--Nordström, Bardeen, and Hayward geometries, the estimator shows a stable radial organization. Matched-flat controls, constructed from the same radial and angular sampling but with the embedding height removed, do not reproduce the same trend.

The current interpretation is deliberately cautious:

> \(C_{\log}\) is a Kretschmann-inspired, curvature-sensitive graph diagnostic based on shortest-path anisotropy. It is not claimed to be a graph-independent continuum invariant or a universal discrete Kretschmann scalar.

The repository includes fixed-seed scans, matched-flat controls, graph-radius sensitivity tests, Forman-Ricci and Ollivier-Ricci baseline comparisons, and exploratory non-black-hole benchmark surfaces.

## Core idea

Given a graph \(G=(V,E)\), a center vertex \(p\), and a graph-distance radius \(r_g\), define the graph-distance shell

\[
S_{r_g}(p) = \{q\in V \mid d_G(p,q)=r_g\}.
\]

For each shell vertex \(q\), count the number of shortest paths from \(p\) to \(q\):

\[
N_{\mathrm{geo}}(p,q).
\]

The estimator measures how uneven these shortest-path counts are across the shell. The working hypothesis is that curvature-organized graph structure leaves a statistical signature in local shortest-path multiplicities.

The current main estimator is the logarithmic cubic-mean-deviation version:

\[
C_{\log}(p,r_g)
=
\left[
\frac{1}{|S_{r_g}(p)|}
\sum_{q\in S_{r_g}(p)}
\left|
\log N_{\mathrm{geo}}(p,q)-\overline{\log N}_{p,r_g}
\right|^3
\right]^{1/3}.
\]

In Mathematica, this estimator is stored as the `LogCMD` column.

## Benchmark geometries

The repository includes graph discretizations of several benchmark geometries:

- flat controls,
- Schwarzschild/Flamm spatial slices,
- Reissner--Nordström spatial slices,
- Bardeen regular black-hole spatial slices,
- Hayward regular black-hole spatial slices,
- paraboloid and hyperbolic-paraboloid surfaces,
- exploratory sphere and hyperbolic-disk tests.

The main black-hole comparison uses static, spherically symmetric metrics of the form

\[
ds^2=-f(r)dt^2+f(r)^{-1}dr^2+r^2d\Omega^2.
\]

On an equatorial spatial slice,

\[
dl^2=f(r)^{-1}dr^2+r^2d\phi^2.
\]

Embedding this slice as a surface of revolution in Euclidean three-space gives

\[
\frac{dz}{dr}=\sqrt{\frac{1}{f(r)}-1}.
\]

For Schwarzschild, the continuum comparison target is the Kretschmann scalar

\[
K_{\mathrm{Schw}}(r)=\frac{48M^2}{r^6}.
\]

For a general static spherical metric of the above form, the Kretschmann scalar can be computed from \(f(r)\) as

\[
K(r)=\left(f''(r)\right)^2+4\left(\frac{f'(r)}{r}\right)^2+4\left(\frac{f(r)-1}{r^2}\right)^2.
\]

This formula is used for the Reissner--Nordström, Bardeen, and Hayward benchmark comparisons.

## Main paper figures

The current paper version uses three complementary outputs.

### 1. Cross-family radial profile

A binned radial comparison of \(C_{\log}\) across Schwarzschild/Flamm, Reissner--Nordström, Bardeen, and Hayward benchmarks.

```text
results/figures/black_hole_family_radial_profile_plot.pdf
```

The radial profiles show a common radial organization across all four black-hole graph geometries, with small model-dependent deviations.

### 2. Three-dimensional binned visualization

A qualitative 3D graph visualization colored by radially binned mean \(C_{\log}\). The binning is used only for visual clarity; the quantitative analysis uses the radial profiles and summary tables.

```text
results/figures/black_hole_family_colored_by_binned_LogCMD_blue_red.pdf
```

### 3. Cross-family summary table

A fixed-parameter comparison using \(N=1000\), \(k=16\), and \(r_g=3\), reporting the mean and standard deviation of \(C_{\log}\) and binned correlations with radial coordinate and \(\log K\).

```text
results/tables/black_hole_family_summary_table.csv
```

Current fixed-parameter summary:

| Geometry | N | Mean \(C_{\log}\) | Std. \(C_{\log}\) | Corr\((r,C_{\log})\) | Corr\((\log K,C_{\log})\) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Schwarzschild/Flamm | 1000 | 1.2265 | 0.1384 | 0.8462 | -0.8932 |
| Reissner--Nordström, \(Q=0.4\) | 1000 | 1.2208 | 0.1373 | 0.7709 | -0.8082 |
| Bardeen, \(g=0.2\) | 1000 | 1.2250 | 0.1391 | 0.8390 | -0.8802 |
| Hayward, \(\ell=0.2\) | 1000 | 1.2256 | 0.1380 | 0.8460 | -0.8872 |

The negative values of \(\mathrm{Corr}(\log K,C_{\log})\) in this fixed-parameter table reflect the fact that, in the binned-profile convention used for the cross-family plot, \(C_{\log}\) increases outward while the Kretschmann scalar decreases outward. The table summarizes radial organization rather than defining a signed curvature scalar.

## Main validation results

### Schwarzschild/Flamm calibration

The Schwarzschild/Flamm embedding provides the primary calibration benchmark.

For \(M=1/2\), \(N=1000\), \(k=16\), \(r_g=3\), 12 radial bins, and ten random seeds, the Flamm/Schwarzschild benchmark gives approximately

\[
\mathrm{Corr}(r,C_{\log})_{\mathrm{Flamm}}=-0.959\pm0.018,
\]

and

\[
\mathrm{Corr}(\log K,C_{\log})_{\mathrm{Flamm}}=0.902\pm0.034.
\]

The matched-flat control gives

\[
\mathrm{Corr}(r,C_{\log})_{\mathrm{MatchedFlat}}=0.183\pm0.263.
\]

Thus, within the calibrated scan protocol, the Flamm graph shows a strong radial organization that is not reproduced by the matched-flat control.

### Reissner--Nordström charge scan

For Reissner--Nordström geometries with \(M=1/2\) and charges \(Q=0,0.1,0.2,0.3,0.4\), the radial organization remains stable over ten random seeds.

| \(Q\) | Corr\((r,C_{\log})\) | Corr\((\log K,C_{\log})\) | Corr\((r,C_{\log})_{\mathrm{flat}}\) | Difference |
| ---: | ---: | ---: | ---: | ---: |
| 0.0 | \(-0.959\pm0.018\) | \(0.902\pm0.034\) | \(0.183\pm0.263\) | \(-1.142\pm0.269\) |
| 0.1 | \(-0.962\pm0.017\) | \(0.908\pm0.032\) | \(0.183\pm0.263\) | \(-1.145\pm0.268\) |
| 0.2 | \(-0.966\pm0.016\) | \(0.916\pm0.032\) | \(0.183\pm0.263\) | \(-1.149\pm0.268\) |
| 0.3 | \(-0.974\pm0.010\) | \(0.931\pm0.022\) | \(0.183\pm0.263\) | \(-1.157\pm0.265\) |
| 0.4 | \(-0.978\pm0.008\) | \(0.944\pm0.020\) | \(0.183\pm0.263\) | \(-1.161\pm0.265\) |

### Bardeen and Hayward scans

The Bardeen and Hayward scans show similar stability. In both cases, the zero-parameter limit reduces to Schwarzschild/Flamm under the calibrated graph protocol.

Bardeen scan:

| \(g\) | Corr\((r,C_{\log})\) | Corr\((\log K,C_{\log})\) | Corr\((r,C_{\log})_{\mathrm{flat}}\) | Difference |
| ---: | ---: | ---: | ---: | ---: |
| 0.0 | \(-0.959\pm0.018\) | \(0.902\pm0.034\) | \(0.183\pm0.263\) | \(-1.142\pm0.269\) |
| 0.1 | \(-0.963\pm0.016\) | \(0.910\pm0.031\) | \(0.183\pm0.263\) | \(-1.146\pm0.269\) |
| 0.2 | \(-0.967\pm0.016\) | \(0.920\pm0.031\) | \(0.183\pm0.263\) | \(-1.150\pm0.269\) |
| 0.3 | \(-0.975\pm0.009\) | \(0.938\pm0.021\) | \(0.183\pm0.263\) | \(-1.158\pm0.265\) |

Hayward scan:

| \(\ell\) | Corr\((r,C_{\log})\) | Corr\((\log K,C_{\log})\) | Corr\((r,C_{\log})_{\mathrm{flat}}\) | Difference |
| ---: | ---: | ---: | ---: | ---: |
| 0.0 | \(-0.959\pm0.018\) | \(0.902\pm0.034\) | \(0.183\pm0.263\) | \(-1.142\pm0.269\) |
| 0.1 | \(-0.961\pm0.017\) | \(0.906\pm0.032\) | \(0.183\pm0.263\) | \(-1.144\pm0.268\) |
| 0.2 | \(-0.965\pm0.015\) | \(0.916\pm0.028\) | \(0.183\pm0.263\) | \(-1.148\pm0.266\) |
| 0.3 | \(-0.969\pm0.013\) | \(0.929\pm0.025\) | \(0.183\pm0.263\) | \(-1.152\pm0.266\) |

## Controls and baselines

### Matched-flat control

A matched-flat control uses the same radial and angular samples as the curved black-hole embedding, but removes the embedded height profile:

\[
(r\cos\phi,r\sin\phi,z(r))\longrightarrow(r\cos\phi,r\sin\phi,0).
\]

This keeps radial sampling fixed while removing the black-hole embedding height. The matched-flat control is therefore a stronger null test than a generic flat disk, because it controls for radial sampling effects.

Across the black-hole-family scans, the matched-flat control has a much weaker and noisier radial trend than the black-hole graphs.

### Graph-radius sensitivity

The estimator depends on the graph-shell radius \(r_g\). To check that the Flamm signal is not an artifact of one shell radius, the matched-flat comparison was repeated for

\[
r_g=2,3,4,5,6,7.
\]

For \(N=1000\), \(k=16\), 12 radial bins, and ten random seeds, the Flamm/matched-flat separation remains large across all tested graph radii.

| \(r_g\) | Matched-flat mean | Matched-flat std | Flamm mean | Flamm std | Difference mean | Difference std |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | 0.298 | 0.224 | -0.931 | 0.029 | -1.229 | 0.230 |
| 3 | 0.183 | 0.263 | -0.959 | 0.018 | -1.142 | 0.269 |
| 4 | 0.192 | 0.320 | -0.959 | 0.015 | -1.151 | 0.320 |
| 5 | 0.262 | 0.178 | -0.943 | 0.027 | -1.205 | 0.184 |
| 6 | 0.213 | 0.276 | -0.900 | 0.035 | -1.113 | 0.272 |
| 7 | 0.311 | 0.270 | -0.872 | 0.063 | -1.182 | 0.243 |

### Forman-Ricci baseline

A simple unweighted Forman-Ricci curvature baseline is computed on the same graph discretizations. For an unweighted graph, the edge-level Forman curvature is

\[
F(u,v)=4-\deg(u)-\deg(v),
\]

and a vertex-level score is obtained by averaging \(F(u,v)\) over the edges incident to each vertex.

For the \(N=1000\), \(k=16\) Flamm graph, the binned vertex-level Forman-Ricci score gives

\[
\mathrm{Corr}(r,F)_{\mathrm{Flamm}}\approx0.957,
\]

while the matched-flat control gives

\[
\mathrm{Corr}(r,F)_{\mathrm{MatchedFlat}}\approx0.216.
\]

This supports the interpretation that the Flamm graph contains curvature-sensitive radial structure also detected by an independent graph-curvature baseline, although with a different sign and scale from \(C_{\log}\).

### Ollivier-Ricci baseline

An exploratory Ollivier-Ricci baseline is also included. In the current graph construction, this transport-based curvature baseline does not clearly separate the Schwarzschild/Flamm graph from the matched-flat control:

\[
\mathrm{Corr}(r,\kappa_{\mathrm{OR}})_{\mathrm{Flamm}}\approx0.364,
\]

and

\[
\mathrm{Corr}(r,\kappa_{\mathrm{OR}})_{\mathrm{MatchedFlat}}\approx0.455.
\]

This result is useful as a limiting comparison. It suggests that \(C_{\log}\) is not merely reproducing a standard transport-based graph curvature, but instead captures a complementary path-multiplicity feature.

## Additional benchmark surfaces

The repository also includes non-black-hole benchmark surfaces. These tests are included to understand the limits of the diagnostic.

### Paraboloid

The paraboloid benchmark is

\[
z=a(x^2+y^2)=ar^2.
\]

Its Gaussian curvature is

\[
K_G(r)=\frac{4a^2}{(1+4a^2r^2)^2}.
\]

This benchmark is useful because the curvature strength can be controlled directly through \(a\). Unlike the Schwarzschild/Flamm benchmark, the matched-flat control can also show a strong radial trend. This demonstrates why matched controls are essential and why \(C_{\log}\) should not be interpreted as a universal curvature scalar.

### Hyperbolic paraboloid

The hyperbolic paraboloid benchmark is

\[
z=a(x^2-y^2),
\]

with Gaussian curvature

\[
K_G(x,y)=\frac{-4a^2}{(1+4a^2(x^2+y^2))^2}.
\]

Because this curvature is negative, comparisons using logarithms are made with \(\log |K_G|\). This benchmark tests the graph-construction dependence of the estimator beyond the Flamm/Schwarzschild case.

## Repository structure

```text
.
├── code/
│   └── CurvatureEstimator.wl
├── docs/
│   ├── paper_notes.md
│   ├── paper_notes.tex
│   └── quickstart.md
├── notebooks/
│   └── README.md
├── results/
│   ├── figures/
│   └── tables/
├── .gitignore
├── LICENSE
└── README.md
```

## Quick start

Open Mathematica and run:

```wolfram
Get["code/CurvatureEstimator.wl"];

SeedRandom[1234];

flamm500 = buildFlammDataset[500, 1/2, 14];

resFlamm500r3 = evaluateDataset[flamm500, 3];

binned500r3 =
  binnedFlammComparison[
    flamm500,
    resFlamm500r3,
    "LogCMD",
    12
  ];

brows = Normal[binned500r3];

Correlation[
  Log[Map[# ["KMean"] &, brows]],
  Map[# ["EstimatorMean"] &, brows]
]
```

For the multi-seed convergence experiment:

```wolfram
scan500 =
  multiSeedRadiusScan[
    500,
    Range[1, 10],
    Range[3, 4],
    14
  ];

summary500 = summarizeSeedScan[scan500];
```

For matched-flat controls, graph-radius sensitivity experiments, Forman-Ricci baselines, Ollivier-Ricci baselines, and black-hole-family scans, see the helper functions in `code/CurvatureEstimator.wl` and the notebooks in `notebooks/`.

## Current validation status

| Test | Status | Interpretation |
| --- | --- | --- |
| Estimator definition | Done | Local shell-based path-anisotropy observable |
| Schwarzschild/Flamm benchmark | Done | Tests against \(K_{\mathrm{Schw}}=48M^2/r^6\) |
| Multi-seed refinement | Done | Stability improves with graph resolution |
| Radial binning | Done | Reveals stable radial organization |
| Matched-flat control | Done | Stronger null test with the same radial sampling |
| Graph-radius sensitivity | Done | Flamm/matched-flat separation persists across \(r_g=2,\dots,7\) |
| Reissner--Nordström scan | Done | Signal persists across charge deformation |
| Bardeen scan | Done | Signal persists across regular black-hole deformation |
| Hayward scan | Done | Signal persists across regular black-hole deformation |
| Forman-Ricci baseline | Done | Independent graph-curvature baseline detects Flamm radial structure |
| Ollivier-Ricci comparison | Exploratory baseline done | Transport baseline does not clearly separate Flamm from matched flat |
| Paraboloid benchmark | Done | Shows curvature-strength sensitivity and graph/sampling dependence |
| Hyperbolic paraboloid benchmark | Exploratory | Tests response to negative curvature and matched-control dependence |
| arXiv-style manuscript | Draft prepared | Short computational methods paper in progress |

## Research status

This is an exploratory research repository. The current evidence suggests that shortest-path anisotropy tracks the spatial organization of curvature-sensitive graph structure better than raw pointwise curvature values.

The main working claim is:

> The logarithmic path-anisotropy estimator provides a local graph observable whose radial organization tracks black-hole curvature profiles in calibrated graph discretizations and is not reproduced by matched-flat controls.

The estimator should not yet be interpreted as a discrete Kretschmann scalar. A safer interpretation is that it is a curvature-sensitive diagnostic based on shortest-path anisotropy.

In short:

> \(C_{\log}\) is a Kretschmann-inspired, curvature-sensitive graph diagnostic based on shortest-path anisotropy.

## Limitations

This project is exploratory. The main current limitations are:

- The estimator is path-statistical, not tensorial.
- The estimator is not derived from a discrete Riemann tensor.
- The current main benchmark is a spatial embedding slice, not a full Lorentzian spacetime.
- The result depends on graph construction choices.
- The estimator depends on graph-shell radius \(r_g\).
- Raw vertex-level comparisons are noisy; radial binning reveals the main signal.
- Matched-flat controls are essential.
- Non-black-hole benchmark surfaces show that the method is not universal.
- The current results support a curvature-sensitive diagnostic, not a continuum-limit theorem.

## Planned next steps

- Clean the arXiv manuscript and upload a first preprint.
- Keep the repository synchronized with the paper figures and tables.
- Repeat selected matched-flat and non-black-hole tests with more random seeds.
- Compare geometric graphs, k-nearest-neighbor graphs, and distance-cutoff graphs systematically.
- Extend the benchmark set to wormhole embeddings and additional numerical surfaces.
- Explore analytic toy models for shortest-path multiplicity anisotropy.
- Extend from graph benchmarks to hypergraph evolution data.

## Project origin

This project grew out of an earlier Wolfram Community / Wolfram Summer School exploration on a possible Kretschmann-like scalar for hypergraphs:

- [Original Wolfram Community post: *Kretschmann scalar for hypergraphs*](https://community.wolfram.com/groups/-/m/t/2312929)
- [Notebook Archive version](https://www.notebookarchive.org/kretschmann-scalar-for-hypergraphs--2021-07-61wg0en/)

The original project asked whether a curvature scalar analogous to the Kretschmann scalar could be defined for hypergraph-based discrete geometries. The present repository reformulates that idea as a more cautious graph-diagnostic program based on shortest-path anisotropy.

## Suggested citation

If you use or refer to this repository, please cite it as:

```bibtex
@misc{palomino_path_anisotropy_curvature,
  author = {Palomino Ylla, Ariadna Uxue},
  title = {Path Anisotropy Curvature: A Shortest-Path Curvature Diagnostic for Graph Discretizations},
  year = {2026},
  howpublished = {\url{https://github.com/Uxuee/PathAnisotropyCurvature}}
}
```

## Author

Ariadna Uxue Palomino Ylla  
GitHub: [@Uxuee](https://github.com/Uxuee)
