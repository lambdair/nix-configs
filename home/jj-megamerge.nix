{ pkgs, lib, ... }:

let
  jj-megamerge-rebuild =
    pkgs.writers.writeNuBin "jj-megamerge-rebuild"
      {
        # Inject jj into the runtime PATH (what runtimeInputs does for the bash
        # writers). nushell has list/uniq built in, so no coreutils/gnused.
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath [ pkgs.jujutsu ])
        ];
        # nu --ide-check exits 0 even on a syntax error, so fail the build when an
        # Error diagnostic shows up (writeShellApplication gets this from shellcheck).
        check = pkgs.writeShellScript "nu-syntax-check" ''
          if ${pkgs.nushell}/bin/nu --no-config-file --ide-check 100 "$1" \
            | ${pkgs.gnugrep}/bin/grep -q '"severity":"Error"'; then
            echo "nushell syntax error in $1" >&2
            exit 1
          fi
        '';
      }
      ''
        # Rebuild or create the megamerge bundling trunk + wip().
        # An existing one gets its parent set swapped (keeping its change_id).

        let trunk_revset = ($env.JJ_MEGAMERGE_TRUNK? | default "trunk()")
        let wip_revset = ($env.JJ_MEGAMERGE_WIP? | default "wip()")
        let do_fetch = ($env.JJ_MEGAMERGE_FETCH? | default "1")

        if $do_fetch == "1" {
          jj git fetch
        }

        # change_ids of the wip bookmarks (deduplicated)
        let wip_ids = (
          jj log -r $wip_revset --no-graph -T 'change_id ++ "\n"'
          | lines
          | where {|x| ($x | str trim) != "" }
          | uniq
        )

        # Resolve trunk to a single change_id
        let trunk_id = (jj log -r $trunk_revset --no-graph -T 'change_id' --limit 1 | str trim)
        if ($trunk_id | is-empty) {
          error make { msg: $"could not resolve trunk revset '($trunk_revset)'" }
        }

        # The existing megamerge, empty string if there is none
        let existing_mm = (
          jj log -r 'mm()' --no-graph -T 'change_id' --limit 1 | complete
          | if $in.exit_code == 0 { $in.stdout | str trim } else { "" }
        )

        # Parent set: trunk + wip*
        let parents = ([$trunk_id] | append $wip_ids)
        if ($wip_ids | is-empty) {
          print -e $"warning: no wip bookmarks matched '($wip_revset)' — creating megamerge with trunk only"
        }

        if ($existing_mm | is-not-empty) {
          # Swap the parent set of the existing megamerge in place
          let rebase_args = (['-s' $existing_mm] | append ($parents | each {|p| ['-d' $p] } | flatten))
          jj rebase ...$rebase_args
          print $"updated megamerge ($existing_mm): ($wip_ids | length) wip + trunk"
        } else {
          # Create a new megamerge
          jj new ...$parents -m "megamerge"
          print $"created megamerge: ($wip_ids | length) wip + trunk"
        }
      '';
in
{
  programs.jujutsu.settings.revset-aliases = {
    # Own feature branches in progress (= own bookmarks not merged into trunk).
    # Detected by state rather than by name, so plain branch names can be pushed
    # and used for PRs without a prefix convention. mm() (the megamerge itself)
    # is excluded from the parent candidates.
    "wip()" = "bookmarks() & mine() ~ ::trunk() ~ mm()";
    # The current megamerge revision
    "mm()" = ''subject(exact:"megamerge") & mine() ~ ::trunk()'';
  };

  home.packages = [ jj-megamerge-rebuild ];
}
