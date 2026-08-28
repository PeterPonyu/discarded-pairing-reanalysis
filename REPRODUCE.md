# Reproducing the numbers

Every quantity printed in the manuscript is emitted by `paper/figs/make_figs.R`
from the artifacts listed below. None is typed into the prose. The figure code
re-hashes each artifact before reading it, so a modified or missing file stops
the build instead of producing a stale number.

## Bound artifacts

| path | role | bytes | sha256 |
|---|---|---|---|
| `data/e-kill/paper_negative_attention_split.json` | recorded_state | 890 | `ed557c282b600ac3…` |
| `data/e-simple/simple.json` | recorded_state | 669 | `37b5326a650f930d…` |
| `data/e-panel/p004a_not_1000_step.json` | derived_table | 4196 | `800ab0f8ef2ef875…` |
| `data/e-baseline/drift_report.json` | derived_table | 913 | `a18fafc19c512e18…` |
| `data/e-composed/drift_report_full.json` | derived_table | 934 | `621382853be6bd4a…` |
| `data/e-identity/drift_report_identity_only.json` | derived_table | 933 | `abf16928f06298a1…` |
| `data/e-train-joint/train_manifest.json` | protocol | 502 | `b72cd95f170d9a83…` |
| `data/e-train-cross/train_manifest.json` | protocol | 500 | `5861e2303d554ad2…` |
| `data/e-train-self/train_manifest.json` | protocol | 496 | `fb83eacc406aec79…` |
| `data/e-proxy/naive.json` | recorded_state | 820 | `d41aa694c26c61e0…` |
| `data/e-proxy-run/e2e_gpu_train.json` | recorded_state | 1114 | `44922842ffe1a68d…` |
| `data/e-closeout/laptop_closeout.json` | recorded_state | 2785 | `a4864b599469bccb…` |
| `data/e-blocked/sota_copy.json` | recorded_state | 525 | `50b9ebd403b63c94…` |
| `data/e-authorisation/next_design.json` | recorded_state | 2939 | `01b57e6d7e0cba1e…` |

Some of these files recorded the paths of the machine that produced them. Those path strings were rewritten before deposit; `REDACTION.md` states the rules, lists every file touched with both digests, and describes the check that proves no number changed.

## Not redistributed

The manuscript's evidence manifest binds one further artifact that this archive does not carry. No number in the manuscript is derived from that material; it is bound because the manuscript refers to the content, and held back for the reason below.

- The project's own working record of this direction. It is an internal narrative that names other directions, planning decisions and process labels, and no number in the manuscript comes from it. Everything it contributes to the manuscript is stated in the methods section and is separately bound in the recorded-state artifacts that are redistributed.

## Checking the archive without building it

```bash
python3 tools/bind_evidence.py paper --check
```

This re-hashes every path above against `paper/evidence/evidence_manifest.json`
and reports the first artifact that has drifted.

## Rebuilding

```bash
bash build.sh
```

Stage order is verify, regenerate, typeset. Each stage is a hard gate on the
next.
