#!/usr/bin/env bb

(require '[cheshire.core :as json]
         '[babashka.process :as p]
         '[babashka.http-client :as http]
         '[clojure.string :as str])

(import '[java.time Instant ZoneId]
        '[java.time.format DateTimeFormatter])

;; === Parse stdin JSON ===
(def input (json/parse-string (slurp *in*) true))

(def model   (get-in input [:model :display_name] "Unknown"))
(def ctx-pct (Math/round (double (get-in input [:context_window :used_percentage] 0))))
(def add     (get-in input [:cost :total_lines_added] 0))
(def del     (get-in input [:cost :total_lines_removed] 0))
(def cwd     (get input :cwd "."))

;; === ANSI Colors (24-bit true color) ===
(def G "\033[38;2;151;201;195m")   ; green  0-49%
(def Y "\033[38;2;229;192;123m")   ; yellow 50-79%
(def R "\033[38;2;224;108;117m")   ; red    80-100%
(def D "\033[38;2;74;88;92m")      ; grey   delimiters
(def N "\033[0m")                   ; reset

(defn color-for-pct [p]
  (cond
    (>= p 80) R
    (>= p 50) Y
    :else     G))

;; === Progress bar (▰▱ × 10 segments) ===
(defn bar [p]
  (let [filled (-> p (+ 5) (/ 10) int (max 0) (min 10))]
    (str (str/join (repeat filled "▰"))
         (str/join (repeat (- 10 filled) "▱")))))

;; === VCS info (jj preferred, git fallback) ===
(defn sh [& args]
  (try
    (let [result (apply p/shell {:out :string :err :string :dir cwd} args)]
      (when (zero? (:exit result))
        (str/trim (:out result))))
    (catch Exception _ nil)))

(defn- jj-log [template]
  (sh "jj" "log" "--no-pager" "-r" "@" "--no-graph" "-T" template))

(def vcs-info
  (if-let [rev (jj-log "change_id.shortest()")]
    (let [bookmarks (jj-log "bookmarks.map(|b| b.name()).join(\" \")")
          bookmark  (when (and bookmarks (not (str/blank? bookmarks)))
                      (first (str/split bookmarks #"\s+")))]
      (if bookmark
        (str bookmark " (" rev ")")
        rev))
    (or (sh "git" "branch" "--show-current")
        (sh "git" "rev-parse" "--short" "HEAD")
        "?")))

;; === Configuration ===
(def display-tz (or (System/getenv "CLAUDE_STATUSLINE_TZ") "Asia/Tokyo"))

;; === OAuth token retrieval ===
(defn- parse-keychain-creds
  "Try JSON parse, then hex-decode fallback for macOS Keychain credentials."
  [creds]
  (or (try (get-in (json/parse-string creds true) [:claudeAiOauth :accessToken])
           (catch Exception _ nil))
      (try (let [decoded (-> (p/shell {:out :string :in creds} "xxd" "-r" "-p") :out)
                 start   (str/index-of decoded "{")
                 end     (when start (str/index-of decoded "}" start))]
             (some-> end inc (as-> e (subs decoded start e))
                     (json/parse-string true) :accessToken))
           (catch Exception _ nil))))

(defn get-token []
  (try
    (if (str/includes? (System/getProperty "os.name") "Mac")
      (-> (p/shell {:out :string :err :string}
                   "security" "find-generic-password"
                   "-s" "Claude Code-credentials" "-w")
          :out str/trim parse-keychain-creds)
      (-> (slurp (str (System/getProperty "user.home") "/.claude/.credentials.json"))
          (json/parse-string true)
          (get-in [:claudeAiOauth :accessToken])))
    (catch Exception _ nil)))

;; === Format ISO 8601 time ===
(defn fmt-time [ts fmt]
  (if (or (nil? ts) (str/blank? ts))
    "?"
    (try
      (let [instant (Instant/parse ts)
            zoned   (.atZone instant (ZoneId/of display-tz))
            result  (.format (DateTimeFormatter/ofPattern fmt) zoned)]
        (.toLowerCase result))
      (catch Exception _ "?"))))

;; === Rate limit usage (cached 360s) ===
(def cache-file (str "/tmp/claude-usage-cache-" (System/getProperty "user.name") ".json"))

(defn- read-cache []
  (try (json/parse-string (slurp cache-file) true)
       (catch Exception _ {})))

(defn- cache-fresh? []
  (let [cf (java.io.File. cache-file)]
    (and (.exists cf)
         (< (- (System/currentTimeMillis) (.lastModified cf)) 360000))))

(defn- call-api [token]
  (let [resp (http/get "https://api.anthropic.com/api/oauth/usage"
                       {:headers {"Authorization"  (str "Bearer " token)
                                  "anthropic-beta"  "oauth-2025-04-20"
                                  "Content-Type"    "application/json"}
                        :timeout 5000 :throw false})
        body (when (= 200 (:status resp))
               (json/parse-string (:body resp) true))]
    (if (:five_hour body)
      (do (spit cache-file (json/generate-string body)) body)
      (do (spit cache-file "{}") {}))))

(defn fetch-usage []
  (if (cache-fresh?)
    (read-cache)
    (if-let [token (get-token)]
      (try (call-api token) (catch Exception _ (spit cache-file "{}") {}))
      (read-cache))))

;; === Fetch and extract rate limit values ===
(def usage (fetch-usage))
(def fp (Math/round (double (get-in usage [:five_hour :utilization] 0))))
(def sp (Math/round (double (get-in usage [:seven_day :utilization] 0))))
(def frs (fmt-time (get-in usage [:five_hour :resets_at]) "H:mm"))
(def srs (fmt-time (get-in usage [:seven_day :resets_at]) "M/d H:mm"))

;; === Output 3 lines ===
(let [cc (color-for-pct ctx-pct)
      fc (color-for-pct fp)
      sc (color-for-pct sp)]
  ;; Line 1: 󰚩 Model │ 󰄨 CTX% │ 󰏫 +N/-N │ 󰘬 VCS info
  (println (str "󰚩 " model " " D "│" N " 󰄨 " cc ctx-pct "%" N
                " " D "│" N " 󰏫 " G "+" add N "/" R "-" del N
                " " D "│" N " 󰘬 " vcs-info))
  ;; Line 2: 󰅒 5h rate limit
  (println (str "󰅒 5h  " fc (bar fp) "  " fp "%" N "  Resets " frs " (" display-tz ")"))
  ;; Line 3: 󰃭 7d rate limit
  (println (str "󰃭 7d  " sc (bar sp) "  " sp "%" N "  Resets " srs " (" display-tz ")")))
