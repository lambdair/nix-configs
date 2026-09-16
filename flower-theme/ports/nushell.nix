# nushell's colours for the selected flower. The assignment replaces the whole
# record, so every key is listed rather than only the ones that differ.
{ config, lib, ... }:
let
  cfg = config.flowerTheme;
  flowerLib = import ../lib.nix { inherit lib; };
  v = flowerLib.variant cfg.flower (flowerLib.resolve cfg.mode);
  r = v.hex.roles;
in
{
  config = lib.mkIf (cfg.flower != null) {
    catppuccin.nushell.enable = false;

    programs.nushell.extraConfig = ''
      $env.config.color_config = {
        separator: { fg: "${r.guide}" attr: b }
        leading_trailing_space_bg: { fg: "${r.warning}" attr: u }
        header: { fg: "${r.text}" attr: b }
        row_index: "${r.comment}"
        record: "${r.text}"
        list: "${r.text}"
        hints: "${r.comment}"
        search_result: { fg: "${r.bg}" bg: "${r.warning}" }
        empty: { attr: n }
        background: "${r.bg}"
        foreground: "${r.text}"
        cursor: "${r.text}"

        bool: "${r.constant}"
        int: "${r.constant}"
        float: "${r.constant}"
        binary: "${r.constant}"
        range: "${r.special}"
        string: "${r.string}"
        glob: "${r.string}"
        nothing: "${r.comment}"
        filesize: "${r.constant}"
        duration: "${r.constant}"
        datetime: "${r.constant}"
        block: "${r.keyword}"
        closure: "${r.type}"
        custom: "${r.special}"
        cell-path: "${r.subtext}"

        shape_bool: "${r.constant}"
        shape_int: "${r.constant}"
        shape_float: "${r.constant}"
        shape_binary: "${r.constant}"
        shape_datetime: "${r.constant}"
        shape_literal: "${r.constant}"
        shape_range: "${r.special}"
        shape_string: "${r.string}"
        shape_raw_string: "${r.string}"
        shape_string_interpolation: "${r.special}"
        shape_glob_interpolation: "${r.special}"
        shape_globpattern: "${r.string}"
        shape_filepath: "${r.string}"
        shape_directory: "${r.info}"
        shape_externalarg: "${r.string}"
        shape_external: "${r.function}"
        shape_external_resolved: "${r.function}"
        shape_internalcall: { fg: "${r.function}" attr: b }
        shape_block: "${r.keyword}"
        shape_closure: "${r.type}"
        shape_custom: "${r.special}"
        shape_signature: "${r.type}"
        shape_keyword: "${r.keyword}"
        shape_operator: "${r.special}"
        shape_pipe: "${r.special}"
        shape_redirection: "${r.special}"
        shape_flag: { fg: "${r.constant}" attr: i }
        shape_variable: { fg: "${r.special}" attr: i }
        shape_vardecl: { fg: "${r.special}" attr: i }
        shape_match_pattern: "${r.string}"
        shape_matching_brackets: { attr: u }
        shape_garbage: "${r.error}"
        shape_nothing: "${r.comment}"
        shape_table: "${r.subtext}"
        shape_list: "${r.subtext}"
        shape_record: "${r.subtext}"
      }
    '';
  };
}
