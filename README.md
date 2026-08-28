# Matched runs, unpaired test: recovering a discarded pairing in a small personalisation comparison, and pre-registering the one that would settle it

Per-prompt fidelity records, adapter training manifests, figure code and manuscript source for a re-analysis that recovers the pairing a small diffusion-personalisation comparison discarded, reports what four pairs can and cannot support, and fixes the paired protocol that would settle the question before it is run.

This repository has not been deposited in a public archive, so it has no persistent identifier yet. One will be recorded here when an archive exists.

## What is here

- `paper/tex/` — manuscript source. The abstract, the methods and the figure
  captions are separate files and each is self-contained.
- `paper/figs/` — the R code that draws every figure and emits every number the
  manuscript prints.
- `paper/evidence/` — the manifest binding each artifact to its SHA-256 digest.
- `data/` — the 14 artifacts the manifest names, at the bytes that
  were hashed.

## Not redistributed

The manuscript's evidence manifest binds one further artifact that this archive does not carry. No number in the manuscript is derived from that material; it is bound because the manuscript refers to the content, and held back for the reason below.

- The project's own working record of this direction. It is an internal narrative that names other directions, planning decisions and process labels, and no number in the manuscript comes from it. Everything it contributes to the manuscript is stated in the methods section and is separately bound in the recorded-state artifacts that are redistributed.

## Rebuild

```bash
bash build.sh
```

The build re-hashes every artifact before reading it and stops if any byte has
moved. Figures and printed numbers are regenerated from those bytes rather than
transcribed, so the manuscript cannot quietly disagree with its own data.

Requires `python3`, `Rscript` with `digest`, `ggplot2` and `jsonlite`, and a
TeX distribution with `latexmk`.

## Status

Working draft. Not submitted to any venue.

## Licence

Code: MIT (`LICENSE`). Manuscript text, figures and recorded result data:
CC BY 4.0 (`LICENSE-CONTENT`).
