{ pkgs, lib, ... }:

let
  jj-megamerge-rebuild =
    pkgs.writers.writeNuBin "jj-megamerge-rebuild"
      {
        # jj を実行時 PATH に注入（bash 版の runtimeInputs 相当）。
        # nushell では list/uniq がネイティブなので coreutils/gnused は不要。
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath [ pkgs.jujutsu ])
        ];
        # nu --ide-check は構文エラーでも exit 0 なので、Error 診断を検出したら
        # ビルドを落とす（writeShellApplication の shellcheck 相当の安全網）。
        check = pkgs.writeShellScript "nu-syntax-check" ''
          if ${pkgs.nushell}/bin/nu --no-config-file --ide-check 100 "$1" \
            | ${pkgs.gnugrep}/bin/grep -q '"severity":"Error"'; then
            echo "nushell syntax error in $1" >&2
            exit 1
          fi
        '';
      }
      ''
        # trunk + wip() を束ねた megamerge を再構築/作成する。
        # 既存があれば親集合を入れ替え (change_id 維持)、無ければ新規作成。

        let trunk_revset = ($env.JJ_MEGAMERGE_TRUNK? | default "trunk()")
        let wip_revset = ($env.JJ_MEGAMERGE_WIP? | default "wip()")
        let do_fetch = ($env.JJ_MEGAMERGE_FETCH? | default "1")

        if $do_fetch == "1" {
          jj git fetch
        }

        # wip bookmark の change_id 一覧 (重複除去)
        let wip_ids = (
          jj log -r $wip_revset --no-graph -T 'change_id ++ "\n"'
          | lines
          | where {|x| ($x | str trim) != "" }
          | uniq
        )

        # trunk を 1 つの change_id に解決
        let trunk_id = (jj log -r $trunk_revset --no-graph -T 'change_id' --limit 1 | str trim)
        if ($trunk_id | is-empty) {
          error make { msg: $"could not resolve trunk revset '($trunk_revset)'" }
        }

        # 既存 megamerge があるか (無ければ空文字)
        let existing_mm = (
          jj log -r 'mm()' --no-graph -T 'change_id' --limit 1 | complete
          | if $in.exit_code == 0 { $in.stdout | str trim } else { "" }
        )

        # 親集合: trunk + wip*
        let parents = ([$trunk_id] | append $wip_ids)
        if ($wip_ids | is-empty) {
          print -e $"warning: no wip bookmarks matched '($wip_revset)' — creating megamerge with trunk only"
        }

        if ($existing_mm | is-not-empty) {
          # 既存 megamerge の親集合を in-place で入れ替える
          let rebase_args = (['-s' $existing_mm] | append ($parents | each {|p| ['-d' $p] } | flatten))
          jj rebase ...$rebase_args
          print $"updated megamerge ($existing_mm): ($wip_ids | length) wip + trunk"
        } else {
          # 新規 megamerge を作る
          jj new ...$parents -m "megamerge"
          print $"created megamerge: ($wip_ids | length) wip + trunk"
        }
      '';
in
{
  programs.jujutsu.settings.revset-aliases = {
    # 自分の作業中 feature branch (= trunk に未マージの自分の bookmark)。
    # prefix 規約に依存せず、素のブランチ名のまま push して PR に使えるよう
    # 名前ではなく状態で検出する。mm() (megamerge 自身) は親候補から除外。
    "wip()" = "bookmarks() & mine() ~ ::trunk() ~ mm()";
    # 現在の megamerge リビジョン
    "mm()" = ''subject(exact:"megamerge") & mine() ~ ::trunk()'';
  };

  home.packages = [ jj-megamerge-rebuild ];
}
