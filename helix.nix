{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      keys.normal = {
        C-a = "goto_line_start";
        C-e = "goto_line_end";
        x = "select_line_below";
        X = "select_line_above";
        A-x = "command_palette";
      };

      keys.insert = {
        C-a = "goto_line_start";
        C-e = "goto_line_end";
        A-x = "command_palette";
      };

      keys.select = {
        x = "select_line_below";
        X = "select_line_above";
        A-x = "command_palette";
      };
    };

    languages = {
      # Uiua
      # probably should build grammar and copy queries
      # e.g.
      #   $ nix-shell -p libgcc
      #   $ hx -g fetch & hx -g build
      #   $ nix copy --to [Path] nixpkg#tree-sitter-grammars.tree-sitter-uiua
      grammar = [
        {
          name = "uiua";
          source.git = "https://github.com/shnarazk/tree-sitter-uiua";
          source.rev = "942e8365d10b9b62be9f2a8b0503459d3d8f3af3";
        }
      ];

      language-server.uiua-lsp = {
        command = "uiua";
        args = [ "lsp" ];
      };

      language = [
        {
          name = "uiua";
          scope = "source.uiua";
          injection-regex = "uiua";
          file-types = [ "ua" ];
          roots = [ ];
          auto-format = true;
          comment-token = "#";
          language-servers = [ "uiua-lsp" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          shebangs = [ "uiua" ];
          auto-pairs = {
            "(" = ")";
            "{" = "}";
            "[" = "]";
            "\"" = "\"";
          };
        }
      ];
    };
  };
}
