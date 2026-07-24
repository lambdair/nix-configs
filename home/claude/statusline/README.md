# claude-statusline

Claude Code statusline renderer, in MoonBit, compiled to a native binary.

Reads the session JSON on stdin and prints three lines: model / context% /
edited lines / VCS on line 1, and the 5h + 7d rate-limit gauges on lines 2-3.

## Layout

- `render.mbt` — colors, progress bar, rounding (pure, unit-tested)
- `timefmt.mbt` — ISO-8601 → display-TZ formatting (pure, unit-tested)
- `account.mbt` — keychain service / cache path / token parsing (pure, tested)
- `cmd/main/main.mbt` — field extraction + 3-line rendering
- `cmd/main/io.mbt` — subprocess (jj/git/security), HTTP usage API, cache I/O

Dependencies: `moonbitlang/async` (process, http+tls, fs, stdio) and
`moonbitlang/x` (crypto/sha256, time, sys). The usage API is called over native
TLS (no FFI, no `curl`).

## Develop

```sh
moon test --target native        # 12 unit tests
moon fmt
echo '{"model":{"display_name":"Opus 4.8"},"cwd":"/path/to/repo"}' \
  | moon run cmd/main --target native --release
```

## Build (nix)

`../statusline.nix` builds this with the `moonbit-overlay` toolchain and wires
the binary into `statusLine.command` in `../default.nix`. Deps are fetched by a
fixed-output derivation and served offline through a seeded `MOON_HOME`; nothing
is committed to the repo. Bump its `outputHash` when the dep versions change.

## Timezone

`moonbitlang/x/time` has no tz database, so `tz_offset_seconds` maps a small set
of IANA names to fixed offsets and defaults to Asia/Tokyo
(`CLAUDE_STATUSLINE_TZ`). DST zones are not modelled.
