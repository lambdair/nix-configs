{
  pkgs,
  sources,
  ...
}:
{
  home.packages = [ (import ../pkgs { inherit pkgs sources; }).elio ];
}
