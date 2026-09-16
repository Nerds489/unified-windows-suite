<p align="center">
  <img src="https://img.shields.io/badge/Version-4.0.0-blue?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/PowerShell-5.1-orange?style=for-the-badge" alt="PowerShell"/>
  <img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-purple?style=for-the-badge" alt="Platform"/>
</p>

<h1 align="center">Unified Windows Suite</h1>

<p align="center">
  <strong>Set up, strip down, and tune a Windows box from one place</strong><br/>
  <em>The Windows counterpart to <a href="https://github.com/Nerds489/ultimate-linux-suite">Unified Linux Suite</a></em>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#features">Features</a> •
  <a href="#commands">Commands</a> •
  <a href="#project-structure">Structure</a> •
  <a href="#what-this-does-not-do">Scope</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## What is This?

**Unified Windows Suite** is the merger of two projects:

- **Win11Debloat** (Raphire): a declarative tweak and app-removal engine with a
  WPF interface, 249 registry files, per-feature undo, structured backups and a
  Pester suite.
- **Ultimate Windows Setup Toolkit** (OffTrackMedia): an application installer,
  hardware profiler, driver manager and performance optimiser.

Neither covered the whole job. Win11Debloat only ever *removes*; the Ultimate
toolkit could install and tune but had no undo that worked. Together they cover
a machine from first boot to tuned.

---

## What's New in v4.0.0

### The Unified Release

| Component | Origin | What it does |
|---|---|---|
| **Tweak engine** | Win11Debloat | 105 features, each with apply, undo and build gating |
| **Registry library** | Win11Debloat | 249 `.reg` files: 91 apply, 65 undo, 91 sysprep, 2 sysprep-undo |
| **App removal** | Win11Debloat | 141-app catalogue, appx + winget, provisioned-package removal |
| **Graphical interface** | Win11Debloat | 9 XAML windows, automatic light/dark theming |
| **Backup & restore** | Win11Debloat | Per-feature registry snapshots with an allow-list validator |
| **Sysprep targeting** | Win11Debloat | Offline `NTUSER.DAT` mounting for the default profile |
| **App installer** | Ultimate | 167 apps / 14 categories, winget → Chocolatey → Scoop cascade |
| **Hardware profiler** | Ultimate | CPU, RAM, storage, GPU, network, power; 100-point tier score |
| **Driver manager** | Ultimate | Inventory, problem devices, DISM export, `pnputil` restore |
| **Performance optimiser** | Ultimate | Power plans, memory, pagefile, disk cleanup, startup, DNS |

### New entry point

```powershell
.\Unified.ps1            # interactive menu
.\Win11Debloat.ps1       # the tweak engine directly; every switch still works
```

---

## Quick Start

```powershell
# Clone
git clone https://github.com/Nerds489/unified-windows-suite.git
cd unified-windows-suite

# Interactive
powershell.exe -ExecutionPolicy Bypass -File .\Unified.ps1

# Or go straight at it
.\Unified.ps1 tweaks                      # graphical tweak + debloat
.\Unified.ps1 tweaks -CLI                 # text mode
.\Unified.ps1 scan                        # hardware report, read-only, no admin
.\Unified.ps1 install                     # application installer
.\Unified.ps1 drivers                     # driver manager
.\Unified.ps1 optimise                    # performance optimiser
```

`Run.bat` double-clicks into the same place.

**Try before you commit:** every tweak path honours `-WhatIf`.

```powershell
.\Unified.ps1 tweaks -CLI -DisableTelemetry -DisableCopilot -WhatIf
```

---

## Features

### Tweaks and debloat

| Area | Coverage |
|---|---|
| **Privacy** | Telemetry, ad ID, activity history, suggested content, feedback, location, Find My Device |
| **AI** | Copilot, Recall, Click to Do, Paint AI, Notepad AI, Edge AI, AI Fabric service |
| **Taskbar** | Alignment, search box modes, Task View, widgets, chat, button combining, multi-monitor |
| **File Explorer** | Extensions, hidden files, launch target, Home/Gallery/OneDrive, drive letters, context menu |
| **Start & search** | Recommended panel, All Apps view, Phone Link, Bing, search history, search highlights |
| **Windows Update** | Continuous innovation, auto-reboot, delivery optimisation, device metadata |
| **System** | Fast startup, storage sense, modern standby networking, mouse acceleration, sticky keys |
| **Apps** | 141-app catalogue with safe/optional/unsafe ratings, OEM presets for HP, Dell, Lenovo, LG |

### Setup and tuning

| Area | Coverage |
|---|---|
| **Install** | 167 apps, 14 categories, 5 bundles (Minimal, Standard, Developer, Gamer, Creative) |
| **Scan** | CPU, RAM slots, storage media type, GPU VRAM, network, battery; tier score and advice |
| **Drivers** | Inventory, 42-code problem-device decoding, Windows Update drivers, full DISM backup |
| **Optimise** | Power plans, memory management, pagefile, disk cleanup, startup, DNS presets |

### Safety

Every change is a named feature with a declared undo path, a build gate, and a
registry snapshot taken before it runs.

- **`-WhatIf`** on every mutation
- **Registry snapshots** scoped to exactly the keys a run will touch, validated
  against an allow-list on restore so a hand-edited backup cannot write arbitrary keys
- **65 undo files** plus per-feature custom undo
- **System restore point** with `-CreateRestorePoint`
- **Cancellation** honoured between every step

---

## Commands

```
.\Unified.ps1 <command> [args...]

  menu       Interactive menu (default)
  tweaks     Tweak, debloat and app removal; passes all args to Win11Debloat.ps1
  debloat    Alias of tweaks
  install    Application installer
  scan       Hardware profile and recommendations (read-only)
  drivers    Driver manager
  optimise   Performance optimiser
  status     Licence status (read-only)
  version    Print version
```

Anything after the command goes straight through, so the full Win11Debloat
parameter surface is intact:

```powershell
.\Unified.ps1 tweaks -RunDefaults -CreateRestorePoint
.\Unified.ps1 tweaks -Sysprep -DisableTelemetry        # default user profile
.\Unified.ps1 tweaks -User alice -DisableCopilot       # another local profile
.\Unified.ps1 tweaks -Config .\my-config.json
```

---

## Project Structure

```
unified-windows-suite/
├── Unified.ps1              # unified entry point
├── Win11Debloat.ps1         # tweak engine (118 parameters)
├── Run.bat                  # double-click launcher
├── VERSION  LICENSE  NOTICE
│
├── Config/
│   ├── Features.json        # 105 features: apply, undo, category, build gate
│   ├── Apps.json            # 141-app removal catalogue
│   ├── InstallCatalog.json  # 167-app install catalogue
│   ├── Services.json        # service profiles
│   ├── Profiles.json        # hardware performance tiers
│   ├── DefaultSettings.json
│   └── Languages/en-US/     # Chrome, Features, Categories
│
├── Regfiles/                # 91 apply
│   ├── Undo/                # 65 undo
│   └── Sysprep/             # 91 default-profile + Undo/
│
├── Schemas/                 # 9 XAML windows
│
├── Scripts/
│   ├── Core/                # CommonFunctions
│   ├── Features/            # orchestrator, backup, restore, telemetry
│   ├── AppRemoval/          # appx + winget removal engine
│   ├── AppInstall/          # winget / Chocolatey / Scoop
│   ├── Diagnostics/         # hardware profiler
│   ├── Drivers/             # driver manager
│   ├── Optimize/            # performance optimiser
│   ├── Helpers/             # registry, user hive, SID resolution
│   ├── FileIO/  Threading/  CLI/  GUI/
│
├── Assets/  Tests/          # 40 Pester files
└── .github/workflows/       # Pester on windows-latest
```

---

## Requirements

| | |
|---|---|
| **OS** | Windows 10 1809+ or Windows 11. Sysprep mode is Windows 11 only |
| **Shell** | Windows PowerShell **5.1**. PowerShell 7 is refused: Appx removal fails with `0x80131539` |
| **Rights** | Administrator for anything that writes. `scan` is read-only and does not need it |
| **Optional** | winget for some app removals and all installs; Chocolatey and Scoop as install fallbacks |

---

## What This Does Not Do

**There is no product activation, licence bypass or key generation in this
suite, and none will be added.**

The Ultimate Windows Setup Toolkit shipped an `Activator.psm1` that downloaded
and ran a third-party activation script, plus a second copy of the same logic in
its debloat menu. Neither was carried across.

Use a licence you own. `.\Unified.ps1 status` reads your activation state and
changes nothing.

---

## Contributing

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

Every new capability lands as a `Features.json` row with an apply path, an undo
path (or an explicit note that it cannot be undone), a build gate where the key
is version-specific, and a Pester test. Nothing writes to the registry outside
`Invoke-FeatureApply`.

```powershell
.\Scripts\Run-Tests.ps1 -Bootstrap
```

---

## Credits

Built on [Win11Debloat](https://github.com/Raphire/Win11Debloat) by Raphire, MIT.
The tweak engine, registry library, GUI, backup system and test suite are theirs.

See [NOTICE](NOTICE) for the full attribution split.

---

## Licence

MIT. See [LICENSE](LICENSE).

Changes here are applied to *your* machine at *your* direction. Read what a
feature does before you run it, keep the restore point, and keep the backup.
