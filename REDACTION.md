# Redaction of recorded paths

The result files in this archive were written by the runs that produced them,
and they recorded where they were running. Those paths describe a private
machine and are not published, so the archived copies were rewritten before
deposit. Describing the rules below without reproducing the paths they remove is
the point of this file, so the left column names each class of string rather
than quoting it.

The rewrite is textual and total: it substitutes path strings and nothing else.
Rules are applied longest match first.

| replaced | with |
|---|---|
| the absolute filesystem prefix of the machine the runs executed on | removed |
| the recorded path of an artifact that is archived here | the path it now has in this archive |
| the home directory of the account the runs executed under | `~/` |
| any remaining directory prefix belonging to the private source tree | `source-tree/` |

## What was checked

Every rewritten file was reparsed after substitution and compared against the
original with all string leaves erased. A changed number, a dropped key, a
reordered list or a lost record fails the export rather than being deposited.
For line-oriented records the record count is compared as well.

## Files rewritten

The digest on the left is the file as the run wrote it; the digest on the right
is the file in this archive, and it is the one the manifest binds and the build
verifies.

| path | substitutions | original sha256 | archived sha256 |
|---|---|---|---|
| `data/e-kill/paper_negative_attention_split.json` | 1 | `724b08d37dc704b4…` | `ed557c282b600ac3…` |
| `data/e-simple/simple.json` | 1 | `0f474de2dbb50f47…` | `37b5326a650f930d…` |
| `data/e-panel/p004a_not_1000_step.json` | 19 | `bae5b127e740cc5f…` | `800ab0f8ef2ef875…` |
| `data/e-train-joint/train_manifest.json` | 2 | `38082853e691b3b1…` | `b72cd95f170d9a83…` |
| `data/e-train-cross/train_manifest.json` | 2 | `2d8232a2d9bd4ab8…` | `5861e2303d554ad2…` |
| `data/e-train-self/train_manifest.json` | 2 | `f869800323908c92…` | `fb83eacc406aec79…` |
| `data/e-proxy/naive.json` | 3 | `b3f4ed866b237b40…` | `d41aa694c26c61e0…` |
| `data/e-proxy-run/e2e_gpu_train.json` | 4 | `57e3b93b9737ac0f…` | `44922842ffe1a68d…` |
| `data/e-closeout/laptop_closeout.json` | 6 | `7197703b1925a14f…` | `a4864b599469bccb…` |
