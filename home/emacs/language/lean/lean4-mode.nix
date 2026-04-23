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

  # Required so lsp-protocol.el macros (lsp-defun, lsp-interface, ...) expand
  # to plist accessors instead of hash-table accessors at byte-compile time.
  # Must be exported via env. under __structuredAttrs (top-level attrs are not).
  env.LSP_USE_PLISTS = "true";

  postInstall = ''
    mkdir -p $out/share/emacs/site-lisp/data
    cp data/abbreviations.json $out/share/emacs/site-lisp/data/
  '';
}
