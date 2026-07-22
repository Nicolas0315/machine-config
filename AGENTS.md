# Machine Config Agent Rules

Global baseline: `~/work/agent-context/AGENTS.MD`.

- This public repository must never contain secrets, private network addresses, credentials, auth state, or raw machine inventories.
- Keep platform configuration declarative. Apply scripts must default to plan-only behavior.
- Windows registry changes require a restorable backup. Keep the 10 newest backups and prune older ones in the same apply operation.
- Do not apply configuration to a live machine, install dependencies, or publish releases without explicit operator approval.
- Validate with `pwsh -NoProfile -File scripts/Test-Config.ps1` and, where Nix is available, `nix flake check --no-build`.
