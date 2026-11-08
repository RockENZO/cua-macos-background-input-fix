# CUA macOS background input crash fix

修复 CUA 0.41.2 在 macOS 后台输入时，由键盘布局查询线程不正确引起的崩溃。包含最小补丁、回归测试、构建步骤和实测边界。

A small, reproducible patch for a **macOS `type_text` crash** in [trycua/cua](https://github.com/trycua/cua), tested through OpenMausBot. Carbon keyboard-layout lookup is moved from a Tokio worker to the existing bounded main-queue bridge.

This is an independent patch kit maintained by [RockENZO](https://github.com/RockENZO), not an official CUA release. Background computer use and newer off-Space window lookup are upstream CUA features; this repository contributes the keyboard-layout thread-affinity fix and its regression test.

## What failed

On macOS 27.3 (Apple Silicon), typing into a background TextEdit document could terminate the driver with `SIGTRAP`:

```text
dispatch_assert_queue
  → TISCopyCurrentKeyboardLayoutInputSource
  → target_layout → press_key
  → document_edit::send_net_zero_edit
  → ensure_marked_after_ax_write → type_text_blocking
```

The failing call ran on `tokio-rt-worker`. `current_layout()` now dispatches its Carbon work to the main queue. If the bridge times out, it returns `None` instead of falling back to Carbon on the worker. This is a layout lookup fallback, not a guarantee that the entire input operation fails atomically or preserves every keyboard layout.

## Use the patch

Requirements: macOS, Xcode command-line tools, Git, Rust/Cargo. Upstream pins Rust 1.97.1; the recorded local build used Homebrew Rust 1.99.1. Accessibility and Screen Recording permissions are needed for GUI verification.

```sh
git clone https://github.com/RockENZO/cua-macos-background-input-fix.git
cd cua-macos-background-input-fix
./scripts/prepare.sh
cd .work/cua/libs/cua-driver/rust
cargo test -p platform-macos --locked keyboard_layout_worker_without_main_queue_times_out_safely
cargo build -p cua-driver --locked
```

The script checks out upstream commit `86b5ea2d403017d224bb7a1057f1841668b0a68c` (tag `cua-driver-rs-v0.41.2`), checks the patch, and applies it. It does not change an installed app or select a runtime. Build output is `target/debug/cua-driver` inside the Rust workspace. No prebuilt executable is distributed here.

For an existing checkout at that commit, apply manually **from `libs/cua-driver/rust`**:

```sh
git apply --check /absolute/path/to/keyboard-main-thread.patch
git apply /absolute/path/to/keyboard-main-thread.patch
```

## Recorded verification

Local results on November 8, 2026; see [validation and limitations](docs/validation.md). These are recorded observations, not CI results from every macOS version.

| Check | Result |
| --- | --- |
| Locked debug build | Passed |
| Worker/no-main-queue regression | 1 passed, 0 failed |
| Off-Space Calculator AX clicks | `6 × 7 = 42`; later `8 × 9 = 72` |
| Background TextEdit input | Chinese, English, digits and newline read back; no crash |
| Text input focus/cursor check | Foreground app and cursor unchanged immediately before/after |
| Background TextEdit save | Failed/refused; not solved by this patch |
| Off-Space window lookup | Intermittent unresolved reads remain |
| Multiple concurrent agents | Not tested |

The regression covers timeout behavior without a draining main queue. It does not independently prove successful main-queue execution; the successful input path is covered by the recorded manual GUI test.

## OpenMausBot integration

An OpenMausBot installation that supports `CUA_DRIVER_PATH` can select a locally built executable. See [integration and rollback](docs/openmausbot.md). This patch does not add background support to apps that reject it, and must not be used as a reason to silently fall back to foreground input.

## Scope and credit

- Upstream: [CUA 0.41.2 source](https://github.com/trycua/cua/tree/86b5ea2d403017d224bb7a1057f1841668b0a68c), including the existing main-queue bridge and cross-Space lookup.
- Our change: [keyboard patch](patches/keyboard-main-thread.patch), reproduced against that exact upstream source.
- Upstream contribution: [trycua/cua#6926](https://github.com/trycua/cua/pull/6926), submitted as a draft against main. The tagged-build validation above does not certify the main-based PR commit; current-commit checks and native E2E remain outstanding.
- MIT licensed; upstream copyright and license are retained in [LICENSE](LICENSE).
