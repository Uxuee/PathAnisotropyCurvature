(* Paired seed-level analysis from the audited 50-row raw CSV. *)

repoRoot = ExpandFileName @ FileNameJoin[{DirectoryName[$InputFileName], ".."}];
Get[FileNameJoin[{repoRoot, "code", "CurvatureEstimator.wl"}]];

input = FileNameJoin[{repoRoot, "results", "construction_audit_multiseed",
    "schwarzschild_five_protocols_N1000_seeds10_raw.csv"}];
outDir = FileNameJoin[{repoRoot, "results", "construction_audit_multiseed",
    "seed_level_analysis"}];
If[! DirectoryQ[outDir], CreateDirectory[outDir, CreateIntermediateDirectories -> True]];

table = Import[input, "CSV"];
headers = First[table];
rows = AssociationThread[headers, #] & /@ Rest[table];
If[Length[rows] =!= 50, Print["ERROR: expected 50 raw rows."]; Exit[2]];

protocols = {"Original matched-flat KNN", "Strict radius", "Pure KNN",
   "Mutual KNN", "Edge-matched radius"};
shortLabels = {"Original", "Strict radius", "Pure KNN", "Mutual KNN",
   "Edge-matched"};
seeds = Range[10];

delta[seed_, protocol_] := Module[{matches},
  matches = Select[rows, #Seed === seed && #Protocol === protocol &];
  If[Length[matches] =!= 1,
   Print["ERROR: missing or duplicate seed/protocol row: ", seed, " / ", protocol];
   Exit[2]];
  N[First[matches]["DeltaRho"]]
  ];

summaryRows = Table[
   Module[{signed, absolute, q1, median, q3, iqr, lower, upper, flagged},
    signed = delta[#, protocol] & /@ seeds;
    absolute = Abs[signed];
    {q1, median, q3} = Quantile[absolute, {0.25, 0.5, 0.75}];
    iqr = q3 - q1;
    lower = Max[0., q1 - 1.5 iqr];
    upper = q3 + 1.5 iqr;
    flagged = Pick[seeds, Map[# < lower || # > upper &, absolute], True];
    <|"Protocol" -> protocol, "NSeeds" -> 10,
     "SignedMeanDeltaRho" -> N[Mean[signed]],
     "SignedStdDeltaRho" -> N[StandardDeviation[signed]],
     "MedianAbsDeltaRho" -> N[median], "Q1AbsDeltaRho" -> N[q1],
     "Q3AbsDeltaRho" -> N[q3], "IQRAbsDeltaRho" -> N[iqr],
     "IQRFlaggedSeeds" -> If[flagged === {}, "", StringRiffle[ToString /@ flagged, ";"]]|>
    ],
   {protocol, protocols}];

tcrit = N @ Quantile[StudentTDistribution[9], 0.975];
contrastRows = Flatten @ Table[
    Module[{a, b, differences, mean, sd, sem, half},
     a = Abs[delta[#, protocols[[i]]]] & /@ seeds;
     b = Abs[delta[#, protocols[[j]]]] & /@ seeds;
     differences = a - b;
     mean = N[Mean[differences]];
     sd = N[StandardDeviation[differences]];
     sem = N[sd/Sqrt[10]];
     half = N[tcrit sem];
     <|"ProtocolA" -> protocols[[i]], "ProtocolB" -> protocols[[j]],
      "ContrastDefinition" -> "AbsDeltaRho_A_minus_AbsDeltaRho_B",
      "NPairedSeeds" -> 10, "MeanPairedDifference" -> mean,
      "StdPairedDifference" -> sd, "SEMPairedDifference" -> sem,
      "CI95Low" -> N[mean - half], "CI95High" -> N[mean + half],
      "MedianPairedDifference" -> N[Median[differences]]|>
     ],
    {i, 1, Length[protocols] - 1}, {j, i + 1, Length[protocols]}];

PathAnisotropyCurvature`exportDatasetCSV[
 FileNameJoin[{outDir, "protocol_median_iqr.csv"}], summaryRows];
PathAnisotropyCurvature`exportDatasetCSV[
 FileNameJoin[{outDir, "paired_protocol_contrasts.csv"}], contrastRows];

absSeries = Table[Abs[delta[seed, #]] & /@ protocols, {seed, seeds}];
signedSeries = Table[delta[seed, #] & /@ protocols, {seed, seeds}];
seedLegends = "Seed " <> ToString[#] & /@ seeds;

absPlot = ListLinePlot[absSeries, Frame -> True,
   FrameLabel -> {"Protocol", "|Delta rho_r|"},
   FrameTicks -> {{Automatic, None}, {Thread[{Range[5], shortLabels}], None}},
   PlotMarkers -> Automatic, PlotLegends -> Placed[seedLegends, Right],
   PlotRange -> All, GridLines -> None, ImageSize -> 800,
   PlotLabel -> "Paired construction sensitivity across ten seeds"];

signedPlot = ListLinePlot[signedSeries, Frame -> True,
   FrameLabel -> {"Protocol", "Signed Delta rho_r"},
   FrameTicks -> {{Automatic, None}, {Thread[{Range[5], shortLabels}], None}},
   PlotMarkers -> Automatic, PlotLegends -> Placed[seedLegends, Right],
   PlotRange -> All, GridLines -> None, ImageSize -> 800,
   PlotLabel -> "Signed radial-correlation gap across ten paired seeds"];

Export[FileNameJoin[{outDir, "paired_abs_delta_by_seed.pdf"}], absPlot];
Export[FileNameJoin[{outDir, "paired_abs_delta_by_seed.png"}], absPlot,
 ImageResolution -> 220];
Export[FileNameJoin[{outDir, "paired_signed_delta_by_seed.pdf"}], signedPlot];
Export[FileNameJoin[{outDir, "paired_signed_delta_by_seed.png"}], signedPlot,
 ImageResolution -> 220];

metadata = <|"Source" -> FileNameJoin[{"results", "construction_audit_multiseed",
      "schwarzschild_five_protocols_N1000_seeds10_raw.csv"}],
   "NPairedSeeds" -> 10, "Protocols" -> protocols,
   "Interval" -> "Two-sided 95% Student-t interval for the mean paired difference, df=9",
   "IQRConvention" -> "Wolfram Quantile defaults; flag outside [Q1-1.5 IQR, Q3+1.5 IQR]",
   "Caution" -> "Marginal confidence-interval overlap is not a paired significance test."|>;
Export[FileNameJoin[{outDir, "analysis_metadata.json"}], metadata, "RawJSON"];

Print["Seed-level analysis complete: ", outDir];
