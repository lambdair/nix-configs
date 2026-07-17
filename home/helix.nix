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
          name = "bqn";
          source.git = "https://github.com/shnarazk/tree-sitter-bqn";
          source.rev = "b4c339b771b1ecd3b6006cc99242f2e270b14abb";
        }
      ];

      language-server.uiua-lsp = {
        command = "uiua";
        args = [ "lsp" ];
      };
      language-server.bqnlsp = {
        command = "bqnlsp";
      };
      language-server.tailwindcss-ls = {
        command = "tailwindcss-language-server";
        args = [ "--stdio" ];
      };
      language-server.typos-lsp = {
        command = "typos-lsp";
      };
      # The toolchain's LSP binary is `moon-lsp`, not the `moonbit-lsp` name
      # upstream helix's default config expects.
      language-server.moonbit-lsp = {
        command = "moon-lsp";
        args = [ "--stdio" ];
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
        {
          name = "bqn";
          language-id = "bqn";
          file-types = [ "bqn" ];
          injection-regex = "bqn";
          scope = "source.bqn";
          roots = [ ];
          comment-token = "#";
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          shebangs = [
            "BQN"
            "CBQN"
            "bqn"
            "cbqn"
          ];
          auto-pairs = {
            "(" = ")";
            "{" = "}";
            "[" = "]";
            "'" = "'";
            "\"" = "\"";
            "⟨" = "⟩";
          };
        }
        {
          name = "moonbit";
          scope = "source.moonbit";
          injection-regex = "moonbit|mbt";
          file-types = [
            "mbt"
            "mbti"
          ];
          # `moon new` generates `moon.mod`, but upstream helix lists only
          # `moon.mod.json`, so without the former it finds no root.
          roots = [
            "moon.mod"
            "moon.mod.json"
          ];
          comment-tokens = [
            "//"
            "///"
          ];
          block-comment-tokens = {
            start = "/*";
            end = "*/";
          };
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          language-servers = [ "moonbit-lsp" ];
          auto-format = true;
        }
        {
          name = "jsx";
          language-servers = [
            "typescript-language-server"
            "tailwindcss-ls"
            "typos-lsp"
          ];
        }
        {
          name = "tsx";
          language-servers = [
            "typescript-language-server"
            "tailwindcss-ls"
            "typos-lsp"
          ];
        }
      ];
    };
  };
}
