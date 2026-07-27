#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :as p]
         '[clojure.string :as str])

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))

(def cwd (get input :cwd "."))
(def file-path (get-in input [:tool_input :file_path]))

;; Early exit if no file path
(when-not file-path (System/exit 0))

;; === Shell helper ===
(defn sh [& args]
  (try
    (let [result (apply p/shell {:out :string :err :string :dir cwd} args)]
      (when (zero? (:exit result))
        (str/trim (:out result))))
    (catch Exception _ nil)))

;; jj repo check
(when-not (sh "jj" "root" "--quiet") (System/exit 0))

;; Get current revision state
(def desc (or (sh "jj" "log" "--no-pager" "-r" "@" "--no-graph" "-T" "description") ""))
(def stat (or (sh "jj" "diff" "--stat" "--no-pager") ""))

;; No changes yet → no context needed
(when (str/blank? stat) (System/exit 0))

;; Extract total changed lines from stat summary (last line: "N file(s) changed, X insertion(s), Y deletion(s)")
(def total-lines
  (let [last-line (last (str/split-lines stat))
        nums (re-seq #"\d+" (or last-line ""))]
    (if (and nums (>= (count nums) 2))
      (reduce + (map #(Long/parseLong %) (rest nums)))
      0)))

(def line-warning
  (when (> total-lines 150)
    (str "\n⚠ 変更行数が " total-lines " 行です（目安: 150行以下）。意味のある単位で分割できないか検討してください。")))

;; Output additionalContext
(println
  (json/generate-string
    {:hookSpecificOutput
     {:hookEventName "PreToolUse"
      :additionalContext
      (str "【リビジョン規律チェック】\n"
           "現在のリビジョンの目的: " (if (str/blank? desc) "(未設定)" desc) "\n"
           "現在の変更:\n" stat "\n"
           "これから編集: " file-path "\n"
           "→ この編集が現在のリビジョンと無関係なら、先に `jj new -m \"目的\"` で新しいリビジョンを作ること。"
           (or line-warning ""))}}))
