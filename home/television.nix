{ ... }:
{
  # catppuccin feeds a theme into programs.television.settings, so home-manager
  # owns config.toml. television writes its own copy there on first run, which
  # activation would otherwise refuse to replace.
  xdg.configFile."television/config.toml".force = true;

  programs.television.enable = true;
}
