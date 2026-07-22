[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$Apply,
    [switch]$SkipPackages
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$settingsPath = Join-Path $repoRoot 'windows\settings.psd1'
$packagesPath = Join-Path $repoRoot 'windows\packages.json'
$settings = Import-PowerShellDataFile -LiteralPath $settingsPath

function Find-GitCommand {
    $command = Get-Command git -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $standardPath = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
    if (Test-Path -LiteralPath $standardPath) {
        return $standardPath
    }

    return $null
}

Write-Host "Mode: $(if ($Apply) { 'APPLY' } else { 'PLAN' })"

foreach ($entry in $settings.Registry) {
    try {
        $current = Get-ItemPropertyValue -LiteralPath $entry.Path -Name $entry.Name -ErrorAction Stop
    }
    catch {
        $current = $null
    }
    Write-Host ("Registry: {0} {1} -> {2} ({3})" -f $entry.Path, $entry.Name, $entry.Value, $entry.Description)
    Write-Host ("  Current: {0}" -f $(if ($null -eq $current) { '<missing>' } else { $current }))
}

$gitCommand = Find-GitCommand
foreach ($name in $settings.Git.Keys | Sort-Object) {
    $current = if ($gitCommand) { & $gitCommand config --global --get $name 2>$null } else { $null }
    Write-Host ("Git: {0} {1} -> {2}" -f $name, $(if ($current) { $current } else { '<missing>' }), $settings.Git[$name])
}

if (-not $SkipPackages) {
    $packageCount = (Get-Content -Raw -LiteralPath $packagesPath | ConvertFrom-Json).Sources[0].Packages.Count
    Write-Host "WinGet packages: $packageCount entries from $packagesPath"
}

if (-not $Apply) {
    Write-Host 'Plan complete. Re-run with -Apply to change this machine.'
    return
}

$localAppDataRoot = [System.IO.Path]::GetFullPath($env:LOCALAPPDATA)
$backupRoot = [System.IO.Path]::GetFullPath((Join-Path $localAppDataRoot 'machine-config\backups'))
$localAppDataPrefix = $localAppDataRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if (-not $backupRoot.StartsWith($localAppDataPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe backup root: $backupRoot"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $backupRoot $timestamp
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$registrySnapshot = foreach ($entry in $settings.Registry) {
    $exists = $true
    try {
        $registryKey = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
        $value = $registryKey.GetValue($entry.Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $valueType = $registryKey.GetValueKind($entry.Name).ToString()
        if ($null -eq $value) {
            throw "Registry value not found: $($entry.Path) $($entry.Name)"
        }
    }
    catch {
        $exists = $false
        $value = $null
        $valueType = $null
    }

    [pscustomobject]@{
        Path = $entry.Path
        Name = $entry.Name
        Type = $valueType
        Existed = $exists
        Value = $value
    }
}
$registrySnapshot | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backupDir 'registry.json') -Encoding utf8

$gitSnapshot = foreach ($name in $settings.Git.Keys) {
    $value = if ($gitCommand) { & $gitCommand config --global --get $name 2>$null } else { $null }
    [pscustomobject]@{
        Name = $name
        Existed = [bool]$value
        Value = $value
    }
}
$gitSnapshot | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backupDir 'git.json') -Encoding utf8

Get-ChildItem -LiteralPath $backupRoot -Directory |
    Sort-Object Name -Descending |
    Select-Object -Skip 10 |
    Where-Object { $_.FullName.StartsWith($backupRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) } |
    Remove-Item -Recurse -Force

if (-not $SkipPackages) {
    winget import --import-file $packagesPath --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget import failed with exit code $LASTEXITCODE"
    }
}

foreach ($entry in $settings.Registry) {
    if (-not (Test-Path -LiteralPath $entry.Path)) {
        New-Item -Path $entry.Path -Force | Out-Null
    }
    New-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -PropertyType $entry.Type -Value $entry.Value -Force | Out-Null
}

$gitCommand = Find-GitCommand
if (-not $gitCommand) {
    throw 'Git was not found after package installation. Start a new shell and re-run this script.'
}

foreach ($name in $settings.Git.Keys) {
    & $gitCommand config --global $name $settings.Git[$name]
    if ($LASTEXITCODE -ne 0) {
        throw "git config failed for $name with exit code $LASTEXITCODE"
    }
}

Write-Host "Applied. Registry and Git backup: $backupDir"
