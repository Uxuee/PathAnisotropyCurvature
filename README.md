# Path Anisotropy Curvature

This repository develops a graph-based curvature diagnostic inspired by geodesic shells, shortest-path statistics, and continuum curvature invariants such as the Schwarzschild Kretschmann scalar.

The project began as an exploratory Wolfram Community / Wolfram Summer School idea about a possible Kretschmann-like scalar for hypergraphs. This repository reformulates the idea more cautiously as a [...]

## TL;DR

This project tests whether local shortest-path anisotropy can act as a curvature-sensitive observable in graph discretizations of continuum geometries.

The strongest current result is obtained in a Flamm / Schwarzschild benchmark. For graph radius $r_g = 3$, the rank correlation between the logarithmic path-anisotropy estimator and the Schwarzsch[...]

|    N | Mean Spearman | Std. Spearman |
| ---: | ------------: | ------------: |
|  200 |        0.5320 |        0.1364 |
|  500 |        0.5630 |        0.0761 |
| 1000 |        0.6636 |        0.0469 |

After radial binning, the estimator shows a strong relation with the logarithmic Schwarzschild curvature profile:

$$
\mathrm{Corr}(\log K_{\mathrm{Schw}}, C_{\log}) \approx 0.912.
$$

The current interpretation is that $C_{\log}$ tracks the **curvature ordering/profile** rather than directly reproducing the Kretschmann scalar.

## Core idea

Given a graph $G$, a center vertex $p$, and a graph-distance radius $r_g$, define the graph-distance ball

$$
B_{r_g}(p) = \{ q \in G \mid d(p,q) \le r_g \},
$$

and the graph-distance shell

$$
S_{r_g}(p) = \{ q \in G \mid d(p,q) = r_g \}.
$$

The ball contains all vertices within $r_g$ graph steps of $p$. The shell is only the boundary layer: the vertices exactly $r_g$ graph steps away.

![Graph shell](results/figures/shell.png)

![Graph ball](results/figures/ball.png)

For each shell vertex $q$, count the number of shortest paths from $p$ to $q$:

$$
N_{\mathrm{geo}}(p,q)
$$

or, more explicitly, $N_{\mathrm{geo}}(p,q)$ denotes the number of distinct shortest paths from $p$ to $q$.

The estimator measures how uneven these shortest-path counts are across the shell. The working hypothesis is that curvature leaves a statistical signature in the local geodesic/path structure of a[...]

The current main estimator is the logarithmic cubic-mean-deviation version:

$$
C_{\log}(p, r_g) = \mathrm{CMD}_{q \in S_{r_g}(p)} \big( \log N_{\mathrm{geo}}(p,q) \big).
$$

This should be understood as a **curvature-sensitive diagnostic**, not yet as a rigorously derived discrete curvature invariant.

## Method at a glance

For each center vertex $p$:

1. Build the graph-distance shell $S_{r_g}(p)$.
2. Count the number of shortest paths $N_{\mathrm{geo}}(p,q)$ from $p$ to each shell vertex $q$.
3. Compute the variation of $\log N_{\mathrm{geo}}(p,q)$ over the shell.
4. Compare the resulting local estimator $C_{\log}(p,r_g)$ with a continuum curvature target.

In Mathematica, the main estimator is stored as the `LogCMD` column.

## Benchmark geometries

The repository includes simple benchmark graph discretizations, including a flat control, a hyperboloid-like surface, and a Flamm paraboloid / Schwarzschild spatial-slice-inspired graph.

![Benchmark geometries](results/figures/benchmark_geometries.png)

The main benchmark is the Flamm / Schwarzschild case. The continuum comparison target is the Schwarzschild Kretschmann scalar

$$
K_{\mathrm{Schw}} = \frac{48 M^2}{r^6}.
$$

The repository tests whether the graph estimator correlates with this radial curvature profile.

## Current preliminary results

Current exploratory Mathematica runs show:

|    N | graph radius | Mean Pearson | Mean Spearman | Std. Spearman |
| ---: | -----------: | -----------: | ------------: | ------------: |
|  200 |            3 |       0.1781 |        0.5320 |        0.1364 |
|  200 |            4 |       0.1134 |        0.3346 |        0.1661 |
|  500 |            3 |       0.1773 |        0.5630 |        0.0761 |
|  500 |            4 |       0.1666 |        0.5023 |        0.0679 |
| 1000 |            3 |       0.2460 |        0.6636 |        0.0469 |
| 1000 |            4 |       0.2496 |        0.6274 |        0.0553 |

The signal strengthens and becomes less seed-dependent as graph resolution increases.

![Mean Spearman vs N](results/figures/mean_spearman_vs_N.png)

The standard deviation across random seeds decreases as $N$ increases, suggesting improved stability under graph refinement.

![Std Spearman vs N](results/figures/std_spearman_vs_N.png)

## Radial binning

The raw vertex-level comparison is noisy because the estimator is local and the graph is randomly sprinkled. Since the Schwarzschild Kretschmann scalar depends only on radial coordinate,

$$
K_{\mathrm{Schw}} = \frac{48 M^2}{r^6},
$$

a more physically meaningful comparison is obtained by binning vertices by radial coordinate and averaging the estimator inside each radial bin.

For $N=500$, graph radius $r_g = 3$, and 12 radial bins, the binned logarithmic path-anisotropy estimator shows a strong relation with the Schwarzschild curvature profile. In the current run,

$$
\mathrm{Corr}(\log K_{\mathrm{Schw}}, C_{\log}) \approx 0.912,
$$

and the Spearman rank correlation with $K_{\mathrm{Schw}}$ is approximately

$$
\rho_{\mathrm{Spearman}} \approx 0.874.
$$

This suggests that radial binning reveals a clearer curvature profile than the raw vertex-by-vertex comparison.

### Binned estimator vs log curvature

![Binned estimator vs log curvature](results/figures/binned_estimator_vs_logK.png)

### Binned estimator vs radial coordinate

![Binned estimator vs radial coordinate](results/figures/binned_estimator_vs_r.png)

## Flat-space control

A basic flat-space control was added to check whether the estimator simply produces a different global distribution in curved and flat graphs. The global distributions of `LogCMD` overlap strongly: the Cohen's $d$ effect size is negligible,

$$
d_{\mathrm{Cohen}} \approx -0.027.
$$

This indicates that the relevant signal is not a simple global shift in the estimator.

The more meaningful comparison is radial. In the flat benchmark, the radial correlation between binned mean `LogCMD` and radial coordinate is close to zero,

$$
\mathrm{Corr}(r,C_{\log})_{\mathrm{Flat}} \approx 0.046,
$$

whereas in the Flamm / Schwarzschild benchmark the radial correlation is strongly negative,

$$
\mathrm{Corr}(r,C_{\log})_{\mathrm{Flamm}} \approx -0.957.
$$

This supports the interpretation that the estimator is sensitive to the spatial organization of the curvature profile rather than merely separating flat and curved graphs by their average value.

![Flat vs Flamm radial path anisotropy](results/figures/flat_vs_flamm_radial_logcmd.png)


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

scan500 = multiSeedRadiusScan[500, Range[1, 10], Range[3, 4], 14];

summarizeSeedScan[scan500]
```

For the binned radial comparison:

```wolfram
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
  Log[Map[#["KMean"] &, brows]],
  Map[#["EstimatorMean"] &, brows]
]
```

## Reproducing the main figures

The main convergence experiment can be reproduced with:

```wolfram
Get["code/CurvatureEstimator.wl"];

scan200 =
  multiSeedRadiusScan[
    200,
    Range[1, 10],
    Range[3, 4],
    12
  ];

scan500 =
  multiSeedRadiusScan[
    500,
    Range[1, 10],
    Range[3, 4],
    14
  ];

scan1000 =
  multiSeedRadiusScan[
    1000,
    Range[1, 5],
    Range[3, 4],
    16
  ];

summary200 = summarizeSeedScan[scan200];
summary500 = summarizeSeedScan[scan500];
summary1000 = summarizeSeedScan[scan1000];
```

The radial-binning experiment can be reproduced with:

```wolfram
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
  Log[Map[#["KMean"] &, brows]],
  Map[#["EstimatorMean"] &, brows]
]
```

## Research status

This is an exploratory research repository. The current evidence suggests that path anisotropy tracks the **ordering** of curvature better than the raw scalar magnitude. The main working claim is

> The logarithmic path-anisotropy estimator provides a local graph observable whose rank correlation with the Schwarzschild Kretschmann profile improves under graph refinement.

The estimator should not yet be interpreted as a discrete Kretschmann scalar. A safer interpretation is that it is a curvature-sensitive diagnostic based on shortest-path anisotropy.

In short:

> $C_{\log}$ is a Kretschmann-inspired, curvature-sensitive graph diagnostic based on shortest-path anisotropy.

## Limitations

This project is exploratory. The main current limitations are:

* The estimator is path-statistical, not tensorial.
* The current benchmark is a spatial Flamm / Schwarzschild slice, not a full Lorentzian spacetime.
* The result may depend on graph construction choices, especially the $k$-nearest-neighbor parameter.
* Raw vertex-level correlations are moderate; radial binning gives a stronger signal.
* Additional flat-space null tests are needed.
* Additional curved benchmarks, such as spheres, hyperbolic surfaces, and causal-set-like graphs, should be tested.
* Comparisons with existing graph curvature definitions, such as Ollivier-Ricci and Forman-Ricci curvature, remain future work.

## Planned next steps

* Add flat-space null tests.
* Add hyperboloid/sphere controls.
* Compare graph radii and neighborhood sizes.
* Compare k-nearest-neighbor graphs with distance-cutoff graphs.
* Add more radial binning plots.
* Add convergence figures with error bars.
* Test sensitivity to the $k$-nearest-neighbor parameter.
* Compare with Ollivier-Ricci, Forman-Ricci, causal-set scalar curvature, and Wolfram-model curvature constructions.
* Extend from graph benchmarks to hypergraph evolution data.

## Project origin

This project grew out of an earlier Wolfram Community / Wolfram Summer School exploration on a possible Kretschmann-like scalar for hypergraphs:

* [Original Wolfram Community post: *Kretschmann scalar for hypergraphs*](https://community.wolfram.com/groups/-/m/t/2312929)
* [Notebook Archive version](https://www.notebookarchive.org/kretschmann-scalar-for-hypergraphs--2021-07-61wg0en/)

The original project asked whether a curvature scalar analogous to the Kretschmann scalar could be defined for hypergraph-based discrete geometries. The present repository reformulates that idea [...]

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
