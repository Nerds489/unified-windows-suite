#Requires -Version 5.1
<#
.SYNOPSIS
    Unified Windows Suite - single entry point.

.DESCRIPTION
    Dispatches to the two halves of the suite:

      tweaks / debloat / apps   ->  Win11Debloat.ps1 (GUI or CLI)
      install                   ->  Scripts/AppInstall
      scan                      ->  Scripts/Diagnostics
      drivers                   ->  Scripts/Drivers
      optimise                  ->  Scripts/Optimize

    Run with no arguments for the interactive menu. Any arguments after the
    command are passed straight through, so every Win11Debloat.ps1 switch keeps
    working:

      .\Unified.ps1 tweaks -RunDefaults -CreateRestorePoint
      .\Unified.ps1 tweaks -CLI -DisableTelemetry -WhatIf

    This suite contains no product-activation functionality. See NOTICE.

.NOTES
    Windows PowerShell 5.1 only. PowerShell 7 breaks Appx removal (0x80131539),
    so the guard below refuses to run under it.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('menu', 'tweaks', 'debloat', 'install', 'scan', 'drivers', 'optimise', 'optimize', 'status', 'version')]
    [string]$Command = 'menu',

    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$Rest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Root    = $PSScriptRoot
$script:Version = (Get-Content (Join-Path $Root 'VERSION') -Raw).Trim()

# --- Guards ------------------------------------------------------------------
# Inherited from Win11Debloat: the Appx cmdlets and Get-ComputerRestorePoint
# fail under pwsh 7. Refuse rather than half-work.
if ($PSVersionTable.PSEdition -eq 'Core') {
    Write-Host ''
    Write-Host '  Unified Windows Suite requires Windows PowerShell 5.1.' -ForegroundColor Red
    Write-Host '  PowerShell 7 cannot remove Appx packages (0x80131539).' -ForegroundColor Red
    Write-Host ''
    Write-Host '  Start it with:  powershell.exe -ExecutionPolicy Bypass -File .\Unified.ps1' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

function Test-IsAdministrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Administrator {
    if (Test-IsAdministrator) { return }
    Write-Host ''
    Write-Host '  Administrator rights are required for this command.' -ForegroundColor Yellow
    $answer = Read-Host '  Restart elevated? (y/n)'
    if ($answer -notmatch '^[Yy]') { exit 1 }

    $argv = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, $Command)
    if ($Rest) { $argv += $Rest }
    Start-Process powershell.exe -ArgumentList $argv -Verb RunAs | Out-Null
    exit 0
}

function Import-SuiteModule {
    param([Parameter(Mandatory)][string]$RelativePath)
    $full = Join-Path $Root $RelativePath
    if (-not (Test-Path $full)) { throw "Module not found: $RelativePath" }
    Import-Module $full -Force -Global
}

function Invoke-Win11Debloat {
    param([object[]]$Arguments)
    $entry = Join-Path $Root 'Win11Debloat.ps1'
    if (-not (Test-Path $entry)) { throw 'Win11Debloat.ps1 is missing from the suite root.' }
    if ($Arguments) { & $entry @Arguments } else { & $entry }
}

function Show-SuiteBanner {
    Write-Host ''
    Write-Host '  UNIFIED WINDOWS SUITE' -ForegroundColor Cyan
    Write-Host "  v$script:Version  |  Windows 10 & 11" -ForegroundColor DarkGray
    Write-Host ''
}

function Show-SuiteMenu {
    while ($true) {
        Clear-Host
        Show-SuiteBanner
        Write-Host '   [1]  Tweaks, debloat & app removal   (graphical)' -ForegroundColor White
        Write-Host '   [2]  Tweaks, debloat & app removal   (command line)' -ForegroundColor White
        Write-Host '   [3]  Install applications' -ForegroundColor White
        Write-Host '   [4]  Scan hardware & report' -ForegroundColor White
        Write-Host '   [5]  Driver manager' -ForegroundColor White
        Write-Host '   [6]  Performance optimiser' -ForegroundColor White
        Write-Host '   [7]  Licence status (read-only)' -ForegroundColor White
        Write-Host ''
        Write-Host '   [Q]  Quit' -ForegroundColor DarkGray
        Write-Host ''
        Write-Host '  Select: ' -NoNewline -ForegroundColor White
        switch ((Read-Host).ToUpper()) {
            '1' { Invoke-Win11Debloat @(); return }
            '2' { Invoke-Win11Debloat @('-CLI'); return }
            '3' { Invoke-SuiteInstall;   Read-Host '  Press Enter' | Out-Null }
            '4' { Invoke-SuiteScan;      Read-Host '  Press Enter' | Out-Null }
            '5' { Invoke-SuiteDrivers;   Read-Host '  Press Enter' | Out-Null }
            '6' { Invoke-SuiteOptimise;  Read-Host '  Press Enter' | Out-Null }
            '7' { Show-LicenceStatus;    Read-Host '  Press Enter' | Out-Null }
            'Q' { return }
            default { }
        }
    }
}

function Invoke-SuiteInstall {
    Assert-Administrator
    Import-SuiteModule 'Scripts\Core\CommonFunctions.psm1'
    Import-SuiteModule 'Scripts\AppInstall\AppInstaller.psm1'
    Initialize-Toolkit | Out-Null
    Show-PackageManagerStatus
}

function Invoke-SuiteScan {
    # Read-only. No elevation required.
    Import-SuiteModule 'Scripts\Core\CommonFunctions.psm1'
    Import-SuiteModule 'Scripts\Diagnostics\SystemScanner.psm1'
    Initialize-Toolkit | Out-Null
    $profileData = Get-SystemProfile
    Show-PerformanceTierSummary -Profile $profileData
    Show-Recommendations -Profile $profileData
}

function Invoke-SuiteDrivers {
    Assert-Administrator
    Import-SuiteModule 'Scripts\Core\CommonFunctions.psm1'
    Import-SuiteModule 'Scripts\Drivers\DriverUpdater.psm1'
    Initialize-Toolkit | Out-Null
    Show-DriverMenu | Out-Null
}

function Invoke-SuiteOptimise {
    Assert-Administrator
    Import-SuiteModule 'Scripts\Core\CommonFunctions.psm1'
    Import-SuiteModule 'Scripts\Optimize\SystemOptimizer.psm1'
    Initialize-Toolkit | Out-Null
    $p = Get-OptimizationProfile
    Write-Host ''
    Write-Host "  Detected profile: $($p.Name)" -ForegroundColor Cyan
    Write-Host "  $($p.Description)" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Optimisation writes to the registry and changes services.' -ForegroundColor Yellow
    Write-Host '  A restore point is created first.' -ForegroundColor Yellow
    Write-Host ''
    if ((Read-Host '  Continue? (y/n)') -notmatch '^[Yy]') { return }
    Invoke-SystemOptimization -CreateRestorePoint | Out-Null
}

function Show-LicenceStatus {
    # Read-only WMI query. Reports what Windows already reports in Settings.
    Write-Host ''
    Write-Host '  LICENCE STATUS' -ForegroundColor Cyan
    Write-Host ''
    try {
        $lic = Get-CimInstance -ClassName SoftwareLicensingProduct |
               Where-Object { $_.PartialProductKey -and $_.Name -like '*Windows*' } |
               Select-Object -First 1
        if (-not $lic) { Write-Host '  No licensed Windows product found.' -ForegroundColor Yellow; return }
        $text = switch ($lic.LicenseStatus) {
            0 { 'Unlicensed' }            1 { 'Licensed (activated)' }
            2 { 'Out-of-box grace' }      3 { 'Out-of-tolerance grace' }
            4 { 'Non-genuine grace' }     5 { 'Notification' }
            6 { 'Extended grace' }        default { 'Unknown' }
        }
        $colour = if ($lic.LicenseStatus -eq 1) { 'Green' } else { 'Yellow' }
        Write-Host "  Product : $($lic.Name)" -ForegroundColor Gray
        Write-Host "  Status  : $text" -ForegroundColor $colour
        Write-Host ''
        if ($lic.LicenseStatus -ne 1) {
            Write-Host '  To activate, use a licence you own:' -ForegroundColor Gray
            Write-Host '    Settings > System > Activation' -ForegroundColor DarkGray
            Write-Host '  A retail licence can be moved to new hardware through the' -ForegroundColor DarkGray
            Write-Host '  Microsoft account it is linked to.' -ForegroundColor DarkGray
            Write-Host ''
        }
    }
    catch {
        Write-Host "  Could not read licence status: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Dispatch ----------------------------------------------------------------
switch ($Command) {
    'version'  { Show-SuiteBanner }
    'menu'     { Show-SuiteMenu }
    'tweaks'   { Invoke-Win11Debloat $Rest }
    'debloat'  { Invoke-Win11Debloat $Rest }
    'install'  { Invoke-SuiteInstall }
    'scan'     { Invoke-SuiteScan }
    'drivers'  { Invoke-SuiteDrivers }
    'optimise' { Invoke-SuiteOptimise }
    'optimize' { Invoke-SuiteOptimise }
    'status'   { Show-LicenceStatus }
}
