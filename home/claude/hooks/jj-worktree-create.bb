#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

(load-file (str (fs/parent *file*) "/lib.bb"))

(defn valid-name?
  "A worktree name must not escape the worktrees directory."
  [n]
  (and n
       (not (str/blank? n))
       (not (str/includes? n "/"))
       (not (str/includes? n ".."))))

(defn clear-the-way!
  "Remove the leftovers that would make the build fail, touching only the
   worktree being created. A directory that is neither an added workspace of
   this repo nor empty fails the run untouched: its commits may live in no
   other store."
  [repo-root worktree-path workspace-name]
  (let [registered? (contains? (->> (or (sh-in repo-root "jj" "workspace" "list") "")
                                    str/split-lines
                                    (keep #(second (re-find #"^(\S+):" %)))
                                    set)
                               workspace-name)]
    (when (and (fs/exists? worktree-path) (not registered?))
      (cond
        (added-workspace-of-repo? repo-root worktree-path)
        (do (binding [*out* *err*]
              (println (str "Removing leftover workspace directory: " worktree-path)))
            (fs/delete-tree worktree-path))

        (empty? (fs/list-dir worktree-path))
        (fs/delete-tree worktree-path)

        :else
        (die! (str "Refusing to replace a directory this hook did not create: "
                   worktree-path
                   "\nInspect it and remove it by hand once its commits are safe."))))
    (when (and registered? (not (fs/exists? worktree-path)))
      (binding [*out* *err*]
        (println (str "Forgetting orphaned workspace: " workspace-name)))
      (sh-in repo-root "jj" "workspace" "forget" workspace-name))))

(defn -main []
  (let [input (json/parse-string (slurp *in*) true)
        wt-name (:name input)
        cwd (:cwd input)]
    (when-not (valid-name? wt-name)
      (die! "Invalid worktree name"))
    (let [repo-root (or (sh-in cwd "jj" "root") (die! "Not a jj repository"))
          worktree-path (str repo-root "/.claude/worktrees/" wt-name)
          workspace-name (str "claude-" wt-name)]
      (clear-the-way! repo-root worktree-path workspace-name)
      (fs/create-dirs (fs/parent worktree-path))
      (sh-in! repo-root "jj" "workspace" "add" worktree-path "--name" workspace-name)
      (write-sidecar! worktree-path {"lane" "workspace" "workspace" workspace-name})
      (println worktree-path))))

(when (= *file* (System/getProperty "babashka.file"))
  (-main))
