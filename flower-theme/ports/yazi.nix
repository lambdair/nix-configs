# yazi's theme for the selected flower. `syntect_theme` is left unset until the
# palettes get a tmTheme, so previews keep yazi's own highlighting.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  v = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
  r = v.hex.roles;

  on = colour: {
    fg = r.bg;
    bg = colour;
  };
  marker = colour: {
    fg = colour;
    bg = colour;
  };
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.yazi.enable = false;

    programs.yazi.theme = {
      app.overall.bg = r.bg;

      mgr = {
        cwd.fg = r.info;
        find_keyword = {
          fg = r.warning;
          italic = true;
        };
        find_position = {
          fg = r.special;
          bg = "reset";
          italic = true;
        };
        marker_copied = marker r.added;
        marker_cut = marker r.removed;
        marker_marked = marker r.info;
        marker_selected = marker r.keyword;
        count_copied = on r.added;
        count_cut = on r.removed;
        count_selected = on r.keyword;
        border_symbol = "│";
        border_style.fg = r.guide;
      };

      tabs = {
        active = on r.text // {
          bold = true;
        };
        inactive = {
          fg = r.text;
          bg = r.statusline;
        };
      };

      mode = {
        normal_main = on r.keyword // {
          bold = true;
        };
        normal_alt = {
          fg = r.keyword;
          bg = r.statusline;
        };
        select_main = on r.added // {
          bold = true;
        };
        select_alt = {
          fg = r.added;
          bg = r.statusline;
        };
        unset_main = on r.warning // {
          bold = true;
        };
        unset_alt = {
          fg = r.warning;
          bg = r.statusline;
        };
      };

      indicator = {
        parent = on r.text;
        current = on r.keyword;
        preview = on r.text;
      };

      status = {
        progress_label = {
          fg = r.text;
          bold = true;
        };
        progress_normal = {
          fg = r.added;
          bg = r.statusline;
        };
        progress_error = {
          fg = r.bg;
          bg = r.error;
        };
        perm_type.fg = r.function;
        perm_read.fg = r.warning;
        perm_write.fg = r.removed;
        perm_exec.fg = r.added;
        perm_sep.fg = r.guide;
      };

      input.border.fg = r.keyword;
      pick = {
        border.fg = r.keyword;
        active.fg = r.special;
      };
      confirm = {
        border.fg = r.keyword;
        title.fg = r.keyword;
        btn_yes.reversed = true;
      };
      cmp.border.fg = r.keyword;
      tasks = {
        border.fg = r.keyword;
        hovered = {
          fg = r.special;
          bold = true;
        };
      };
      which = {
        border.fg = r.keyword;
        cand.fg = r.info;
        rest.fg = r.subtext;
        desc.fg = r.special;
        separator = "  ";
        separator_style.fg = r.guide;
      };
      help = {
        border.fg = r.keyword;
        chord.fg = r.info;
        action.fg = r.subtext;
        hovered = {
          bg = r.cursorline;
          bold = true;
        };
      };
      notify = {
        title_info.fg = r.info;
        title_warn.fg = r.warning;
        title_error.fg = r.error;
      };
      spot = {
        border.fg = r.keyword;
        title.fg = r.keyword;
        tbl_cell = {
          fg = r.keyword;
          reversed = true;
        };
        tbl_col.bold = true;
      };

      filetype.rules = [
        {
          mime = "**/image/*";
          fg = r.warning;
        }
        {
          mime = "**/{audio,video}/*";
          fg = r.special;
        }
        {
          mime = "**/application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
          fg = r.removed;
        }
        {
          mime = "**/application/{pdf,doc,rtf}";
          fg = r.info;
        }
        {
          mime = "vfs/{absent,stale}";
          fg = r.comment;
        }
        {
          url = "*";
          is = "orphan";
          bg = r.error;
        }
        {
          url = "*";
          is = "exec";
          fg = r.added;
        }
        {
          url = "*";
          is = "dummy";
          bg = r.error;
        }
        {
          url = "*/";
          is = "dummy";
          bg = r.error;
        }
        {
          url = "*/";
          fg = r.keyword;
        }
      ];
    };
  };
}
