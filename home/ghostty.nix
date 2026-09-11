{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    # nixpkgs builds ghostty on Linux only; on darwin the app is installed
    # outside Nix and just reads the config written here.
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

    # The theme comes from flower-theme, or from the catppuccin module when no
    # flower is selected.
    settings = {
      font-family = "Maple Mono NF CN";
      font-size = 18;

      # Ghostty's CTFontCollection scoring can otherwise pick an arbitrary
      # monospace fallback for kanji/kana even when the primary font covers
      # them.
      font-codepoint-map = [
        "U+3000-U+303F=Maple Mono NF CN"
        "U+3040-U+309F=Maple Mono NF CN"
        "U+30A0-U+30FF=Maple Mono NF CN"
        "U+3400-U+4DBF=Maple Mono NF CN"
        "U+4E00-U+9FFF=Maple Mono NF CN"
        "U+F900-U+FAFF=Maple Mono NF CN"
        "U+FF00-U+FFEF=Maple Mono NF CN"
      ];
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      # The macOS login shell is zsh, so ghostty has to launch nu itself.
      command = "${lib.getExe pkgs.nushell} --login";

      # Send Option+x as ESC+x instead of composing "≈", so Emacs-style Meta
      # chords reach the terminal app. Per-side values (left/right) are
      # unreliable in cmux (manaflow-ai/cmux#2369).
      macos-option-as-alt = true;

      # Hand Ctrl+J to the input method (macSKK: switch to kana mode). cmux's
      # keyDown has a Ctrl fast path that would otherwise consume the chord
      # before the IME sees it. Trade-off: Ctrl+J no longer inserts a newline
      # in TUIs.
      keybind = [ "ctrl+j=ignore" ];
    };
  };
}
