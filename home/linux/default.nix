{ pkgs, sources, ... }:

let
  heptabaseContents = pkgs.appimageTools.extractType2 {
    pname = "heptabase";
    inherit (sources.heptabase) version src;
  };
  heptabase = pkgs.appimageTools.wrapType2 {
    pname = "heptabase";
    inherit (sources.heptabase) version src;
    extraInstallCommands = ''
      install -m 444 -D ${heptabaseContents}/project-meta.desktop $out/share/applications/heptabase.desktop
      install -m 444 -D ${heptabaseContents}/usr/share/icons/hicolor/0x0/apps/project-meta.png $out/share/icons/hicolor/512x512/apps/heptabase.png
      substituteInPlace $out/share/applications/heptabase.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=heptabase'
    '';
  };
in
rec {
  home.username = "lambdair";
  home.homeDirectory = "/home/${home.username}";

  home.packages = with pkgs; [
    vivaldi
    nyxt
    thunderbird
    discord
    heptabase

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
