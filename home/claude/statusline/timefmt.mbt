///|
/// Which rendering a formatted reset time uses.
pub(all) enum TimeFmt {
  HourMinute // "H:mm"
  MonthDayHourMinute // "M/d H:mm"
}

///|
/// Resolve a display timezone name to a fixed UTC offset in seconds.
///
/// `@x/time` has no tz database, so this table covers the common zones and
/// defaults to Asia/Tokyo (+9, the statusline default). Zones with DST are not
/// modelled; unknown names fall back to JST.
pub fn tz_offset_seconds(tz : String) -> Int {
  match tz {
    "UTC" | "Etc/UTC" => 0
    "Asia/Tokyo" | "Asia/Seoul" => 9 * 3600
    "Asia/Shanghai" | "Asia/Taipei" | "Asia/Hong_Kong" | "Asia/Singapore" =>
      8 * 3600
    "Asia/Kolkata" => 5 * 3600 + 1800
    _ => 9 * 3600
  }
}

///|
/// Format an ISO-8601 UTC instant (e.g. "2026-07-24T09:00:00Z") into the
/// display timezone. Returns "?" on empty input or any parse failure.
pub fn fmt_time(iso : String, offset_sec : Int, kind : TimeFmt) -> String {
  if iso == "" {
    return "?"
  }
  fmt_time_inner(iso, offset_sec, kind) catch {
    _ => "?"
  }
}

///|
/// Truncate an ISO-8601 timestamp to "YYYY-MM-DDTHH:MM:SS", dropping any
/// fractional seconds and zone suffix (Z / +hh:mm). The instant is treated as
/// UTC, which is what the OAuth usage API returns.
fn normalize_iso(iso : String) -> String {
  if iso.length() >= 19 {
    iso[0:19].to_owned()
  } else {
    iso
  }
}

///|
fn fmt_time_inner(
  iso : String,
  offset_sec : Int,
  kind : TimeFmt,
) -> String raise {
  let plain = @time.PlainDateTime::from_str(normalize_iso(iso))
  let epoch = plain.to_unix_second()
  let zone = @time.fixed_zone("display", offset_sec)
  let zdt = @time.ZonedDateTime::from_unix_second(epoch, zone~)
  let hour = zdt.hour()
  let minute = zdt.minute()
  match kind {
    HourMinute => "\{hour}:\{pad2(minute)}"
    MonthDayHourMinute => "\{zdt.month()}/\{zdt.day()} \{hour}:\{pad2(minute)}"
  }
}
