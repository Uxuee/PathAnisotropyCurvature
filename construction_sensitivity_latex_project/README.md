# Portable LaTeX manuscript project

- Main file: `main.tex`
- Figure directory: `figures/`
- Compiled preview: `compiled_preview.pdf`
- Repository: https://github.com/Uxuee/PathAnisotropyCurvature

Compile from this directory with:

```sh
tectonic main.tex
```

The manuscript requires the standard LaTeX packages `geometry`, `amsmath`,
`amssymb`, `graphicx`, `booktabs`, `array`, `float`, `hyperref`, `xcolor`,
`microtype`, and `caption`. Tectonic downloads missing packages automatically.

The ZIP archive contains `main.tex`, all referenced figures as PDF files, this
README, and the compiled preview. It can be imported directly into Overleaf;
select `main.tex` as the main document if Overleaf does not detect it
automatically.
