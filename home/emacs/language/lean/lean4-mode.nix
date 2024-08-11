{
  trivialBuild,
  markdown-mode,
  dash,
  lsp-mode,
  compat,
  magit-section,
  sources,
}:

trivialBuild {
  pname = "lean4-mode";
  version = sources.lean4-mode.version;
  src = sources.lean4-mode.src;
  packageRequires = [
    markdown-mode
    dash
    lsp-mode
    compat
    magit-section
  ];

  postInstall = ''
    mkdir -p $out/share/emacs/site-lisp/data
    cp data/abbreviations.json $out/share/emacs/site-lisp/data/
  '';
}
