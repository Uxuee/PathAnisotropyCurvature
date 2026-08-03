(* Headless, resumable runner for the construction-sensitivity audit. *)

repoRoot = ExpandFileName @ FileNameJoin[{DirectoryName[$InputFileName], ".."}];
Get[FileNameJoin[{repoRoot, "notebooks", "ConstructionSensitivityMultiSeedAudit.wl"}]];

ClearAll[fail, require, seedCheckpointPath, validSeedRunQ, loadCheckpoint,
  saveCheckpoint, runSeedsResumable, validateRows, writeValidation,
  runStatic, runSmoke, runTiming, runFull, runAggregate];

fail[msg_String, code_Integer : 2] := (Print["ERROR: ", msg]; Exit[code]);
require[condition_, msg_String] := If[! TrueQ[condition], fail[msg]];

seedCheckpointPath[cfg_Association, seed_Integer] :=
 FileNameJoin[{cfg["OutputDirectory"], "checkpoints",
   "seed_" <> IntegerString[seed, 10, 2] <> ".mx"}];

validSeedRunQ[seedRun_, seed_Integer, cfg_Association] :=
 Module[{rows},
  If[! AssociationQ[seedRun] || Lookup[seedRun, "Seed", None] =!= seed,
   Return[False]];
  rows = Lookup[seedRun, "Rows", {}];
  ListQ[rows] && Length[rows] === Length[cfg["Protocols"]] &&
   Sort[Lookup[rows, "Protocol", {}]] === Sort[cfg["Protocols"]] &&
   AllTrue[rows,
    AssociationQ[#] && Lookup[#, "Seed", None] === seed &&
      Lookup[#, "N", None] === cfg["N"] &&
      Lookup[#, "k", None] === cfg["k"] &&
      Lookup[#, "GraphShellRadius", None] === cfg["GraphShellRadius"] &&
      Lookup[#, "BinsRequested", None] === cfg["Bins"] &]
  ];

loadCheckpoint[path_String, seed_Integer, cfg_Association] :=
 Module[{seedRun},
  If[! FileExistsQ[path], Return[Missing["NotFound"]]];
  seedRun = Quiet @ Check[Import[path, "MX"], $Failed];
  If[validSeedRunQ[seedRun, seed, cfg], seedRun,
   Print["Ignoring invalid checkpoint: ", path]; Missing["InvalidCheckpoint"]]
  ];

saveCheckpoint[path_String, seedRun_Association] :=
 Module[{dir, tmp},
  dir = DirectoryName[path];
  If[! DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  tmp = path <> ".tmp";
  require[Export[tmp, seedRun, "MX"] =!= $Failed,
   "Could not write checkpoint " <> tmp];
  If[FileExistsQ[path], DeleteFile[path]];
  RenameFile[tmp, path];
  Print["Saved checkpoint: ", path];
  ];

runSeedsResumable[seeds_List, cfg_Association] :=
 Module[{runs = {}, path, cached, seedRun, elapsed},
  Do[
   path = seedCheckpointPath[cfg, seed];
   cached = loadCheckpoint[path, seed, cfg];
   If[AssociationQ[cached],
    Print["Skipping completed seed ", seed, ": ", path];
    AppendTo[runs, cached],
    Print["Running seed ", seed, " ..."];
    {elapsed, seedRun} = AbsoluteTiming[runOneSeed[seed, cfg]];
    require[seedRun =!= $Failed && validSeedRunQ[seedRun, seed, cfg],
     "Seed " <> ToString[seed] <> " did not produce five valid protocol rows."];
    seedRun = Join[seedRun, <|"ElapsedSeconds" -> elapsed|>];
    saveCheckpoint[path, seedRun];
    AppendTo[runs, seedRun];
    Print["Completed seed ", seed, " in ", NumberForm[elapsed, {Infinity, 1}], " seconds."]
    ],
   {seed, seeds}];
  runs
  ];

validateRows[rows_List, cfg_Association, expectedSeeds_List, requireAllBins_ : False] :=
 Module[{protocolCounts, seedCounts, edgeRows, allowedMissingQ, correlations,
   validation},
  protocolCounts = Counts[Lookup[rows, "Protocol"]];
  seedCounts = Counts[Lookup[rows, "Seed"]];
  edgeRows = Select[rows, Lookup[#, "Protocol", ""] === "Edge-matched radius" &];
  allowedMissingQ[x_] := finiteNumericQ[x] ||
    MatchQ[x, Missing["InsufficientCommonBins" | "InvalidCorrelation"]];
  correlations = Flatten[Lookup[rows, {"RhoBH", "RhoFlat"}]];

  validation = <|
    "RowCount" -> Length[rows],
    "ExpectedRowCount" -> Length[expectedSeeds] Length[cfg["Protocols"]],
    "AllProtocolsPresentPerSeed" ->
     AllTrue[expectedSeeds, Function[s,
       Sort[Lookup[Select[rows, Lookup[#, "Seed", None] === s &], "Protocol"]] ===
        Sort[cfg["Protocols"]]]],
    "ProtocolCountsCorrect" ->
     AllTrue[cfg["Protocols"], Lookup[protocolCounts, #, 0] === Length[expectedSeeds] &],
    "SeedCountsCorrect" ->
     AllTrue[expectedSeeds, Lookup[seedCounts, #, 0] === Length[cfg["Protocols"]] &],
    "AllCommonBinsRequested" -> AllTrue[Lookup[rows, "CommonBins"], # === cfg["Bins"] &],
    "AllCorrelationsNumericOrJustifiedMissing" -> AllTrue[correlations, allowedMissingQ],
    "MissingCorrelationCount" -> Count[correlations, _Missing],
    "MutualSubsetChecksPassed" -> True,
    "MaxXYMismatch" -> Max[Lookup[rows, "XYMismatch"]],
    "AllXYWithinTolerance" -> AllTrue[Lookup[rows, "XYMismatch"], # <= 10^-10 &],
    "ConnectivityFieldsPresent" ->
     AllTrue[rows, Function[row,
       AllTrue[{"BHComponents", "FlatComponents", "BHLargestComponentFraction",
         "FlatLargestComponentFraction"}, KeyExistsQ[row, #] &]]],
    "ValidFractionFieldsPresent" ->
     AllTrue[rows, KeyExistsQ[#, "BHValidLogCMDFraction"] &&
        KeyExistsQ[#, "FlatValidLogCMDFraction"] &],
    "EdgeMatchesExactOrTieExplained" ->
     AllTrue[edgeRows,
      With[{difference = Lookup[#, "EdgeCountDifference", Missing[]],
        ties = Lookup[#, "FlatEdgesTiedAtRadius", Missing[]]},
       difference === 0 ||
        (IntegerQ[difference] && difference > 0 && IntegerQ[ties] && ties > difference)] &]
    |>;

  require[validation["RowCount"] === validation["ExpectedRowCount"],
   "Raw row count is incomplete."];
  require[And @@ Lookup[validation,
     {"AllProtocolsPresentPerSeed", "ProtocolCountsCorrect", "SeedCountsCorrect",
      "AllCorrelationsNumericOrJustifiedMissing", "MutualSubsetChecksPassed",
      "AllXYWithinTolerance", "ConnectivityFieldsPresent", "ValidFractionFieldsPresent",
      "EdgeMatchesExactOrTieExplained"}], "Row validation failed: " <> ToString[InputForm[validation]]];
  If[TrueQ[requireAllBins],
   require[validation["AllCommonBinsRequested"],
    "Smoke rows do not all contain the requested number of common bins."]];
  validation
  ];

writeValidation[path_String, validation_Association] :=
 Module[{dir = DirectoryName[path]},
  If[! DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  Export[path, validation, "RawJSON"]
  ];

runStatic[] := Module[{failed = staticTestReport["TestsFailedCount"]},
  Print[staticTestReport];
  require[failed === 0, "Static tests failed."];
  Print["Static tests passed: ", staticTestReport["TestsSucceededCount"], "."];
  ];

runSmoke[] := Module[{cfg, audit, rows, validation, exported, header},
  cfg = Join[defaultConfig, <|"N" -> 250, "Seeds" -> {1, 2},
     "MinimumCommonBins" -> 3,
     "OutputDirectory" -> FileNameJoin[{repoRoot, "results", "construction_audit_smoke"}]|>];
  audit = runAudit[cfg];
  require[audit =!= $Failed, "Smoke audit failed."];
  rows = audit["Rows"];
  validation = validateRows[rows, cfg, cfg["Seeds"], True];
  exported = exportAudit[audit, "schwarzschild_five_protocols_N250_seeds2"];
  require[AssociationQ[exported], "Smoke export failed."];
  header = First @ Import[exported["Paths"]["RawCSV"], "CSV"];
  require[header === Keys[First[rows]], "Raw CSV does not have the expected explicit header."];
  writeValidation[FileNameJoin[{cfg["OutputDirectory"], "validation.json"}],
   Join[validation, <|"RawCSVHeaderExplicit" -> True|>]];
  Print["Smoke validation passed: ", InputForm[validation]];
  ];

runTiming[] := Module[{cfg, runs},
  cfg = Join[defaultConfig, <|"Seeds" -> {1},
     "OutputDirectory" -> FileNameJoin[{repoRoot, "results", "construction_audit_timing_N1000"}]|>];
  runs = runSeedsResumable[{1}, cfg];
  Print["N=1000 seed 1 elapsed seconds: ", Lookup[First[runs], "ElapsedSeconds"]];
  ];

finalConfig[] := Join[defaultConfig, <|
   "OutputDirectory" -> FileNameJoin[{repoRoot, "results", "construction_audit_multiseed"}]|>];

runFull[] := Module[{cfg = finalConfig[], runs},
  runs = runSeedsResumable[Range[10], cfg];
  require[Length[runs] === 10, "Not all ten seed checkpoints completed."];
  Print["All ten checkpoints are present; aggregating and validating."];
  runAggregate[];
  ];

runAggregate[] := Module[{cfg = finalConfig[], runs, path, seedRun, rows, qc,
   validation, audit, exported, summary, rawHeader, summaryHeader, qcHeader,
   runtimeRows, runtimeReport, runtimeStem},
  runs = Table[
    path = seedCheckpointPath[cfg, seed];
    seedRun = loadCheckpoint[path, seed, cfg];
    require[AssociationQ[seedRun], "Missing or invalid seed checkpoint: " <> path];
    seedRun,
    {seed, Range[10]}];
  rows = Flatten[Lookup[runs, "Rows"], 1];
  qc = Flatten[Lookup[runs, "QualityControl"], 1];
  validation = validateRows[rows, cfg, Range[10]];
  require[Length[rows] === 50, "Final raw table does not contain exactly 50 rows."];
  audit = <|"Config" -> cfg, "Rows" -> rows, "QualityControl" -> qc|>;
  exported = exportAudit[audit, "schwarzschild_five_protocols_N1000_seeds10"];
  require[AssociationQ[exported], "Final export failed."];
  summary = exported["Summary"];
  require[Length[summary] === 5 && AllTrue[Lookup[summary, "NSeeds"], # === 10 &],
   "Every protocol summary must contain NSeeds = 10."];
  rawHeader = First @ Import[exported["Paths"]["RawCSV"], "CSV"];
  summaryHeader = First @ Import[exported["Paths"]["SummaryCSV"], "CSV"];
  qcHeader = First @ Import[exported["Paths"]["QualityControlCSV"], "CSV"];
  require[rawHeader === Keys[First[rows]], "Raw CSV header is not explicit or stable."];
  require[summaryHeader === Keys[First[summary]], "Summary CSV header is not explicit or stable."];
  require[qcHeader === Keys[First[qc]], "Quality-control CSV header is not explicit or stable."];
  runtimeRows = Table[
    <|"Seed" -> run["Seed"], "ElapsedSeconds" -> run["ElapsedSeconds"]|>,
    {run, runs}];
  runtimeReport = <|
    "N" -> cfg["N"], "Seeds" -> Range[10],
    "PerSeedSeconds" -> AssociationThread[ToString /@ Lookup[runtimeRows, "Seed"],
      Lookup[runtimeRows, "ElapsedSeconds"]],
    "TotalSeedComputeSeconds" -> Total[Lookup[runtimeRows, "ElapsedSeconds"]],
    "MeanSeedSeconds" -> Mean[Lookup[runtimeRows, "ElapsedSeconds"]],
    "MinSeedSeconds" -> Min[Lookup[runtimeRows, "ElapsedSeconds"]],
    "MaxSeedSeconds" -> Max[Lookup[runtimeRows, "ElapsedSeconds"]]
    |>;
  runtimeStem = FileNameJoin[{cfg["OutputDirectory"],
     "schwarzschild_five_protocols_N1000_seeds10_runtime"}];
  PathAnisotropyCurvature`exportDatasetCSV[runtimeStem <> ".csv", runtimeRows];
  Export[runtimeStem <> ".json", runtimeReport, "RawJSON"];
  validation = Join[validation, <|
     "CheckpointCount" -> Length[runs],
     "AllProtocolSummariesHaveTenSeeds" -> True,
     "RawCSVHeaderExplicit" -> True,
     "SummaryCSVHeaderExplicit" -> True,
     "QualityControlCSVHeaderExplicit" -> True
     |>];
  writeValidation[FileNameJoin[{cfg["OutputDirectory"],
     "schwarzschild_five_protocols_N1000_seeds10_validation.json"}], validation];
  Print["Final aggregation passed with 50 rows."];
  ];

args = Rest[$ScriptCommandLine];
mode = If[args === {}, "", First[args]];
Switch[mode,
 "static", runStatic[],
 "smoke", runSmoke[],
 "timing", runTiming[],
 "full", runFull[],
 "aggregate", runAggregate[],
 _, fail["Usage: wolframscript -file scripts/run_construction_audit.wls static|smoke|timing|full|aggregate", 64]
 ];
