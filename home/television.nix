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

  helix = lib.getExe config.programs.helix.package;

  # Enter opens the entry, so the selection output moves to alt-enter. `fork`
  # returns to the picker when helix exits, letting one search visit several
  # hits.
  editAction = action: {
    keybindings = {
      enter = "actions:edit";
      "alt-enter" = "confirm_selection";
    };
    actions.edit = {
      description = "Open the selection in helix";
      mode = "fork";
    }
    // action;
  };

  # Patching the definition television ships keeps the source and preview
  # commands owned by upstream. The config directory holds real files that
  # activation would otherwise refuse to replace.
  patchedChannel =
    name: patch:
    pkgs.runCommand "television-${name}.toml" { } ''
      ${lib.getExe pkgs.nushell} --no-config-file ${./television-channel-patch.nu} \
        ${config.programs.television.package.src}/cable/unix/${name}.toml \
        ${pkgs.writeText "television-${name}-patch.json" (builtins.toJSON patch)} \
        $out
    '';
in
{
  xdg.configFile = {
    # catppuccin feeds a theme into programs.television.settings, so
    # home-manager owns config.toml. television writes its own copy there on
    # first run, which activation would otherwise refuse to replace.
    "television/config.toml".force = true;

    # A `text` entry is the rg hit with its ANSI codes, and selections arrive
    # joined by `separator`, so the template rebuilds and quotes each one into
    # the `path:line` helix jumps to. `join:\:` restores the colon that the
    # range split drops.
    "television/cable/text.toml" = {
      source = patchedChannel "text" (editAction {
        command = "${helix} {split:\\n:..|map:{strip_ansi|split:\\::..2|join:\\:|prepend:'|append:'}|join: }";
        separator = "\n";
      });
      force = true;
    };
  };

  programs.television = {
    enable = true;

    channels.tools = {
      metadata = {
        name = "tools";
        description = "Installed packages and shell aliases";
      };

      source = {
        command = "cat ${toolCatalog}/catalog.txt";
        output = "{split: :0}";
      };

      preview.command = lib.concatStringsSep " " [
        (lib.getExe pkgs.nushell)
        "--no-config-file"
        "${./television-preview.nu}"
        "${toolCatalog}/catalog.json"
        (lib.getExe' pkgs.coreutils "timeout")
        (lib.getExe pkgs.tldr)
        "'{split: :0}'"
      ];
    };
  };
}
