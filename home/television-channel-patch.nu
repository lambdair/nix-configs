# Merge a patch into one of television's built-in channel definitions.
#
# The built-in definitions live in television's source tree. Reading them from
# there leaves the source and preview commands owned by upstream, so a
# television update carries its own changes along.

def main [upstream: string, patch: string, out: string] {
  open --raw $upstream
  | from toml
  | merge deep (open --raw $patch | from json)
  | to toml
  | save --force $out
}
