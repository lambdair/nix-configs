# Claude Code custom themes for every flower variant, with the selected one set
# as the theme. Claude Code reads <configDir>/themes/<slug>.json but skips
# symlinks, so the files are copied in at activation rather than linked by
# home.file. It ignores tokens it does not know, so the map can cover more than
# one version's token set.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };

  theme =
    v:
    let
      r = v.hex.roles;
      a = v.hex.ansi;
      mix = flowerLib.mix;
      lighter = colour: mix 0.35 colour r.text;
    in
    {
      name = v.title;
      base = v.mode;
      overrides = {
        claude = r.keyword;
        claudeShimmer = lighter r.keyword;
        text = r.text;
        inverseText = r.bg;
        inactive = r.comment;
        inactiveShimmer = lighter r.comment;
        subtle = r.guide;
        suggestion = r.function;
        permission = r.type;
        permissionShimmer = lighter r.type;
        remember = r.special;

        success = r.added;
        error = r.error;
        warning = r.warning;
        warningShimmer = lighter r.warning;
        merged = r.type;

        promptBorder = r.subtext;
        promptBorderShimmer = lighter r.subtext;
        planMode = r.info;
        autoAccept = r.added;
        bashBorder = r.constant;
        ide = r.info;
        fastMode = r.hint;
        fastModeShimmer = lighter r.hint;
        effortUltra = r.keyword;

        diffAdded = mix 0.22 r.bg r.added;
        diffRemoved = mix 0.22 r.bg r.removed;
        diffAddedDimmed = mix 0.12 r.bg r.added;
        diffRemovedDimmed = mix 0.12 r.bg r.removed;
        diffAddedWord = mix 0.42 r.bg r.added;
        diffRemovedWord = mix 0.42 r.bg r.removed;

        userMessageBackground = r.cursorline;
        userMessageBackgroundHover = r.selection;
        bashMessageBackgroundColor = r.statusline;
        memoryBackgroundColor = r.statusline;
        selectionBg = r.selection;

        rate_limit_fill = r.added;
        rate_limit_empty = r.guide;
        briefLabelYou = r.subtext;
        briefLabelClaude = r.keyword;

        red_FOR_SUBAGENTS_ONLY = a.red;
        blue_FOR_SUBAGENTS_ONLY = a.blue;
        green_FOR_SUBAGENTS_ONLY = a.green;
        yellow_FOR_SUBAGENTS_ONLY = a.yellow;
        purple_FOR_SUBAGENTS_ONLY = a.magenta;
        orange_FOR_SUBAGENTS_ONLY = r.warning;
        pink_FOR_SUBAGENTS_ONLY = a.bright-magenta;
        cyan_FOR_SUBAGENTS_ONLY = a.cyan;
      };
    };

  selected = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
  themesDir = "${config.programs.claude-code.configDir}/themes";
in
{
  config = lib.mkIf (cfg.flower != null) {
    # After linkGeneration, which removes the links earlier generations left at
    # these paths.
    home.activation.flowerClaudeThemes = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      ''
        run mkdir -p ${lib.escapeShellArg themesDir}
      ''
      + lib.concatMapStrings (v: ''
        run install -m 644 ${pkgs.writeText "${v.name}.json" (builtins.toJSON (theme v))} ${lib.escapeShellArg "${themesDir}/${v.name}.json"}
      '') flowerLib.variants
    );

    programs.claude-code.settings.theme = "custom:${selected.name}";
  };
}
