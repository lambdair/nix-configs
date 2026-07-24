///|
/// An empty JSON object, used as the "no data" fallback.
fn empty_json() -> Json {
  Json::empty_object()
}

///|
/// Run `cmd args` in `cwd`, returning trimmed stdout on exit 0, else None.
async fn sh(cwd : String, cmd : String, args : Array[String]) -> String? {
  let (code, out, _err) = @process.collect_output(cmd, args, cwd~) catch {
    _ => return None
  }
  if code != 0 {
    return None
  }
  let text = out.text() catch { _ => return None }
  Some(text.trim(chars=" \n\r\t").to_owned())
}

///|
/// `jj log -r @ --no-graph -T <template>` in `cwd`.
async fn jj_log(cwd : String, template : String) -> String? {
  sh(cwd, "jj", ["log", "--no-pager", "-r", "@", "--no-graph", "-T", template])
}

///|
/// First whitespace-delimited token of `s`, or None if blank.
fn first_token(s : String) -> String? {
  let t = s.trim(chars=" \n\r\t").to_owned()
  if t == "" {
    return None
  }
  for i in 0..<t.length() {
    if t[i].to_int() == ' '.to_int() {
      return Some(t[0:i].to_owned())
    }
  }
  Some(t)
}

///|
/// Split a string on its first tab into (before, after). No tab => (s, "").
fn split_tab(s : String) -> (String, String) {
  for i in 0..<s.length() {
    if s[i].to_int() == '\t'.to_int() {
      return (s[0:i].to_owned(), s[i + 1:s.length()].to_owned())
    }
  }
  (s, "")
}

///|
/// VCS summary: jj preferred ("bookmark (rev)" or "rev"), git fallback.
/// rev and bookmarks come from one jj call, tab-joined in the template.
async fn vcs_info(cwd : String) -> String {
  let template =
    #|change_id.shortest() ++ "\t" ++ bookmarks.map(|b| b.name()).join(" ")
  match jj_log(cwd, template) {
    Some(line) => {
      let (rev, bookmarks) = split_tab(line)
      match first_token(bookmarks) {
        Some(bm) => "\{bm} (\{rev})"
        None => rev
      }
    }
    None =>
      match sh(cwd, "git", ["branch", "--show-current"]) {
        Some(b) if b != "" => b
        _ =>
          match sh(cwd, "git", ["rev-parse", "--short", "HEAD"]) {
            Some(h) => h
            None => "?"
          }
      }
  }
}

///|
/// Retrieve the OAuth access token: macOS Keychain first, then a
/// `<config_dir>/.credentials.json` file fallback.
async fn get_token(config_dir : String?, home : String) -> String? {
  let service = @sl.keychain_service(config_dir, home)
  match sh(".", "security", ["find-generic-password", "-s", service, "-w"]) {
    Some(creds) =>
      match @sl.parse_token_creds(creds) {
        Some(t) => return Some(t)
        None => ()
      }
    None => ()
  }
  // File fallback (non-macOS or empty keychain).
  let dir = config_dir.unwrap_or(home + "/.claude")
  let contents = @fs.read_file_to_string(dir + "/.credentials.json") catch {
    _ => return None
  }
  @sl.parse_token_creds(contents)
}

///|
/// True when the cache file exists and is younger than 360 seconds.
async fn cache_fresh(path : String) -> Bool {
  let (mtime_sec, _ns) = @afs.mtime(path) catch { _ => return false }
  let now_ms = @async.now()
  now_ms - mtime_sec * 1000L < 360000L
}

///|
/// Read and parse the cache file, or an empty object on any failure.
fn read_cache(path : String) -> Json {
  let s = @fs.read_file_to_string(path) catch { _ => return empty_json() }
  @json.parse(s) catch {
    _ => empty_json()
  }
}

///|
/// Write `content` to the cache file, ignoring IO errors.
fn write_cache(path : String, content : String) -> Unit {
  @fs.write_string_to_file(path, content) catch {
    _ => ()
  }
}

///|
/// Call the OAuth usage API with a 5s timeout. On a 200 with a `five_hour`
/// field, cache and return the body; otherwise cache "{}" and return empty.
async fn call_api(token : String, cache_path : String) -> Json {
  let headers = {
    "Authorization": "Bearer " + token,
    "anthropic-beta": "oauth-2025-04-20",
    "Content-Type": "application/json",
  }
  let (status, body) = @async.with_timeout(5000, () => {
    @http.get("https://api.anthropic.com/api/oauth/usage", headers~)
  })
  if status.code != 200 {
    write_cache(cache_path, "{}")
    return empty_json()
  }
  let text = body.text()
  let json = @json.parse(text)
  match json {
    { "five_hour": _, .. } => {
      write_cache(cache_path, text)
      json
    }
    _ => {
      write_cache(cache_path, "{}")
      empty_json()
    }
  }
}

///|
/// Usage data: fresh cache, else fetch via token, else stale cache.
async fn fetch_usage(
  config_dir : String?,
  home : String,
  user : String,
) -> Json {
  let cache_path = @sl.cache_file_path(user, config_dir, home)
  if cache_fresh(cache_path) {
    return read_cache(cache_path)
  }
  match get_token(config_dir, home) {
    Some(token) =>
      // On an API exception (timeout / connection / parse error), cache "{}"
      // so the failure is remembered for 360s instead of retrying — with its
      // 5s timeout — on every render.
      call_api(token, cache_path) catch {
        _ => {
          write_cache(cache_path, "{}")
          empty_json()
        }
      }
    None => read_cache(cache_path)
  }
}
