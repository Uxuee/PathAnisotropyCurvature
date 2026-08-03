## Colored shell and ball examples

The local estimator is computed from graph-distance shells. To visualize this, a center vertex is highlighted in red, the graph-distance ball in light blue, and the shell in orange.

![Flat colored shell and ball](results/figures/flat_colored_shell_ball.png)

![Flamm colored shell and ball](results/figures/flamm_colored_shell_ball.png)

These figures are produced by:

```wolfram
SeedRandom[1234];

flat500 = buildFlatDataset[500, 14];
flamm500 = buildFlammDataset[500, 1/2, 14];

centerVertex = 1;
graphRadius = 3;

flatColoredShell =
  coloredGeometryPlot[
    flat500,
    centerVertex,
    graphRadius,
    "Flat shell/ball example"
  ];

flammColoredShell =
  coloredGeometryPlot[
    flamm500,
    centerVertex,
    graphRadius,
    "Flamm shell/ball example"
  ];

Export["results/figures/flat_colored_shell_ball.png", flatColoredShell];
Export["results/figures/flamm_colored_shell_ball.png", flammColoredShell];
```
