# Personal Development Preferences

## Version Control

I use jujutsu (jj) instead of git for version control. When working with version control:

- Use `jj` commands instead of `git` commands
- `jj status` instead of `git status`
- `jj diff --git` instead of `git diff`
- `jj log` instead of `git log`
- `jj new` / `jj commit` instead of `git commit`
- `jj describe` to edit commit messages
- `jj git push` instead of `git push`

**IMPORTANT**: Never run `jj git push` without explicit user permission. Always ask before pushing to remote.

**IMPORTANT**: リビジョンはレビューしやすいように、なるべく細かく分割すること。一つのリビジョンには一つの論理的な変更のみを含める。

**IMPORTANT**: 修正を行う際は、明確な指示がない限り `jj edit` で過去のリビジョンを編集する形で行う。ただし、構造が大きく変わる場合は実行前に確認を取ること。

## Revision Notation

- `r:xxx` or `rev:xxx` - indicates a jj revision
- Examples: `r:abc123`, `rev:@-`, `r:main`

For reference: https://github.com/jj-vcs/jj
