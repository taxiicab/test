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
| `0001-squashfs-return-EINVAL-on-invalid-directory-inode-size.patch` | squashfs: return -EINVAL on invalid directory inode size |
| `0002-squashfs-return-EIO-on-out-of-bounds-directory-entry-in-lookup.patch` | squashfs: return -EIO on out of bounds directory entry |

`archive/` keeps withdrawn or rejected patches for reference; they are not applied.

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
