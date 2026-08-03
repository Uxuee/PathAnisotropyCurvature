# Paper Notes

## Working title

Path Anisotropy as a Curvature Diagnostic in Discrete Geometries

## One-sentence idea

We define a local graph observable based on the anisotropy of shortest-path counts on geodesic shells and test whether it tracks known continuum curvature profiles.

## Main benchmark

Use a Flamm/Schwarzschild spatial-slice-inspired graph and compare the estimator against

\[
K_{\mathrm{Schw}}=\frac{48M^2}{r^6}.
\]

## Current numerical result

For the logarithmic path-anisotropy estimator `LogCMD`, seed-averaged rank correlation improves with graph resolution:

| N | graph radius | Mean Spearman | Std. Spearman |
|---:|---:|---:|---:|
| 200 | 3 | 0.5320 | 0.1364 |
| 500 | 3 | 0.5630 | 0.0761 |
| 1000 | 3 | 0.6636 | 0.0469 |

This suggests refinement stability.

## Cautious interpretation

The estimator should not yet be called a discrete Kretschmann scalar. The safer statement is that it is a curvature-sensitive path anisotropy diagnostic whose rank correlation with \(K_{\mathrm{Schw}}\) improves under refinement.

## Proposed figures

1. Benchmark graphs: flat, hyperboloid, Flamm/Schwarzschild.
2. Mean Spearman correlation vs number of vertices \(N\).
3. Standard deviation of Spearman correlation vs \(N\).
4. Binned mean path anisotropy vs \(\log K_{\mathrm{Schw}}\).
5. Binned mean path anisotropy vs radial coordinate \(r\).

## Comparison section to write

Need compare against:

- Ollivier-Ricci graph curvature.
- Forman-Ricci graph/hypergraph curvature.
- Benincasa-Dowker causal-set scalar curvature.
- Higher-order causal-set curvature operators.
- Wolfram-model Riemann/Ricci curvature constructions.
- Recent path-count/Weyl curvature causal-set work.

## Main limitation

The current estimator tracks curvature ordering better than magnitude. It is not a full tensor reconstruction and is not yet a rigorously derived scalar invariant.
