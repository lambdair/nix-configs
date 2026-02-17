export def compare-output [cmd1: closure, cmd2: closure] {
  let temp1 = (mktemp)
  let temp2 = (mktemp)
  do $cmd1 | to text | save -f $temp1
  do $cmd2 | to text | save -f $temp2
  ^delta $temp1 $temp2

  rm $temp1 $temp2
}
