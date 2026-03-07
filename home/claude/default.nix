{ config, ... }:
{
  programs.claude-code = {
    enable = true;
    memory.source = ./CLAUDE.md;
    settings = {
      permissions.allow = [
        "Bash(jj:*)"
        "Glob"
        "Grep"
        "Read"
        "WebFetch"
        "WebSearch"
        "LSP"
      ];
      enabledPlugins = {
        "context7@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "claude-mem@thedotmack" = true;
      };
      statusLine = {
        type = "command";
        command = "bb ${config.home.homeDirectory}/.claude/statusline-command.bb";
      };
      alwaysThinkingEnabled = true;

      hooks = {
        PreToolUse = [
          {
            matcher = "Edit|Write";
            hooks = [
              {
                type = "command";
                command = "bb ${config.home.homeDirectory}/.claude/hooks/revision-context.bb";
                timeout = 10;
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "prompt";
                prompt = ''
                  あなたはリビジョン規律チェッカーです。jujutsu (jj) を使ったワークフローで、各リビジョンが1つの論理変更のみを含んでいるか確認してください。

                  以下のトランスクリプトを確認し:
                  $ARGUMENTS

                  判断基準:
                  - 1リビジョンに1つの論理変更のみ含まれているか
                  - 無関係な変更（異なる機能、異なるバグ、ついでの改善）が混入していないか
                  - レビュアーが各リビジョンを独立して理解できるか

                  問題がある場合: {"decision": "block", "reason": "【リビジョン規律違反】<具体的に何が問題で、どう分割すべきか日本語で説明>"}
                  問題がない場合: {"decision": "allow"}
                '';
                model = "claude-haiku-4-5-20251001";
                timeout = 30;
              }
            ];
          }
        ];
      };
    };
  };

  home.file.".claude/statusline-command.bb" = {
    source = ./statusline-command.bb;
    executable = true;
  };

  home.file.".claude/hooks/revision-context.bb" = {
    source = ./hooks/revision-context.bb;
    executable = true;
  };

  home.file.".claude/rules/jj-workflow.md".source = ./jj-workflow.md;
  home.file.".claude/rules/coding-preferences.md".source = ./coding-preferences.md;
  home.file.".claude/rules/revision-discipline.md".source = ./revision-discipline.md;
}
