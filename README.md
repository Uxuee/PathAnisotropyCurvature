# Path Anisotropy Curvature

This repository develops a graph-based curvature diagnostic inspired by geodesic shells, shortest-path statistics, and continuum curvature invariants such as the Schwarzschild Kretschmann scalar.

The project began as an exploratory Wolfram Community / Wolfram Summer School idea about a possible Kretschmann-like scalar for hypergraphs. This repository reformulates the idea more cautiously as [...]

## Core idea

Given a graph (G), a center vertex (p), and a graph-distance radius (r_g), define the graph-distance ball

$$
B_{r_g}(p)={q\in G:d(p,q)\leq r_g},
$$

and the graph-distance shell

$$
S_{r_g}(p)={q\in G:d(p,q)=r_g}.
$$

The ball contains all vertices within (r_g) graph steps of (p). The shell is only the boundary layer: the vertices exactly (r_g) graph steps away.

![Graph shell](results/figures/shell.png)
![Graph ball](results/figures/ball.png)

For each shell vertex (q), count the number of shortest paths from (p) to (q):

$$
N_{\mathrm{geo}}(p,q).
$$

The estimator measures how uneven these shortest-path counts are across the shell. The working hypothesis is that curvature leaves a statistical signature in the local geodesic/path structure of a[...]

The current main estimator is the logarithmic cubic-mean-deviation version:

$$
C_{\log}(p, r_g) = \operatorname{CMD}_{\,q \in S_{r_g}(p)}\!\big( \log N_{\mathrm{geo}}(p,q) \big).
$$

This should be understood as a **curvature-sensitive diagnostic**, not yet as a rigorously derived discrete curvature invariant.

## Benchmark geometries

The repository includes simple benchmark graph discretizations, including a flat control, a hyperboloid-like surface, and a Flamm paraboloid / Schwarzschild spatial-slice-inspired graph.

![Benchmark geometries](results/figures/benchmark_geometries.png)

The main benchmark is the Flamm / Schwarzschild case. The continuum comparison target is the Schwarzschild Kretschmann scalar

$$
K_{\mathrm{Schw}}=\frac{48M^2}{r^6}.
$$

The repository tests whether the graph estimator correlates with this radial curvature profile.

## Preliminary results

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

The standard deviation across random seeds decreases as (N) increases, suggesting improved stability under graph refinement.

![Std Spearman vs N](results/figures/std_spearman_vs_N.png)

## Radial binning

The raw vertex-level comparison is noisy because the estimator is local and the graph is randomly sprinkled. Since the Schwarzschild Kretschmann scalar depends only on radial coordinate,

$$
K_{\mathrm{Schw}}=\frac{48M^2}{r^6},
$$

a more physically meaningful comparison is obtained by binning vertices by radial coordinate and averaging the estimator inside each radial bin.

For (N=500) and graph radius (r_g=3), the binned estimator decreases with radial distance, matching the expected decrease of the Schwarzschild curvature profile.

![Binned estimator vs radial coordinate](results/figures/binned_estimator_vs_r.png)

Because (K_{\mathrm{Schw}}) changes by orders of magnitude, the relation is clearer when the estimator is compared with (\log K_{\mathrm{Schw}}).

![Binned estimator vs log curvature](results/figures/binned_estimator_vs_logK.png)

The current binned runs suggest that the path-anisotropy estimator tracks the curvature profile more clearly after radial averaging than in the raw vertex-by-vertex comparison.

## Repository structure

```text
.
├── code/
│   └── CurvatureEstimator.wl
├── docs/
│   ├── paper_notes.md
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

## Research status

This is an exploratory research repository. The current evidence suggests that path anisotropy tracks the **ordering** of curvature better than the raw scalar magnitude. The main working claim is:

> The logarithmic path-anisotropy estimator provides a local graph observable whose rank correlation with the Schwarzschild Kretschmann profile improves under graph refinement.

The estimator should not yet be interpreted as a discrete Kretschmann scalar. A safer interpretation is that it is a curvature-sensitive diagnostic based on shortest-path anisotropy.

## Planned next steps

* Add flat-space null tests.
* Add hyperboloid/sphere controls.
* Compare graph radii and neighborhood sizes.
* Compare k-nearest-neighbor graphs with distance-cutoff graphs.
* Add more radial binning plots.
* Add convergence figures with error bars.
* Compare with Ollivier-Ricci, Forman-Ricci, causal-set scalar curvature, and Wolfram-model curvature constructions.
* Extend from graph benchmarks to hypergraph evolution data.

## Possible paper direction

Possible titles:

* **Path Anisotropy as a Curvature Diagnostic in Discrete Geometries**
* **A Geodesic-Shell Curvature Estimator for Graph and Hypergraph Discretizations**
* **Shortest-Path Anisotropy and Curvature Profiles in Discrete Spacetime Benchmarks**

## Author

Ariadna Uxue Palomino Ylla
GitHub: [@Uxuee](https://github.com/Uxuee)
