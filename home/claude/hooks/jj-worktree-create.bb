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
(when (fs/exists? worktrees-dir)
  (let [workspace-list (or (sh "jj" "workspace" "list") "")
        active-names (->> (str/split-lines workspace-list)
                          (keep #(second (re-find #"^(\S+):" %)))
                          set)]
    (doseq [dir (fs/list-dir worktrees-dir)]
      (let [dir-name (str (fs/file-name dir))
            ws-name (str "claude-" dir-name)]
        (cond
          (not (contains? active-names ws-name))
          (do
            (binding [*out* *err*]
              (println (str "Cleaning up stale worktree: " dir-name)))
            (fs/delete-tree dir))

          (not (fs/exists? dir))
          (do
            (binding [*out* *err*]
              (println (str "Forgetting orphaned workspace: " ws-name)))
            (sh "jj" "workspace" "forget" ws-name)))))))

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
