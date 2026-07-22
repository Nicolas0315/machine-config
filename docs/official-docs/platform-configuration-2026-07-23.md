# Platform configuration evidence

- Retrieved: 2026-07-23 JST
- Next refresh: 2026-10-23
- Local Windows Package Manager: `v1.29.280`
- Local Git: `2.54.0.windows.1`
- Local Nix: unavailable on the Windows host and its current WSL distribution

## Sources

- WinGet Configuration: https://learn.microsoft.com/windows/package-manager/configuration/
- WinGet export/import format: https://learn.microsoft.com/windows/package-manager/winget/export
- Nix flakes: https://nix.dev/concepts/flakes.html
- nix-darwin: https://github.com/nix-darwin/nix-darwin

## Decision

- Use the WinGet JSON import format for a small, curated native Windows package set.
- Keep Windows user settings in a plan-first PowerShell script with an explicit `-Apply` gate.
- Export reusable Home Manager and nix-darwin modules from an input-free flake. The private consuming flake owns pinned `nixpkgs`, Home Manager, nix-darwin, and repository revisions.
- Pin GitHub Actions to immutable commit SHAs.

## Verification

```powershell
pwsh -NoProfile -File scripts/Test-Config.ps1
pwsh -NoProfile -File scripts/Apply-Windows.ps1 -SkipPackages
```

```bash
nix flake check --no-build
```

The PowerShell checks were run locally. Nix evaluation is delegated to the pinned Linux CI job because Nix is not installed on the current Windows/WSL host.

## Risk and rollback

- `Apply-Windows.ps1` defaults to plan-only behavior. Machine mutation requires `-Apply`.
- Before registry changes, it stores the previous values under `%LOCALAPPDATA%\machine-config\backups`, retains the newest 10 backups, and prunes older backups in the same run.
- Restore registry and global Git settings with `Restore-WindowsSettings.ps1 -BackupPath <timestamp-directory>`.
- Package installation is additive. Remove an unwanted package explicitly with WinGet; this repository does not automate package removal.
- Nix consumers roll back by reverting the repository revision or selecting a previous Nix generation.
