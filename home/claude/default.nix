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

  # Upstream's Lightpanda plugin, repointed at the Nix-managed binary.
  lightpanda-plugin = import ./lightpanda-plugin.nix { inherit pkgs sources; };

  # Paths of every file under `dir`, relative to it.
  filesUnder =
    dir:
    lib.flatten (
      lib.mapAttrsToList (
        name: type:
        if type == "directory" then map (sub: "${name}/${sub}") (filesUnder (dir + "/${name}")) else name
      ) (builtins.readDir dir)
    );

  # Mirror `dir` into ~/.claude/<target>. Everything but documentation is run
  # rather than read, so it needs the executable bit.
  deploy =
    target: dir:
    lib.listToAttrs (
      map (
        rel:
        lib.nameValuePair ".claude/${target}/${rel}" {
          source = dir + "/${rel}";
          executable = !(lib.hasSuffix ".md" rel);
        }
      ) (filesUnder dir)
    );
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
      lightpanda = lightpanda-plugin;
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

        # lightpanda: one-off page reads, when the MCP session is overkill
        "Bash(lightpanda fetch *)"

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
        # Brings both the skill and lightpanda's own MCP server, so the server
        # is not declared again under mcpServers.
        "lightpanda@lightpanda" = true;
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

  home.file =
    deploy "hooks" ./hooks
    // deploy "skills" ./skills
    // {
      ".claude/rules/jj-workflow.md".source = ./jj-workflow.md;
      ".claude/rules/coding-preferences.md".source = ./coding-preferences.md;
      ".claude/rules/revision-discipline.md".source = ./revision-discipline.md;

      # Claude sessions rewrite known_marketplaces.json and settings.json, so
      # force the overwrite to avoid activation conflicts (the claude-code
      # module owns the source).
      "${config.home.homeDirectory}/.claude/plugins/known_marketplaces.json".force = true;
      "${config.home.homeDirectory}/.claude/settings.json".force = true;
    }
    # macOS only: symlink shared settings for secondary account
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      ".claude-personal/settings.json" = link "settings.json";
      ".claude-personal/CLAUDE.md" = link "CLAUDE.md";
      ".claude-personal/hooks" = link "hooks";
      ".claude-personal/rules" = link "rules";
      ".claude-personal/skills" = link "skills";
    };
}
