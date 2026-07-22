# machine-config

Windows, WSL, and macOS development environment configuration for a small personal machine fleet.

This repository uses the native declarative tool for each platform:

- Windows: WinGet package manifest plus a plan-first PowerShell settings script
- WSL/Linux: Nix and Home Manager modules
- macOS: Nix, Home Manager, and a nix-darwin module

It intentionally does not contain SSH configuration, Tailscale addresses, API keys, tokens, machine-local auth, service state, or raw inventories.

## Managed fleet profiles

- `darwin-arm64`: Apple Silicon Macs
- `wsl-x86_64`: Windows WSL development environments
- `windows-common`: native Windows developer tools and user-scoped settings

Hardware-specific drivers, GPU runtimes, creative applications, and vendor utilities remain outside the common profile.

## Windows

Preview the package and settings changes:

```powershell
pwsh -NoProfile -File .\scripts\Apply-Windows.ps1
```

Apply them explicitly:

```powershell
pwsh -NoProfile -File .\scripts\Apply-Windows.ps1 -Apply
```

Before registry settings are changed, the script writes a JSON backup under
`$env:LOCALAPPDATA\machine-config\backups`. It stores registry and global Git
settings, retains the 10 newest backups, and prunes older entries in the same run.

Restore a specific backup:

```powershell
pwsh -NoProfile -File .\scripts\Restore-WindowsSettings.ps1 `
  -BackupPath "$env:LOCALAPPDATA\machine-config\backups\<timestamp>"
```

## Nix

The input-free flake exports reusable modules instead of embedding personal usernames, home paths, or unlocked dependencies:

- `homeManagerModules.default`
- `darwinModules.default`
Consumers pin `nixpkgs`, Home Manager, nix-darwin, and this repository revision in their private host flake, then import these modules. The public module stays portable and secret-free while the consuming flake owns dependency versions.

## Validation

```powershell
pwsh -NoProfile -File .\scripts\Test-Config.ps1
```

When Nix is installed:

```bash
nix flake check --no-build
```

## Design boundary

This repository defines reproducible user tooling. The existing private operational repository remains the source for internal fleet topology and service runbooks. Secrets must be referenced from an external secret manager or environment and never committed here.
