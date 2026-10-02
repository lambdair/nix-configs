final: prev: {
  # lix sets NIX_LDFLAGS = "-z,noexecstack" on every platform, and Apple's ld64
  # has no -z option, so Meson's compiler sanity check fails to link on darwin.
  # Fixed upstream in nixpkgs 31a68c07fe; the guard turns this overlay into a
  # no-op once our nixpkgs carries that fix.
  lixPackageSets = prev.lib.recurseIntoAttrs (
    prev.lixPackageSets.extend (
      _: sets: {
        lix_2_95 = sets.lix_2_95.overrideScope (
          _: scope: {
            lix =
              if (scope.lix.env.NIX_LDFLAGS or "") == "-z,noexecstack" then
                scope.lix.overrideAttrs (old: {
                  env = removeAttrs old.env [ "NIX_LDFLAGS" ];
                })
              else
                scope.lix;
          }
        );
      }
    )
  );
}
