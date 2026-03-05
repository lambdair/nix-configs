{ ... }:
{
  programs.claude-code = {
    enable = true;
    memory.source = ./CLAUDE.md;
  };

  # statusline script (referenced from settings.json)
  home.file.".claude/statusline-command.sh" = {
    source = ./statusline-command.sh;
    executable = true;
  };
}
