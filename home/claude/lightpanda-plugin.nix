# The official Lightpanda plugin — its skill plus the MCP server declaration —
# repointed onto the binary from pkgs/, with the install script and its
# instructions dropped. --replace-fail so an upstream rewording fails the build
# rather than leaving install advice in the skill.
{ pkgs, sources }:

let
  inherit (pkgs) lib;
  inherit (import ../../pkgs { inherit pkgs sources; }) lightpanda;

  # Everything the install section says about fetching a binary, verbatim.
  installSection = ''
    Check first whether Lightpanda is already installed (`command -v lightpanda`) before running the installer below.

    - **Claude Code:**
      ```bash
      bash ''${CLAUDE_SKILL_DIR}/scripts/install.sh
      ```
      `''${CLAUDE_SKILL_DIR}` is a Claude Code substitution that resolves to this skill's own directory regardless of the shell's current working directory — needed because when this skill runs as a plugin, the shell's cwd is your project, not the skill's install location.
    - **Any other agent runtime** (Cursor, Codex CLI, Gemini CLI, etc.): this substitution isn't supported. `scripts/install.sh` is bundled directly next to this file — locate it there and run it with that path instead, e.g. `bash /path/to/this/skill/scripts/install.sh`.'';
in
pkgs.runCommand "lightpanda-plugin" { inherit installSection; } ''
  cp -r ${sources.lightpanda-skill.src} $out
  chmod -R u+w $out
  rm -r $out/scripts

  # Upstream leaves the MCP command to PATH; the store path pins it wherever
  # the server is started from.
  substituteInPlace $out/.claude-plugin/marketplace.json \
    --replace-fail '"command": "lightpanda"' '"command": "${lib.getExe lightpanda}"'

  substituteInPlace $out/SKILL.md \
    --replace-fail "$installSection" 'Nothing to install: nix-configs puts the binary on PATH.' \
    --replace-fail 'Installs its own binary via scripts/install.sh — not run automatically by the plugin installer, so run it once before first use.' 'The binary comes from nix-configs.' \
    --replace-fail 'allowed-tools: Bash(bash ''${CLAUDE_SKILL_DIR}/scripts/install.sh), Bash(command -v lightpanda), Bash(lightpanda *)' 'allowed-tools: Bash(command -v lightpanda), Bash(lightpanda *)' \
    --replace-fail 'Unlike `scripts/install.sh`, which always tracks the latest nightly, these pin to a stable release unless you explicitly opt into a nightly variant.' 'These pin to a stable release unless you explicitly opt into a nightly variant.' \
    --replace-fail 'The binary is a nightly build that evolves quickly. If you encounter crashes or issues, run the install command above again to update to the latest version (max once per day).' 'The binary is pinned in nix-configs; update it there with `just fetch` rather than downloading a build.' \
    --replace-fail '- `scripts/install.sh` — Install Lightpanda binary' '- (none: nix-configs installs the binary)'

  substituteInPlace $out/README.md \
    --replace-fail 'bash scripts/install.sh' '# Nothing to install: lightpanda is already on PATH.'
''
