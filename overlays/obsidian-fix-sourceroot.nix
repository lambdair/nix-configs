final: prev: {
  # The macOS dmg ships the app under a versioned volume directory
  # (`Obsidian <version>-universal/Obsidian.app`), so the bare `Obsidian.app`
  # sourceRoot finds nothing. Fixed upstream in nixpkgs c594c220ba1f; the
  # guard turns this overlay into a no-op once our nixpkgs carries that fix.
  obsidian =
    if (prev.obsidian.sourceRoot or "") == "Obsidian.app" then
      prev.obsidian.overrideAttrs (old: {
        sourceRoot = "Obsidian ${old.version}-universal/Obsidian.app";
      })
    else
      prev.obsidian;
}
