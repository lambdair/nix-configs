{
  pkgs,
  config,
  sources,
  ...
}:
let
  inherit (import ../pkgs { inherit pkgs sources; })
    steel
    helix-steel-unwrapped
    helix-runtime
    sulafat
    ;

  # nrepl.hx cog dependencies, resolved to ~/.steel/cogs/<package-name>/ exactly
  # as Forge would install them. Names match the `package-name` each cog.scm
  # declares, which is what nrepl.scm's requires resolve against.
  nreplCogDeps = {
    "ui-utils.hx" = sources.ui-utils-hx.src;
    "repl-ui.hx" = sources.repl-ui-hx.src;
    "run-command" = sources.run-command.src;
  };

  helix-steel = pkgs.symlinkJoin {
    name = "helix-steel";
    paths = [ helix-steel-unwrapped ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      rm $out/bin/hx
      makeBinaryWrapper ${helix-steel-unwrapped}/bin/hx $out/bin/hx \
        --set HELIX_RUNTIME "${helix-runtime}" \
        --set STEEL_HOME "${config.home.homeDirectory}/.steel"
    '';
  };

  nreplLibName = if pkgs.stdenv.isDarwin then "libsteel_nrepl.dylib" else "libsteel_nrepl.so";
in
{
  programs.helix.package = helix-steel;

  home.file.".steel/cogs" = {
    source = "${steel}/lib/steel/cogs";
    recursive = true;
  };

  home.file.".steel/cogs/ui-utils.hx" = {
    source = nreplCogDeps."ui-utils.hx";
    recursive = true;
  };
  home.file.".steel/cogs/repl-ui.hx" = {
    source = nreplCogDeps."repl-ui.hx";
    recursive = true;
  };
  home.file.".steel/cogs/run-command" = {
    source = nreplCogDeps."run-command";
    recursive = true;
  };

  home.file.".steel/native/${nreplLibName}".source = sulafat + "/lib/${nreplLibName}";

  home.file.".config/helix/nrepl.scm".source = "${sources.sulafat.src}/nrepl.scm";

  home.file.".config/helix/cogs/nrepl" = {
    source = "${sources.sulafat.src}/cogs/nrepl";
    recursive = true;
  };

  home.file.".config/helix/lean-unicode.hx/abbreviations.scm".source =
    "${sources.lean-unicode-hx.src}/abbreviations.scm";
  home.file.".config/helix/lean-unicode.hx/engine.scm".source =
    "${sources.lean-unicode-hx.src}/engine.scm";
  home.file.".config/helix/lean-unicode.hx/lean-unicode.scm".source =
    "${sources.lean-unicode-hx.src}/lean-unicode.scm";
  home.file.".config/helix/lean-unicode.hx/cog.scm".source = "${sources.lean-unicode-hx.src}/cog.scm";

  home.file.".config/helix/init.scm".text = ''
    (require (prefix-in helix. "helix/commands.scm"))
    (require (prefix-in helix.static. "helix/static.scm"))
    (require "helix/keymaps.scm")
    (require "nrepl.scm")
    (require "lean-unicode.hx/lean-unicode.scm")

    (keymap (global)
            (normal (space (n (C ":nrepl-connect")
                              (D ":nrepl-disconnect")
                              (J ":nrepl-jack-in")
                              (L ":nrepl-load-file")
                              (b ":nrepl-eval-buffer")
                              (l ":nrepl-lookup")
                              (m ":nrepl-eval-multiple-selections")
                              (p ":nrepl-eval-prompt")
                              (s ":nrepl-eval-selection")))
                    (A-ret ":nrepl-eval-selection"))
            (select (space (n (C ":nrepl-connect")
                              (D ":nrepl-disconnect")
                              (J ":nrepl-jack-in")
                              (L ":nrepl-load-file")
                              (b ":nrepl-eval-buffer")
                              (l ":nrepl-lookup")
                              (m ":nrepl-eval-multiple-selections")
                              (p ":nrepl-eval-prompt")
                              (s ":nrepl-eval-selection")))
                    (A-ret ":nrepl-eval-selection")))

    ;; Lean4 Unicode abbreviation: \ in insert mode on .lean files
    (keymap (extension "lean") (insert ("\\" enter-abbrev-mode)))
  '';
}
