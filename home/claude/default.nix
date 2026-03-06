{ ... }:
{
  programs.claude-code = {
    enable = true;
    memory.source = ./CLAUDE.md;
    settings = {
      permissions.allow = [
        "Bash(jj:*)"
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
        command = "bb /Users/ziyuguo/.claude/statusline-command.bb";
      };
      alwaysThinkingEnabled = true;
    };
  };

  home.file.".claude/statusline-command.bb" = {
    source = ./statusline-command.bb;
    executable = true;
  };

  home.file.".claude/rules/jj-workflow.md".source = ./jj-workflow.md;
  home.file.".claude/rules/coding-preferences.md".source = ./coding-preferences.md;
  home.file.".claude/rules/revision-discipline.md".source = ./revision-discipline.md;
}
