flake := justfile_directory()

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

# Check flake validity
check:
    nix flake check '{{ flake }}'

# Run nvfetcher to update sources
fetch:
    nvfetcher -o '{{ flake }}/_sources'

# Format nix files
fmt:
    nix run nixpkgs#nixfmt-tree -- '{{ flake }}'
