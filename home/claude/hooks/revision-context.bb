#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

(load-file (str (fs/parent *file*) "/lib.bb"))

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))

(def cwd (get input :cwd "."))
(def file-path (get-in input [:tool_input :file_path]))

;; Early exit if no file path
(when-not file-path (System/exit 0))

(defn sh [& args] (apply sh-in cwd args))

;; jj repo check
(when-not (sh "jj" "root" "--quiet") (System/exit 0))

;; Get current revision state
(def desc (or (sh "jj" "log" "--no-pager" "-r" "@" "--no-graph" "-T" "description") ""))
(def stat (or (sh "jj" "diff" "--stat" "--no-pager") ""))

;; No changes yet → no context needed
(when (str/blank? stat) (System/exit 0))

(def total-lines (changed-lines stat))

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
