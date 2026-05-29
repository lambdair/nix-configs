final: prev: {
  # macOS Tahoe (Darwin 25) SDK で emacs 30.2 の Objective-C コンパイルが失敗するワークアラウンド。
  # configure.ac は ObjC が C99 未満のとき GNU_OBJC_CFLAGS に -std=c99 を追加するが、
  # lisp.h / conf_post.h は alignof / bool を `<stdalign.h>` / `<stdbool.h>` 無しで使うため
  # C23 (-std=gnu23) でないとコンパイルできない。
  emacs-unstable = prev.emacs-unstable.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace configure.ac \
        --replace-fail \
          'GNU_OBJC_CFLAGS="$GNU_OBJC_CFLAGS -std=c99"' \
          'GNU_OBJC_CFLAGS="$GNU_OBJC_CFLAGS -std=gnu23"'
    '';
  });
}
