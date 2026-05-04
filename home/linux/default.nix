{ pkgs, ... }:

rec {
  imports = [
    ./heptabase.nix
    ./tolaria.nix
  ];

  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";

  home.packages = with pkgs; [
    vivaldi
    nyxt
    thunderbird
    discord

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
