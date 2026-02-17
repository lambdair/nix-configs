final: prev: {
  uiua386 = prev.uiua386.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      (prev.python3.withPackages (ps: [ ps.fonttools ]))
    ];

    postInstall =
      (old.postInstall or "")
      + ''
        chmod 644 $out/share/fonts/truetype/*.ttf
        python3 -c "
        from fontTools.ttLib import TTFont
        import glob, os

        for ttf in glob.glob(os.path.join('$out', 'share/fonts/truetype/*.ttf')):
            font = TTFont(ttf)
            font['post'].isFixedPitch = 1
            font['OS/2'].panose.bProportion = 9
            font.save(ttf)
        "
        chmod 444 $out/share/fonts/truetype/*.ttf
      '';
  });
}
