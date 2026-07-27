#!/usr/bin/env bb
;; Helpers shared by the hooks in this directory. Each hook loads this file via
;; a path derived from its own *file*, which babashka reports as the invoked
;; path rather than the store target, so the lookup stays inside the deployed
;; hooks directory and no home path is baked in.

(require '[babashka.process :as p]
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
