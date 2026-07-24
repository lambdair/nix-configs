///|
/// Claude Code statusline renderer. Reads the session JSON on stdin, gathers
/// VCS and rate-limit context, and prints three lines.
async fn main {
  let input = @stdio.stdin.read_all().json() catch { _ => empty_json() }

  // --- session fields ---
  let model = match input {
    { "model": { "display_name": String(n), .. }, .. } => n
    _ => "Unknown"
  }
  let ctx_pct = match input {
    { "context_window": { "used_percentage": Number(n, ..), .. }, .. } =>
      @sl.round_pct(n)
    _ => 0
  }
  let add = match input {
    { "cost": { "total_lines_added": Number(n, ..), .. }, .. } => n.to_int()
    _ => 0
  }
  let del = match input {
    { "cost": { "total_lines_removed": Number(n, ..), .. }, .. } => n.to_int()
    _ => 0
  }
  let cwd = match input {
    { "cwd": String(c), .. } => c
    _ => "."
  }

  // --- environment ---
  let tz = @sys.get_env_var("CLAUDE_STATUSLINE_TZ").unwrap_or("Asia/Tokyo")
  let offset = @sl.tz_offset_seconds(tz)
  let config_dir = @sys.get_env_var("CLAUDE_CONFIG_DIR")
  let home = @sys.get_env_var("HOME").unwrap_or("")
  let user = @sys.get_env_var("USER").unwrap_or("unknown")

  // --- context requiring subprocesses / network ---
  let vcs = vcs_info(cwd)
  let usage = fetch_usage(config_dir, home, user)
  let fp = match usage {
    { "five_hour": { "utilization": Number(n, ..), .. }, .. } =>
      @sl.round_pct(n)
    _ => 0
  }
  let sp = match usage {
    { "seven_day": { "utilization": Number(n, ..), .. }, .. } =>
      @sl.round_pct(n)
    _ => 0
  }
  let frs = @sl.fmt_time(reset_iso(usage, FiveHour), offset, HourMinute)
  let srs = @sl.fmt_time(reset_iso(usage, SevenDay), offset, MonthDayHourMinute)

  // --- render ---
  let g = @sl.color_green
  let r = @sl.color_red
  let d = @sl.color_grey
  let n = @sl.color_reset
  let cc = @sl.color_for_pct(ctx_pct)
  let fc = @sl.color_for_pct(fp)
  let sc = @sl.color_for_pct(sp)
  println(
    "\u{f06a9} \{model} \{d}│\{n} \u{f0128} \{cc}\{ctx_pct}%\{n} \{d}│\{n} \u{f03eb} \{g}+\{add}\{n}/\{r}-\{del}\{n} \{d}│\{n} \u{f062c} \{vcs}",
  )
  println(
    "\u{f0152} 5h  \{fc}\{@sl.bar(fp)}  \{fp}%\{n}  Resets \{frs} (\{tz})",
  )
  println(
    "\u{f00ed} 7d  \{sc}\{@sl.bar(sp)}  \{sp}%\{n}  Resets \{srs} (\{tz})",
  )
}

///|
/// Which rate-limit window a reset timestamp belongs to.
enum Window {
  FiveHour
  SevenDay
}

///|
/// Extract the `resets_at` ISO string for a window, or "" if absent.
fn reset_iso(usage : Json, window : Window) -> String {
  match window {
    FiveHour =>
      match usage {
        { "five_hour": { "resets_at": String(s), .. }, .. } => s
        _ => ""
      }
    SevenDay =>
      match usage {
        { "seven_day": { "resets_at": String(s), .. }, .. } => s
        _ => ""
      }
  }
}
