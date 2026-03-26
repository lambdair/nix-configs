#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :as p]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))

(def worktree-path (:worktree_path input))
(def worktree-name (:name input))
(def cwd (:cwd input))

;; Determine workspace name
(def workspace-name (when worktree-name (str "claude-" worktree-name)))

;; Use cwd to run jj root, fall back to deriving from worktree path structure
(def repo-root
  (or (try
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
