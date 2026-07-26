{ pkgs, ... }:

rec {
  imports = [
    ./heptabase.nix
    ./tolaria.nix
    ./zmk-battery-center.nix
  ];

  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";

  home.packages = with pkgs; [
    vivaldi
    nyxt
    thunderbird
    discord
    obsidian # Knowledge base
    bitwarden-desktop # pinned in overlays/pin-broken-pkg.nix
    obs-studio # Free and open source streaming/recording software
    (symlinkJoin {
      name = "peek";
      paths = [ peek ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/peek --set DISPLAY :0
      '';
    }) # Simple animated GIF screen recorder
    pcloud # Secure cloud storage client

    # Wayland desktop tools
    waybar # ステータスバー
    mako # 通知デーモン
    swaylock # 画面ロック
    swayidle # アイドル管理
    grim # スクリーンショット
    slurp # 領域選択
    wl-clipboard # クリップボード (wl-copy/wl-paste)
    swaybg # 壁紙設定
    vicinae # Raycast互換ランチャー
  ];

  xdg.configFile."niri/config.kdl".source = ./niri-config.kdl;
}
