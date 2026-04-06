#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :as p]
         '[clojure.string :as str])

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))
(def cwd (get input :cwd "."))

;; === Shell helper ===
(defn sh [& args]
  (try
    (let [result (apply p/shell {:out :string :err :string :dir cwd} args)]
      (when (zero? (:exit result))
        (str/trim (:out result))))
    (catch Exception _ nil)))

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
          :let [stat (or (sh "jj" "diff" "--stat" "--no-pager" "-r" id) "")
                last-line (last (str/split-lines stat))
                nums (re-seq #"\d+" (or last-line ""))
                total (if (and nums (>= (count nums) 2))
                        (reduce + (map #(Long/parseLong %) (rest nums)))
                        0)]
          :when (> total 150)]
      {:id id :desc desc :lines total})))

;; Also check if current working copy has changes with no description
(def wc-desc (or (sh "jj" "log" "--no-pager" "-r" "@" "--no-graph" "-T" "description.first_line()") ""))
(def wc-stat (or (sh "jj" "diff" "--stat" "--no-pager") ""))
(def wc-has-changes (not (str/blank? wc-stat)))
(def wc-no-desc (str/blank? wc-desc))

(def issues
  (cond-> []
    (seq violations)
    (into (map (fn [{:keys [id desc lines]}]
                 (str "リビジョン " id " (\"" desc "\") は " lines " 行の変更があります（目安: 150行以下）"))
               violations))

    (and wc-has-changes wc-no-desc)
    (conj "現在のワーキングコピー (@) に変更がありますが、description が未設定です")))

(if (seq issues)
  (do
    (binding [*out* *err*]
      (println (str "【リビジョン規律チェック】\n"
                    (str/join "\n" issues)
                    "\n\n分割を検討してください（`jj split` または `jj new`）")))
    (println (json/generate-string {})))
  (println (json/generate-string {})))
