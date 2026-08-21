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

(let [{:keys [fail error]} (t/run-tests 'user)]
  (System/exit (if (zero? (+ fail error)) 0 1)))
