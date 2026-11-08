# OpenMausBot integration and rollback

This was tested with an installation supporting `CUA_DRIVER_PATH`. Paths and supported override behavior may differ in other versions. Build the executable first; this repository does not install it automatically.

For a GUI app launched through macOS launch services, use an **absolute path** to your locally built executable:

```sh
launchctl setenv CUA_DRIVER_PATH /absolute/path/to/cua-driver
launchctl getenv CUA_DRIVER_PATH
```

Completely quit and reopen OpenMausBot. Verify the active executable/runtime before testing; the version may still say 0.41.2, so the version string alone does not prove the patch is loaded. If macOS requests Accessibility or Screen Recording permission for the new executable, grant it through System Settings before GUI testing. Do not disable system protections to bypass a permission failure.

This override is login-session-only and is lost at logout or reboot. This repository does not install a persistent launch agent or modify the app bundle. An already running driver is not changed by setting the variable.

To roll back:

```sh
launchctl unsetenv CUA_DRIVER_PATH
```

Then completely quit and reopen OpenMausBot. That restores the app's default selection, provided no other override has been configured.

For background acceptance, use a disposable document in a separate target window, record the foreground application and cursor, insert a known short string, and independently read it back. Compare foreground and cursor immediately after. Stop on a background refusal; do not silently activate windows or retry with foreground input. Do not use valuable documents for the first test.
