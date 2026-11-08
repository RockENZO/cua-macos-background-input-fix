#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$repo_dir/.work/cua"
upstream_commit=86b5ea2d403017d224bb7a1057f1841668b0a68c

if [ -e "$source_dir" ]; then
    echo "Source directory already exists: $source_dir" >&2
    echo "Use a new clone of this patch kit, or inspect the existing source first." >&2
    exit 1
fi
mkdir -p "$repo_dir/.work"
git clone --filter=blob:none --depth 1 --no-checkout --branch cua-driver-rs-v0.41.2     https://github.com/trycua/cua.git "$source_dir"
git -C "$source_dir" sparse-checkout set libs/cua-driver libs/cua libs/images
git -C "$source_dir" checkout --detach "$upstream_commit"
actual_commit=$(git -C "$source_dir" rev-parse HEAD)
if [ "$actual_commit" != "$upstream_commit" ]; then
    echo "Unexpected upstream revision; refusing to patch." >&2
    exit 1
fi
cd "$source_dir/libs/cua-driver/rust"
git apply --check "$repo_dir/patches/keyboard-main-thread.patch"
git apply "$repo_dir/patches/keyboard-main-thread.patch"
echo "Patch applied to $actual_commit"
echo "Source: $source_dir/libs/cua-driver/rust"
