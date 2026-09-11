(ns flower.check-test
  (:require [babashka.fs :as fs]
            [clojure.string :as str]
            [clojure.test :refer [deftest is run-tests]]))

(load-file (str (fs/path (fs/parent (fs/absolutize *file*)) "check.bb")))
(require '[flower.check :as check])

(def role-hex
  {:crust "#111118" :bg "#1A1A22" :cursorline "#24232D" :selection "#3C303F" :statusline "#2D2934"
   :text "#DAD6D2" :subtext "#BAADB1" :comment "#818691" :linenr "#5F5B68" :guide "#32323A"
   :keyword "#EF6661" :function "#A9C0DE" :type "#C5ABD9" :string "#EDB2BA" :constant "#DC8EBB" :special "#D5CAAE"
   :error "#ED5350" :warning "#EBB25F" :info "#88BFE6" :hint "#9CA5B8"
   :added "#7CC58C" :removed "#E85F61" :changed "#D9B06B"})

(def ansi-hex
  {:black "#2D2D36" :red "#E85854" :green "#78BF7B" :yellow "#DAC46D"
   :blue "#7EA7DC" :magenta "#CC8BC5" :cyan "#76C7CC" :white "#C8C3BF"
   :bright-black "#54545E" :bright-red "#FD736D" :bright-green "#8BD28D" :bright-yellow "#E8DA82"
   :bright-blue "#9BC1F1" :bright-magenta "#E3A6DD" :bright-cyan "#96DCE0" :bright-white "#EEEAE7"})

(defn variant
  "A dark variant that passes every rule, with individual role or ANSI hex overridden."
  ([] (variant {} {}))
  ([role-overrides ansi-overrides]
   (let [rh (merge role-hex role-overrides)
         ah (merge ansi-hex ansi-overrides)
         ansi-name #(keyword (str "ansi-" (name %)))]
     {:name "flower-test-dark" :title "Test Dark" :flower "test" :mode "dark" :strand "#C8202A"
      :colors (merge (update-vals rh (fn [h] {:hex h :label "role"}))
                     (update-keys (update-vals ah (fn [h] {:hex h :label "ansi"})) ansi-name))
      :roles (into {} (for [k (keys rh)] [k (name k)]))
      :ansi (into {} (for [k (keys ah)] [k (name (ansi-name k))]))})))

(defn violations [v] (:violations (check/evaluate v)))
(defn has? [prefix v] (some #(str/starts-with? % prefix) (violations v)))

(deftest passing-variant
  (is (= [] (violations (variant)))))

(deftest low-contrast-syntax
  (is (has? "keyword " (variant {:keyword "#3A3A44"} {}))))

(deftest indistinct-syntax-pair
  (is (has? "syntax " (variant {:type "#A9C0DE"} {}))))

(deftest indistinct-surfaces
  (is (has? "surfaces " (variant {:cursorline "#1B1B23"} {}))))

(deftest ansi-hue-drift
  (is (has? "ansi red hue" (variant {} {:red "#7EA7DC"}))))

(deftest ansi-low-contrast
  (is (has? "ansi green " (variant {} {:green "#2F3A30"}))))

(deftest missing-strand
  (is (has? "no syntax" (assoc (variant) :strand "#20A040"))))

(deftest unknown-colour
  (is (= ["role keyword names unknown colour nope"]
         (violations (assoc-in (variant) [:roles :keyword] "nope")))))

(let [{:keys [fail error]} (run-tests 'flower.check-test)]
  (System/exit (if (zero? (+ fail error)) 0 1)))
