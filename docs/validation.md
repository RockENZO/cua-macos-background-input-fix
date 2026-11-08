# Validation record — November 8, 2026

## Environment and provenance

- macOS 27.3, build 26C5035r; Apple Silicon arm64.
- OpenMausBot 0.1.148 integration; Accessibility and Screen Recording allowed.
- CUA source tag `cua-driver-rs-v0.41.2`, commit `86b5ea2d403017d224bb7a1057f1841668b0a68c`.
- Local compiler: Homebrew rustc 1.99.1. The upstream toolchain file pins 1.97.1; that compiler has not been separately validated here.
- `cargo build -p cua-driver --locked`: successful debug build.
- Targeted regression: `keyboard_layout_worker_without_main_queue_times_out_safely`: 1 passed, 0 failed, 690 filtered out, approximately 2.01 seconds.
- Changed Rust file passed rustfmt. Existing unrelated deprecation warning for `AtomicU64::fetch_update` remained.
- Patch SHA256: `26917267485b19a2f64a9667c7f4305899bae3b8a8afae80ddae748a878b8e50`.
- Locally tested stripped, ad-hoc-signed debug executable SHA256: `612562261c6ba112b453b2619d0fc9251576acc595d0676a7461df698770a15a`. The executable is not included; this is provenance, not a reproducible-binary promise.

Before publication, the patch was independently applied to the pinned upstream archive and the resulting keyboard.rs was byte-for-byte identical to the previously built and GUI-tested source. The build and GUI results above were recorded during the repair, not rerun for publication. The source-preparation script was syntax checked and then run end-to-end successfully: sparse clone, pinned checkout, patch check and application all passed.

## Manual GUI observations

1. Upstream 0.41.2 enabled exact off-Space window lookup that the embedded 0.28.2 had not resolved in these tests. This improvement belongs to upstream.
2. Before the local patch, TextEdit `type_text` caused `SIGTRAP` with `dispatch_assert_queue` and `TISCopyCurrentKeyboardLayoutInputSource` on a Tokio worker.
3. After selecting the patched executable and completely restarting OpenMausBot, background TextEdit input containing Chinese, English, digits and a newline succeeded. A later independent AX snapshot showed the expected inserted string. The driver did not crash.
4. Immediately before and after that text insertion, OpenMausBot remained the foreground app and the cursor position was unchanged.
5. Calculator background AX clicks produced 6 × 7 = 42 before the keyboard patch and 8 × 9 = 72 after it. For the first test foreground and cursor were unchanged. During later samples the user was active; cursor movement then cannot be attributed to the bot or used to prove invariance.
6. Background Cmd+S did not persist the edited TextEdit document. Native File > Save returned `background_unavailable`; disk readback retained the previous content. No foreground escalation was attempted.
7. One later AX read failed to resolve the TextEdit window; a bounded reread resolved it. Window lookup remains intermittent.

## Limits of the evidence

This is one machine and a small set of manual operations. It does not prove support for all applications, all keyboard layouts, every macOS version, background saving, or concurrent agents. Whole-operation typing latency and repeated layout-lookup timeout costs have not been benchmarked.

The new unit test exercises a worker while the test harness does not service the main queue. It verifies a safe `None` result and no process abort in that condition. It does not directly exercise an active main queue or verify cancellation after the queue resumes. Those aspects rely on the existing upstream bridge and the manual input observation, within their respective scope.

No personal screenshots, raw crash reports, chat transcripts, platform credentials, or local absolute paths are included.
