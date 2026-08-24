#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

(load-file (str (fs/parent *file*) "/lib.bb"))

(defn ours?
  "Whether `dest` is a worktree this hook may delete: one named directory under
   a `.claude/worktrees/`, never the repository itself. The path test is the
   guard against a malformed event taking more than the job it names."
  [dest repo-root]
  (boolean (and dest repo-root
                (not= dest repo-root)
                (re-find #"/\.claude/worktrees/[^/]+/?$" dest))))

(defn workspace-to-forget
  "The workspace `dest` registered, or nil when it registered none. The sidecar
   is authoritative; the store check covers worktrees created before there were
   sidecars."
  [repo-root dest]
  (if-let [record (read-sidecar dest)]
    (get record "workspace")
    (when (added-workspace-of-repo? repo-root dest)
      (str "claude-" (fs/file-name dest)))))

(defn -main []
  (let [input (json/parse-string (slurp *in*) true)
        dest (:worktree_path input)
        cwd (:cwd input)
        repo-root (or (:git_repo_path input)
                      (sh-in cwd "jj" "root")
                      (some-> dest fs/parent fs/parent fs/parent str))]
    (if-not (ours? dest repo-root)
      (binding [*out* *err*]
        (println (str "Not a worktree this hook allocated, leaving it alone: " dest)))
      (do
        (when-let [workspace (workspace-to-forget repo-root dest)]
          (when-not (sh-in repo-root "jj" "workspace" "forget" workspace)
            (binding [*out* *err*]
              (println (str "Warning: failed to forget workspace " workspace)))))
        (when (fs/exists? dest) (fs/delete-tree dest))
        (fs/delete-if-exists (sidecar-path dest))))))

(when (= *file* (System/getProperty "babashka.file"))
  (-main))
