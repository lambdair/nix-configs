#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[clojure.string :as str]
         '[babashka.fs :as fs])

(load-file (str (fs/parent *file*) "/lib.bb"))

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))
(def cwd (get input :cwd "."))

(defn sh [& args] (apply sh-in cwd args))

;; Early exit if not a jj repo
(when-not (sh "jj" "root" "--quiet")
  (println (json/generate-string {}))
  (System/exit 0))

;; Get unpushed revisions (between trunk and @, excluding trunk)
(def log-output
  (or (sh "jj" "log" "--no-pager" "-r" "trunk()..@" "--no-graph"
          "-T" "concat(change_id.short(), \"\\t\", description.first_line(), \"\\n\")")
      ""))

(def revisions
  (->> (str/split-lines log-output)
       (remove str/blank?)
       (mapv (fn [line]
               (let [[id & desc-parts] (str/split line #"\t")]
                 {:id (str/trim (or id ""))
                  :desc (str/trim (str/join "\t" desc-parts))})))))

;; No unpushed revisions → allow
(when (empty? revisions)
  (println (json/generate-string {}))
  (System/exit 0))

;; Check each revision's line count
(def violations
  (vec
    (for [{:keys [id desc]} revisions
          :let [total (changed-lines (sh "jj" "diff" "--stat" "--no-pager" "-r" id))]
          :when (> total 150)]
      {:id id :desc desc :lines total})))

;; Also check if current working copy has changes with no description
(def wc-desc (or (sh "jj" "log" "--no-pager" "-r" "@" "--no-graph" "-T" "description.first_line()") ""))
(def wc-stat (or (sh "jj" "diff" "--stat" "--no-pager") ""))
(def wc-has-changes (not (str/blank? wc-stat)))
(def wc-no-desc (str/blank? wc-desc))

;; Revisions still to be pushed, and which of them nobody has reviewed. The push
;; gate catches these too, but only for work that ends in a push.
(def unpushed
  (->> (str/split-lines
         (or (sh "jj" "log" "--no-pager" "-r" "remote_bookmarks()..@" "--no-graph"
                 "-T" "concat(change_id.short(), \"\\n\")")
             ""))
       (remove str/blank?)
       (map str/trim)))

(def unreviewed
  (let [record (read-record (sh "jj" "root" "--quiet"))]
    (remove #(reviewed? record cwd %) unpushed)))

(def issues
  (cond-> []
    (seq unreviewed)
    (conj (str "未レビューのリビジョンが " (count unreviewed) " 件あります: "
               (str/join ", " unreviewed)
               "\n→ /self-review で確認すること"))

    (seq violations)
    (into (map (fn [{:keys [id desc lines]}]
                 (str "リビジョン " id " (\"" desc "\") は " lines
                      " 行の変更があります（目安: 150行以下）"
                      "\n→ 分割を検討すること（`jj split` または `jj new`）"))
               violations))

    (and wc-has-changes wc-no-desc)
    (conj "現在のワーキングコピー (@) に変更がありますが、description が未設定です")))

(when (seq issues)
  (binding [*out* *err*]
    (println (str "【リビジョン規律チェック】\n" (str/join "\n" issues)))))

(println (json/generate-string {}))
