flake := justfile_directory()

# jj's working copy is always "dirty" from git's perspective; silence the noisy
# Nix warning so flake commands don't spam it on every invocation.
export NIX_CONFIG := "warn-dirty = false"

# List available commands
default:
    @just --list

# ── System (nixos-rebuild / darwin-rebuild) ──────────────────────

# Apply macOS system configuration (nix-darwin)
system-darwin:
    sudo darwin-rebuild switch --flake '{{ flake }}#MacOS'

# Apply NixOS system configuration
system-nixos:
    sudo nixos-rebuild switch --flake '{{ flake }}#NixOS'

# Apply WSL system configuration
system-wsl:
    sudo nixos-rebuild switch --flake '{{ flake }}#WSL'

# ── Home (home-manager) ─────────────────────────────────────────

# Apply macOS home-manager configuration
home-mac:
    home-manager switch --flake '{{ flake }}#MacHome'

# Apply Linux home-manager configuration
home-linux:
    home-manager switch --flake '{{ flake }}#NixHome'

# ── Maintenance ──────────────────────────────────────────────────

# Update all flake inputs
update:
    nix flake update --flake '{{ flake }}'

# Update a specific flake input
update-input input:
    nix flake update {{ input }} --flake '{{ flake }}'

# Update every flake input except `private`, which lives on sr.ht and is
# unreachable from CI. The input list is derived from flake.lock so it needs no
# maintenance; used by the weekly update workflow.
update-public:
    #!/usr/bin/env sh
    inputs=$(nix eval --impure --raw --expr 'let l = builtins.fromJSON (builtins.readFile {{ flake }}/flake.lock); in builtins.concatStringsSep " " (builtins.filter (x: x != "private") (builtins.attrNames l.nodes.root.inputs))')
    nix flake update $inputs --flake '{{ flake }}'

# Check flake validity
check:
    nix flake check '{{ flake }}'

# Run nvfetcher to update sources
fetch:
    nvfetcher -o '{{ flake }}/_sources'

# Format nix files
fmt:
    nix run nixpkgs#nixfmt-tree -- '{{ flake }}'

# ── Remotes ──────────────────────────────────────────────────────

# Push master to sr.ht (origin) and the GitHub CI mirror, which triggers the
# build workflow. Add the mirror once with:
#   jj git remote add github git@github.com:lambdair/nix-configs.git
push:
    jj git push -b master
    jj git push -b master --remote github --allow-new

# ── Cache ────────────────────────────────────────────────────────

# Push home-manager closure to personal Cachix cache (macOS)
cache-push-mac:
    nix build '{{ flake }}#homeConfigurations.MacHome.activationPackage' --no-link --print-out-paths | nix run nixpkgs#cachix -- push lambdair

# Push home-manager closure to personal Cachix cache (Linux)
cache-push-linux:
    nix build '{{ flake }}#homeConfigurations.NixHome.activationPackage' --no-link --print-out-paths | nix run nixpkgs#cachix -- push lambdair
