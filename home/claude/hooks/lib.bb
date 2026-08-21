#!/usr/bin/env bb
;; Helpers shared by the hooks in this directory. Each hook loads this file via
;; a path derived from its own *file*, which babashka reports as the invoked
;; path rather than the store target, so the lookup stays inside the deployed
;; hooks directory and no home path is baked in.

(require '[babashka.process :as p]
         '[babashka.fs :as fs]
         '[cheshire.core :as json]
         '[clojure.string :as str])

(defn sh-in
  "Run `args` with `dir` as the working directory. Returns trimmed stdout on
   exit 0, nil on a non-zero exit or a failure to spawn."
  [dir & args]
  (try
    (let [result (apply p/shell {:out :string :err :string :dir dir} args)]
      (when (zero? (:exit result))
        (str/trim (:out result))))
    (catch Exception _ nil)))

(defn changed-lines
  "Total insertions + deletions reported by `jj diff --stat`, 0 when there is
   no summary. The summary is the last line — \"N files changed, X
   insertion(s)(+), Y deletion(s)(-)\" — whose leading file count is dropped."
  [stat]
  (let [last-line (last (str/split-lines (or stat "")))
        nums (re-seq #"\d+" (or last-line ""))]
    (if (and nums (>= (count nums) 2))
      (reduce + (map #(Long/parseLong %) (rest nums)))
      0)))

;; === Self-review record ===
;; A revision counts as reviewed when the record holds the hash its diff has
;; now, so a rebase keeps the entry while an edit to the content drops it.

(def record-name "claude-self-review.json")

(defn sha256 [s]
  (->> (.getBytes (or s "") "UTF-8")
       (.digest (java.security.MessageDigest/getInstance "SHA-256"))
       (map #(format "%02x" %))
       (str/join)))

(defn record-path
  "Where `root`'s record lives. `.jj/repo` is the store directory in the main
   workspace and a file naming it, relative to `.jj`, in an added one;
   resolving it keeps every workspace of a repo on one record."
  [root]
  (let [repo (fs/path root ".jj" "repo")]
    (when (fs/exists? repo)
      (let [store (if (fs/directory? repo)
                    (fs/real-path repo)
                    (fs/normalize (fs/path root ".jj" (str/trim (slurp (str repo))))))]
        (str (fs/path store record-name))))))

(defn read-record
  "The record as a map of change id to entry, empty when there is none."
  [root]
  (let [path (record-path root)]
    (if (and path (fs/exists? path))
      (try (json/parse-string (slurp path)) (catch Exception _ {}))
      {})))

(defn diff-hash [dir change-id]
  (some-> (sh-in dir "jj" "diff" "--no-pager" "--git" "-r" change-id) sha256))

(defn reviewed?
  "Whether `record` covers `change-id` as it currently stands."
  [record dir change-id]
  (and (get-in record [change-id "diff"])
       (= (get-in record [change-id "diff"]) (diff-hash dir change-id))))

;; === Worktree hooks ===

(defn worktree-config
  "Per-repository worktree settings from `<root>/.claude/worktree.json`. A
   missing file, a missing key or unreadable JSON means the workspace lane and
   no symlinks, so a repository that declares nothing needs no file."
  [root]
  (let [path (str (fs/path root ".claude" "worktree.json"))
        raw (if (fs/exists? path)
              (try (json/parse-string (slurp path)) (catch Exception _ {}))
              {})]
    {:default-lane (if (= "clone" (get raw "defaultLane")) :clone :workspace)
     :symlink-dirs (vec (get raw "symlinkDirectories"))}))

(defn sidecar-path
  "Where the record for the worktree at `worktree-path` lives: a sibling of the
   directory, so no working copy snapshots it into a revision."
  [worktree-path]
  (str worktree-path ".json"))

(defn write-sidecar!
  "Record what was built at `worktree-path`. `m` carries \"lane\" and, for the
   workspace lane, the \"workspace\" name to forget on removal."
  [worktree-path m]
  (spit (sidecar-path worktree-path) (json/generate-string m)))

(defn read-sidecar
  "The record for `worktree-path`, or nil when there is none to trust."
  [worktree-path]
  (let [path (sidecar-path worktree-path)]
    (when (fs/exists? path)
      (try (json/parse-string (slurp path)) (catch Exception _ nil)))))
