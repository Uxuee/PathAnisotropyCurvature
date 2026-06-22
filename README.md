# Path Anisotropy Curvature

This repository develops a graph-based curvature diagnostic inspired by geodesic shells, shortest-path statistics, and continuum curvature invariants such as the Schwarzschild Kretschmann scalar.

The project began as an exploratory Wolfram Community / Wolfram Summer School idea about a possible Kretschmann-like scalar for hypergraphs. This repository reformulates the idea more cautiously as[...]

## Core idea

Given a graph $G$, a center vertex $p$, and a graph-distance radius $r_g$, define the shell

$$
S_{r_g}(p)=\{q\in G:d(p,q)=r_g\}.
$$

For each shell vertex $q$, count the number of shortest paths from $p$ to $q$:

$$
N_{\mathrm{geo}}(p,q).
$$

The estimator measures how uneven these shortest-path counts are across the shell. The working hypothesis is that curvature leaves a statistical signature in the local geodesic/path structure of a[...]

The current main estimator is the logarithmic cubic-mean-deviation version:

$$
C_{\log}(p,r_g) = \mathrm{CMD}_{q\in S_{r_g}(p)}\left(\log(N_{\mathrm{geo}}(p,q))\right).
$$

This should be understood as a **curvature-sensitive diagnostic**, not yet as a rigorously derived discrete curvature invariant.

## Benchmark

The main benchmark is a Flamm paraboloid / Schwarzschild spatial-slice-inspired graph. The continuum comparison target is the Schwarzschild Kretschmann scalar

$$
K_{\mathrm{Schw}}=\frac{48M^2}{r^6}.
$$

The repository tests whether the graph estimator correlates with the radial curvature profile.

## Preliminary results

Current exploratory Mathematica runs show:

| N | graph radius | Mean Pearson | Mean Spearman | Std. Spearman |
|---:|---:|---:|---:|---:|
| 200 | 3 | 0.1781 | 0.5320 | 0.1364 |
| 200 | 4 | 0.1134 | 0.3346 | 0.1661 |
| 500 | 3 | 0.1773 | 0.5630 | 0.0761 |
| 500 | 4 | 0.1666 | 0.5023 | 0.0679 |
| 1000 | 3 | 0.2460 | 0.6636 | 0.0469 |
| 1000 | 4 | 0.2496 | 0.6274 | 0.0553 |

The signal strengthens and becomes less seed-dependent as graph resolution increases.

A radial-binning test for $N=500$, graph radius $r_g=3$, shows a strong monotonic relation between binned mean path anisotropy and the Schwarzschild curvature profile. In the current run, the [...]

## Repository structure

```text
.
├── code/
│   └── CurvatureEstimator.wl
├── docs/
│   └── paper_notes.md
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

This is an exploratory research repository. The current evidence suggests that path anisotropy tracks the **ordering** of curvature better than the raw scalar magnitude. The main working claim is[...]

> The logarithmic path-anisotropy estimator provides a local graph observable whose rank correlation with the Schwarzschild Kretschmann profile improves under graph refinement.

The next step is to test robustness across graph construction choices, benchmark geometries, and hypergraph versions.

## Planned next steps

- Add flat-space null tests.
- Add hyperboloid/sphere controls.
- Compare graph radii and neighborhood sizes.
- Compare k-nearest-neighbor graphs with distance-cutoff graphs.
- Add radial binning plots.
- Add convergence figures.
- Compare with Ollivier-Ricci, Forman-Ricci, causal-set scalar curvature, and Wolfram-model curvature constructions.
- Extend from graph benchmarks to hypergraph evolution data.

## Author

Ariadna Uxue Palomino Ylla  
GitHub: [@Uxuee](https://github.com/Uxuee)
