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
  (let [r (p/shell {:in (json/generate-string input)
                    :out :string :err :string :continue true}
                   "bb" (str hooks-dir "/" hook))]
    {:exit (:exit r) :out (str/trim (:out r)) :err (:err r)}))

(defn git! [dir & args]
  (apply p/shell {:dir dir :out :string :err :string
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
    (p/shell {:dir source :out :string :err :string} "jj" "git" "init" "--colocate")
    ;; jj reports the root as a realpath, which on macOS differs from the temp
    ;; directory's /var symlink; canonicalize so path assertions compare equal.
    (str (fs/real-path source))))

(defn workspace-names [root]
  (->> (:out (p/shell {:dir root :out :string :err :string} "jj" "workspace" "list"))
       str/split-lines
       (keep #(second (re-find #"^(\S+):" %)))
       set))

(t/deftest create-adds-a-jj-workspace-and-prints-its-path
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)
          {:keys [exit out]} (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})
          expected (str source "/.claude/worktrees/job")]
      (t/is (zero? exit))
      (t/is (= expected out))
      (t/is (fs/directory? expected))
      (t/is (contains? (workspace-names source) "claude-job")))))

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
        (let [status (:out (p/shell {:dir source :out :string :err :string} "jj" "status"))]
          (t/is (not (str/includes? status ".claude/worktrees"))
                "neither the worktree nor its sidecar reaches the source's @"))))))

(t/deftest create-recovers-a-directory-whose-workspace-was-forgotten
  (fs/with-temp-dir [dir {}]
    (let [source (make-repo! dir)]
      (run-hook "jj-worktree-create.bb" {:name "job" :cwd source})
      (p/shell {:dir source :out :string :err :string}
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

(let [{:keys [fail error]} (t/run-tests 'user)]
  (System/exit (if (zero? (+ fail error)) 0 1)))
