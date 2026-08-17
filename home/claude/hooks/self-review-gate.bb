#!/usr/bin/env bb
;; Push gate: a revision may only be published once it carries a self-review
;; record. As a PreToolUse hook it blocks the push (exit 2) and names the
;; revisions still missing one; as `--mark <change-id> <note>` it writes the
;; record. The record itself lives in lib.bb, which the Stop hook reads too.
;;
;; The gate cannot tell a real review from a bare `--mark`; it turns "forgot to
;; review" into "was asked to review", nothing more. Anything that leaves the
;; push scope unknown — no jj, a refused dry-run — lets the push through rather
;; than standing between a finished change and its remote. An unreadable record
;; is the one case that blocks, since marking the revisions again recovers it.

(require '[cheshire.core :as json]
         '[clojure.string :as str]
         '[babashka.fs :as fs]
         '[babashka.process :as p])

(load-file (str (fs/parent *file*) "/lib.bb"))

(defn run
  "Run `args` in `dir`, returning the exit code with both streams."
  [dir & args]
  (try
    (apply p/shell {:out :string :err :string :dir dir :continue true} args)
    (catch Exception _ {:exit 1 :out "" :err ""})))

(defn write-record [root record]
  (when-let [path (record-path root)]
    (let [tmp (str path ".tmp")]
      (spit tmp (json/generate-string record {:pretty true}))
      (fs/move tmp path {:replace-existing true}))))

;; === Push scope ===

(def push-pattern #"jj\s+git\s+push[^;&|\n]*")

(defn push-commands
  "The jj invocations `command` implies. A `just` recipe is expanded by just
   itself, so the gate never has to know what a recipe wraps."
  [dir command]
  (let [direct (map str/trim (re-seq push-pattern command))
        expanded (mapcat (fn [recipe]
                           (let [{:keys [exit out err]} (run dir "just" "-n" recipe)]
                             (when (zero? exit)
                               (map str/trim (re-seq push-pattern (str out err))))))
                         (map second (re-seq #"\bjust\s+([A-Za-z0-9_-]+)" command)))]
    (distinct (concat direct expanded))))

(defn destinations
  "The commit ids `push-command` would publish, read off jj's dry-run report.
   `[add to H]` and `[move forward from A to H]` both end in \" to <id>]\";
   `[delete from H]` publishes no content and has no \" to \"."
  [dir push-command]
  (let [args (->> (str/split push-command #"\s+")
                  (remove str/blank?)
                  (map #(str/replace % #"^['\"]|['\"]$" "")))
        {:keys [exit out err]} (apply run dir (concat args ["--dry-run"]))]
    (when (zero? exit)
      (map second (re-seq #" to ([0-9a-f]{8,})\]" (str out err))))))

(defn revisions-to-publish [dir dests]
  (when (seq dests)
    (let [revset (str "remote_bookmarks()..(" (str/join "|" dests) ")")
          out (sh-in dir "jj" "log" "--no-pager" "-r" revset "--no-graph"
                     "-T" "concat(change_id.short(), \"\\t\", description.first_line(), \"\\n\")")]
      (->> (str/split-lines (or out ""))
           (remove str/blank?)
           (mapv (fn [line]
                   (let [[id & rest] (str/split line #"\t")]
                     {:id (str/trim id) :desc (str/trim (str/join "\t" rest))})))))))

;; === Modes ===

(defn allow [] (println (json/generate-string {})) (System/exit 0))

(defn gate []
  (let [input (json/parse-string (slurp *in*) true)
        cwd (get input :cwd ".")
        command (get-in input [:tool_input :command] "")
        pushes (push-commands cwd command)]
    (when (empty? pushes) (allow))
    (let [root (or (sh-in cwd "jj" "root" "--quiet") (allow))
          record (read-record root)
          pending (->> pushes
                       (mapcat #(revisions-to-publish cwd (destinations cwd %)))
                       distinct
                       (remove #(reviewed? record cwd (:id %))))]
      (when (empty? pending) (allow))
      (binding [*out* *err*]
        (println (str "【自己レビュー未実施】この push は次のリビジョンを publish します:\n"
                      (str/join "\n" (map #(str "  " (:id %) " " (:desc %)) pending))
                      "\n\n/self-review で内容の妥当性とコメント方針を確認してから push すること。")))
      (System/exit 2))))

(defn mark [change-id note]
  (let [root (or (sh-in "." "jj" "root" "--quiet") (System/exit 0))
        hash (or (diff-hash "." change-id)
                 (do (binding [*out* *err*] (println (str "unknown revision: " change-id)))
                     (System/exit 1)))
        ;; Entries for revisions that reached a remote are dead weight, but a
        ;; lookup that fails must not take the rest of the record with it.
        live (some-> (sh-in "." "jj" "log" "--no-pager" "--no-graph"
                            "-r" "all() & ~::remote_bookmarks()"
                            "-T" "concat(change_id.short(), \"\\n\")")
                     str/split-lines
                     set)
        record (-> (read-record root)
                   (cond-> live (select-keys live))
                   (assoc change-id {"diff" hash "note" note}))]
    (write-record root record)
    (println (str "marked " change-id))))

(let [[flag change-id & note] *command-line-args*]
  (if (= flag "--mark")
    (let [note (str/trim (str/join " " note))]
      (when (or (str/blank? change-id) (str/blank? note))
        (binding [*out* *err*] (println "usage: self-review-gate.bb --mark <change-id> <note>"))
        (System/exit 1))
      (mark change-id note))
    (gate)))
