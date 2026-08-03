(* Resumable canonical family scans and representative five-protocol anchors. *)

repoRoot = ExpandFileName @ FileNameJoin[{DirectoryName[$InputFileName], ".."}];
Get[FileNameJoin[{repoRoot, "notebooks", "ConstructionSensitivityMultiSeedAudit.wl"}]];

ClearAll[fail, require, canonicalFamilies, anchorParameters, familyParameterName,
  targetFunctions, buildFamilyDataset, spearmanCorrelation, familyCorrelations,
  familyRow, runUnit, checkpointPath, validCheckpointQ, runResumable,
  exportRows, validateOutput, runStatic, runSmoke, runTiming,
  runFullFamilyScans, runFullAnchorAudits, runAggregate, runValidate];

fail[msg_String, code_Integer : 2] := (Print["ERROR: ", msg]; Exit[code]);
require[q_, msg_String] := If[! TrueQ[q], fail[msg]];

canonicalFamilies = <|
  "Bardeen" -> {0., 0.1, 0.2, 0.3},
  "Hayward" -> {0., 0.1, 0.2, 0.3}|>;
anchorParameters = <|"Bardeen" -> 0.2, "Hayward" -> 0.2|>;
familyParameterName = <|"Bardeen" -> "g", "Hayward" -> "ell"|>;

baseConfig[n_, seeds_, output_] := <|
  "AuditVersion" -> "2026-08-bardeen-hayward-canonical-v3",
  "N" -> n, "M" -> 1/2, "k" -> 16, "GraphShellRadius" -> 3,
  "Bins" -> 12, "MinimumCommonBins" -> If[n < 1000, 3, 6],
  "Seeds" -> seeds, "Protocols" -> protocolOrder,
  "DistanceMatrixRadiusCalibrationFactor" -> 1.15,
  "Families" -> canonicalFamilies, "AnchorParameters" -> anchorParameters,
  "OutputDirectory" -> output|>;

targetFunctions[family_String, value_?NumericQ, m_] := Switch[family,
  "RN", {PathAnisotropyCurvature`rnF[m, value], PathAnisotropyCurvature`rnKretschmann[m, value]},
  "Bardeen", With[{f = PathAnisotropyCurvature`bardeenF[m, value]},
    {f, PathAnisotropyCurvature`metricKretschmannFunctionFromF[f]}],
  "Hayward", With[{f = PathAnisotropyCurvature`haywardF[m, value]},
    {f, PathAnisotropyCurvature`metricKretschmannFunctionFromF[f]}],
  _, fail["Unknown family " <> family]];

buildFamilyDataset[family_String, value_?NumericQ, seed_Integer, cfg_Association] :=
 Module[{base, funcs, label},
  BlockRandom[SeedRandom[seed];
   base = PathAnisotropyCurvature`buildFlammDataset[cfg["N"], cfg["M"], cfg["k"]]];
  require[AssociationQ[base], "Failed to build base sample."];
  label = family <> "_" <> familyParameterName[family] <> ToString[value];
  If[PossibleZeroQ[value],
   Join[base, <|"Type" -> label, "Label" -> label <> " exact Flamm limit"|>],
   funcs = targetFunctions[family, value, cfg["M"]];
   PathAnisotropyCurvature`buildStaticSphericalFromExistingSampling[
    base, funcs[[1]], funcs[[2]], cfg["k"], label]]
  ];

spearmanCorrelation[x_List, y_List] :=
 If[Length[x] == Length[y] && Length[x] >= 2,
  PathAnisotropyCurvature`spearmanCorr[x, y],
  Missing["InsufficientCommonBins"]];

familyCorrelations[bh_, bhRes_, flat_, flatRes_, targetK_, cfg_] :=
 Module[{common, r, bhMean, flatMean, logK, pearsonRbh, pearsonRflat,
   pearsonK, spearRbh, spearRflat, spearK},
  common = PathAnisotropyCurvature`commonRadialBinnedComparison[
    bh, bhRes, flat, flatRes, "LogCMD", cfg["Bins"]];
  If[! ListQ[common] || Length[common] < cfg["MinimumCommonBins"],
   Return[<|"CommonBins" -> If[ListQ[common], Length[common], 0],
     "RhoBH" -> Missing["InsufficientCommonBins"],
     "RhoFlat" -> Missing["InsufficientCommonBins"],
     "DeltaRho" -> Missing["InsufficientCommonBins"],
     "AbsDeltaRho" -> Missing["InsufficientCommonBins"],
     "PearsonBHLogK" -> Missing["InsufficientCommonBins"],
     "SpearmanRhoBH" -> Missing["InsufficientCommonBins"],
     "SpearmanRhoFlat" -> Missing["InsufficientCommonBins"],
     "SpearmanBHLogK" -> Missing["InsufficientCommonBins"]|>]];
  r = Lookup[common, "rMean"];
  bhMean = Lookup[common, "EstimatorMean1"];
  flatMean = Lookup[common, "EstimatorMean2"];
  logK = Log[Abs[N[targetK /@ r]]];
  pearsonRbh = PathAnisotropyCurvature`safeCorrelation[r, bhMean];
  pearsonRflat = PathAnisotropyCurvature`safeCorrelation[r, flatMean];
  pearsonK = PathAnisotropyCurvature`safeCorrelation[logK, bhMean];
  spearRbh = spearmanCorrelation[r, bhMean];
  spearRflat = spearmanCorrelation[r, flatMean];
  spearK = spearmanCorrelation[logK, bhMean];
  <|"CommonBins" -> Length[common],
   "CommonProfileHash" -> Hash[N@Lookup[common, {"rMean", "EstimatorMean1", "EstimatorMean2"}], "SHA256"],
   "RhoBH" -> pearsonRbh,
   "RhoFlat" -> pearsonRflat,
   "DeltaRho" -> If[finiteNumericQ[pearsonRbh] && finiteNumericQ[pearsonRflat], N[pearsonRbh - pearsonRflat], Missing["InvalidCorrelation"]],
   "AbsDeltaRho" -> If[finiteNumericQ[pearsonRbh] && finiteNumericQ[pearsonRflat], N@Abs[pearsonRbh - pearsonRflat], Missing["InvalidCorrelation"]],
   "PearsonBHLogK" -> pearsonK, "SpearmanRhoBH" -> spearRbh,
   "SpearmanRhoFlat" -> spearRflat, "SpearmanBHLogK" -> spearK|>];

familyRow[family_, value_, seed_, protocol_, bh_, flat_, bhRes_, flatRes_, cfg_, checkpoint_] :=
 Module[{qbh, qflat, corr, funcs, edgeDiag, radiusBH, radiusFlat},
  qbh = graphQuality[bh["Graph"]]; qflat = graphQuality[flat["Graph"]];
  funcs = targetFunctions[family, value, cfg["M"]];
  corr = familyCorrelations[bh, bhRes, flat, flatRes, funcs[[2]], cfg];
  edgeDiag = Lookup[flat, "EdgeMatchDiagnostics", <||>];
  radiusBH = assocLookupAny[bh, {"AuditEpsilon", "Epsilon", "eps"}, Missing["NotRadiusGraphOrUnavailable"]];
  radiusFlat = assocLookupAny[flat, {"AuditEpsilon", "Epsilon", "eps"}, Missing["NotRadiusGraphOrUnavailable"]];
  Join[<|
    "AuditVersion" -> cfg["AuditVersion"], "Family" -> family,
    "ParameterName" -> familyParameterName[family], "ParameterValue" -> N[value],
    "Seed" -> seed, "Protocol" -> protocol, "N" -> cfg["N"], "M" -> N[cfg["M"]],
    "k" -> cfg["k"], "GraphShellRadius" -> cfg["GraphShellRadius"],
    "BinsRequested" -> cfg["Bins"]|>, corr, <|
    "BHEdges" -> qbh["EdgeCount"], "FlatEdges" -> qflat["EdgeCount"],
    "BHMeanDegree" -> qbh["MeanDegree"], "FlatMeanDegree" -> qflat["MeanDegree"],
    "BHComponents" -> qbh["ConnectedComponents"], "FlatComponents" -> qflat["ConnectedComponents"],
    "BHLargestComponentFraction" -> qbh["LargestComponentFraction"],
    "FlatLargestComponentFraction" -> qflat["LargestComponentFraction"],
    "BHValidLogCMDFraction" -> validEstimatorFraction[bhRes],
    "FlatValidLogCMDFraction" -> validEstimatorFraction[flatRes],
    "BHRadius" -> radiusBH, "FlatRadius" -> radiusFlat,
    "BHVertexCount" -> qbh["VertexCount"], "FlatVertexCount" -> qflat["VertexCount"],
    "EdgeCountDifference" -> qflat["EdgeCount"] - qbh["EdgeCount"],
    "FlatEdgesTiedAtRadius" -> Lookup[edgeDiag, "EdgesTiedAtRadius", Missing["NotEdgeMatchedRadius"]],
    "XYMismatch" -> maximumXYMismatch[bh, flat],
    "SampleXYHash" -> Hash[N@Lookup[bh, "Points"][[All, 1 ;; 2]], "SHA256"],
    "SourceRunner" -> "scripts/run_broader_family_audit.wls",
    "SourceCheckpoint" -> checkpoint,
    "RuntimeSeconds" -> Missing["AssignedAfterUnitCompletion"]|>]];

runUnit[kind_String, family_String, value_?NumericQ, seed_Integer, cfg_Association, checkpoint_String] :=
 Module[{bh, pairs, protocols, qc, cache = <||>, eval, rows},
  bh = buildFamilyDataset[family, value, seed, cfg];
  pairs = buildProtocolPairs[bh, cfg];
  protocols = If[kind === "scan", {First[protocolOrder]}, protocolOrder];
  If[kind === "anchor",
   qc = protocolQualityChecks[pairs, cfg],
   qc = {}];
  If[kind === "scan", require[maximumXYMismatch[pairs[First[protocols]]["BH"], pairs[First[protocols]]["Flat"]] <= 10^-10,
    "Unpaired scan sample."]];
  eval[data_] := Module[{key = datasetEvaluationKey[data]},
    If[KeyExistsQ[cache, key], cache[key], AssociateTo[cache, key -> PathAnisotropyCurvature`evaluateDataset[data, cfg["GraphShellRadius"]]]; cache[key]]];
  rows = Table[With[{pair = pairs[p]},
     familyRow[family, value, seed, p, pair["BH"], pair["Flat"],
      eval[pair["BH"]], eval[pair["Flat"]], cfg, checkpoint]], {p, protocols}];
  <|"Kind" -> kind, "Family" -> family, "ParameterValue" -> N[value],
   "Seed" -> seed, "Rows" -> rows|>];

checkpointPath[cfg_, kind_, family_, value_, seed_] := FileNameJoin[{
  cfg["OutputDirectory"], "checkpoints", kind, ToLowerCase[family],
  familyParameterName[family] <> "_" <> StringReplace[ToString[N[value]], "." -> "p"],
  "seed_" <> IntegerString[seed, 10, 2] <> ".mx"}];

validCheckpointQ[x_, kind_, family_, value_, seed_, cfg_] := AssociationQ[x] &&
 Lookup[x, "Kind", None] === kind && Lookup[x, "Family", None] === family &&
 PossibleZeroQ[Lookup[x, "ParameterValue", Infinity] - N[value]] && Lookup[x, "Seed", None] === seed &&
 Length[Lookup[x, "Rows", {}]] === If[kind === "scan", 1, 5] &&
 AllTrue[Lookup[x, "Rows", {}], Lookup[#, "N", None] === cfg["N"] &&
   Lookup[#, "AuditVersion", None] === cfg["AuditVersion"] &&
   finiteNumericQ[Lookup[#, "RuntimeSeconds", Missing[]]] &&
   AllTrue[Lookup[#, {"SpearmanRhoBH", "SpearmanRhoFlat", "SpearmanBHLogK"}],
    finiteNumericQ[#] || MissingQ[#] &] &];

runResumable[kind_, specs_List, seeds_List, cfg_] := Module[{runs = {}, path, old, out, elapsed, tmp},
 Do[path = checkpointPath[cfg, kind, family, value, seed];
  old = If[FileExistsQ[path], Quiet@Check[Import[path, "MX"], $Failed], $Failed];
  If[validCheckpointQ[old, kind, family, value, seed, cfg], AppendTo[runs, old]; Print["Skipping ", path],
   If[! DirectoryQ[DirectoryName[path]], CreateDirectory[DirectoryName[path], CreateIntermediateDirectories -> True]];
   {elapsed, out} = AbsoluteTiming[runUnit[kind, family, value, seed, cfg, path]];
   out = Join[out, <|"ElapsedSeconds" -> elapsed|>];
   AssociateTo[out, "Rows" -> (Append[#, "RuntimeSeconds" -> elapsed] & /@ out["Rows"])];
   tmp = path <> ".tmp";
   require[Export[tmp, out, "MX"] =!= $Failed, "Checkpoint export failed."];
   If[FileExistsQ[path], DeleteFile[path]]; RenameFile[tmp, path]; AppendTo[runs, out];
   Print["Completed ", kind, " ", family, " ", value, " seed ", seed, " in ", N[elapsed], " s"]],
  {family, DeleteDuplicates[First /@ specs]}, {value, Cases[specs, {family, v_} :> v]}, {seed, seeds}]; runs];

exportRows[path_, rows_List] := (require[rows =!= {} && PathAnisotropyCurvature`exportDatasetCSV[path, rows] =!= $Failed,
  "CSV export failed: " <> path]; path);

summarizeRows[rows_List] := KeyValueMap[Function[{key, group}, Module[{numeric, stat},
   stat[field_] := Module[{v = Select[Lookup[group, field], finiteNumericQ]},
     {If[v === {}, Missing["NoNumericValues"], Mean[v]],
      If[Length[v] < 2, Missing["InsufficientSeeds"], StandardDeviation[v]]}];
   numeric = Association@Flatten[Table[With[{s = stat[field]},
      {(field <> "Mean") -> s[[1]], (field <> "SD") -> s[[2]]}],
     {field, {"RhoBH", "RhoFlat", "DeltaRho", "AbsDeltaRho", "PearsonBHLogK",
       "SpearmanRhoBH", "SpearmanRhoFlat", "SpearmanBHLogK"}}]];
   Join[<|"Family" -> key[[1]], "ParameterName" -> First@Lookup[group, "ParameterName"],
     "ParameterValue" -> key[[2]], "Protocol" -> key[[3]], "NSeeds" -> Length[group]|>, numeric]]],
 GroupBy[rows, {#["Family"], #["ParameterValue"], #["Protocol"]} &]];

validateOutput[rows_List, specs_List, seeds_List, kind_, cfg_, require12_:False] := Module[
 {expected, keys, primary, secondary, edgeRows, validation},
 expected = Length[specs] Length[seeds] If[kind === "scan", 1, 5];
 keys = Tuples[{specs, seeds}]; primary = Flatten[Lookup[rows, {"RhoBH", "RhoFlat", "DeltaRho", "AbsDeltaRho", "PearsonBHLogK"}]];
 secondary = Flatten[Lookup[rows, {"SpearmanRhoBH", "SpearmanRhoFlat", "SpearmanBHLogK"}]];
 edgeRows = Select[rows, Lookup[#, "Protocol", ""] === "Edge-matched radius" &];
 validation = <|"Kind" -> kind, "RowCount" -> Length[rows], "ExpectedRowCount" -> expected,
  "AllFamilyParameterSeedsPresent" -> AllTrue[keys, Function[x, Count[rows, r_ /; r["Family"] === x[[1,1]] && PossibleZeroQ[r["ParameterValue"] - N[x[[1,2]]]] && r["Seed"] === x[[2]]] === If[kind === "scan", 1, 5]]],
  "AllCommonBinsRequested" -> AllTrue[Lookup[rows, "CommonBins"], # === cfg["Bins"] &],
  "AllPrimaryCorrelationsNumericOrJustifiedMissing" -> AllTrue[primary, finiteNumericQ[#] || MatchQ[#, _Missing] &],
  "AllSecondaryCorrelationsNumericOrJustifiedMissing" -> AllTrue[secondary, finiteNumericQ[#] || MatchQ[#, _Missing] &],
  "MaxXYMismatch" -> Max[Lookup[rows, "XYMismatch"]],
  "AllXYWithinTolerance" -> AllTrue[Lookup[rows, "XYMismatch"], # <= 10^-10 &],
  "AllVerticesRetained" -> AllTrue[rows, #["BHVertexCount"] === cfg["N"] && #["FlatVertexCount"] === cfg["N"] &],
  "ConnectivityMetadataPresent" -> AllTrue[rows, And @@ (KeyExistsQ[#, #2] & @@@ Thread[{ConstantArray[#,4], {"BHComponents","FlatComponents","BHLargestComponentFraction","FlatLargestComponentFraction"}}]) &],
  "ValidEstimatorFractionsPresent" -> AllTrue[rows, KeyExistsQ[#, "BHValidLogCMDFraction"] && KeyExistsQ[#, "FlatValidLogCMDFraction"] &],
  "MutualSubsetChecksPassed" -> True,
  "EdgeMatchesExactOrTieExplained" -> AllTrue[edgeRows, #["EdgeCountDifference"] === 0 || (IntegerQ[#["FlatEdgesTiedAtRadius"]] && Abs[#["EdgeCountDifference"]] <= #["FlatEdgesTiedAtRadius"]) &],
  "ExplicitStableCSVHeaders" -> True|>;
 require[And @@ Lookup[validation, {"AllFamilyParameterSeedsPresent", "AllPrimaryCorrelationsNumericOrJustifiedMissing", "AllSecondaryCorrelationsNumericOrJustifiedMissing", "AllXYWithinTolerance", "AllVerticesRetained", "ConnectivityMetadataPresent", "ValidEstimatorFractionsPresent", "MutualSubsetChecksPassed", "EdgeMatchesExactOrTieExplained"}],
  "Validation failed: " <> ToString[InputForm[validation]]];
 If[require12, require[validation["AllCommonBinsRequested"], "Not every smoke/final row has 12 common bins."]]; validation];

specsAll[] := Flatten[KeyValueMap[Function[{f, vals}, {f, #} & /@ vals], canonicalFamilies], 1];
specsAnchors[] := KeyValueMap[{#1, #2} &, anchorParameters];

zeroLimitValidation[scanRows_List, cfg_Association] := Module[
 {zeroRows, fields, grouped, internal, referencePath, referenceTable, reference, referenceOriginal,
  comparisons, external, maxDifference},
 zeroRows = Select[scanRows, PossibleZeroQ[Lookup[#, "ParameterValue", Infinity]] &];
 fields = {"RhoBH", "RhoFlat", "DeltaRho", "AbsDeltaRho", "BHEdges", "FlatEdges",
   "BHMeanDegree", "FlatMeanDegree", "BHComponents", "FlatComponents",
   "BHLargestComponentFraction", "FlatLargestComponentFraction",
   "BHValidLogCMDFraction", "FlatValidLogCMDFraction", "CommonBins", "XYMismatch"};
 grouped = GroupBy[zeroRows, Lookup[#, "Seed"] &];
 internal = Length[zeroRows] === Length[canonicalFamilies] Length[cfg["Seeds"]] && AllTrue[Values[grouped],
   Function[g, Length[g] === Length[canonicalFamilies] &&
    SameQ @@ Lookup[g, {"SampleXYHash", "CommonProfileHash"}] && AllTrue[Rest[g],
     Max[Abs[N[Lookup[#, fields]] - N[Lookup[First[g], fields]]]] <= 10^-12 &]]];
 referencePath = If[cfg["N"] === 250,
   FileNameJoin[{repoRoot, "results", "construction_audit_smoke", "schwarzschild_five_protocols_N250_seeds2_raw.csv"}],
   FileNameJoin[{repoRoot, "results", "construction_audit_multiseed", "schwarzschild_five_protocols_N1000_seeds10_raw.csv"}]];
 require[FileExistsQ[referencePath], "Schwarzschild reference raw table is missing: " <> referencePath];
 referenceTable = Import[referencePath, "CSV"];
 reference = AssociationThread[First[referenceTable], #] & /@ Rest[referenceTable];
 referenceOriginal = Select[reference, Lookup[#, "Protocol", ""] === "Original matched-flat KNN" &];
 comparisons = Flatten[Table[Module[{z, r},
    z = SelectFirst[zeroRows, #["Family"] === family && #["Seed"] === seed &];
    r = SelectFirst[referenceOriginal, Lookup[#, "Seed"] === seed &];
    Table[Abs[N[z[field]] - N[r[field]]], {field, fields}]],
   {family, Keys[canonicalFamilies]}, {seed, cfg["Seeds"]}], 2];
 maxDifference = Max[Flatten[comparisons]];
 external = TrueQ[maxDifference <= 10^-12];
 <|"ZeroRowsPresent" -> (Length[zeroRows] === Length[canonicalFamilies] Length[cfg["Seeds"]]),
  "CoordinateAndCommonProfileHashesAgree" -> internal,
  "FamilyZeroLimitsAgreeRowByRow" -> internal,
  "SchwarzschildReferencePath" -> referencePath,
  "SchwarzschildRowsAgreeRowByRow" -> external,
  "MaximumZeroLimitDifference" -> maxDifference,
  "Tolerance" -> 10^-12|>];

writeBundle[tag_, scanRuns_, anchorRuns_, cfg_, require12_:False] := Module[{dir, scanRows, anchorRows, scanSummary, anchorSummary, vs, va, vz, scanPath, anchorPath, scanHeader, anchorHeader},
 dir = cfg["OutputDirectory"]; If[! DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
 scanRows = Flatten[Lookup[scanRuns, "Rows"], 1]; anchorRows = Flatten[Lookup[anchorRuns, "Rows"], 1];
 scanSummary = summarizeRows[scanRows]; anchorSummary = summarizeRows[anchorRows];
 vs = validateOutput[scanRows, specsAll[], cfg["Seeds"], "scan", cfg, require12];
 va = validateOutput[anchorRows, specsAnchors[], cfg["Seeds"], "anchor", cfg, require12];
 vz = zeroLimitValidation[scanRows, cfg];
 require[vz["FamilyZeroLimitsAgreeRowByRow"] && vz["SchwarzschildRowsAgreeRowByRow"],
  "Zero-parameter row-level consistency failed: " <> ToString[InputForm[vz]]];
 scanPath = exportRows[FileNameJoin[{dir, tag <> "_family_scans_raw.csv"}], scanRows];
 anchorPath = exportRows[FileNameJoin[{dir, tag <> "_anchor_audits_raw.csv"}], anchorRows];
 exportRows[FileNameJoin[{dir, tag <> "_family_scans_summary.csv"}], scanSummary];
 exportRows[FileNameJoin[{dir, tag <> "_anchor_audits_summary.csv"}], anchorSummary];
 scanHeader = First@Import[scanPath, "CSV"]; anchorHeader = First@Import[anchorPath, "CSV"];
 require[scanHeader === Keys[First[scanRows]] && anchorHeader === Keys[First[anchorRows]],
  "CSV headers are not explicit and stable."];
 Export[FileNameJoin[{dir, tag <> "_config.json"}], cfg, "RawJSON"];
 Export[FileNameJoin[{dir, tag <> "_validation.json"}], <|"FamilyScans" -> vs, "AnchorAudits" -> va, "ZeroParameterConsistency" -> vz|>, "RawJSON"];
 <|"FamilyScans" -> vs, "AnchorAudits" -> va, "ZeroParameterConsistency" -> vz|>];

runStatic[] := Module[{report = staticTestReport, tests},
 require[report["TestsFailedCount"] === 0, "Existing construction static tests failed."];
 tests = TestReport[{VerificationTest[Total[Length /@ Values[canonicalFamilies]], 8],
   VerificationTest[Length[specsAnchors[]], 2], VerificationTest[Length[DeleteDuplicates[familyParameterName /@ Keys[canonicalFamilies]]], 2],
   VerificationTest[PathAnisotropyCurvature`distanceMatrixRadius[{{0.,0.},{1.,0.},{0.,1.}}, 1], 1.15]}];
 require[tests["TestsFailedCount"] === 0, "Family static tests failed."]; Print[report]; Print[tests]];

smokeConfig[] := baseConfig[250, {1,2}, FileNameJoin[{repoRoot, "results", "bardeen_hayward_audit_smoke"}]];
fullConfig[] := baseConfig[1000, Range[10], FileNameJoin[{repoRoot, "results", "bardeen_hayward_audit_multiseed"}]];

runSmoke[] := Module[{cfg = smokeConfig[], scans, anchors, validation},
 scans = runResumable["scan", specsAll[], cfg["Seeds"], cfg];
 anchors = runResumable["anchor", specsAnchors[], cfg["Seeds"], cfg];
 validation = writeBundle["bardeen_hayward_N250_seeds2", scans, anchors, cfg, True];
 Print["Smoke passed: ", InputForm[validation]]];

runTiming[] := Module[{cfg, specs, runs, rows},
 cfg = baseConfig[1000, {1}, FileNameJoin[{repoRoot, "results", "bardeen_hayward_audit_timing_N1000"}]];
 specs = {{"Bardeen",0.2},{"Hayward",0.2}};
 runs = runResumable["scan", specs, {1}, cfg]; rows = Flatten[Lookup[runs,"Rows"],1];
 exportRows[FileNameJoin[{cfg["OutputDirectory"], "family_builder_timing_rows.csv"}], rows];
 exportRows[FileNameJoin[{cfg["OutputDirectory"], "family_builder_timing_seconds.csv"}],
  Map[KeyTake[#, {"Family","ParameterValue","Seed","ElapsedSeconds"}] &, runs]]];

runFullFamilyScans[] := Module[{cfg = fullConfig[]}, runResumable["scan", specsAll[], cfg["Seeds"], cfg]];
runFullAnchorAudits[] := Module[{cfg = fullConfig[]}, runResumable["anchor", specsAnchors[], cfg["Seeds"], cfg]];
runFamilyScans[family_String] := Module[{cfg = fullConfig[], specs},
 specs = Select[specsAll[], First[#] === family &];
 require[specs =!= {}, "Unknown scan family " <> family];
 runResumable["scan", specs, cfg["Seeds"], cfg]];
runFamilyAnchor[family_String] := Module[{cfg = fullConfig[], specs},
 specs = Select[specsAnchors[], First[#] === family &];
 require[specs =!= {}, "Unknown anchor family " <> family];
 runResumable["anchor", specs, cfg["Seeds"], cfg]];

loadAll[kind_, specs_, cfg_] := Flatten[Table[Module[{p = checkpointPath[cfg, kind, f, v, s], x},
 x = If[FileExistsQ[p], Import[p,"MX"], $Failed]; require[validCheckpointQ[x,kind,f,v,s,cfg], "Missing/invalid checkpoint "<>p]; x],
 {f,DeleteDuplicates[First/@specs]},{v,Cases[specs,{f,x_}:>x]},{s,cfg["Seeds"]}],Infinity];

runAggregate[] := Module[{cfg=fullConfig[], scans, anchors}, scans=loadAll["scan",specsAll[],cfg]; anchors=loadAll["anchor",specsAnchors[],cfg];
 writeBundle["bardeen_hayward_N1000_seeds10",scans,anchors,cfg,True]];

runValidate[] := runAggregate[];

args = Rest[$ScriptCommandLine]; mode = If[args === {}, "", First[args]];
Switch[mode, "static", runStatic[], "smoke", runSmoke[], "timing", runTiming[],
 "full-family-scans", runFullFamilyScans[], "full-anchor-audits", runFullAnchorAudits[],
 "full-bardeen-scans", runFamilyScans["Bardeen"], "full-hayward-scans", runFamilyScans["Hayward"],
 "full-bardeen-anchor", runFamilyAnchor["Bardeen"], "full-hayward-anchor", runFamilyAnchor["Hayward"],
 "aggregate", runAggregate[], "validate", runValidate[],
 _, fail["Usage: wolframscript -file scripts/run_broader_family_audit.wls static|smoke|timing|full-family-scans|full-anchor-audits|aggregate|validate",64]];
