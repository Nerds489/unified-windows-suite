# Merge notes

Why the merge went the direction it did, and what is still owed.

## Why Win11Debloat is the base

The two codebases were audited before anything was moved.

| | Win11Debloat | Ultimate toolkit |
|---|---|---|
| PowerShell | 14,466 lines | 10,872 lines |
| Tests | 40 Pester files, 452 assertions, CI | none |
| Working `-WhatIf` / `-DryRun` | yes | no, see below |
| Undo | 65 `.reg` files + per-feature custom undo | dead code |
| Registry backup | per-feature snapshots, allow-list validated on restore | dead code |
| Build gating | 64 features carry `MinVersion` / `MaxVersion` | none |
| Adding a tweak | one `Features.json` row | edit module, menu art and switch block |

One `Features.json` row produces a CLI switch, a GUI checkbox with tooltip and
category, an apply path, an undo path, a build gate, a backup plan and a state
probe. The Ultimate toolkit's menus are roughly 3,250 lines of hand-drawn box
art that cannot be generated. Rebuilding Win11Debloat into that shape would have
invalidated 40 test files to get a worse structure.

## Defects found during the audit

Recorded here so nobody assumes they were fixed.

### `-DryRun` never worked

`$Script:DryRunMode` was set in `Start-Toolkit.ps1`, a banner was printed, and
then every module called `Set-RegistryValue`, `Remove-AppxPackage` and
`Set-Service` directly. `Invoke-WithDryRunCheck` had zero call sites. A dry-run
debloat really debloated.

The tweak engine's `-WhatIf` is checked at every mutation site and does work.
The ported `Optimize/`, `Drivers/` and `AppInstall/` modules still do not honour
it. Do not trust a dry run on those paths.

### False success reporting

`Remove-BloatwareApp` wrapped both removal stages in `-ErrorAction
SilentlyContinue` and then returned `$true` unconditionally, so it printed
"Removed" for apps that were never removed. The telemetry scheduled-task loop
incremented its counter inside a `try`/`catch {}` regardless of outcome, so it
reported "Disabled 11 telemetry tasks" on a machine where all 11 failed.

Win11Debloat's equivalents collect errors with `-ErrorVariable +` and aggregate
failures into counters reported at the end. The ported modules were not
rewritten and still report optimistically.

### Telemetry key divergence

The two toolkits wrote different policy keys:

- Ultimate: `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection`
- Win11Debloat: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection`

The first takes GPO precedence. Running the Ultimate optimiser and then
Win11Debloat's undo leaves telemetry off while the interface reports it
re-enabled. The merged suite applies only Win11Debloat's tweak path, so the
divergence does not arise in normal use, but the ported optimiser can still
write the other key.

### App list contradicts itself

`Get-AggressiveBloatwareList` removed `Microsoft.WindowsStore`,
`Microsoft.SecHealthUI`, `Microsoft.Windows.Photos` and `Microsoft.ScreenSketch`
while the toolkit's own `debloat-apps.json` listed all four as protected. The
JSON was never loaded, so the module won. Superseded here by `Config/Apps.json`,
which carries a `Recommendation` of safe, optional or unsafe per app and gates
unsafe removals behind `Confirm-UnsafeAppRemoval`.

### Dead configuration

Three of the Ultimate toolkit's four config files were never read by any code
path. `services.json` defines a 30-entry `CriticalServices` never-touch list
that nothing consults, so there is no guard rail in the live service-disable
path. `settings.json` drifted from the code: it names a profile
`ExtremePerfomance` (sic) and declares a `DisableIndexing` key nothing handles.

Both were carried across as `Config/Services.json` and `Config/Profiles.json`
because they are the better-organised data. **They are still not wired up.**

## Owed work

In priority order.

1. Port the optimiser tweak by tweak into `Features.json` rows with declared
   undo paths, converting the silent side effects into explicit consent.
2. Wire `Config/Services.json` up, with a service-state backup analogous to
   `Backup-RegistryState.ps1` and the `CriticalServices` list enforced.
3. Give `AppInstall/`, `Diagnostics/`, `Drivers/` and `Optimize/` real
   `-WhatIf` support and honest failure reporting.
4. Add Pester coverage for the four ported domains. They currently have none.
5. Wire `Config/Profiles.json` into hardware-adaptive profile selection.

## Invariants

- `Regfiles/Sysprep/` must stay a complete mirror of `Regfiles/` for every
  `RegistryKey`. The contract test enforces it, and
  `Get-RegistryFilePathForFeature` switches to it for `-User` as well as
  `-Sysprep`.
- `.reg` files are UTF-16LE with BOM, except 16 that are ASCII. Preserve bytes;
  do not normalise encodings.
- `Config/Apps.json` is UTF-8 with BOM. Some readers use `-Encoding UTF8` and
  some read raw.
- Nothing writes to the registry outside `Invoke-FeatureApply`.
