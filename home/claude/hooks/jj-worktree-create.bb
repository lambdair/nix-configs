#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :as p]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

(load-file (str (fs/parent *file*) "/lib.bb"))

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

(defn sh [& args] (apply sh-in cwd args))

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

;; === Clear the way for this worktree ===
;; A directory can outlive its workspace and a workspace can outlive its
;; directory, and either leftover makes `jj workspace add` fail. Both halves
;; only touch the worktree being created: the other directories under
;; .claude/worktrees belong to other jobs, and some of them are clones this
;; hook never registered, whose commits exist nowhere else.

(defn added-workspace-of-repo?
  "Whether `dir` is an added workspace of this repo, which is the only kind of
   directory that can be deleted without losing commits: its store is the one
   this repo uses. `.jj/repo` is the store directory itself in a clone and a
   file naming the store, relative to `.jj`, in an added workspace."
  [dir]
  (let [repo (fs/path dir ".jj" "repo")]
    (and (fs/exists? repo)
         (fs/regular-file? repo)
         (= (str (fs/real-path (fs/path repo-root ".jj" "repo")))
            (str (fs/real-path (fs/path dir ".jj" (str/trim (slurp (str repo))))))))))

(let [workspace-list (or (sh "jj" "workspace" "list") "")
      active-names (->> (str/split-lines workspace-list)
                        (keep #(second (re-find #"^(\S+):" %)))
                        set)
      registered? (contains? active-names workspace-name)]
  ;; Directory left behind by a workspace that is no longer registered.
  (when (and (fs/exists? worktree-path)
             (not registered?)
             (added-workspace-of-repo? worktree-path))
    (binding [*out* *err*]
      (println (str "Removing leftover workspace directory: " worktree-path)))
    (fs/delete-tree worktree-path))

  ;; Workspace registered without its directory, which would make an add under
  ;; the same name be rejected as already existing.
  (when (and registered? (not (fs/exists? worktree-path)))
    (binding [*out* *err*]
      (println (str "Forgetting orphaned workspace: " workspace-name)))
    (sh "jj" "workspace" "forget" workspace-name)))

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
