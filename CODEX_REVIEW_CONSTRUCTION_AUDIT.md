# Codex review request: construction-sensitivity multi-seed audit

Please review the pull request as a **scientific-computing and reproducibility audit**, not merely as a style review.

## Intended result

The notebook must rerun the Schwarzschild/Flamm construction-sensitivity comparison over ten paired seeds for five protocols:

1. Original matched-flat KNN
2. Strict radius
3. Pure KNN
4. Mutual KNN
5. Edge-matched radius

For each seed and protocol it must compute

\[
\Delta \rho_r =
\rho_r(C_{\log})_{\mathrm{BH}} -
\rho_r(C_{\log})_{\mathrm{flat}},
\]

then summarize \(|\Delta \rho_r|\) as mean ± standard deviation over seeds.

## Please inspect these high-risk points

1. **Alignment with the existing package**
   - The code must import `code/CurvatureEstimator.wl`.
   - It must use the package's `buildFlammDataset`, `evaluateDataset`, and `commonRadialBinnedComparison`.
   - It must not silently replace the package's calibrated epsilon convention. In particular, `distanceMatrixRadius` has a default calibration factor of 1.15.

2. **Protocol definitions**
   - Original protocol: curved epsilon graph versus matched-flat kNN.
   - Strict radius: both curved and flat graphs use the calibrated epsilon-graph rule.
   - Pure kNN: both use the same k.
   - Mutual kNN: retain an edge only when each endpoint is among the other's k nearest neighbors.
   - Edge-matched radius: flat radius graph is thresholded to match the curved graph's edge count.

3. **Paired random design**
   - For a seed, the Flamm sample must be generated exactly once.
   - Every flat control must preserve the same x-y/radial-angular sample.
   - The same seed/sample must be reused across all five protocols.

4. **Correlation pipeline**
   - BH and flat profiles must use the same common-bin implementation.
   - Missing `LogCMD` values and insufficient common bins must not produce fabricated correlations.
   - Confirm that `EstimatorMean1` is BH and `EstimatorMean2` is flat.

5. **Graph correctness**
   - Mutual-kNN edges must be a subset of pure-kNN edges.
   - Edge matching should be exact except for possible exact distance ties.
   - All graphs must retain the complete vertex set, including isolated vertices.
   - Disconnected graphs and valid-estimator fractions must be reported rather than hidden.

6. **Caching**
   - Graph evaluations are cached by edge set and radial-coordinate vector.
   - Confirm that this cache key is sufficient for the quantities used by the common-bin `LogCMD` analysis.

7. **Exports and reproducibility**
   - CSV exports must contain stable headers and one row per seed/protocol.
   - Configuration and quality-control metadata must be sufficient to reproduce the result.
   - The notebook must not overwrite unrelated project results.

8. **Performance**
   - Estimate whether the final N=1000, ten-seed run is practical.
   - Identify avoidable repeated distance matrices or graph evaluations.
   - Do not trade correctness for premature optimization.

## Tests to run

At minimum:

- Load the notebook from `notebooks/`.
- Run the static test report.
- Run the smoke configuration with N=250 and seeds {1,2}.
- Verify that all ten smoke-test protocol rows have numeric correlations or a clearly justified `Missing`.
- Verify `XYMismatch <= 1e-10` for every row.
- Verify the mutual-kNN subset assertion.
- Verify the edge-matched graph edge counts.
- Inspect one seed manually to confirm that every protocol uses the same Flamm point sample.

Run the full N=1000, ten-seed audit if the environment and time budget allow.

## Review format

Please report findings by severity:

- P0: invalidates the computation
- P1: can materially change the paper's numerical conclusion
- P2: reproducibility, robustness, or performance defect
- P3: maintainability or presentation issue

For every P0-P2 finding, propose a concrete patch and explain which numerical output it could affect.
