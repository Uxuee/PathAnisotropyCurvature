# Quickstart Mathematica Commands

```wolfram
Get["code/CurvatureEstimator.wl"];

SeedRandom[1234];

flat500 = buildFlatDataset[500, 14];
hyp500 = buildHyperboloidDataset[500, 14];
flamm500 = buildFlammDataset[500, 1/2, 14];

GraphicsRow[
 {
  plotDataset2D[flat500, "Flat control"],
  plotDataset3D[hyp500, "Hyperboloid"],
  plotDataset3D[flamm500, "Flamm / Schwarzschild"]
 },
 ImageSize -> Large
]

scan500 =
 multiSeedRadiusScan[
  500,
  Range[1, 10],
  Range[3, 4],
  14
 ];

summarizeSeedScan[scan500]

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

ListPlot[
 ({Log[#["KMean"]], #["EstimatorMean"]} &) /@ brows,
 Frame -> True,
 FrameLabel -> {
   "Log of binned mean Schwarzschild K",
   "Binned mean LogCMD"
 },
 GridLines -> Automatic,
 ImageSize -> Large
]
```
