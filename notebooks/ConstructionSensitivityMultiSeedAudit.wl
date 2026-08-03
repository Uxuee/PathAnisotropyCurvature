(* ::Title:: *)
(*Construction-Sensitivity Multi-Seed Audit*)

(* ::Subtitle:: *)
(*Shortest-path anisotropy in Schwarzschild/Flamm and matched-flat graphs*)

(* ::Text:: *)
(*Purpose

This notebook performs the minimum defensible rerun required by the unified paper:

  - Schwarzschild/Flamm benchmark
  - five diagnostic--construction--control protocols
  - ten paired random seeds
  - N = 1000, k = 16, graph-shell radius r_g = 3
  - 12 common radial bins
  - mean +/- standard deviation of |Delta rho_r|

The notebook deliberately imports code/CurvatureEstimator.wl instead of
reimplementing the established estimator. This keeps the rerun aligned with the
repository's calibrated graph convention, including the default 1.15 factor in
distanceMatrixRadius.

The curved and flat graphs always use the same radial/angular sample for a seed.
Each seed is generated once and reused for all five protocols.
*)

(* ::Section:: *)
(*0. Locate and load the project package*)

ClearAll["Global`*"];

ClearAll[resolveRepoRoot];
resolveRepoRoot[] :=
 Module[{nbdir, inputDir, candidates, found},
  nbdir = Quiet @ Check[NotebookDirectory[], $Failed];
  inputDir =
   If[StringQ[$InputFileName] && StringLength[$InputFileName] > 0,
    DirectoryName[ExpandFileName[$InputFileName]],
    Directory[]
    ];

  candidates = DeleteDuplicates @ Select[
     {
      If[StringQ[nbdir], ExpandFileName @ FileNameJoin[{nbdir, ".."}], Nothing],
      ExpandFileName @ FileNameJoin[{inputDir, ".."}],
      ExpandFileName[inputDir],
      ExpandFileName[Directory[]]
      },
     StringQ
     ];

  found = SelectFirst[
    candidates,
    FileExistsQ @ FileNameJoin[{#, "code", "CurvatureEstimator.wl"}] &,
    Missing["RepositoryRootNotFound"]
    ];

  found
  ];

repoRoot = resolveRepoRoot[];

If[MissingQ[repoRoot],
 Print[
  "ERROR: Could not find code/CurvatureEstimator.wl. ",
  "Place this notebook in the repository notebooks/ directory."
  ];
 Abort[];
 ];

packagePath = FileNameJoin[{repoRoot, "code", "CurvatureEstimator.wl"}];
Get[packagePath];

Print["Repository root: ", repoRoot];
Print["Loaded package: ", packagePath];


(* ::Section:: *)
(*1. Configuration*)

auditVersion = "2026-08-multiseed-construction-audit-v2";

protocolOrder = {
   "Original matched-flat KNN",
   "Strict radius",
   "Pure KNN",
   "Mutual KNN",
   "Edge-matched radius"
   };

defaultConfig = <|
   "N" -> 1000,
   "k" -> 16,
   "M" -> 1/2,
   "GraphShellRadius" -> 3,
   "Bins" -> 12,
   "Seeds" -> Range[10],
   "Protocols" -> protocolOrder,
   "MinimumCommonBins" -> 6,
   "OutputDirectory" ->
    FileNameJoin[{repoRoot, "results", "construction_audit_multiseed"}]
   |>;

ClearAll[validatedConfig];
validatedConfig[cfg_Association] :=
 Module[{required, missing},
  required = Keys[defaultConfig];
  missing = Complement[required, Keys[cfg]];
  If[missing =!= {},
   Print["ERROR: Missing configuration keys: ", missing];
   Abort[];
   ];

  If[! IntegerQ[cfg["N"]] || cfg["N"] < 20, Abort[]];
  If[! IntegerQ[cfg["k"]] || cfg["k"] < 1 || cfg["k"] >= cfg["N"], Abort[]];
  If[! IntegerQ[cfg["GraphShellRadius"]] || cfg["GraphShellRadius"] < 1, Abort[]];
  If[! IntegerQ[cfg["Bins"]] || cfg["Bins"] < 3, Abort[]];
  If[! VectorQ[cfg["Seeds"], IntegerQ], Abort[]];
  If[! SubsetQ[protocolOrder, cfg["Protocols"]], Abort[]];

  cfg
  ];

config = validatedConfig[defaultConfig];

If[! DirectoryQ[config["OutputDirectory"]],
 CreateDirectory[
  config["OutputDirectory"],
  CreateIntermediateDirectories -> True
  ]
 ];

Print["Audit version: ", auditVersion];
Print["Output directory: ", config["OutputDirectory"]];


(* ::Section:: *)
(*2. Small helpers*)

ClearAll[
  finiteNumericQ,
  assocLookupAny,
  datasetEvaluationKey,
  graphQuality,
  validEstimatorFraction,
  datasetWithGraph,
  flatPointsFromFlamm
  ];

finiteNumericQ[x_] := TrueQ[PathAnisotropyCurvature`validRealNumberQ[x]];

assocLookupAny[a_Association, keys_List, default_: Missing["NotAvailable"]] :=
 SelectFirst[
  Lookup[a, #, Missing["NotAvailable"]] & /@ keys,
  Not @* MissingQ,
  default
  ];

datasetEvaluationKey[data_Association] :=
 Hash[
  {
   Sort[Sort /@ (List @@@ EdgeList[data["Graph"]])],
   N @ Lookup[data, "r", {}]
   },
  "SHA256"
  ];

graphQuality[g_Graph] :=
 Module[{n, degrees, sizes},
  n = VertexCount[g];
  degrees = VertexDegree[g];
  sizes = Length /@ ConnectedComponents[g];

  <|
   "VertexCount" -> n,
   "EdgeCount" -> EdgeCount[g],
   "MeanDegree" -> N @ Mean[degrees],
   "IsolatedVertices" -> Count[degrees, 0],
   "ConnectedComponents" -> Length[sizes],
   "LargestComponentFraction" ->
    If[n > 0 && sizes =!= {}, N[Max[sizes]/n], 0.]
   |>
  ];

validEstimatorFraction[res_] :=
 Module[{rows, vals},
  rows = Normal[res];
  If[! ListQ[rows] || rows === {}, Return[0.]];
  vals = PathAnisotropyCurvature`getRowValue[#, "LogCMD"] & /@ rows;
  N[Count[vals, _?finiteNumericQ]/Length[vals]]
  ];

flatPointsFromFlamm[flamm_Association] :=
 Module[{pts3},
  pts3 = Lookup[flamm, "Points"];
  pts3[[All, 1 ;; 2]]
  ];

datasetWithGraph[
  template_Association,
  points_?MatrixQ,
  graph_Graph,
  type_String,
  label_String
  ] :=
 Module[{n, rvals, targetK},
  n = Length[points];
  rvals = Norm /@ points[[All, 1 ;; 2]];
  targetK = Lookup[template, "TargetK", ConstantArray[0., n]];

  <|
   "Type" -> type,
   "Label" -> label,
   "N" -> n,
   "k" -> Lookup[template, "k", Missing["NotAvailable"]],
   "Points" -> points,
   "r" -> rvals,
   "Graph" -> graph,
   "TargetK" -> targetK
   |>
  ];


(* ::Section:: *)
(*3. Additional graph constructors required by the audit*)

ClearAll[
  makeMutualKNNGraph,
  radiusForTargetEdgeCount,
  makeEdgeMatchedRadiusDataset
  ];

makeMutualKNNGraph[points_?MatrixQ, k_Integer?Positive] :=
 Module[{n, dm, neighbors, edges, coords},
  n = Length[points];
  If[k >= n, Return[$Failed]];

  dm = DistanceMatrix[points];
  neighbors =
   Table[
    Rest @ Ordering[dm[[i]], k + 1],
    {i, n}
    ];

  edges =
   DeleteDuplicates @ Flatten[
     Table[
      If[
       i < j && MemberQ[neighbors[[j]], i],
       UndirectedEdge[i, j],
       Nothing
       ],
      {i, n},
      {j, neighbors[[i]]}
      ]
     ];

  coords = points[[All, 1 ;; Min[3, Length[First[points]]]]];

  Graph[
   Range[n],
   edges,
   VertexCoordinates -> coords
   ]
  ];

radiusForTargetEdgeCount[
  points_?MatrixQ,
  targetEdges_Integer?Positive
  ] :=
 Module[{n, dm, upper, idx},
  n = Length[points];
  dm = DistanceMatrix[points];

  upper = Sort @ Flatten[
      Table[
       dm[[i, j]],
       {i, 1, n - 1},
       {j, i + 1, n}
       ]
      ];

  idx = Clip[targetEdges, {1, Length[upper]}];
  N[upper[[idx]]]
  ];

ClearAll[edgeMatchDiagnostics];
edgeMatchDiagnostics[points_?MatrixQ, eps_?NumericQ, targetEdges_Integer] :=
 Module[{distances, below, tied},
  distances = Flatten @ Table[
      EuclideanDistance[points[[i]], points[[j]]],
      {i, 1, Length[points] - 1}, {j, i + 1, Length[points]}
      ];
  below = Count[distances, d_ /; d < eps];
  tied = Count[distances, d_ /; PossibleZeroQ[d - eps]];
  <|
   "TargetEdges" -> targetEdges,
   "EdgesStrictlyBelowRadius" -> below,
   "EdgesTiedAtRadius" -> tied,
   "ExactMatchPossibleWithRadiusThreshold" ->
    TrueQ[targetEdges == below || targetEdges == below + tied]
   |>
  ];

makeEdgeMatchedRadiusDataset[
  template_Association,
  points_?MatrixQ,
  targetEdges_Integer?Positive,
  type_String,
  label_String
  ] :=
 Module[{eps, g, diagnostics},
  eps = radiusForTargetEdgeCount[points, targetEdges];
  g = PathAnisotropyCurvature`makeGeometricGraph[points, eps];
  diagnostics = edgeMatchDiagnostics[points, eps, targetEdges];

  Join[
   datasetWithGraph[template, points, g, type, label],
   <|"AuditEpsilon" -> eps, "EdgeMatchDiagnostics" -> diagnostics|>
   ]
  ];


(* ::Section:: *)
(*4. Build all five protocol pairs from one shared seed*)

ClearAll[buildProtocolPairs];

buildProtocolPairs[
  flamm_Association,
  cfg_Association
  ] :=
 Module[
  {
   k, bhPoints, flatPoints,
   originalFlat, strictFlat,
   bhKNN, flatKNN,
   bhMutual, flatMutual,
   edgeMatchedFlat,
   bhKNNData, flatKNNData,
   bhMutualData, flatMutualData,
   bhEdges
   },

  k = cfg["k"];
  bhPoints = Lookup[flamm, "Points"];
  flatPoints = flatPointsFromFlamm[flamm];

  (* Current repository's original control: curved epsilon graph vs flat kNN. *)
  originalFlat =
   PathAnisotropyCurvature`buildMatchedFlatFromFlamm3[flamm, k];

  (* Strict radius protocol: each geometry uses the same calibrated
     distanceMatrixRadius rule. This intentionally uses the repository helper,
     whose default calibration factor is 1.15. *)
  strictFlat =
   PathAnisotropyCurvature`buildMatchedFlatGeometricFromFlamm[flamm, k];

  (* Pure kNN protocol. *)
  bhKNN = PathAnisotropyCurvature`makeKNNGraph[bhPoints, k];
  flatKNN = PathAnisotropyCurvature`makeKNNGraph[flatPoints, k];

  bhKNNData =
   datasetWithGraph[
    flamm, bhPoints, bhKNN,
    "FlammKNN", "Schwarzschild/Flamm (kNN)"
    ];

  flatKNNData =
   datasetWithGraph[
    originalFlat, flatPoints, flatKNN,
    "MatchedFlatKNN", "Matched flat (kNN)"
    ];

  (* Mutual-kNN protocol. *)
  bhMutual = makeMutualKNNGraph[bhPoints, k];
  flatMutual = makeMutualKNNGraph[flatPoints, k];

  bhMutualData =
   datasetWithGraph[
    flamm, bhPoints, bhMutual,
    "FlammMutualKNN", "Schwarzschild/Flamm (mutual kNN)"
    ];

  flatMutualData =
   datasetWithGraph[
    originalFlat, flatPoints, flatMutual,
    "MatchedFlatMutualKNN", "Matched flat (mutual kNN)"
    ];

  (* Edge-matched radius protocol:
     keep the calibrated Flamm epsilon graph and choose the flat radius
     threshold so its edge count matches the Flamm edge count. *)
  bhEdges = EdgeCount[Lookup[flamm, "Graph"]];

  edgeMatchedFlat =
   makeEdgeMatchedRadiusDataset[
    originalFlat,
    flatPoints,
    bhEdges,
    "MatchedFlatEdgeMatchedRadius",
    "Matched flat (edge-matched radius)"
    ];

  <|
   "Original matched-flat KNN" ->
    <|"BH" -> flamm, "Flat" -> originalFlat|>,

   "Strict radius" ->
    <|"BH" -> flamm, "Flat" -> strictFlat|>,

   "Pure KNN" ->
    <|"BH" -> bhKNNData, "Flat" -> flatKNNData|>,

   "Mutual KNN" ->
    <|"BH" -> bhMutualData, "Flat" -> flatMutualData|>,

   "Edge-matched radius" ->
    <|"BH" -> flamm, "Flat" -> edgeMatchedFlat|>
   |>
  ];


(* ::Section:: *)
(*5. Quality-control checks*)

ClearAll[maximumXYMismatch, protocolQualityChecks];

maximumXYMismatch[
  bh_Association,
  flat_Association
  ] :=
 Module[{xyBH, xyFlat},
  xyBH = Lookup[bh, "Points"][[All, 1 ;; 2]];
  xyFlat = Lookup[flat, "Points"][[All, 1 ;; 2]];
  Max[Abs @ Flatten[xyBH - xyFlat]]
  ];

protocolQualityChecks[
  pairs_Association,
  cfg_Association
  ] :=
 Module[{rows, pureEdges, mutualEdges, edgePair},

  rows = KeyValueMap[
    Function[
     {protocol, pair},
     Module[{bh, flat, qBH, qFlat, mismatch},
      bh = pair["BH"];
      flat = pair["Flat"];
      qBH = graphQuality[bh["Graph"]];
      qFlat = graphQuality[flat["Graph"]];
      mismatch = maximumXYMismatch[bh, flat];

      <|
       "Protocol" -> protocol,
       "XYMismatch" -> mismatch,
       "BHEdges" -> qBH["EdgeCount"],
       "FlatEdges" -> qFlat["EdgeCount"],
       "BHComponents" -> qBH["ConnectedComponents"],
       "FlatComponents" -> qFlat["ConnectedComponents"],
       "BHLargestComponentFraction" -> qBH["LargestComponentFraction"],
       "FlatLargestComponentFraction" -> qFlat["LargestComponentFraction"]
       |>
      ]
     ],
    pairs
    ];

  If[Max[Lookup[rows, "XYMismatch"]] > 10^-10,
   Print["ERROR: curved and flat point samples are not paired."];
   Abort[];
   ];

  pureEdges =
   Sort[Sort /@ (List @@@ EdgeList[pairs["Pure KNN"]["BH"]["Graph"]])];

  mutualEdges =
   Sort[Sort /@ (List @@@ EdgeList[pairs["Mutual KNN"]["BH"]["Graph"]])];

  If[! SubsetQ[pureEdges, mutualEdges],
   Print["ERROR: mutual-kNN edges are not a subset of pure-kNN edges."];
   Abort[];
   ];

  pureEdges =
   Sort[Sort /@ (List @@@ EdgeList[pairs["Pure KNN"]["Flat"]["Graph"]])];
  mutualEdges =
   Sort[Sort /@ (List @@@ EdgeList[pairs["Mutual KNN"]["Flat"]["Graph"]])];

  If[! SubsetQ[pureEdges, mutualEdges],
   Print["ERROR: flat mutual-kNN edges are not a subset of flat pure-kNN edges."];
   Abort[];
   ];

  edgePair = pairs["Edge-matched radius"];
  If[
   Abs[
     EdgeCount[edgePair["BH"]["Graph"]] -
      EdgeCount[edgePair["Flat"]["Graph"]]
     ] > 0,
   Print[
    "WARNING: radius threshold cannot select an exact target edge count ",
    "because multiple pairs are tied at the boundary distance."
    ];
   ];

  rows
  ];


(* ::Section:: *)
(*6. Common-bin correlation calculation*)

ClearAll[commonProfileCorrelations];

commonProfileCorrelations[
  bh_Association,
  bhResult_,
  flat_Association,
  flatResult_,
  cfg_Association
  ] :=
 Module[{common, r, bhMean, flatMean, rhoBH, rhoFlat},

  common =
   PathAnisotropyCurvature`commonRadialBinnedComparison[
    bh,
    bhResult,
    flat,
    flatResult,
    "LogCMD",
    cfg["Bins"]
    ];

  If[
   ! ListQ[common] ||
    Length[common] < cfg["MinimumCommonBins"],
   Return[
    <|
     "CommonProfile" -> common,
     "CommonBins" -> If[ListQ[common], Length[common], 0],
     "RhoBH" -> Missing["InsufficientCommonBins"],
     "RhoFlat" -> Missing["InsufficientCommonBins"],
     "DeltaRho" -> Missing["InsufficientCommonBins"],
     "AbsDeltaRho" -> Missing["InsufficientCommonBins"]
     |>
    ];
   ];

  r = Lookup[common, "rMean"];
  bhMean = Lookup[common, "EstimatorMean1"];
  flatMean = Lookup[common, "EstimatorMean2"];

  rhoBH = PathAnisotropyCurvature`safeCorrelation[r, bhMean];
  rhoFlat = PathAnisotropyCurvature`safeCorrelation[r, flatMean];

  <|
   "CommonProfile" -> common,
   "CommonBins" -> Length[common],
   "RhoBH" -> rhoBH,
   "RhoFlat" -> rhoFlat,
   "DeltaRho" ->
    If[finiteNumericQ[rhoBH] && finiteNumericQ[rhoFlat],
     N[rhoBH - rhoFlat],
     Missing["InvalidCorrelation"]
     ],
   "AbsDeltaRho" ->
    If[finiteNumericQ[rhoBH] && finiteNumericQ[rhoFlat],
     N @ Abs[rhoBH - rhoFlat],
     Missing["InvalidCorrelation"]
     ]
   |>
  ];


(* ::Section:: *)
(*7. Run one seed, reusing graphs and cached evaluations*)

ClearAll[runOneSeed];

runOneSeed[
  seed_Integer,
  cfg_Association
  ] :=
 Module[
  {
   flamm, pairs, qcRows, cache, getEvaluation,
   protocolRows, rg
   },

  rg = cfg["GraphShellRadius"];

  BlockRandom[
   SeedRandom[seed];
   flamm =
    PathAnisotropyCurvature`buildFlammDataset[
     cfg["N"],
     cfg["M"],
     cfg["k"]
     ];
   ];

  If[flamm === $Failed,
   Print["ERROR: failed to build Flamm data for seed ", seed];
   Return[$Failed];
   ];

  pairs = buildProtocolPairs[flamm, cfg];
  qcRows = Append[#, "Seed" -> seed] & /@ protocolQualityChecks[pairs, cfg];

  cache = <||>;

  getEvaluation[data_Association] :=
   Module[{key},
    key = datasetEvaluationKey[data];

    If[
     KeyExistsQ[cache, key],
     cache[key],
     AssociateTo[
      cache,
      key ->
       PathAnisotropyCurvature`evaluateDataset[
        data,
        rg
        ]
      ];
     cache[key]
     ]
    ];

  protocolRows =
   Table[
    Module[
     {
      protocol, pair, bh, flat,
      bhRes, flatRes, corr,
      qBH, qFlat, epsBH, epsFlat
      },

     protocol = protocolName;
     pair = pairs[protocol];
     bh = pair["BH"];
     flat = pair["Flat"];

     bhRes = getEvaluation[bh];
     flatRes = getEvaluation[flat];

     corr = commonProfileCorrelations[
       bh, bhRes, flat, flatRes, cfg
       ];

     qBH = graphQuality[bh["Graph"]];
     qFlat = graphQuality[flat["Graph"]];

     epsBH =
      assocLookupAny[
       bh,
       {"AuditEpsilon", "Epsilon", "eps"},
       Missing["NotRadiusGraphOrUnavailable"]
       ];

     epsFlat =
      assocLookupAny[
       flat,
       {"AuditEpsilon", "Epsilon", "eps"},
       Missing["NotRadiusGraphOrUnavailable"]
       ];

     <|
      "AuditVersion" -> auditVersion,
      "Model" -> "Schwarzschild/Flamm",
      "Seed" -> seed,
      "Protocol" -> protocol,
      "N" -> cfg["N"],
      "k" -> cfg["k"],
      "GraphShellRadius" -> cfg["GraphShellRadius"],
      "BinsRequested" -> cfg["Bins"],
      "CommonBins" -> corr["CommonBins"],
      "RhoBH" -> corr["RhoBH"],
      "RhoFlat" -> corr["RhoFlat"],
      "DeltaRho" -> corr["DeltaRho"],
      "AbsDeltaRho" -> corr["AbsDeltaRho"],
      "BHValidLogCMDFraction" -> validEstimatorFraction[bhRes],
      "FlatValidLogCMDFraction" -> validEstimatorFraction[flatRes],
      "BHEdges" -> qBH["EdgeCount"],
      "FlatEdges" -> qFlat["EdgeCount"],
      "BHMeanDegree" -> qBH["MeanDegree"],
      "FlatMeanDegree" -> qFlat["MeanDegree"],
      "BHComponents" -> qBH["ConnectedComponents"],
      "FlatComponents" -> qFlat["ConnectedComponents"],
      "BHLargestComponentFraction" ->
       qBH["LargestComponentFraction"],
      "FlatLargestComponentFraction" ->
       qFlat["LargestComponentFraction"],
      "BHRadius" -> epsBH,
      "FlatRadius" -> epsFlat,
      "EdgeCountDifference" -> qFlat["EdgeCount"] - qBH["EdgeCount"],
      "FlatEdgesTiedAtRadius" ->
       Lookup[
        Lookup[flat, "EdgeMatchDiagnostics", <||>],
        "EdgesTiedAtRadius",
        Missing["NotEdgeMatchedRadius"]
        ],
      "XYMismatch" -> maximumXYMismatch[bh, flat]
      |>
     ],
    {protocolName, cfg["Protocols"]}
    ];

  <|
   "Seed" -> seed,
   "Rows" -> protocolRows,
   "QualityControl" -> qcRows
   |>
  ];


(* ::Section:: *)
(*8. Full audit and summaries*)

ClearAll[
  runAudit,
  summarizeAudit,
  wideSummaryDataset,
  auditPlot
  ];

runAudit[cfg_Association : defaultConfig] :=
 Module[{validated, seedRuns, rows, qc},
  validated = validatedConfig[cfg];

  seedRuns =
   Table[
    Print[
     "Running seed ", seed, " of ",
     Length[validated["Seeds"]]
     ];
    runOneSeed[seed, validated],
    {seed, validated["Seeds"]}
    ];

  If[MemberQ[seedRuns, $Failed],
   Print["ERROR: at least one seed failed."];
   Return[$Failed];
   ];

  rows = Flatten[Lookup[seedRuns, "Rows"], 1];
  qc = Flatten[Lookup[seedRuns, "QualityControl"], 1];

  <|
   "Config" -> validated,
   "Rows" -> rows,
   "QualityControl" -> qc
   |>
  ];

summarizeAudit[rows_List] :=
 Module[{valid, grouped},

  valid =
   Select[
    rows,
    finiteNumericQ[Lookup[#, "AbsDeltaRho", Missing[]]] &
    ];

  grouped = GroupBy[valid, #["Protocol"] &];

  Table[
   Module[{group, vals, deltas, n, mean, sd, sem, tcrit, ci},
    group = Lookup[grouped, protocol, {}];
    vals = Lookup[group, "AbsDeltaRho", {}];
    deltas = Lookup[group, "DeltaRho", {}];
    n = Length[vals];

    mean = If[n > 0, N @ Mean[vals], Missing["NoRuns"]];
    sd =
     If[n > 1,
      N @ StandardDeviation[vals],
      Missing["NeedAtLeastTwoSeeds"]
      ];
    sem =
     If[n > 1,
      N[sd/Sqrt[n]],
      Missing["NeedAtLeastTwoSeeds"]
      ];
    tcrit =
     If[n > 1,
      N @ Quantile[StudentTDistribution[n - 1], 0.975],
      Missing["NeedAtLeastTwoSeeds"]
      ];
    ci =
     If[n > 1,
      N[tcrit sem],
      Missing["NeedAtLeastTwoSeeds"]
      ];

    <|
     "Protocol" -> protocol,
     "MeanAbsDeltaRho" -> mean,
     "StdAbsDeltaRho" -> sd,
     "SEMAbsDeltaRho" -> sem,
     "CI95HalfWidth" -> ci,
     "MinAbsDeltaRho" -> If[n > 0, N @ Min[vals], Missing[]],
     "MaxAbsDeltaRho" -> If[n > 0, N @ Max[vals], Missing[]],
     "MeanDeltaRho" ->
      If[n > 0, N @ Mean[deltas], Missing["NoRuns"]],
     "PositiveDeltaFraction" ->
      If[n > 0, N @ Mean[Boole[# > 0] & /@ deltas], Missing[]],
     "NSeeds" -> n
     |>
    ],
   {protocol, protocolOrder}
   ]
  ];

wideSummaryDataset[summaryRows_List] :=
 Dataset[
  Association @ Table[
    row["Protocol"] ->
     Row[{
       NumberForm[row["MeanAbsDeltaRho"], {5, 3}],
       " +/- ",
       NumberForm[row["StdAbsDeltaRho"], {5, 3}]
       }],
    {row, summaryRows}
    ]
  ];

auditPlot[summaryRows_List] :=
 Module[{means, sds, labels, points},
  means = Lookup[summaryRows, "MeanAbsDeltaRho"];
  sds = Lookup[summaryRows, "StdAbsDeltaRho"];
  labels = Lookup[summaryRows, "Protocol"];

  points =
   MapIndexed[
    {First[#2], Around[#1, sds[[First[#2]]]]} &,
    means
    ];

  ListPlot[
   points,
   Frame -> True,
   FrameLabel -> {"Construction/control protocol", "Mean |Delta rho_r|"},
   FrameTicks -> {
     {Automatic, None},
     {Thread[{Range[Length[labels]], labels}], None}
     },
   PlotRange -> All,
   PlotMarkers -> Automatic,
   IntervalMarkers -> "Bars",
   ImageSize -> Large,
   PlotLabel -> "Ten-seed construction-sensitivity audit"
   ]
  ];


(* ::Section:: *)
(*9. Export reproducible outputs*)

ClearAll[exportAudit];

exportAudit[
  audit_Association,
  stem_String : "schwarzschild_five_protocols_10seeds"
  ] :=
 Module[
  {
   cfg, rows, qc, summary, plot,
   outDir, paths, manuscriptText
   },

  cfg = audit["Config"];
  rows = audit["Rows"];
  qc = audit["QualityControl"];
  summary = summarizeAudit[rows];
  plot = auditPlot[summary];
  outDir = cfg["OutputDirectory"];

  paths = <|
    "RawCSV" -> FileNameJoin[{outDir, stem <> "_raw.csv"}],
    "SummaryCSV" -> FileNameJoin[{outDir, stem <> "_summary.csv"}],
    "QualityControlCSV" ->
     FileNameJoin[{outDir, stem <> "_quality_control.csv"}],
    "ConfigJSON" -> FileNameJoin[{outDir, stem <> "_config.json"}],
    "SummaryMX" -> FileNameJoin[{outDir, stem <> "_summary.mx"}],
    "PlotPDF" -> FileNameJoin[{outDir, stem <> "_mean_sd.pdf"}],
    "PlotPNG" -> FileNameJoin[{outDir, stem <> "_mean_sd.png"}],
    "PaperText" -> FileNameJoin[{outDir, stem <> "_paper_text.txt"}]
    |>;

  PathAnisotropyCurvature`exportDatasetCSV[paths["RawCSV"], rows];
  PathAnisotropyCurvature`exportDatasetCSV[paths["SummaryCSV"], summary];
  PathAnisotropyCurvature`exportDatasetCSV[paths["QualityControlCSV"], qc];

  Export[paths["ConfigJSON"], Normal[cfg], "JSON"];
  Export[paths["SummaryMX"], summary];
  Export[paths["PlotPDF"], plot];
  Export[paths["PlotPNG"], plot, ImageResolution -> 220];

  manuscriptText =
   StringRiffle[
    {
     "Construction-sensitivity multi-seed rerun",
     "",
     "For the Schwarzschild/Flamm benchmark, each diagnostic--construction--control protocol was repeated over " <>
      ToString[Length[cfg["Seeds"]]] <>
      " paired random seeds. The curved and matched-flat graphs shared the same radial and angular sample within each seed. For every run, C_log was radially binned using the common-bin comparison pipeline, and we computed Delta rho_r = rho_r(C_log)_BH - rho_r(C_log)_flat. The reported separation is |Delta rho_r|, summarized as mean +/- standard deviation across seeds.",
     "",
     "Protocol summary:",
     StringRiffle[
      Table[
       row["Protocol"] <> ": " <>
        ToString @ NumberForm[row["MeanAbsDeltaRho"], {5, 3}] <>
        " +/- " <>
        ToString @ NumberForm[row["StdAbsDeltaRho"], {5, 3}] <>
        " (n=" <> ToString[row["NSeeds"]] <> ")",
       {row, summary}
       ],
      "\n"
      ]
     },
    "\n"
    ];

  Export[paths["PaperText"], manuscriptText, "Text"];

  <|
   "Paths" -> paths,
   "Summary" -> summary,
   "Plot" -> plot
   |>
  ];


(* ::Section:: *)
(*10. Static self-checks*)

ClearAll[runStaticSelfChecks];

runStaticSelfChecks[] :=
 Module[{tiny, pure, mutual, subsetOK, completeVerticesOK},
  tiny = {
    {0., 0.},
    {1., 0.},
    {0., 1.},
    {1., 1.},
    {0.5, 0.5}
    };

  pure = PathAnisotropyCurvature`makeKNNGraph[tiny, 3];
  mutual = makeMutualKNNGraph[tiny, 3];

  subsetOK =
   SubsetQ[
    Sort[Sort /@ (List @@@ EdgeList[pure])],
    Sort[Sort /@ (List @@@ EdgeList[mutual])]
    ];

  completeVerticesOK = Sort[VertexList[mutual]] === Range[Length[tiny]];

  TestReport[
   {
    VerificationTest[
     FileExistsQ[packagePath],
     True,
     TestID -> "project package exists"
     ],
    VerificationTest[
     subsetOK,
     True,
     TestID -> "mutual-kNN is a subset of pure-kNN"
     ],
    VerificationTest[
     completeVerticesOK,
     True,
     TestID -> "mutual-kNN retains the complete vertex set"
     ],
    VerificationTest[
     Length[protocolOrder],
     5,
     TestID -> "five protocols are defined"
     ],
    VerificationTest[
     defaultConfig["Seeds"],
     Range[10],
     TestID -> "final run uses ten seeds"
     ]
    }
   ]
  ];

staticTestReport = runStaticSelfChecks[];
staticTestReport


(* ::Section:: *)
(*11. Commands to run*)

(* ::Subsection:: *)
(*A. Quick smoke test*)

(*
quickConfig = Join[
   defaultConfig,
   <|
    "N" -> 250,
    "Seeds" -> {1, 2},
    "MinimumCommonBins" -> 3,
    "OutputDirectory" ->
     FileNameJoin[{repoRoot, "results", "construction_audit_smoke"}]
    |>
   ];

quickAudit = runAudit[quickConfig];
quickSummary = summarizeAudit[quickAudit["Rows"]];
Dataset[quickSummary]
quickPlot = auditPlot[quickSummary]
*)


(* ::Subsection:: *)
(*B. Final paper rerun*)

(*
finalAudit = runAudit[defaultConfig];

finalSummary = summarizeAudit[finalAudit["Rows"]];
Dataset[finalSummary]

wideSummaryDataset[finalSummary]

finalPlot = auditPlot[finalSummary]

exported = exportAudit[
   finalAudit,
   "schwarzschild_five_protocols_N1000_seeds10"
   ];

exported["Paths"]
*)


(* ::Section:: *)
(*12. Interpretation guardrails*)

paperGuardrails = {
   "The ten seeds quantify graph-realization variability, not continuum convergence.",
   "The original protocol is curved epsilon graph versus matched-flat kNN.",
   "Strict radius means that both curved and flat graphs use the calibrated epsilon-graph rule; the repository helper recalibrates epsilon on each point cloud.",
   "Pure kNN and mutual kNN use identical k for curved and flat graphs.",
   "The edge-matched radius control matches the flat radius graph to the curved graph's edge count.",
   "All correlations use the same common-bin pipeline.",
   "The result supports protocol dependence; it does not establish a graph-independent curvature scalar."
   };

Column[paperGuardrails]
