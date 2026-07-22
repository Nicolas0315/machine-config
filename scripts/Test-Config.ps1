[CmdletBinding(PositionalBinding = $false)]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($script in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1') {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    foreach ($parseError in $errors) {
        $failures.Add("$($script.FullName): $($parseError.Message)")
    }
}

$packagesPath = Join-Path $repoRoot 'windows\packages.json'
$packages = Get-Content -Raw -LiteralPath $packagesPath | ConvertFrom-Json
if ($packages.'$schema' -ne 'https://aka.ms/winget-packages.schema.2.0.json') {
    $failures.Add('windows/packages.json uses an unexpected schema')
}
if ($packages.Sources.Count -ne 1 -or $packages.Sources[0].Packages.Count -lt 1) {
    $failures.Add('windows/packages.json must contain at least one package in one source')
}

$identifiers = @($packages.Sources[0].Packages.PackageIdentifier)
$duplicates = $identifiers | Group-Object | Where-Object Count -gt 1
foreach ($duplicate in $duplicates) {
    $failures.Add("Duplicate WinGet package: $($duplicate.Name)")
}

$settings = Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'windows\settings.psd1')
if ($settings.Registry.Count -lt 1) {
    $failures.Add('windows/settings.psd1 must contain at least one registry setting')
}

$trackedText = git -C $repoRoot grep -I -n -E '(100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|gh[opusr]_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,})' -- . 2>$null
if ($LASTEXITCODE -eq 0 -and $trackedText) {
    $failures.Add("Potential secret or private network address detected:`n$trackedText")
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "OK: $($identifiers.Count) WinGet packages, $($settings.Registry.Count) registry settings, PowerShell syntax valid"
