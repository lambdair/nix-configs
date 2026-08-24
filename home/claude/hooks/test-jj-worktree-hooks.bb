#!/usr/bin/env bb
;; Self-test for the jj worktree hooks. Run from the repo root:
;;   bb home/claude/hooks/test-jj-worktree-hooks.bb
(require '[clojure.test :as t]
         '[babashka.fs :as fs]
         '[babashka.process :as p]
         '[cheshire.core :as json]
         '[clojure.string :as str])

(def hooks-dir (str (fs/parent *file*)))
(load-file (str hooks-dir "/lib.bb"))
(load-file (str hooks-dir "/jj-worktree-create.bb"))

(def xdg-home
  "jj keeps repo-scoped config outside the repo, under XDG_CONFIG_HOME and keyed
   by the repo path. Every fixture repo would otherwise leave an entry in the
   user's own config that outlives the temp directory it names."
  (str (fs/create-temp-dir {:prefix "jj-worktree-hook-tests"})))

(defn sh
  "`babashka.process/shell` with the fixtures' own config home."
  [opts & args]
  (apply p/shell (update opts :extra-env merge {"XDG_CONFIG_HOME" xdg-home}) args))

(t/deftest worktree-config-defaults-to-the-workspace-lane
  (fs/with-temp-dir [root {}]
    (t/is (= {:default-lane :workspace :symlink-dirs []}
             (worktree-config (str root))))))

(t/deftest worktree-config-reads-lane-and-symlinks
  (fs/with-temp-dir [root {}]
    (fs/create-dirs (fs/path root ".claude"))
    (spit (str (fs/path root ".claude" "worktree.json"))
          (json/generate-string {"defaultLane" "clone"
                                 "symlinkDirectories" ["a/node_modules" ".devenv"]}))
    (t/is (= {:default-lane :clone :symlink-dirs ["a/node_modules" ".devenv"]}
             (worktree-config (str root))))))

(t/deftest worktree-config-survives-broken-json
  (fs/with-temp-dir [root {}]
    (fs/create-dirs (fs/path root ".claude"))
    (spit (str (fs/path root ".claude" "worktree.json")) "{ not json")
    (t/is (= {:default-lane :workspace :symlink-dirs []}
             (worktree-config (str root))))))

(t/deftest sidecar-sits-beside-the-worktree-not-inside-it
  (t/is (= "/r/.claude/worktrees/job.json" (sidecar-path "/r/.claude/worktrees/job"))))

(t/deftest sidecar-roundtrips
  (fs/with-temp-dir [dir {}]
    (let [wt (str (fs/path dir "job"))]
      (write-sidecar! wt {"lane" "workspace" "workspace" "claude-job"})
      (t/is (= {"lane" "workspace" "workspace" "claude-job"} (read-sidecar wt))))))

(t/deftest sidecar-is-nil-when-absent-or-broken
  (fs/with-temp-dir [dir {}]
    (let [wt (str (fs/path dir "job"))]
      (t/is (nil? (read-sidecar wt)))
      (spit (sidecar-path wt) "{ not json")
      (t/is (nil? (read-sidecar wt))))))

(defn run-hook
  "Drive `hook` through its real contract: `input` as stdin JSON."
  [hook input]
  (let [r (sh {:in (json/generate-string input)
               :out :string :err :string :continue true}
              "bb" (str hooks-dir "/" hook))]
    {:exit (:exit r) :out (str/trim (:out r)) :err (:err r)}))

(defn git! [dir & args]
  (apply sh {:dir dir :out :string :err :string
             :extra-env {"GIT_AUTHOR_NAME" "T" "GIT_AUTHOR_EMAIL" "t@example.com"
                         "GIT_COMMITTER_NAME" "T" "GIT_COMMITTER_EMAIL" "t@example.com"}}
         "git" args))

(defn make-repo!
  "A colocated jj repo at `<dir>/source` with a bare `origin` beside it and one
   commit on `master`, so `trunk()` resolves and the clone lane has a remote."
  [dir]
  (let [origin (str (fs/path dir "origin.git"))
        source (str (fs/path dir "source"))]
    (git! dir "init" "--bare" "-b" "master" origin)
    (git! dir "init" "-b" "master" source)
    (spit (str (fs/path source "README")) "fixture\n")
    (git! source "add" "README")
    (git! source "commit" "-m" "init")
    (git! source "remote" "add" "origin" origin)
    (git! source "push" "-u" "origin" "master")
    (sh {:dir source :out :string :err :string} "jj" "git" "init" "--colocate")
    ;; jj reports the root as a realpath, which on macOS differs from the temp
    ;; directory's /var symlink; canonicalize so path assertions compare equal.
    (str (fs/real-path source))))

(defn workspace-names [root]
  (->> (:out (sh {:dir root :out :string :err :string} "jj" "workspace" "list"))
       str/split-lines
       (keep #(second (re-find #"^(\S+):" %)))
       set))

(t/deftest trunk-bookmark-is-read-without-decoration
  (fs/with-temp-dir [dir {}]
    (t/is (= "master" (trunk-bookmark (make-repo! dir))))))

(t/deftest clone-lane-gets-its-own-store-and-the-configured-symlinks
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (fs/create-dirs (fs/path source ".claude"))
      (fs/create-dirs (fs/path source "deps"))
      (spit (str (fs/path source "deps" "marker")) "x")
      (spit (str (fs/path source ".claude" "worktree.json"))
            (json/generate-string {"defaultLane" "clone" "symlinkDirectories" ["deps"]}))
      (let [{:keys [exit out]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (zero? exit))
        (t/is (fs/directory? (fs/path out ".jj" "repo"))
              "a clone owns its store, so .jj/repo is a directory")
        (t/is (not (contains? (workspace-names source) "claude-job"))
              "a clone registers no workspace in the source repo")
        (t/is (fs/sym-link? (fs/path out "deps")))
        (t/is (= {"lane" "clone"} (read-sidecar out)))
        (t/is (str/includes? (:out (sh {:dir out :out :string :err :string}
                                       "jj" "log" "--no-graph" "-r" "@-" "-T" "bookmarks"))
                             "master")
              "the clone starts on the source's trunk, not on root()")))))

(defn forget-local-bookmark!
  "Leave `master` as a remote-only bookmark, the shape a repo has when its trunk
   is tracked by no local bookmark. `git clone --local` copies local branches
   only, so the name no longer crosses into a clone."
  [source]
  (sh {:dir source :out :string :err :string} "jj" "bookmark" "forget" "master"))

(t/deftest trunk-bookmark-falls-back-to-a-remote-only-bookmark
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (forget-local-bookmark! source)
      (t/is (= "master" (trunk-bookmark source))
            "a name is still read, so the failure downstream can name it"))))

(t/deftest clone-lane-fails-loudly-when-trunk-does-not-cross-into-the-clone
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (forget-local-bookmark! source)
      (fs/create-dirs (fs/path source ".claude"))
      (spit (str (fs/path source ".claude" "worktree.json"))
            (json/generate-string {"defaultLane" "clone"}))
      (let [{:keys [exit err]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (pos? exit) "a start revision the clone cannot resolve fails the run")
        (t/is (str/includes? err "master@origin")
              "the failure names the revision, rather than silently using root()")
        (t/is (nil? (read-sidecar (str source "/.claude/worktrees/job")))
              "nothing records a worktree that never started on trunk")))))

(t/deftest create-adds-a-jj-workspace-and-prints-its-path
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          {:keys [exit out]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})
          expected (str source "/.claude/worktrees/job")]
      (t/is (zero? exit))
      (t/is (= expected out))
      (t/is (fs/directory? expected))
      (t/is (contains? (workspace-names source) "claude-job")))))

(t/deftest workspace-lane-starts-on-trunk-rather-than-on-the-source-checkout
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (sh {:dir source :out :string :err :string} "jj" "describe" "-m" "wip")
      (sh {:dir source :out :string :err :string} "jj" "new")
      (let [{:keys [exit out]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (zero? exit))
        (t/is (str/includes? (:out (sh {:dir out :out :string :err :string}
                                       "jj" "log" "--no-graph" "-r" "@-" "-T" "bookmarks"))
                             "master")
              "the job starts on trunk, not on the work in progress beside it")))))

(t/deftest workspace-lane-keeps-the-default-start-when-trunk-is-the-root-commit
  (fs/with-temp-dir [dir {}]
    (let [source (str (fs/path dir "solo"))]
      (git! dir "init" "-b" "master" source)
      (spit (str (fs/path source "README")) "fixture\n")
      (git! source "add" "README")
      (git! source "commit" "-m" "init")
      (sh {:dir source :out :string :err :string} "jj" "git" "init" "--colocate")
      (let [{:keys [exit out]} (run-hook "jj-worktree-create.bb"
                                         {:name "job" :cwd (str (fs/real-path source))})]
        (t/is (zero? exit) "a repo whose trunk() is root() still gets a workspace")
        (t/is (fs/exists? (fs/path out "README"))
              "and it starts with the files, rather than on the empty root commit")))))

(t/deftest create-rejects-a-name-that-escapes-the-worktrees-directory
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (doseq [bad ["" "a/b" ".."]]
        (t/is (pos? (:exit (run-hook "jj-worktree-create.bb" {:name bad :cwd source}))))))))

(t/deftest sidecar-is-invisible-to-the-source-working-copy
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (spit (str (fs/path source ".gitignore")) ".claude/worktrees/\n")
      (let [{:keys [exit out]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (zero? exit))
        (t/is (fs/exists? (sidecar-path out)) "the sidecar was actually written")
        (let [status (:out (sh {:dir source :out :string :err :string} "jj" "status"))]
          (t/is (not (str/includes? status ".claude/worktrees"))
                "neither the worktree nor its sidecar reaches the source's @"))))))

(t/deftest create-recovers-a-directory-whose-workspace-was-forgotten
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})
      (sh {:dir source :out :string :err :string}
          "jj" "workspace" "forget" "claude-job")
      (let [{:keys [exit]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (zero? exit))
        (t/is (contains? (workspace-names source) "claude-job"))))))

(t/deftest create-recovers-a-workspace-whose-directory-is-gone
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          path (:out (run-hook "jj-worktree-create.bb" {:name "job" :cwd source}))]
      (fs/delete-tree path)
      (let [{:keys [exit]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (zero? exit))
        (t/is (fs/directory? path))))))

(t/deftest create-refuses-to-replace-a-foreign-directory
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          path (str source "/.claude/worktrees/job")]
      (fs/create-dirs path)
      (spit (str (fs/path path "someones-work")) "not ours")
      (let [{:keys [exit err]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (pos? exit))
        (t/is (str/includes? err "Refusing to replace")
              "the hook's own guard refuses, not jj's destination check")
        (t/is (fs/exists? (fs/path path "someones-work"))
              "a directory this hook did not create is never deleted")))))

(t/deftest create-reuses-an-empty-leftover-directory
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          path (str source "/.claude/worktrees/job")]
      (fs/create-dirs path)
      (let [{:keys [exit]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (zero? exit) "an empty directory has nothing to lose")
        (t/is (contains? (workspace-names source) "claude-job"))))))

(t/deftest create-refuses-a-foreign-directory-even-with-a-stale-sidecar
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          path (str source "/.claude/worktrees/job")]
      (fs/create-dirs path)
      (spit (str (fs/path path "someones-work")) "not ours")
      (write-sidecar! path {"lane" "workspace" "workspace" "claude-job"})
      (let [{:keys [exit err]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})]
        (t/is (pos? exit))
        (t/is (str/includes? err "Refusing to replace"))
        (t/is (fs/exists? (fs/path path "someones-work"))
              "a sidecar is a stale claim, not proof of what the directory is now")))))

(t/deftest sentinel-forces-the-workspace-lane-for-exactly-one-job
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (fs/create-dirs (fs/path source ".claude"))
      (spit (str (fs/path source ".claude" "worktree.json"))
            (json/generate-string {"defaultLane" "clone"}))
      (spit (str (fs/path source ".claude" ".bg-stack")) "")
      (run-hook "jj-worktree-create.bb" {:name "first" :cwd source})
      (t/is (contains? (workspace-names source) "claude-first")
            "the armed job takes the workspace lane")
      (t/is (not (fs/exists? (fs/path source ".claude" ".bg-stack")))
            "the sentinel is consumed")
      (run-hook "jj-worktree-create.bb" {:name "second" :cwd source})
      (t/is (not (contains? (workspace-names source) "claude-second"))
            "the next job reverts to the repository default"))))

(t/deftest remove-forgets-the-recorded-workspace-and-deletes-both-files
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          path (:out (run-hook "jj-worktree-create.bb" {:name "job" :cwd source}))]
      (run-hook "jj-worktree-remove.bb" {:worktree_path path :cwd source})
      (t/is (not (contains? (workspace-names source) "claude-job")))
      (t/is (not (fs/exists? path)))
      (t/is (not (fs/exists? (sidecar-path path)))
            "the sidecar goes with the worktree it recorded"))))

(t/deftest remove-deletes-a-clone-lane-tree-and-its-sidecar
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (fs/create-dirs (fs/path source ".claude"))
      (spit (str (fs/path source ".claude" "worktree.json"))
            (json/generate-string {"defaultLane" "clone"}))
      (let [path (:out (run-hook "jj-worktree-create.bb" {:name "job" :cwd source}))]
        (run-hook "jj-worktree-remove.bb" {:worktree_path path :cwd source})
        (t/is (not (fs/exists? path)))
        (t/is (not (fs/exists? (sidecar-path path))))))))

(t/deftest remove-forgets-nothing-for-a-worktree-that-registered-no-workspace
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          other (:out (run-hook "jj-worktree-create.bb" {:name "other" :cwd source}))
          path (str source "/.claude/worktrees/job")]
      ;; A clone-lane directory sharing its basename with a live workspace of
      ;; another job: deleting it must leave that workspace registered.
      (fs/create-dirs path)
      (write-sidecar! path {"lane" "clone"})
      (sh {:dir source :out :string :err :string}
          "jj" "workspace" "add" (str source "/.claude/worktrees/spare")
          "--name" "claude-job")
      (run-hook "jj-worktree-remove.bb" {:worktree_path path :cwd source})
      (t/is (contains? (workspace-names source) "claude-job")
            "a clone's removal never forgets a workspace of the same name")
      (t/is (fs/exists? other) "another job's worktree is untouched"))))

(t/deftest remove-refuses-a-path-that-names-no-single-worktree
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          worktrees (str source "/.claude/worktrees")]
      (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})
      (run-hook "jj-worktree-remove.bb" {:worktree_path source :cwd source})
      (t/is (fs/exists? source) "the repository itself is never deleted")
      (run-hook "jj-worktree-remove.bb" {:worktree_path (str worktrees "/") :cwd source})
      (t/is (fs/exists? (str worktrees "/job"))
            "nor does every job's worktree go with one malformed path")
      (run-hook "jj-worktree-remove.bb" {:worktree_path (str worktrees "/job/.jj") :cwd source})
      (t/is (fs/exists? (str worktrees "/job/.jj"))
            "nor a directory inside a worktree, which names no job at all"))))

(t/deftest remove-cleans-up-when-the-directory-is-already-gone
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          path (:out (run-hook "jj-worktree-create.bb" {:name "job" :cwd source}))]
      (fs/delete-tree path)
      (run-hook "jj-worktree-remove.bb" {:worktree_path path :cwd source})
      (t/is (not (contains? (workspace-names source) "claude-job"))
            "the workspace is forgotten even when its directory went first")
      (t/is (not (fs/exists? (sidecar-path path))) "no sidecar is left behind"))))

(let [{:keys [fail error]} (t/run-tests 'user)]
  (fs/delete-tree xdg-home)
  (System/exit (if (zero? (+ fail error)) 0 1)))
