# Downloads the reference images, measures every region in regions.csv and
# draws the regions onto copies of the images. The images are not committed, so
# this is how to see where each colour was taken from.
#
#   nix shell nixpkgs#imagemagick nixpkgs#nushell -c nu flower-theme/sources/annotate.nu <out-dir>
#
# A region is a w×h box centred on (x, y); its colour is the most frequent of
# `colors` colours after ImageMagick reduces the box to that many.
def main [out: path] {
  let here = ($env.FILE_PWD)
  let images = (open $"($here)/images.csv")
  let regions = (open $"($here)/regions.csv")
  mkdir $"($out)/images" $"($out)/annotated"

  for i in $images {
    let file = $"($out)/images/($i.file)"
    if not ($file | path exists) { http get --raw $i.url | save $file }
  }

  let measured = ($regions | par-each {|r|
    let x0 = $r.x - ($r.w / 2 | math floor)
    let y0 = $r.y - ($r.h / 2 | math floor)
    let clusters = (^magick $"($out)/images/($r.image)" -crop $"($r.w)x($r.h)+($x0)+($y0)" +repage -colors $r.colors -depth 8 -format "%c" histogram:info:-
      | lines
      | parse -r '^\s*(?<n>\d+):.*?(?<hex>#[0-9A-Fa-f]{6})'
      | update n { into int }
      | update hex { str uppercase }
      | sort-by n hex -r)
    $r
    | insert now $clusters.0.hex
    | insert share (100 * $clusters.0.n / ($clusters.n | math sum) | math round)
    | insert clusters ($clusters | each {|c| $"($c.hex):($c.n)" } | str join " ")
  })

  for g in ($measured | group-by image | transpose image rs) {
    let draws = ($g.rs | each {|r|
      let x0 = $r.x - ($r.w / 2 | math floor)
      let y0 = $r.y - ($r.h / 2 | math floor)
      [-stroke "#ff00ff" -strokewidth 3 -fill none -draw $"rectangle ($x0),($y0) ($x0 + ([$r.w 12] | math max)),($y0 + ([$r.h 12] | math max))"
       -stroke none -fill "#ff00ff" -undercolor "#000000a0" -pointsize 18 -annotate $"+($x0 + $r.w + 4)+($y0 + 14)" $"($r.label) ($r.now)"]
    } | flatten)
    ^magick $"($out)/images/($g.image)" ...$draws $"($out)/annotated/($g.image | path parse | get stem).png"
  }

  $measured | sort-by image label | save -f $"($out)/measured.csv"
  $measured | where {|r| $r.recorded != $r.now } | select image label recorded now clusters
}
