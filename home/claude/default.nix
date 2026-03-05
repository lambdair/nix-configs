{ ... }:
{
  programs.claude-code = {
    enable = true;
    memory.source = ./CLAUDE.md;
  };

  # statusline script (referenced from settings.json)
  home.file.".claude/statusline-command.bb" = {
    source = ./statusline-command.bb;
    executable = true;
  };
}
