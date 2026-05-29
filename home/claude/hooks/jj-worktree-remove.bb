#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :as p]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))

(def worktree-path (:worktree_path input))
(def cwd (:cwd input))

;; WorktreeRemove does not provide a `name` field, so derive the workspace
;; name from the worktree directory basename. The create hook names the
;; workspace "claude-<basename>", so this stays consistent with it.
(def workspace-name
  (some->> worktree-path fs/file-name str (str "claude-")))

;; repo root: prefer git_repo_path, then `jj root` from cwd, then derive
;; from the worktree path structure (.../.claude/worktrees/<name>)
(def repo-root
  (or (:git_repo_path input)
      (try
        (let [result (p/shell {:out :string :err :string :dir cwd}
                              "jj" "root")]
          (when (zero? (:exit result))
            (str/trim (:out result))))
        (catch Exception _ nil))
      (some-> worktree-path fs/parent fs/parent fs/parent str)))

(defn sh [& args]
  (try
    (let [result (apply p/shell {:out :string :err :string :dir repo-root} args)]
      (when (zero? (:exit result))
        (str/trim (:out result))))
    (catch Exception e
      (binding [*out* *err*]
        (println (str "Command failed: " (.getMessage e))))
      nil)))

;; === Forget workspace ===
(when (and workspace-name repo-root)
  (let [result (sh "jj" "workspace" "forget" workspace-name)]
    (when-not result
      (binding [*out* *err*]
        (println (str "Warning: failed to forget workspace " workspace-name))))))

;; === Remove directory ===
(when (and worktree-path (fs/exists? worktree-path))
  (fs/delete-tree worktree-path))
