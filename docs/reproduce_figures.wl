(* Reproduce selected figures for PathAnisotropyCurvature. *)

Get[FileNameJoin[{NotebookDirectory[], "..", "code", "CurvatureEstimator.wl"}]];

ensureDirectory["results/figures"];
ensureDirectory["results/tables"];

SeedRandom[1234];

(* Geometry benchmarks *)
flat500 = buildFlatDataset[500, 14];
hyp500 = buildHyperboloidDataset[500, 14];
flamm500 = buildFlammDataset[500, 1/2, 14];

benchmarkGeometriesPlot =
 GraphicsRow[
  {
   plotDataset2D[flat500, "Flat control"],
   plotDataset3D[hyp500, "Hyperboloid-like"],
   plotDataset3D[flamm500, "Flamm / Schwarzschild"]
  },
  ImageSize -> Large
 ];

Export["results/figures/benchmark_geometries.png", benchmarkGeometriesPlot];

(* Colored shell/ball examples, useful for README or paper explanation. *)
centerVertex = 1;
graphRadius = 3;

flatColoredShell = coloredGeometryPlot[flat500, centerVertex, graphRadius, "Flat shell/ball example"];
flammColoredShell = coloredGeometryPlot[flamm500, centerVertex, graphRadius, "Flamm shell/ball example"];

Export["results/figures/flat_colored_shell_ball.png", flatColoredShell];
Export["results/figures/flamm_colored_shell_ball.png", flammColoredShell];

(* Main binned radial comparison. *)
resFlamm500r3 = evaluateDataset[flamm500, 3];
binned500r3 = binnedFlammComparison[flamm500, resFlamm500r3, "LogCMD", 12];

binnedEstimatorVsLogK =
 ListPlot[
  ({Log[#["KMean"]], #["EstimatorMean"]} &) /@ binned500r3,
  Frame -> True,
  FrameLabel -> {"Log of binned mean Schwarzschild K", "Binned mean LogCMD"},
  GridLines -> Automatic,
  ImageSize -> Large,
  PlotLabel -> "Binned path anisotropy vs log curvature"
 ];

binnedEstimatorVsR =
 ListPlot[
  ({#["rMean"], #["EstimatorMean"]} &) /@ binned500r3,
  Frame -> True,
  FrameLabel -> {"Mean radial coordinate r", "Binned mean LogCMD"},
  GridLines -> Automatic,
  ImageSize -> Large,
  PlotLabel -> "Binned path anisotropy decreases with radius"
 ];

Export["results/figures/binned_estimator_vs_logK.png", binnedEstimatorVsLogK];
Export["results/figures/binned_estimator_vs_r.png", binnedEstimatorVsR];

(* Matched-flat and k-sensitivity scans can be expensive. Run when needed. *)
(*
matchedFlatFlammScan1000 = matchedFlatFlammSeedScan[1000, Range[1, 5], 16, 3, 12];
Export["results/tables/matched_flat_flamm_seed_scan_N1000.csv", matchedFlatFlammScan1000];

matchedFlatFlammKScan1000 = matchedFlatFlammKScan[1000, Range[1, 3], {12, 14, 16, 18, 20}, 3, 12];
kSummary1000 = summarizeMatchedFlatKScan[matchedFlatFlammKScan1000];
Export["results/tables/k_sensitivity_matched_flat_flamm_N1000.csv", kSummary1000];
*)
