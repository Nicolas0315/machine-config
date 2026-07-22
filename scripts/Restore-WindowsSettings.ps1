[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory)]
    [string]$BackupPath
)

$ErrorActionPreference = 'Stop'
$resolvedBackup = (Resolve-Path -LiteralPath $BackupPath).Path
$allowedRoot = [System.IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'machine-config\backups'))
$allowedPrefix = $allowedRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

if (-not $resolvedBackup.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "BackupPath must be under $allowedRoot"
}

$registryBackup = Join-Path $resolvedBackup 'registry.json'
$gitBackup = Join-Path $resolvedBackup 'git.json'
$registrySnapshot = Get-Content -Raw -LiteralPath $registryBackup | ConvertFrom-Json
foreach ($entry in $registrySnapshot) {
    if ($entry.Existed) {
        if (-not (Test-Path -LiteralPath $entry.Path)) {
            New-Item -Path $entry.Path -Force | Out-Null
        }
        New-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -PropertyType $entry.Type -Value $entry.Value -Force | Out-Null
    }
    else {
        Remove-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
    }
}

$gitCommand = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $gitCommand) {
    $standardGit = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
    if (Test-Path -LiteralPath $standardGit) {
        $gitCommand = $standardGit
    }
}
if (-not $gitCommand) {
    throw 'Git is required to restore global Git settings.'
}

$gitSnapshot = Get-Content -Raw -LiteralPath $gitBackup | ConvertFrom-Json
foreach ($entry in $gitSnapshot) {
    if ($entry.Existed) {
        & $gitCommand config --global $entry.Name $entry.Value
        if ($LASTEXITCODE -ne 0) {
            throw "git config restore failed for $($entry.Name) with exit code $LASTEXITCODE"
        }
    }
    else {
        & $gitCommand config --global --unset-all $entry.Name 2>$null
    }
}

Write-Host "Restored registry and Git settings from $resolvedBackup"
