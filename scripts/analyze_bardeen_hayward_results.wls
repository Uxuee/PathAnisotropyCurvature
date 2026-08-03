repoRoot = ExpandFileName@FileNameJoin[{DirectoryName[$InputFileName], ".."}];
Get[FileNameJoin[{repoRoot, "code", "CurvatureEstimator.wl"}]];
outDir = FileNameJoin[{repoRoot, "results", "bardeen_hayward_audit_multiseed"}];
figDir = FileNameJoin[{repoRoot, "results", "figures"}];
If[!DirectoryQ[figDir], CreateDirectory[figDir, CreateIntermediateDirectories -> True]];

readCSV[path_] := Module[{t=Import[path,"CSV"]}, AssociationThread[First[t],#]& /@ Rest[t]];
scanRows = readCSV[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_family_scans_raw.csv"}]];
anchorRows = readCSV[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_anchor_audits_raw.csv"}]];
families={"Bardeen","Hayward"};
protocols={"Original matched-flat KNN","Strict radius","Pure KNN","Mutual KNN","Edge-matched radius"};

stats[v_List] := Module[{n=Length[v],m,sd,sem,t}, m=Mean[v]; sd=StandardDeviation[v]; sem=sd/Sqrt[n];
 t=Quantile[StudentTDistribution[n-1],.975]; <|"Mean"->m,"SD"->sd,"SEM"->sem,
 "CI95Low"->m-t sem,"CI95High"->m+t sem,"Minimum"->Min[v],"Maximum"->Max[v]|>];

scanSummary=Flatten@Table[Module[{g=Select[scanRows,#Family===fam&&#ParameterValue==par&], row=<||>,s},
 row=<|"Family"->fam,"ParameterName"->First[g]["ParameterName"],"ParameterValue"->par,"NSeeds"->Length[g]|>;
 Do[s=stats[N@Lookup[g,field]]; row=Join[row,Association@KeyValueMap[(field<>#1)->#2&,s]],
  {field,{"RhoBH","RhoFlat","DeltaRho","AbsDeltaRho","PearsonBHLogK","SpearmanBHLogK"}}]; row],
 {fam,families},{par,Sort@DeleteDuplicates@Lookup[Select[scanRows,#Family===fam&],"ParameterValue"]}];

anchorSummary=Flatten@Table[Module[{g=Select[anchorRows,#Family===fam&&#Protocol===prot&], row=<||>,s},
 row=<|"Family"->fam,"ParameterName"->First[g]["ParameterName"],"ParameterValue"->First[g]["ParameterValue"],"Protocol"->prot,"NSeeds"->Length[g]|>;
 Do[s=stats[N@Lookup[g,field]]; row=Join[row,Association@KeyValueMap[(field<>#1)->#2&,s]],
  {field,{"RhoBH","RhoFlat","DeltaRho","AbsDeltaRho","BHEdges","FlatEdges","BHMeanDegree","FlatMeanDegree"}}]; row],
 {fam,families},{prot,protocols}];

contrasts=Flatten@Table[Module[{a,b,dAbs,dSigned,sAbs,sSigned},
 a=SortBy[Select[anchorRows,#Family===fam&&#Protocol===protocols[[i]]&],#Seed&];
 b=SortBy[Select[anchorRows,#Family===fam&&#Protocol===protocols[[j]]&],#Seed&];
 dAbs=N@Lookup[a,"AbsDeltaRho"]-N@Lookup[b,"AbsDeltaRho"];
 dSigned=N@Lookup[a,"DeltaRho"]-N@Lookup[b,"DeltaRho"];
 sAbs=stats[dAbs]; sSigned=stats[dSigned];
 Join[<|"Family"->fam,"ProtocolA"->protocols[[i]],"ProtocolB"->protocols[[j]],"NPairedSeeds"->Length[dAbs]|>,
  Association@KeyValueMap[("AbsDeltaContrast"<>#1)->#2&,sAbs],
  Association@KeyValueMap[("SignedDeltaContrast"<>#1)->#2&,sSigned]]],
 {fam,families},{i,1,Length[protocols]-1},{j,i+1,Length[protocols]}];

qcFields={"Family","ParameterName","ParameterValue","Seed","Protocol","N","k","GraphShellRadius","BinsRequested","CommonBins",
 "BHEdges","FlatEdges","BHMeanDegree","FlatMeanDegree","BHComponents","FlatComponents","BHLargestComponentFraction","FlatLargestComponentFraction",
 "BHValidLogCMDFraction","FlatValidLogCMDFraction","BHRadius","FlatRadius","EdgeCountDifference","FlatEdgesTiedAtRadius","XYMismatch","SampleXYHash","CommonProfileHash","SourceCheckpoint"};
qcRows=KeyTake[#,qcFields]& /@ Join[scanRows,anchorRows];
runtimeRows=KeyTake[#, {"Family","ParameterName","ParameterValue","Seed","Protocol","RuntimeSeconds","SourceCheckpoint"}]& /@ Join[scanRows,anchorRows];
runtimeUnique=DeleteDuplicatesBy[runtimeRows,{#Family,#ParameterValue,#Seed,#RuntimeSeconds}&];
runtimeJSON=<|"CheckpointUnits"->Length[runtimeUnique],"TotalCheckpointComputeSeconds"->Total@Lookup[runtimeUnique,"RuntimeSeconds"],
 "MeanCheckpointSeconds"->Mean@Lookup[runtimeUnique,"RuntimeSeconds"],"MinimumCheckpointSeconds"->Min@Lookup[runtimeUnique,"RuntimeSeconds"],
 "MaximumCheckpointSeconds"->Max@Lookup[runtimeUnique,"RuntimeSeconds"]|>;

PathAnisotropyCurvature`exportDatasetCSV[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_scan_detailed_summary.csv"}],scanSummary];
PathAnisotropyCurvature`exportDatasetCSV[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_anchor_detailed_summary.csv"}],anchorSummary];
PathAnisotropyCurvature`exportDatasetCSV[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_paired_contrasts.csv"}],contrasts];
PathAnisotropyCurvature`exportDatasetCSV[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_quality_control.csv"}],qcRows];
PathAnisotropyCurvature`exportDatasetCSV[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_runtime.csv"}],runtimeUnique];
Export[FileNameJoin[{outDir,"bardeen_hayward_N1000_seeds10_runtime.json"}],runtimeJSON,"RawJSON"];

short=<|"Original matched-flat KNN"->"Original","Strict radius"->"Strict radius","Pure KNN"->"Pure KNN","Mutual KNN"->"Mutual KNN","Edge-matched radius"->"Edge-matched"|>;
colors={RGBColor[.12,.47,.71],RGBColor[.85,.33,.10],RGBColor[.20,.63,.17],RGBColor[.58,.40,.74],RGBColor[.55,.34,.29]};

Do[Module[{s=Select[scanSummary,#Family===fam&],parLabel,plot}, parLabel=If[fam==="Bardeen","g","ell"];
 plot=ListLinePlot[{({#ParameterValue,Around[#RhoBHMean,#RhoBHSD]}&/@s),({#ParameterValue,Around[#RhoFlatMean,#RhoFlatSD]}&/@s),({#ParameterValue,Around[#AbsDeltaRhoMean,#AbsDeltaRhoSD]}&/@s)},
  Frame->True,FrameLabel->{parLabel,"Correlation / absolute gap"},PlotLegends->{"BH rho","Flat rho","|Delta rho|"},PlotMarkers->Automatic,
  GridLines->{Automatic,Automatic},GridLinesStyle->Directive[GrayLevel[.65],Opacity[.32],AbsoluteThickness[.6]],Method->{"GridLinesInFront"->False},
  PlotRange->All,ImageSize->520,PlotLabel->fam<>" canonical fixed-protocol scan (mean +/- SD)"];
 Export[FileNameJoin[{figDir,ToLowerCase[fam]<>"_canonical_parameter_scan.pdf"}],plot];
 Export[FileNameJoin[{figDir,ToLowerCase[fam]<>"_canonical_parameter_scan.png"}],plot,ImageResolution->180]],{fam,families}];

Do[Module[{s=Select[anchorSummary,#Family===fam&],meanPlot,rows,absSeries,signedSeries,seedPlotAbs,seedPlotSigned,plots,ticks},
 ticks=Table[{i,Rotate[Style[short[protocols[[i]]],9],Pi/5]},{i,5}];
 meanPlot=ListPlot[MapIndexed[{First[#2],Around[#1["AbsDeltaRhoMean"],#1["AbsDeltaRhoSD"]]}&,s],Frame->True,
  FrameLabel->{"Protocol","Mean |Delta rho|"},FrameTicks->{{Automatic,None},{ticks,None}},ImagePadding->{{60,20},{85,25}},
  GridLines->{None,Automatic},GridLinesStyle->Directive[GrayLevel[.65],Opacity[.32],AbsoluteThickness[.6]],Method->{"GridLinesInFront"->False},
  PlotMarkers->{Automatic,10},PlotRange->All,ImageSize->540,PlotLabel->fam<>" five-protocol anchor (mean +/- SD)"];
 rows=Select[anchorRows,#Family===fam&];
 absSeries=Table[Lookup[SortBy[Select[rows,#Seed===seed&],First@FirstPosition[protocols,#Protocol]&],"AbsDeltaRho"],{seed,Range[10]}];
 signedSeries=Table[Lookup[SortBy[Select[rows,#Seed===seed&],First@FirstPosition[protocols,#Protocol]&],"DeltaRho"],{seed,Range[10]}];
 seedPlotAbs=ListLinePlot[absSeries,Frame->True,FrameLabel->{"Protocol","|Delta rho|"},FrameTicks->{{Automatic,None},{ticks,None}},ImagePadding->{{60,100},{85,25}},
  GridLines->{None,Automatic},GridLinesStyle->Directive[GrayLevel[.65],Opacity[.32],AbsoluteThickness[.6]],Method->{"GridLinesInFront"->False},
  PlotLegends->("Seed "<>ToString[#]&/@Range[10]),PlotMarkers->Automatic,PlotRange->All,ImageSize->600,PlotLabel->fam<>" paired absolute gaps"];
 seedPlotSigned=ListLinePlot[signedSeries,Frame->True,FrameLabel->{"Protocol","Signed Delta rho"},FrameTicks->{{Automatic,None},{ticks,None}},ImagePadding->{{60,100},{85,25}},
  GridLines->{None,Automatic},GridLinesStyle->Directive[GrayLevel[.65],Opacity[.32],AbsoluteThickness[.6]],Method->{"GridLinesInFront"->False},
  PlotLegends->("Seed "<>ToString[#]&/@Range[10]),PlotMarkers->Automatic,PlotRange->All,ImageSize->600,PlotLabel->fam<>" paired signed gaps"];
 plots=Thread[{{"_anchor_mean_abs_gap","_anchor_paired_abs_gap","_anchor_paired_signed_gap"},{meanPlot,seedPlotAbs,seedPlotSigned}}];
 Do[If[ext===".png",Export[FileNameJoin[{figDir,ToLowerCase[fam]<>pair[[1]]<>ext}],pair[[2]],ImageResolution->180],
   Export[FileNameJoin[{figDir,ToLowerCase[fam]<>pair[[1]]<>ext}],pair[[2]]]],{pair,plots},{ext,{".pdf",".png"}}]],{fam,families}];

fmt[x_]:=ToString@NumberForm[N[x],{5,3},NumberPadding->{"","0"}];
scanTable[fam_]:=StringRiffle[Join[{"\\begin{tabular}{c r r r r}","\\toprule","Parameter & $\\rho_{BH}$ & $\\rho_{flat}$ & $\\Delta\\rho$ & $|\\Delta\\rho|$ \\\\","\\midrule"},
 (fmt[#ParameterValue]<>" & "<>fmt[#RhoBHMean]<>" $\\pm$ "<>fmt[#RhoBHSD]<>" & "<>fmt[#RhoFlatMean]<>" $\\pm$ "<>fmt[#RhoFlatSD]<>" & "<>fmt[#DeltaRhoMean]<>" $\\pm$ "<>fmt[#DeltaRhoSD]<>" & "<>fmt[#AbsDeltaRhoMean]<>" $\\pm$ "<>fmt[#AbsDeltaRhoSD]<>" \\\\"& /@ Select[scanSummary,#Family===fam&]),
 {"\\bottomrule","\\end{tabular}"}],"\n"];
anchorTable[fam_]:=StringRiffle[Join[{"\\begin{tabular}{l r r r r}","\\toprule","Protocol & $\\rho_{BH}$ & $\\rho_{flat}$ & $\\Delta\\rho$ & $|\\Delta\\rho|$ \\\\","\\midrule"},
 (short[#Protocol]<>" & "<>fmt[#RhoBHMean]<>" $\\pm$ "<>fmt[#RhoBHSD]<>" & "<>fmt[#RhoFlatMean]<>" $\\pm$ "<>fmt[#RhoFlatSD]<>" & "<>fmt[#DeltaRhoMean]<>" $\\pm$ "<>fmt[#DeltaRhoSD]<>" & "<>fmt[#AbsDeltaRhoMean]<>" $\\pm$ "<>fmt[#AbsDeltaRhoSD]<>" \\\\"& /@ Select[anchorSummary,#Family===fam&]),
 {"\\bottomrule","\\end{tabular}"}],"\n"];
Do[Export[FileNameJoin[{outDir,ToLowerCase[fam]<>"_scan_table.tex"}],scanTable[fam],"Text"];
 Export[FileNameJoin[{outDir,ToLowerCase[fam]<>"_anchor_table.tex"}],anchorTable[fam],"Text"],{fam,families}];
Print["Analysis complete: ",outDir];
