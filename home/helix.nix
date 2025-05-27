{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor = {
        line-number = "relative";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides = {
          character = "|";
          render = true;
        };
      };

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
      grammar = [
        {
          name = "uiua";
          source.git = "https://github.com/shnarazk/tree-sitter-uiua";
          source.rev = "0da15357bc1179b187018131dc20c2395e77ce71";
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
