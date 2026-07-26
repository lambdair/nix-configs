{
  config,
  lib,
  pkgs,
  sources,
  ...
}:
let
  link = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.claude/${name}";
  };
  # Native statusline binary, compiled from MoonBit (see ./statusline.nix).
  statusline = import ./statusline.nix { inherit pkgs; };
in
{
  programs.claude-code = {
    enable = true;
    context = ./CLAUDE.md;
    marketplaces = {
      agent-toolkit-for-aws = sources.agent-toolkit-for-aws.src;
      bento = sources.bento.src;
      heptabase-cli-skills = sources.heptabase-cli-skills.src;
      lean4-skills = sources.lean4-skills.src;
      moonbit-code-plugins = sources.moonbit-skills.src;
      superpowers-dev = sources.superpowers.src;
      thedotmack = sources.claude-mem.src;
    };
    mcpServers.context7 = {
      type = "stdio";
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp"
      ];
    };
    settings = {
      permissions.allow = [
        # jj: read-only
        "Bash(jj status)"
        "Bash(jj status *)"
        "Bash(jj diff)"
        "Bash(jj diff *)"
        "Bash(jj log)"
        "Bash(jj log *)"
        "Bash(jj show *)"

        # jj: revision operations
        "Bash(jj new *)"
        "Bash(jj edit *)"
        "Bash(jj commit *)"
        "Bash(jj describe *)"
        "Bash(jj abandon *)"

        # jj: revision management
        "Bash(jj squash)"
        "Bash(jj squash *)"
        "Bash(jj rebase *)"
        "Bash(jj absorb)"
        "Bash(jj absorb *)"
        "Bash(JJ_EDITOR=\"true\" jj split *)"

        # jj: bookmarks & workspaces
        "Bash(jj bookmark *)"
        "Bash(jj workspace *)"

        # jj: git fetch / push
        "Bash(jj git fetch)"
        "Bash(jj git fetch *)"
        "Bash(jj git push)"
        "Bash(jj git push *)"

        # nix
        "Bash(nix *)"
        "Bash(nix-build *)"
        "Bash(nix-store *)"
        "Bash(nix-shell *)"
        "Bash(nix-env *)"
        "Bash(nix-instantiate *)"
        "Bash(nixfmt *)"
        "Bash(home-manager *)"

        # shell: prefer nushell / babashka
        "Bash(nu *)"
        "Bash(bb *)"

        # read-only Bash commands
        "Bash(find *)"
        "Bash(grep *)"
        "Bash(ls *)"
        "Bash(cat *)"
        "Bash(head *)"
        "Bash(tail *)"
        "Bash(wc *)"

        # misc
        "Bash(cd *)"
        "Bash(just *)"
        "Bash(devenv *)"
        "Glob"
        "Grep"
        "Read"
        "WebFetch"
        "WebSearch"
        "LSP"
      ];
      enabledPlugins = {
        "bento-slides@bento" = true;
        "moonbit-skills@moonbit-code-plugins" = true;
        "superpowers@superpowers-dev" = true;
        # Disabled: the stale v10.0.4 hook left in ~/.claude does not match nix's
        # v13.5.2 worker and blocks UserPromptSubmit seven times in a row.
        "claude-mem@thedotmack" = false;
        "heptabase@heptabase-cli-skills" = true;
      };
      statusLine = {
        type = "command";
        command = "${statusline}/bin/claude-statusline";
      };
      alwaysThinkingEnabled = true;
      tui = "fullscreen";
      advisorModel = "fable";

      hooks = {
        PreToolUse = [
          {
            matcher = "Edit|Write";
            hooks = [
              {
                type = "command";
                command = "bb ${config.home.homeDirectory}/.claude/hooks/revision-context.bb";
                timeout = 10;
              }
            ];
          }
        ];
        WorktreeCreate = [
          {
            hooks = [
              {
                type = "command";
                command = "bb ${config.home.homeDirectory}/.claude/hooks/jj-worktree-create.bb";
                timeout = 30;
              }
            ];
          }
        ];
        WorktreeRemove = [
          {
            hooks = [
              {
                type = "command";
                command = "bb ${config.home.homeDirectory}/.claude/hooks/jj-worktree-remove.bb";
                timeout = 30;
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "bb ${config.home.homeDirectory}/.claude/hooks/revision-discipline-check.bb";
                timeout = 15;
              }
            ];
          }
        ];
      };
    };
  };

  home.file.".claude/hooks/revision-context.bb" = {
    source = ./hooks/revision-context.bb;
    executable = true;
  };

  home.file.".claude/hooks/jj-worktree-create.bb" = {
    source = ./hooks/jj-worktree-create.bb;
    executable = true;
  };

  home.file.".claude/hooks/jj-worktree-remove.bb" = {
    source = ./hooks/jj-worktree-remove.bb;
    executable = true;
  };

  home.file.".claude/hooks/revision-discipline-check.bb" = {
    source = ./hooks/revision-discipline-check.bb;
    executable = true;
  };

  home.file.".claude/rules/jj-workflow.md".source = ./jj-workflow.md;
  home.file.".claude/rules/coding-preferences.md".source = ./coding-preferences.md;
  home.file.".claude/rules/revision-discipline.md".source = ./revision-discipline.md;

  home.file.".claude/skills/creating-heptabase-concept-card/SKILL.md".source =
    ./skills/creating-heptabase-concept-card/SKILL.md;

  home.file.".claude/skills/checking-removable-nix-workarounds/SKILL.md".source =
    ./skills/checking-removable-nix-workarounds/SKILL.md;
  home.file.".claude/skills/checking-removable-nix-workarounds/check-workarounds.nu".source =
    ./skills/checking-removable-nix-workarounds/check-workarounds.nu;

  home.file.".claude/skills/pr-inline-comments/SKILL.md".source =
    ./skills/pr-inline-comments/SKILL.md;

  home.file.".claude/skills/reviewing-jj-revisions-with-hunk/SKILL.md".source =
    ./skills/reviewing-jj-revisions-with-hunk/SKILL.md;
  home.file.".claude/skills/reviewing-jj-revisions-with-hunk/hr" = {
    source = ./skills/reviewing-jj-revisions-with-hunk/hr;
    executable = true;
  };

  home.file.".claude/skills/create-pr/SKILL.md".source = ./skills/create-pr/SKILL.md;

  # Claude sessions rewrite known_marketplaces.json and settings.json, so force
  # the overwrite to avoid activation conflicts (the claude-code module owns the
  # source).
  home.file."${config.home.homeDirectory}/.claude/plugins/known_marketplaces.json".force = true;
  home.file."${config.home.homeDirectory}/.claude/settings.json".force = true;

  # macOS only: symlink shared settings for secondary account
  home.file.".claude-personal/settings.json" = lib.mkIf pkgs.stdenv.isDarwin (link "settings.json");
  home.file.".claude-personal/CLAUDE.md" = lib.mkIf pkgs.stdenv.isDarwin (link "CLAUDE.md");
  home.file.".claude-personal/hooks" = lib.mkIf pkgs.stdenv.isDarwin (link "hooks");
  home.file.".claude-personal/rules" = lib.mkIf pkgs.stdenv.isDarwin (link "rules");
  home.file.".claude-personal/skills" = lib.mkIf pkgs.stdenv.isDarwin (link "skills");
}
