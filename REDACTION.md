# Local paths rewritten before deposit

Some result files recorded the machine they ran on, including local folder
names. Those strings are not published. The copies in this archive were
rewritten before deposit. The left column names each class of string rather
than quoting it.

The rewrite changes path strings only. Numbers and table structure stay the
same. Longer matches are applied first.

| replaced | with |
|---|---|
| the absolute filesystem prefix of the machine the archive was assembled on | removed |
| the checkout prefix of a rented machine a run executed on | removed |
| the remaining scratch-mount prefix of that rented machine | `<remote>/` |
| the recorded path of an artifact that is archived here | the path it now has in this archive |
| the home directory of the account the runs executed under | `~/` |
| any remaining directory prefix belonging to the private source tree | `source-tree/` |
| a branch of the private repository named in a recorded instruction | `<private-branch>` |
| a private project status word | the ordinary word it stands for |

Both machine prefixes are removed before a file is mapped to its place in this
archive, so the same path recorded on two machines becomes the same archived
string. A study that never left one machine will only show some of these
substitutions.

The last two rows rewrite recorded values, never keys. A reader comparing an
archived file with the original should see the same fields and the same
numbers; only a local name is changed.

## What was checked

Every rewritten file was read again after substitution and compared with the
original after all string values were blanked. A changed number, a dropped
field, a reordered list or a lost record stops the export. For line-oriented
files the line count is compared as well.

## Files rewritten

The hash on the left is the file as the run wrote it. The hash on the right is
the file in this archive, and it is the one the file list names and the build
checks.

| path | path substitutions | receipt-link refreshes | original sha256 | archived sha256 |
|---|---:|---:|---|---|
| `data/e-kill/paper_negative_attention_split.json` | 1 | 0 | `724b08d37dc704b4…` | `ed557c282b600ac3…` |
| `data/e-simple/simple.json` | 1 | 0 | `0f474de2dbb50f47…` | `37b5326a650f930d…` |
| `data/e-panel/p004a_not_1000_step.json` | 19 | 0 | `bae5b127e740cc5f…` | `800ab0f8ef2ef875…` |
| `data/e-train-joint/train_manifest.json` | 2 | 0 | `38082853e691b3b1…` | `b72cd95f170d9a83…` |
| `data/e-train-cross/train_manifest.json` | 2 | 0 | `2d8232a2d9bd4ab8…` | `5861e2303d554ad2…` |
| `data/e-train-self/train_manifest.json` | 2 | 0 | `f869800323908c92…` | `fb83eacc406aec79…` |
| `data/e-proxy/naive.json` | 3 | 0 | `b3f4ed866b237b40…` | `d41aa694c26c61e0…` |
| `data/e-proxy-run/e2e_gpu_train.json` | 4 | 0 | `57e3b93b9737ac0f…` | `44922842ffe1a68d…` |
| `data/e-closeout/laptop_closeout.json` | 7 | 0 | `7197703b1925a14f…` | `0ca2fbf280db26ef…` |
| `data/e-authorisation/next_design.json` | 2 | 0 | `01b57e6d7e0cba1e…` | `027151dafb365afc…` |
