#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :as p]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))

(def worktree-name (:name input))
(def cwd (:cwd input))

;; === Validate worktree name ===
(when (or (nil? worktree-name)
          (str/blank? worktree-name)
          (str/includes? worktree-name "/")
          (str/includes? worktree-name ".."))
  (binding [*out* *err*]
    (println "Invalid worktree name"))
  (System/exit 1))

;; === Shell helper ===
(defn sh [& args]
  (try
    (let [result (apply p/shell {:out :string :err :string :dir cwd} args)]
      (when (zero? (:exit result))
        (str/trim (:out result))))
    (catch Exception _ nil)))

;; === Get repo root ===
(def repo-root (sh "jj" "root"))
(when-not repo-root
  (binding [*out* *err*]
    (println "Not a jj repository"))
  (System/exit 1))

;; === Determine worktree path ===
(def worktrees-dir (str repo-root "/.claude/worktrees"))
(def worktree-path (str worktrees-dir "/" worktree-name))
(def workspace-name (str "claude-" worktree-name))

;; === Cleanup stale workspaces ===
;; The two halves are independent: a directory can outlive its workspace and a
;; workspace can outlive its directory, and neither is visible from the other
;; side's listing.
(let [workspace-list (or (sh "jj" "workspace" "list") "")
      active-names (->> (str/split-lines workspace-list)
                        (keep #(second (re-find #"^(\S+):" %)))
                        set)]
  ;; Directory whose workspace is gone → delete the directory.
  (when (fs/exists? worktrees-dir)
    (doseq [dir (fs/list-dir worktrees-dir)
            :let [dir-name (str (fs/file-name dir))]
            :when (not (contains? active-names (str "claude-" dir-name)))]
      (binding [*out* *err*]
        (println (str "Cleaning up stale worktree: " dir-name)))
      (fs/delete-tree dir)))

  ;; Workspace whose directory is gone → forget the workspace, so a later add
  ;; under the same name is not rejected as already existing.
  (doseq [ws-name active-names
          :when (str/starts-with? ws-name "claude-")
          :let [dir (str worktrees-dir "/" (subs ws-name (count "claude-")))]
          :when (not (fs/exists? dir))]
    (binding [*out* *err*]
      (println (str "Forgetting orphaned workspace: " ws-name)))
    (sh "jj" "workspace" "forget" ws-name)))

;; === Create workspace ===
(fs/create-dirs worktrees-dir)

(let [result (p/shell {:out :string :err :string :dir repo-root}
                      "jj" "workspace" "add" worktree-path "--name" workspace-name)]
  (when-not (zero? (:exit result))
    (binding [*out* *err*]
      (println (str "Failed to create workspace: " (str/trim (:err result)))))
    (System/exit 1)))

;; === Output absolute path (stdout) ===
(println worktree-path)
