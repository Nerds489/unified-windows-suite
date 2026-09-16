# Changelog

All notable changes to Unified Windows Suite are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2026-09-16

The unified release. Merges Win11Debloat (Raphire, MIT) and Ultimate Windows
Setup Toolkit (OffTrackMedia, MIT) into one suite.

### Added

- `Unified.ps1`, a single entry point dispatching to both halves. All arguments
  after the command pass through to `Win11Debloat.ps1`, so its 118-parameter
  surface is unchanged.
- Application installer from the Ultimate toolkit: 167 apps across 14
  categories, winget to Chocolatey to Scoop cascade, 5 bundles.
- Hardware profiler: CPU, RAM slots, storage media type, GPU, network, power,
  plus a 100-point performance tier score and generated recommendations.
- Driver manager: inventory, problem-device decoding across 42 error codes,
  Windows Update driver search and install, DISM export backup, `pnputil`
  restore.
- Performance optimiser: power plans, memory management, virtual memory, disk
  cleanup, startup programs, DNS presets.
- `Config/InstallCatalog.json`, `Config/Services.json`, `Config/Profiles.json`
  carried over from the Ultimate toolkit's `configs/`.
- `.\Unified.ps1 status`, a read-only licence state report.

### Fixed

- **`DisableSearchHistory` and `DisableSearchHighlights` now work.** Both were
  declared as parameters in `Win11Debloat.ps1` and `Scripts/Get.ps1`, and both
  had `.reg` files, but neither had a `Features.json` entry. Using either
  printed "Unknown feature could not be applied" and incremented the failure
  counter. Added to `Features.json` and to the en-US language file; all four
  `.reg` files were already present in `Regfiles/`, `Regfiles/Sysprep/` and
  `Regfiles/Undo/`, so the feature-parameter contract test passes.
- Ported modules resolve `CommonFunctions.psm1` through `$PSScriptRoot` rather
  than a `$ModulePath` variable that no longer exists at that depth.
- `SystemScanner.psm1` now imports `CommonFunctions.psm1` explicitly. It
  previously relied on a `-Global` import from the old entry point, which made
  it unusable standalone.
- The app catalogue lookup points at `Config/InstallCatalog.json` rather than
  the removed `configs/apps.json`.
- Corrected the app count in `docs/APP_LIST.md`. The catalogue holds 167 apps;
  the documentation claimed "200+" and the statistics table claimed "170+".

### Changed

- Win11Debloat is the architectural base. Its declarative `Features.json`
  catalogue drives the CLI surface, the GUI, undo, backups and build gating from
  one file, and it ships 40 Pester files with CI.
- The Ultimate toolkit's subsystems fold in as new `Scripts/` domains:
  `AppInstall/`, `Diagnostics/`, `Drivers/`, `Optimize/`, `Core/`.
- Feature count 103 to 105.

### Removed

- **All product-activation functionality.** `modules/Activator.psm1`, the
  duplicate activation implementation inside `DebloatActivateMenu.ps1`, the
  `Activate` value of `-Action`, `Invoke-FullDebloatAndActivate`, and every
  documentation reference. Not reimplemented under another name. See NOTICE.
- The Ultimate toolkit's menu layer (`Start-Toolkit.ps1`, `menus/*.ps1`). Its
  capabilities are reachable through `Unified.ps1` and the Win11Debloat GUI.
- `menus/MainMenu.ps1`, which was orphaned dead code: `Start-Toolkit.ps1`
  defined its own `Start-MainMenu` and never dot-sourced it.

### Known issues carried from the Ultimate toolkit

These are documented rather than silently inherited. See `docs/MERGE-NOTES.md`.

- `Invoke-WithDryRunCheck`, `Start-OperationTracking` and `Invoke-Rollback` in
  `CommonFunctions.psm1` have no call sites. The optimiser and driver modules
  do not honour a dry-run flag. Use `-WhatIf` on the tweak engine, which does.
- `Backup-RegistryKey` is never called by any ported module.
- The optimiser writes several keys as side effects of unrelated menu items
  rather than as declared, undoable features.
- `Config/Services.json` defines a `CriticalServices` never-touch list that no
  code path consults.

## Prior history

Win11Debloat: https://github.com/Raphire/Win11Debloat/releases
Ultimate Windows Setup Toolkit: v4.0.0, 2025-01-01.
