///|
test "color_for_pct thresholds" {
  inspect(@sl.color_for_pct(0) == @sl.color_green, content="true")
  inspect(@sl.color_for_pct(49) == @sl.color_green, content="true")
  inspect(@sl.color_for_pct(50) == @sl.color_yellow, content="true")
  inspect(@sl.color_for_pct(79) == @sl.color_yellow, content="true")
  inspect(@sl.color_for_pct(80) == @sl.color_red, content="true")
  inspect(@sl.color_for_pct(100) == @sl.color_red, content="true")
}

///|
test "bar rounds to nearest segment" {
  inspect(@sl.bar(0), content="▱▱▱▱▱▱▱▱▱▱")
  inspect(@sl.bar(4), content="▱▱▱▱▱▱▱▱▱▱") // (4+5)/10 = 0
  inspect(@sl.bar(5), content="▰▱▱▱▱▱▱▱▱▱") // (5+5)/10 = 1
  inspect(@sl.bar(50), content="▰▰▰▰▰▱▱▱▱▱")
  inspect(@sl.bar(95), content="▰▰▰▰▰▰▰▰▰▰")
  inspect(@sl.bar(100), content="▰▰▰▰▰▰▰▰▰▰")
}

///|
test "pad2 and round_pct" {
  inspect(@sl.pad2(0), content="00")
  inspect(@sl.pad2(9), content="09")
  inspect(@sl.pad2(10), content="10")
  inspect(@sl.round_pct(49.4), content="49")
  inspect(@sl.round_pct(49.5), content="50")
}

///|
test "keychain_service is account-aware" {
  inspect(
    @sl.keychain_service(None, "/Users/me"),
    content="Claude Code-credentials",
  )
  // Default config dir => unsalted.
  inspect(
    @sl.keychain_service(Some("/Users/me/.claude"), "/Users/me"),
    content="Claude Code-credentials",
  )
  // Non-default => salted with sha8 of the dir.
  let salted = @sl.keychain_service(Some("/Users/me/.claude-work"), "/Users/me")
  inspect(
    salted == "Claude Code-credentials-" + @sl.sha8("/Users/me/.claude-work"),
    content="true",
  )
}

///|
test "cache_file_path is account-aware" {
  inspect(
    @sl.cache_file_path("alice", None, "/Users/alice"),
    content="/tmp/claude-usage-cache-alice.json",
  )
  let p = @sl.cache_file_path(
    "alice",
    Some("/Users/alice/.claude-x"),
    "/Users/alice",
  )
  inspect(
    p ==
    "/tmp/claude-usage-cache-alice-" +
    @sl.sha8("/Users/alice/.claude-x") +
    ".json",
    content="true",
  )
}

///|
test "sha8 is 8 lowercase hex chars" {
  inspect(@sl.sha8("hello").length(), content="8")
  // Known SHA-256("hello") starts with 2cf24dba.
  inspect(@sl.sha8("hello"), content="2cf24dba")
}

///|
test "parse_token_creds: plain JSON" {
  let creds =
    #|{"claudeAiOauth":{"accessToken":"sk-tok-123"}}
  inspect(@sl.parse_token_creds(creds) == Some("sk-tok-123"), content="true")
}

///|
test "parse_token_creds: hex-encoded JSON fallback" {
  // hex of: {"accessToken":"hexok"}
  let inner =
    #|{"accessToken":"hexok"}
  let hex = @sl.to_hex_utf8(inner)
  inspect(@sl.parse_token_creds(hex) == Some("hexok"), content="true")
}

///|
test "parse_token_creds: garbage yields None" {
  inspect(@sl.parse_token_creds("not-a-token") == None, content="true")
}

///|
test "fmt_time formats into JST" {
  let jst = @sl.tz_offset_seconds("Asia/Tokyo")
  // 2026-07-24T00:15:00Z + 9h = 09:15 JST
  inspect(@sl.fmt_time("2026-07-24T00:15:00Z", jst, HourMinute), content="9:15")
  inspect(
    @sl.fmt_time("2026-07-24T00:15:00Z", jst, MonthDayHourMinute),
    content="7/24 9:15",
  )
  // fractional seconds + Z tolerated
  inspect(
    @sl.fmt_time("2026-12-31T20:05:30.123Z", jst, MonthDayHourMinute),
    content="1/1 5:05",
  )
}

///|
test "fmt_time returns ? on bad input" {
  inspect(@sl.fmt_time("", 0, HourMinute), content="?")
  inspect(@sl.fmt_time("garbage", 0, HourMinute), content="?")
}

///|
test "tz_offset defaults to JST for unknown zones" {
  inspect(@sl.tz_offset_seconds("Mars/Olympus"), content="32400")
  inspect(@sl.tz_offset_seconds("UTC"), content="0")
}
