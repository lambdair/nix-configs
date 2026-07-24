///|
/// ANSI escape introducer.
let esc : String = "\u{1b}"

///|
/// 24-bit truecolor palette for the statusline.
pub let color_green : String = esc + "[38;2;151;201;195m" // 0-49%

///|
pub let color_yellow : String = esc + "[38;2;229;192;123m" // 50-79%

///|
pub let color_red : String = esc + "[38;2;224;108;117m" // 80-100%

///|
pub let color_grey : String = esc + "[38;2;74;88;92m" // delimiters

///|
pub let color_reset : String = esc + "[0m"

///|
/// Pick a color by percentage: >=80 red, >=50 yellow, else green.
pub fn color_for_pct(p : Int) -> String {
  if p >= 80 {
    color_red
  } else if p >= 50 {
    color_yellow
  } else {
    color_green
  }
}

///|
/// Clamp an integer into `[lo, hi]`.
fn clamp(x : Int, lo : Int, hi : Int) -> Int {
  if x < lo {
    lo
  } else if x > hi {
    hi
  } else {
    x
  }
}

///|
/// Render a 10-segment progress bar (▰ filled, ▱ empty) for percentage `p`.
/// Rounds to the nearest segment: filled = clamp((p + 5) / 10, 0, 10).
pub fn bar(p : Int) -> String {
  let filled = clamp((p + 5) / 10, 0, 10)
  let sb = StringBuilder::new()
  for _ in 0..<filled {
    sb.write_string("▰")
  }
  for _ in filled..<10 {
    sb.write_string("▱")
  }
  sb.to_string()
}

///|
/// Zero-pad an integer to at least two digits (for minutes).
pub fn pad2(n : Int) -> String {
  if n >= 0 && n < 10 {
    "0\{n}"
  } else {
    "\{n}"
  }
}

///|
/// Round a non-negative Double to the nearest Int (half up).
pub fn round_pct(x : Double) -> Int {
  (x + 0.5).to_int()
}
