{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Interpolating outPath makes every package build before the generator runs,
  # which is what lets it read their bin/ directories.
  packagesJson = pkgs.writeText "tool-packages.json" (
    builtins.toJSON (
      map (p: {
        path = p.outPath;
        name = lib.getName p;
        desc = p.meta.description or "";
        main = p.meta.mainProgram or "";
      }) config.home.packages
    )
  );

  aliasesJson = pkgs.writeText "tool-aliases.json" (
    builtins.toJSON config.programs.nushell.shellAliases
  );

  toolCatalog = pkgs.runCommand "tool-catalog" { } ''
    export HOME="$TMPDIR"
    mkdir -p "$out"
    ${lib.getExe pkgs.nushell} --no-config-file ${./tools-catalog.nu} \
      ${packagesJson} ${aliasesJson} "$out"
  '';
in
{
  # catppuccin feeds a theme into programs.television.settings, so home-manager
  # owns config.toml. television writes its own copy there on first run, which
  # activation would otherwise refuse to replace.
  xdg.configFile."television/config.toml".force = true;

  programs.television.enable = true;
}
