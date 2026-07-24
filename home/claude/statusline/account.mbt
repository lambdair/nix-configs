///|
/// First 8 hex chars of the SHA-256 of `s` (UTF-8), used to derive
/// account-aware names.
pub fn sha8(s : String) -> String {
  let digest = @crypto.sha256(@utf8.encode(s))
  @crypto.bytes_to_hex_string(digest)[0:8].to_owned()
}

///|
/// Hex-encode the UTF-8 bytes of `s`. Inverse of the hex-decode fallback;
/// exposed for tests.
pub fn to_hex_utf8(s : String) -> String {
  @crypto.bytes_to_hex_string(@utf8.encode(s))
}

///|
/// The default config dir for a given home directory.
fn default_config_dir(home : String) -> String {
  home + "/.claude"
}

///|
/// macOS Keychain service name for the credentials. When `CLAUDE_CONFIG_DIR`
/// is set and differs from the default, the name is salted with a hash of that
/// dir so multiple accounts do not collide.
pub fn keychain_service(config_dir : String?, home : String) -> String {
  match config_dir {
    Some(cd) if cd != default_config_dir(home) =>
      "Claude Code-credentials-" + sha8(cd)
    _ => "Claude Code-credentials"
  }
}

///|
/// Path of the rate-limit usage cache file, account-aware like the keychain
/// service name.
pub fn cache_file_path(
  user : String,
  config_dir : String?,
  home : String,
) -> String {
  let base = "/tmp/claude-usage-cache-" + user
  let salted = match config_dir {
    Some(cd) if cd != default_config_dir(home) => base + "-" + sha8(cd)
    _ => base
  }
  salted + ".json"
}

///|
/// Extract `claudeAiOauth.accessToken` from a parsed credentials JSON value.
fn token_from_json(json : Json) -> String? {
  match json {
    { "claudeAiOauth": { "accessToken": String(t), .. }, .. } => Some(t)
    _ => None
  }
}

///|
/// Parse credentials returned by `security find-generic-password -w`.
/// Tries JSON first, then a hex-decode fallback (macOS stores some blobs as
/// hex).
pub fn parse_token_creds(creds : String) -> String? {
  let trimmed = creds.trim(chars="\n \r\t").to_owned()
  // Fast path: the value is JSON.
  let from_json = token_from_json(@json.parse(trimmed)) catch { _ => None }
  match from_json {
    Some(t) => Some(t)
    // Fallback: the value is hex-encoded JSON.
    None =>
      match hex_decode_to_string(trimmed) {
        Some(decoded) =>
          match extract_brace_object(decoded) {
            Some(obj) =>
              try {
                match @json.parse(obj) {
                  { "accessToken": String(t), .. } => Some(t)
                  _ => None
                }
              } catch {
                _ => None
              }
            None => None
          }
        None => None
      }
  }
}

///|
/// Decode a hex string to its UTF-8 text, or None if it is not valid hex.
fn hex_decode_to_string(s : String) -> String? {
  if s.length() % 2 != 0 || s.length() == 0 {
    return None
  }
  let bytes : Array[Byte] = []
  let mut i = 0
  while i < s.length() {
    let hi = hex_val(s[i])
    let lo = hex_val(s[i + 1])
    match (hi, lo) {
      (Some(h), Some(l)) => bytes.push((h * 16 + l).to_byte())
      _ => return None
    }
    i = i + 2
  }
  Some(@utf8.decode(Bytes::from_array(bytes))) catch {
    _ => None
  }
}

///|
/// Hex digit value for a UTF-16 code unit, or None if not a hex digit.
fn hex_val(code : UInt16) -> Int? {
  let c = code.to_int()
  if c >= '0'.to_int() && c <= '9'.to_int() {
    Some(c - '0'.to_int())
  } else if c >= 'a'.to_int() && c <= 'f'.to_int() {
    Some(c - 'a'.to_int() + 10)
  } else if c >= 'A'.to_int() && c <= 'F'.to_int() {
    Some(c - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
/// Return the first `{...}` substring (inclusive) of `s`, or None.
fn extract_brace_object(s : String) -> String? {
  let start = find_char(s, '{', 0)
  match start {
    Some(i) =>
      match find_char(s, '}', i) {
        Some(j) => Some(s[i:j + 1].to_owned())
        None => None
      }
    None => None
  }
}

///|
/// Index of the first `target` at or after `from`, or None.
fn find_char(s : String, target : Char, from : Int) -> Int? {
  for i in from..<s.length() {
    if s[i].to_int() == target.to_int() {
      return Some(i)
    }
  }
  None
}
