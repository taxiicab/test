# kbuild-verify

Compile-only verification for the patches that are currently in flight upstream.

## What it does

On every push to `main`, GitHub Actions:

1. clones `torvalds/linux` (shallow),
2. applies every `patches/*.patch` with `git apply --3way` and records the result,
3. configures the tree with `allmodconfig` + `make prepare`,
4. compiles the objects touched by the patches with `make W=1`,
5. pushes the logs to the **`ci-logs`** branch (`apply.log`, `prepare.log`, `build.log`).

The job result is red if any target object fails to build; the logs are published
either way, so reading them only needs `git fetch origin ci-logs`.

## Patch set

| File | Subject |
|---|---|
| `0001-net-hso-fix-stashed-tx-skb-leak-and-replay-race.patch` | net: hso: fix stashed tx skb leak and replay race (v4) |
| `0001-net-hso-cap-the-MTU-and-drop-oversized-frames.patch` | net: hso: cap the MTU and drop oversized frames (v2) |
| `0001-net-rds-defer-CM-id-destruction-to-a-workqueue.patch` | net/rds: defer CM id destruction to a workqueue (v4) |
| `0001-md-raid1-reject-oversized-raid_disks-values.patch` | md/raid1: reject oversized raid_disks values (v2) |
| `0001-net-mlx5-fix-a-stack-over-read-in-the-QP-debugfs.patch` | net/mlx5: fix a stack over-read in the QP debugfs (v2) |
| `0001-ntfs3-avoid-freeing-the-primary-MFT-record-during-attribute-.patch` | ntfs3: avoid freeing the primary MFT record |

`archive/` keeps withdrawn or rejected patches for reference; they are not applied.

## linux-next workflow

squashfs 1/2 and 2/2 depend on a commit that is still only in linux-next, so
they live in patches-next/ and are verified by .github/workflows/linux-next.yml,
which applies them to 
ext/linux-next.git and builds s/squashfs/*.o.
Logs go to the ci-logs-next branch.

## Reading the results locally

```sh
git fetch origin ci-logs
git show origin/ci-logs:ci-logs/build.log
git show origin/ci-logs:ci-logs/apply.log
```

## Using it for syzbot

Once the repository is public, a patch can be handed to syzbot for a build +
boot test with:

```
#syz test: https://github.com/<owner>/<repo> <commit>
```

The commit must be pushed here first and the repository must be reachable by
syzbot (public).

## Result log (2026-11-26)

Base tree: `torvalds/linux` master, cloned at run time.

| Patch | Apply | `make W=1` object |
|---|---|---|
| net: hso: fix stashed tx skb leak and replay race (v4) | OK | `drivers/net/usb/hso.o` OK |
| net: hso: cap the MTU and drop oversized frames (v2) | OK | `drivers/net/usb/hso.o` OK |
| net/rds: defer CM id destruction to a workqueue (v4) | OK | `net/rds/ib.o` OK |
| md/raid1: reject oversized raid_disks values (v2) | OK | `drivers/md/raid1.o` OK |
| net/mlx5: fix a stack over-read in the QP debugfs (v2) | OK | `.../mlx5/core/debugfs.o` OK |
| ntfs3: avoid freeing the primary MFT record | OK | (covered by fs/ntfs3 build) |
| squashfs 1/2, 2/2 | **FAIL** | not applied; they target an unmerged linux-next commit (`5213b0a08263`) and need a rebase onto mainline |

`make W=1` produced **no warnings** for any of the compiled objects.