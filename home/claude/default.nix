{
  config,
  lib,
  pkgs,
  ...
}:
let
  link = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.claude/${name}";
  };
in
{
  programs.claude-code = {
    enable = true;
    context = ./CLAUDE.md;
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

        # jj: allow git fetch only (push excluded)
        "Bash(jj git fetch)"
        "Bash(jj git fetch *)"

        # nix
        "Bash(nix *)"
        "Bash(nix-build *)"
        "Bash(nix-store *)"
        "Bash(nix-shell *)"
        "Bash(nix-env *)"
        "Bash(nix-instantiate *)"
        "Bash(nixfmt *)"
        "Bash(home-manager *)"

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
        "context7@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "claude-mem@thedotmack" = true;
      };
      statusLine = {
        type = "command";
        command = "bb ${config.home.homeDirectory}/.claude/statusline-command.bb";
      };
      alwaysThinkingEnabled = true;

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

  home.file.".claude/statusline-command.bb" = {
    source = ./statusline-command.bb;
    executable = true;
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

  # macOS only: symlink shared settings for secondary account
  home.file.".claude-personal/settings.json" = lib.mkIf pkgs.stdenv.isDarwin (link "settings.json");
  home.file.".claude-personal/CLAUDE.md" = lib.mkIf pkgs.stdenv.isDarwin (link "CLAUDE.md");
  home.file.".claude-personal/statusline-command.bb" = lib.mkIf pkgs.stdenv.isDarwin (
    link "statusline-command.bb"
  );
  home.file.".claude-personal/hooks" = lib.mkIf pkgs.stdenv.isDarwin (link "hooks");
  home.file.".claude-personal/rules" = lib.mkIf pkgs.stdenv.isDarwin (link "rules");
}
