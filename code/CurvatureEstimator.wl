(* ::Package:: *)

(* Path Anisotropy Curvature Estimator *)
(* Author: Ariadna Uxue Palomino Ylla *)

ClearAll["Global`*"];

(* ========================= *)
(* Utilities                 *)
(* ========================= *)

ClearAll[rankData];

rankData[x_List] :=
 Module[{ord, sortedPairs, groups, ranks, pos, len, inds},
  ord = Ordering[x];
  sortedPairs = Transpose[{ord, x[[ord]]}];
  groups = Split[sortedPairs, #1[[2]] == #2[[2]] &];
  ranks = ConstantArray[0., Length[x]];
  pos = 1;

  Do[
   inds = group[[All, 1]];
   len = Length[group];
   ranks[[inds]] = Mean[Range[pos, pos + len - 1]];
   pos = pos + len;
   ,
   {group, groups}
  ];

  ranks
];

ClearAll[cubicMeanDeviation];

cubicMeanDeviation[x_List] :=
 Module[{m},
  If[Length[x] <= 1,
   Missing["NotEnoughPoints"],
   m = Mean[x];
   Mean[Abs[x - m]^3]^(1/3)
  ]
];

ClearAll[spearmanCorr];

spearmanCorr[x_, y_] :=
 Correlation[rankData[N[x]], rankData[N[y]]];

(* ========================= *)
(* Graph construction        *)
(* ========================= *)

ClearAll[makeKNNGraph];

makeKNNGraph[pts_, k_Integer : 12] :=
 Module[{n, nearest, neighborLists, pairs, edges},
  n = Length[pts];
  nearest = Nearest[Thread[pts -> Range[n]]];

  neighborLists =
   Table[
    DeleteCases[nearest[pts[[i]], k + 1], i],
    {i, n}
   ];

  pairs =
   Flatten[
    Table[
     ({i, #} & /@ neighborLists[[i]]),
     {i, n}
    ],
    1
   ];

  pairs = DeleteDuplicates[Sort /@ pairs];
  edges = UndirectedEdge @@@ pairs;

  Graph[
   Range[n],
   edges,
   VertexSize -> Tiny,
   EdgeStyle -> Directive[Gray, Opacity[0.35]]
  ]
];

(* ========================= *)
(* Benchmark point clouds    *)
(* ========================= *)

ClearAll[
  flatDiskPoints,
  hyperboloidPoints,
  flammPoints,
  kHyperboloid,
  kSchwarzschild
];

flatDiskPoints[n_, rmax_ : 3] :=
 Module[{rho, theta},
  Table[
   rho = rmax Sqrt[RandomReal[]];
   theta = RandomReal[{0, 2 Pi}];
   {rho Cos[theta], rho Sin[theta], 0},
   {n}
  ]
];

hyperboloidPoints[n_, nuMax_ : 1.8] :=
 Module[{mu, nu},
  Table[
   mu = RandomReal[{0, 2 Pi}];
   nu = RandomReal[{-nuMax, nuMax}];
   <|
    "Coordinates" -> {Cosh[nu] Cos[mu], Cosh[nu] Sin[mu], Sinh[nu]},
    "mu" -> mu,
    "nu" -> nu
   |>,
   {n}
  ]
];

kHyperboloid[nu_] := 4 Sech[nu]^4;

flammPoints[n_, M_ : 1/2, rmin_ : 1.05, rmax_ : 5] :=
 Module[{theta, rr, z},
  Table[
   theta = RandomReal[{0, 2 Pi}];
   rr = RandomReal[{rmin, rmax}];
   z = 2 Sqrt[2 M (rr - 2 M)];
   <|
    "Coordinates" -> {rr Cos[theta], rr Sin[theta], z},
    "r" -> rr,
    "theta" -> theta
   |>,
   {n}
  ]
];

kSchwarzschild[r_, M_ : 1/2] := 48 M^2/r^6;

(* ========================= *)
(* Dataset builders          *)
(* ========================= *)

ClearAll[buildFlatDataset, buildHyperboloidDataset, buildFlammDataset];

buildFlatDataset[n_, k_Integer : 12] :=
 Module[{pts, g},
  pts = flatDiskPoints[n];
  g = makeKNNGraph[pts, k];

  <|
   "Type" -> "Flat",
   "N" -> n,
   "Points" -> pts,
   "Graph" -> g,
   "TargetK" -> ConstantArray[0, n],
   "k" -> k
  |>
];

buildHyperboloidDataset[n_, k_Integer : 12] :=
 Module[{data, pts, nus, g, target},
  data = hyperboloidPoints[n];
  pts = data[[All, "Coordinates"]];
  nus = data[[All, "nu"]];
  g = makeKNNGraph[pts, k];
  target = kHyperboloid /@ nus;

  <|
   "Type" -> "Hyperboloid",
   "N" -> n,
   "Points" -> pts,
   "nu" -> nus,
   "Graph" -> g,
   "TargetK" -> target,
   "k" -> k
  |>
];

buildFlammDataset[n_, M_ : 1/2, k_Integer : 12] :=
 Module[{data, pts, rs, g, target},
  data = flammPoints[n, M];
  pts = data[[All, "Coordinates"]];
  rs = data[[All, "r"]];
  g = makeKNNGraph[pts, k];
  target = kSchwarzschild[#, M] & /@ rs;

  <|
   "Type" -> "FlammSchwarzschild",
   "N" -> n,
   "Mass" -> M,
   "Points" -> pts,
   "r" -> rs,
   "Graph" -> g,
   "TargetK" -> target,
   "k" -> k
  |>
];

(* ========================= *)
(* Plotting                  *)
(* ========================= *)

ClearAll[plotDataset2D, plotDataset3D];

plotDataset2D[dataset_Association, label_ : Automatic] :=
 Module[{g, pts, title},
  g = dataset["Graph"];
  pts = dataset["Points"];
  title = If[label === Automatic, dataset["Type"], label];

  Graph[
   VertexList[g],
   EdgeList[g],
   VertexCoordinates -> Thread[Range[Length[pts]] -> pts[[All, {1, 2}]]],
   VertexSize -> Tiny,
   EdgeStyle -> Directive[Gray, Opacity[0.35]],
   PlotLabel -> title,
   ImageSize -> Medium
  ]
];

plotDataset3D[dataset_Association, label_ : Automatic] :=
 Module[{g, pts, title},
  g = dataset["Graph"];
  pts = dataset["Points"];
  title = If[label === Automatic, dataset["Type"], label];

  Graph3D[
   VertexList[g],
   EdgeList[g],
   VertexCoordinates -> Thread[Range[Length[pts]] -> pts],
   VertexSize -> Tiny,
   EdgeStyle -> Directive[Gray, Opacity[0.35]],
   PlotLabel -> title,
   ImageSize -> Medium,
   Boxed -> False,
   ViewPoint -> {2, -2, 1.5}
  ]
];

(* ========================= *)
(* BFS and estimator         *)
(* ========================= *)

ClearAll[
  precomputeAdjacency,
  shortestPathCountsFromAdj,
  estimatorFromBFS,
  pathAnisotropyEstimator
];

precomputeAdjacency[g_Graph] :=
 Module[{verts},
  verts = VertexList[g];
  AssociationThread[
   verts,
   (AdjacencyList[g, #] &) /@ verts
  ]
];

shortestPathCountsFromAdj[adj_Association, source_, maxRadius_Integer] :=
 Module[{dist, counts, frontier, next, d},

  dist = <|source -> 0|>;
  counts = <|source -> 1|>;

  frontier = {source};
  d = 0;

  While[frontier =!= {} && d < maxRadius,

   d++;
   next = {};

   Scan[
    Function[u,
     Scan[
      Function[nb,
       If[! KeyExistsQ[dist, nb],
        AssociateTo[dist, nb -> d];
        AssociateTo[counts, nb -> Lookup[counts, u, 0]];
        next = Append[next, nb],
        If[Lookup[dist, nb, Infinity] === d,
         AssociateTo[
          counts,
          nb -> Lookup[counts, nb, 0] + Lookup[counts, u, 0]
         ]
        ]
       ]
      ],
      Lookup[adj, u, {}]
     ]
    ],
    frontier
   ];

   frontier = DeleteDuplicates[next];
  ];

  <|"Distances" -> dist, "Counts" -> counts|>
];

estimatorFromBFS[source_, radius_Integer, bfs_Association] :=
 Module[{dist, counts, shell, pathCounts, oldCMD, normCMD, logCMD},
  dist = bfs["Distances"];
  counts = bfs["Counts"];

  shell = Keys @ Select[dist, # == radius &];

  If[Length[shell] <= 2,
   Return[
    <|
     "Vertex" -> source,
     "Radius" -> radius,
     "ShellSize" -> Length[shell],
     "MeanPathCount" -> Missing["TooSmallShell"],
     "OldCMD" -> Missing["TooSmallShell"],
     "NormalizedCMD" -> Missing["TooSmallShell"],
     "LogCMD" -> Missing["TooSmallShell"]
    |>
   ]
  ];

  pathCounts = Lookup[counts, shell, 0];

  oldCMD = cubicMeanDeviation[pathCounts]/radius;
  normCMD = cubicMeanDeviation[pathCounts]/(Mean[pathCounts] + 10^-12);
  logCMD = cubicMeanDeviation[Log[pathCounts + 10^-12]];

  <|
   "Vertex" -> source,
   "Radius" -> radius,
   "ShellSize" -> Length[shell],
   "MeanPathCount" -> Mean[pathCounts],
   "OldCMD" -> oldCMD,
   "NormalizedCMD" -> normCMD,
   "LogCMD" -> logCMD
  |>
];

pathAnisotropyEstimator[g_Graph, source_, radius_Integer] :=
 Module[{adj, bfs},
  adj = precomputeAdjacency[g];
  bfs = shortestPathCountsFromAdj[adj, source, radius];
  estimatorFromBFS[source, radius, bfs]
];

(* ========================= *)
(* Evaluation                *)
(* ========================= *)

ClearAll[evaluateDataset, cleanRows, evaluateDatasetAllRadii];

evaluateDataset[dataset_Association, radius_Integer] :=
 Module[{g, verts, target, targetAssoc, adj, rows},
  g = dataset["Graph"];
  verts = VertexList[g];
  target = dataset["TargetK"];
  targetAssoc = AssociationThread[Range[Length[target]], target];
  adj = precomputeAdjacency[g];

  rows =
   Map[
    Function[v,
     Module[{bfs},
      bfs = shortestPathCountsFromAdj[adj, v, radius];
      Join[
       estimatorFromBFS[v, radius, bfs],
       <|
        "TargetK" -> Lookup[targetAssoc, v, Missing["NoTarget"]],
        "Type" -> dataset["Type"],
        "N" -> dataset["N"]
       |>
      ]
     ]
    ],
    verts
   ];

  Dataset[rows]
];

cleanRows[ds_Dataset, estimatorName_ : "LogCMD"] :=
 Select[
  Normal[ds],
  NumericQ[Lookup[#, "TargetK"]] &&
   NumericQ[Lookup[#, estimatorName]] &
 ];

evaluateDatasetAllRadii[dataset_Association, radii_List] :=
 Module[{g, verts, target, targetAssoc, adj, maxRadius, rows},
  g = dataset["Graph"];
  verts = VertexList[g];
  target = dataset["TargetK"];
  targetAssoc = AssociationThread[Range[Length[target]], target];
  adj = precomputeAdjacency[g];
  maxRadius = Max[radii];

  rows =
   Flatten[
    Map[
     Function[v,
      Module[{bfs},
       bfs = shortestPathCountsFromAdj[adj, v, maxRadius];

       Join[
          estimatorFromBFS[v, #, bfs],
          <|
           "TargetK" -> Lookup[targetAssoc, v, Missing["NoTarget"]],
           "Type" -> dataset["Type"],
           "N" -> dataset["N"]
          |>
        ] & /@ radii
       ]
      ],
     verts
    ],
    1
   ];

  Dataset[rows]
];

(* ========================= *)
(* Scans and summaries       *)
(* ========================= *)

ClearAll[
  fastRadiusScan,
  oneSeedRadiusScan,
  multiSeedRadiusScan,
  summarizeSeedScan
];

fastRadiusScan[dataset_Association, radii_List, estimatorName_ : "LogCMD"] :=
 Module[{ds, rows, sub, pairs},
  ds = evaluateDatasetAllRadii[dataset, radii];
  rows = Normal[ds];

  Dataset[
   Table[
    sub =
     Select[
      rows,
      #["Radius"] == rad &&
        NumericQ[Lookup[#, "TargetK"]] &&
        NumericQ[Lookup[#, estimatorName]] &
     ];

    pairs = N[({#["TargetK"], #[estimatorName]} &) /@ sub];

    If[Length[pairs] < 5,
     <|
      "Radius" -> rad,
      "Rows" -> Length[pairs],
      "Pearson" -> Missing["TooFewRows"],
      "Spearman" -> Missing["TooFewRows"]
     |>,
     <|
      "Radius" -> rad,
      "Rows" -> Length[pairs],
      "Pearson" -> N@Correlation[pairs[[All, 1]], pairs[[All, 2]]],
      "Spearman" -> N@spearmanCorr[pairs[[All, 1]], pairs[[All, 2]]]
     |>
    ],
    {rad, radii}
   ]
  ]
];

oneSeedRadiusScan[n_, seed_, radii_List, k_Integer : 14] :=
 Module[{data, scan},
  SeedRandom[seed];
  data = buildFlammDataset[n, 1/2, k];
  scan = Normal[fastRadiusScan[data, radii, "LogCMD"]];

  Map[
   Join[#, <|"Seed" -> seed, "N" -> n, "k" -> k|>] &,
   scan
  ]
];

multiSeedRadiusScan[n_, seeds_List, radii_List, k_Integer : 14] :=
 Dataset[
  Flatten[
   oneSeedRadiusScan[n, #, radii, k] & /@ seeds,
   1
  ]
];

summarizeSeedScan[scan_Dataset] :=
 Module[{rows, grouped},
  rows = Normal[scan];
  grouped = GroupBy[rows, #Radius &];

  Dataset[
   KeyValueMap[
    Function[{rad, vals},
     <|
      "Radius" -> rad,
      "MeanPearson" -> Mean[vals[[All, "Pearson"]]],
      "MeanSpearman" -> Mean[vals[[All, "Spearman"]]],
      "StdSpearman" -> StandardDeviation[vals[[All, "Spearman"]]]
     |>
    ],
    grouped
   ]
  ]
];

(* ========================= *)
(* Radial binning            *)
(* ========================= *)

ClearAll[binnedFlammComparison];

binnedFlammComparison[
  dataset_Association,
  ds_Dataset,
  estimatorName_ : "LogCMD",
  nbins_Integer : 12
] :=
 Module[{rows, rs, rAssoc, joined, rmin, rmax, binEdges, binned},
  rows = cleanRows[ds, estimatorName];

  If[! KeyExistsQ[dataset, "r"],
   Return["This dataset does not contain radial coordinates under key \"r\"."]
  ];

  rs = dataset["r"];
  rAssoc = AssociationThread[Range[Length[rs]], rs];

  joined =
   Map[
    Join[
      #,
      <|"r" -> Lookup[rAssoc, #["Vertex"], Missing["NoR"]]|>
    ] &,
    rows
   ];

  joined =
   Select[
    joined,
    NumericQ[#["r"]] &&
      NumericQ[#["TargetK"]] &&
      NumericQ[#[estimatorName]] &
   ];

  rmin = Min[Map[#["r"] &, joined]];
  rmax = Max[Map[#["r"] &, joined]];
  binEdges = Subdivide[rmin, rmax, nbins];

  binned =
   Table[
    Module[{sub},
     sub =
      Select[
       joined,
       binEdges[[i]] <= #["r"] < binEdges[[i + 1]] &
      ];

     If[Length[sub] < 5,
      Nothing,
      <|
       "Bin" -> i,
       "rMin" -> binEdges[[i]],
       "rMax" -> binEdges[[i + 1]],
       "rMean" -> Mean[Map[#["r"] &, sub]],
       "KMean" -> Mean[Map[#["TargetK"] &, sub]],
       "EstimatorMean" -> Mean[Map[#[estimatorName] &, sub]],
       "EstimatorStd" -> StandardDeviation[Map[#[estimatorName] &, sub]],
       "Count" -> Length[sub]
      |>
     ]
    ],
    {i, Length[binEdges] - 1}
   ];

  Dataset[binned]
];
