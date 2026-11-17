#!/usr/bin/env bash
# Compile-verify the patches in this directory inside a GitHub Codespace
# (or any Ubuntu/Debian VM with >=2 cores and ~4 GB free disk).
#
# Usage:
#   ./verify-build-codespace.sh [PATCH_DIR]
#
# Default PATCH_DIR is ./patches next to this script.
# Logs land in ./build-logs/.

set -euo pipefail

PATCH_DIR="${1:-$(cd "$(dirname "$0")" && pwd)/patches}"
WORK="${HOME}/kbuild"
BASE_SHA="${BASE_SHA:-7e1392a42}"          # net-7.4-rc3 merge, base of the patches
LOG_DIR="$(pwd)/build-logs"
KERNEL_URL="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"

mkdir -p "$LOG_DIR"

echo "==> installing build dependencies"
sudo apt-get update -qq
sudo apt-get install -y -qq build-essential bc bison flex libssl-dev \
	libelf-dev libncurses-dev zstd git >/dev/null

echo "==> cloning linux (shallow)"
rm -rf "$WORK"
git clone --depth 1 "$KERNEL_URL" "$WORK"
cd "$WORK"

# Try to get the exact base the patches were written against; fall back to
# current master if the server refuses to serve that object shallowly.
if git fetch --depth 1 origin "$BASE_SHA" 2>"$LOG_DIR/fetch-base.log"; then
	git checkout -q FETCH_HEAD
	echo "==> base: $BASE_SHA ($(git log -1 --format='%s'))"
else
	echo "==> base: current master ($(git log -1 --format='%h %s'))"
fi

echo "==> applying patches from $PATCH_DIR"
shopt -s nullglob
applied=0
for p in "$PATCH_DIR"/*.patch; do
	echo "    $(basename "$p")"
	if git apply --3way "$p"; then
		applied=$((applied + 1))
	else
		echo "!!! failed to apply: $p" | tee -a "$LOG_DIR/apply.log"
	fi
done
[ "$applied" -gt 0 ] || { echo "no patch applied, aborting"; exit 1; }

echo "==> configuring"
make defconfig >/dev/null
./scripts/config -e USB -e USB_HSO -e NET -e RDS -e RDS_RDMA >/dev/null
make olddefconfig >/dev/null
make -j"$(nproc)" prepare >"$LOG_DIR/prepare.log" 2>&1

build() {
	local obj="$1" tag="$2"
	echo "==> compiling $obj (W=1)"
	if make W=1 -j"$(nproc)" "$obj" >"$LOG_DIR/$tag.log" 2>&1; then
		echo "    OK   $obj"
		return 0
	fi
	echo "    FAIL $obj (see $LOG_DIR/$tag.log)"
	return 1
}

rc=0
build drivers/net/usb/hso.o hso || rc=1
build net/rds/ib.o rds_ib || rc=1

# Optional sparse pass, only if sparse is installed.
if command -v sparse >/dev/null; then
	echo "==> sparse (C=1) pass"
	make C=1 -j"$(nproc)" drivers/net/usb/hso.o net/rds/ib.o \
		>"$LOG_DIR/sparse.log" 2>&1 || echo "    sparse reported issues (see $LOG_DIR/sparse.log)"
fi

if [ "$rc" -eq 0 ]; then
	echo "==> BUILD OK"
else
	echo "==> BUILD FAILED"
fi
echo "logs: $LOG_DIR"
exit "$rc"
