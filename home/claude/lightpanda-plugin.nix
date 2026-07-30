# The official Lightpanda plugin — its skill plus the MCP server declaration —
# repointed from upstream's ~/.local/bin nightly onto the binary from pkgs/, with
# the install script and its instructions dropped. --replace-fail so an upstream
# rewording fails the build rather than leaving ~/.local/bin advice in the skill.
{ pkgs, sources }:

let
  inherit (pkgs) lib;
  inherit (import ../../pkgs { inherit pkgs sources; }) lightpanda;
in
pkgs.runCommand "lightpanda-plugin" { } ''
  cp -r ${sources.lightpanda-skill.src} $out
  chmod -R u+w $out
  rm -r $out/scripts

  substituteInPlace $out/SKILL.md $out/README.md $out/.claude-plugin/marketplace.json \
    --replace-fail '$HOME/.local/bin/lightpanda' '${lib.getExe lightpanda}'

  substituteInPlace $out/SKILL.md $out/README.md \
    --replace-fail 'bash scripts/install.sh' '# Nothing to install: lightpanda is already on PATH.'

  substituteInPlace $out/SKILL.md \
    --replace-fail 'The binary is a nightly build that evolves quickly. If you encounter crashes or issues, run `scripts/install.sh` again to update to the latest version (max once per day).' 'The binary is pinned in nix-configs; update it there with `just fetch` rather than downloading a build.' \
    --replace-fail '- `scripts/install.sh` — Install Lightpanda binary' '- (none: nix-configs installs the binary)'
''
