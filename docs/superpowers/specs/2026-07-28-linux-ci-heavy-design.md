# Extending the ci-heavy cache to x86_64-linux

Date: 2026-07-28

## Problem

CI builds `packages.aarch64-darwin.ci-heavy` and pushes it to the `lambdair`
Cachix cache, so a nixpkgs bump costs the Mac nothing. The Linux side gets no
such treatment: `build.yml`'s `configs` job only evaluates the four Linux
attributes with `nix build --dry-run`, which catches renamed options but builds
nothing. Every nixpkgs bump therefore recompiles helix-steel, steel, difit and
the rest on daiquiri and on WSL.

## Constraints

Measured on 2026-07-28 with `nix build --dry-run
.#homeConfigurations.NixHome.activationPackage`:

- 1013 derivations to build, 7.6 GB to fetch, 26 GB unpacked.
- The build list is dominated by cheap derivations — several hundred
  tree-sitter grammars, several hundred `bun-pkg-*` fetches, Emacs elisp
  byte-compiles — plus the expensive custom packages.
- A GitHub `ubuntu-latest` runner has roughly 14 GB free, so caching a whole
  configuration would need a disk-reclaiming step and would grow the Cachix
  cache by an order of magnitude.

Caching only the expensive custom packages avoids both costs while covering the
rebuild that actually hurts.

## Design

### Scope

Mirror the existing macOS output: add `packages.x86_64-linux.ci-heavy` with the
same members — steel, helix-steel-unwrapped, helix-runtime, sulafat, difit,
elio, budget_tracker_tui, hunkdiff. The Linux configurations already build all
of them: `home/default.nix`, `home/helix-steel.nix`, `home/difit.nix` and
`home/elio.nix` import `../pkgs` unconditionally, and `pkgs/` branches on the
platform only for the tree-sitter grammar extension. `inputs.hunk` exposes an
`x86_64-linux` output.

The four Linux configurations stay on `--dry-run`. Their full closures are what
the constraints above rule out.

### flake.nix

`darwinPkgs` sits in the top-level `let`, but `linuxPkgs` is local to the
`homeConfigurations` `let`, so `packages` cannot reach it. Hoist both out of a
shared `pkgsFor` function that branches on the system for the two macOS-only
details: `config.allowUnsupportedSystem` and the uiua386 overlay. Hoist
`linuxSources` alongside `darwinSources`.

Factor the linkFarm into `ciHeavyFor system pkgs sources` and instantiate it for
both systems.

The refactor must leave every existing derivation hash-identical, otherwise it
invalidates the macOS cache it exists to serve. Baselines captured before the
change:

| attribute | drvPath |
|---|---|
| `homeConfigurations.MacHome.activationPackage` | `/nix/store/zwzz12rb32fyq7jh6rsh1v4m6ic2yj1l-home-manager-generation.drv` |
| `packages.aarch64-darwin.ci-heavy` | `/nix/store/56ifbarqlmr7bywizxa5yyywvfp6f8x2-ci-heavy.drv` |

### build.yml

Add a `ci-heavy-linux` job on `ubuntu-latest` that builds
`.#packages.x86_64-linux.ci-heavy` and lets `cachix-action` push it, structured
like the existing macOS `ci-heavy` job. It stays separate from `configs`:
`configs` evaluates in about a minute and that fast feedback should not queue
behind a build measured in tens of minutes.

No disk-reclaiming step, since this closure is far smaller than a full
configuration.

Triggers stay as they are, so the twice-weekly update PR now gates on the Linux
build too and can catch a bump that breaks only the Linux side.

## Revisions

1. flake.nix — derive both package sets from `pkgsFor` and hoist `linuxPkgs`
   and `linuxSources`, with no new output. Behaviour-neutral, so the baseline
   drvPaths must already match here.
2. flake.nix — factor `ciHeavyFor` and add the `x86_64-linux` output.
3. build.yml — add the `ci-heavy-linux` job.
