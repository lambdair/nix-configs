{ ... }:

{
  programs.jujutsu.settings.revset-aliases = {
    # 自分の作業中 feature branch (= trunk に未マージの自分の bookmark)。
    # prefix 規約に依存せず、素のブランチ名のまま push して PR に使えるよう
    # 名前ではなく状態で検出する。mm() (megamerge 自身) は親候補から除外。
    "wip()" = ''bookmarks() & mine() ~ ::trunk() ~ mm()'';
    # 現在の megamerge リビジョン
    "mm()" = ''subject(exact:"megamerge") & mine() ~ ::trunk()'';
  };
}
