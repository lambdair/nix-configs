---
name: checking-removable-nix-workarounds
description: 'Use when the user wants to check whether pinned / overridden / overlaid Nix packages in this repo can now be un-pinned because upstream is fixed. Triggered by phrases like "ピン解除チェック", "回避策が外せるか確認", "override/overlay/pin が unstable で外せるか", "remove obsolete pins". Audits all workarounds, auto-applies + verifies the build-gated removable ones, reports the rest.'
---

## Overview

This repo carries temporary workarounds for upstream (nixpkgs unstable, etc.)
breakage. When upstream is fixed, the workaround becomes dead weight. This skill
inventories every workaround, decides which are now removable, **auto-applies and
verifies the ones that can be checked by build**, and reports the rest for human
judgement.

This skill runs `nix build` and edits Nix files. Follow the user's conventions:
use `jj` (never `git`), keep **one workaround = one revision**, and never push.

## Workaround classification (3 buckets)

| Bucket | Definition | How to decide removability |
|---|---|---|
| **build-gated** | Without the workaround, build/eval *fails*. | Build the target without the workaround against current `inputs.nixpkgs`. Clean build ⇒ removable. Machine-decidable → auto-apply + verify. |
| **behavior-gated** | Build succeeds either way, but *behaviour/output* differs. | Run the inspectable check named in the code comment (e.g. font table flag). No build signal → **report for human**, do not auto-remove. |
| **deliberate config** | Not an upstream-bug workaround — an intentional permanent setting. | **Skip.** Note it was considered and is intentional. |

Read each item's code comment to classify. A `.override`/`.overrideAttrs` with a
comment about performance, preference, or a permanent choice is *deliberate
config*, not a workaround — skip it.

## Procedure

### 1. Inventory

From the repo root, enumerate workarounds from three sources:

- **Pins:** the `<name> = pkgs-pinned.<name>;` attrs in `overlays/pin-broken-pkg.nix`.
- **Custom overlays:** each `overlays/*.nix` except `pin-broken-pkg.nix` (source-patching overlays imported in `flake.nix`).
- **Overrides:** `.override` / `.overrideAttrs` call sites under `home/` and `host/` (use Grep).

For each item record: file:line, target package/attr, and the explanatory comment
(the "why"). If a workaround has **no comment**, flag it as `reason-unknown` in the
report (you cannot confidently test or remove it).

### 2. Classify

Put each item into one of the three buckets above using its comment/intent.

### 3. Build removability exprs (build-gated only)

For each build-gated item, construct a Nix expr that builds the target **without**
the workaround, against the current flake's nixpkgs. Let
`F = builtins.getFlake (toString ./.)` and `S = builtins.currentSystem`.

- **Pin** `name = pkgs-pinned.name`: build the un-pinned upstream package:
  `(F).inputs.nixpkgs.legacyPackages.${S}.<name>`
- **Override** `pkgs.X.override {...}`: build the bare package:
  `(F).inputs.nixpkgs.legacyPackages.${S}.<X>`
  (If the override is nested/derived, build the smallest target that exercises the
  fix — e.g. the package that consumes it.)
  - **Caveat — override whose consumer is flake-internal** (e.g. `home/difit.nix`
    pins `pnpm` to fix a libuv abort that only happens while *difit* builds):
    building the bare overridden dep is a **false positive** — `pnpm` builds fine
    on its own; the fix is exercised by `difit`, which is not in `legacyPackages`.
    There is no cheap standalone expr. **Skip the helper** for this item and test
    it via the step 5 path directly: drop the override in its own revision, run
    `just check` + build the consumer, keep only if green (revert if red).
- **Custom overlay** (e.g. `emacs-objc-std.nix`): build the overlaid attr from
  nixpkgs **without** that overlay. Easiest: reference the package as it is in the
  MacHome pkgs but with the overlay list excluding the file — construct via an
  `import F.inputs.nixpkgs { system = S; overlays = [ ... ]; }` expr that drops the
  one overlay, then `.<attr>`. Keep the other overlays so the build is realistic.

Pass these as `[{label, expr}]` to the helper:

```bash
echo '<json jobs>' | nu ~/.claude/skills/checking-removable-nix-workarounds/check-workarounds.nu
```

The helper returns `[{label, ok, error}]`. `ok: true` ⇒ removable (build-gated).
For `ok: false`, keep the `error` to show the user why it is still required.

### 4. behavior-gated checks

For each behavior-gated item, run the inspectable check named in its comment if one
exists. Example — `uiua386-fix-monospace.nix` sets the font's `post.isFixedPitch`;
build upstream `uiua386` without the overlay and inspect the TTF
(`fontTools.ttLib`) `post.isFixedPitch` / `OS/2.panose.bProportion`. If upstream
now ships it fixed-pitch, report **likely removable (human-confirm)**. If there is
no inspectable check, report **manual check needed** and state exactly what to look
at. Never auto-remove a behavior-gated workaround.

### 5. Auto-apply + verify (build-gated removable only)

For each build-gated item the helper marked `ok: true`, in its **own revision**:

```bash
jj new -m "chore(nix): drop <workaround> (upstream fixed)"
```

Then remove the workaround:
- Pin → delete the `<name> = pkgs-pinned.<name>;` line in `overlays/pin-broken-pkg.nix`.
- Override → remove the `.override {...}` wrapper, restoring the bare package.
- Overlay → remove the overlay file's import from `flake.nix` (and delete the file
  if nothing else uses it).

Verify:
```bash
just check
just home-mac   # macOS workaround; for Linux use just home-linux / just system-nixos,
                # or build the specific affected package/config directly
```
- **Green:** keep the revision; record it in the report with its change id.
- **Red:** the build check disagreed with the standalone test — revert this single
  change (`jj abandon` the revision or restore the file) and reclassify the item as
  *still required*, attaching the failure. Do **not** stack more removals on a red one.

Keep the chain linear: one workaround = one revision, no octopus, no "while I'm
here" edits.

### 6. Report

Emit a final summary:

- ✅ **Removed & verified** — workaround, change id, what now builds.
- ⚠️ **behavior-gated / human-confirm** — workaround, the exact check to run.
- ⏸️ **Still required** — workaround, the build error proving upstream is unfixed.
- ⏭️ **Skipped** — deliberate config, or `reason-unknown` (no comment).

## Notes

- Run everything from the repo root so relative paths in exprs resolve.
- `nix`/`just` build commands may run without asking (user-approved); editing Nix
  files and creating revisions follows normal revision discipline.
- Do not push. Leave the user to review and `jj git push` themselves.
