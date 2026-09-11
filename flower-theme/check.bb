#!/usr/bin/env bb
;; Checks flower-theme variants against the palette rules and optionally writes
;; the measurements as JSON for the overview page.
;;
;;   bb check.bb <variants.json> [--report <out.json>]
(ns flower.check
  (:require [cheshire.core :as json]
            [clojure.string :as str]))

(def role-keys
  [:crust :bg :cursorline :selection :statusline
   :text :subtext :comment :linenr :guide
   :keyword :function :type :string :constant :special
   :error :warning :info :hint
   :added :removed :changed])

(def syntax [:keyword :function :type :string :constant :special])

(def ansi-slots
  [:black :red :green :yellow :blue :magenta :cyan :white
   :bright-black :bright-red :bright-green :bright-yellow
   :bright-blue :bright-magenta :bright-cyan :bright-white])

(def min-contrast
  (merge {:text 7 :comment 3 :linenr 2.5}
         (zipmap (concat syntax [:error :warning :info :hint :added :removed :changed])
                 (repeat 4.5))))

;; OKLCH hue of the sRGB colour each chromatic ANSI slot stands for.
(def canonical-hue {:red 29.2 :yellow 109.8 :green 142.5 :cyan 194.8 :blue 264.1 :magenta 328.4})

(def ansi-min-contrast 3)
(def ansi-hue-window 30)
(def surface-min-de 0.03)
(def syntax-min-de 0.06)
(def strand-hue-window 10)
(def strand-min-chroma 0.04)

(defn- channel [hex i]
  (/ (Integer/parseInt (subs hex (inc (* 2 i)) (+ 3 (* 2 i))) 16) 255.0))

(defn- linear [c]
  (if (<= c 0.04045) (/ c 12.92) (Math/pow (/ (+ c 0.055) 1.055) 2.4)))

(defn- rgb-linear [hex] (mapv #(linear (channel hex %)) [0 1 2]))

(defn luminance [hex]
  (let [[r g b] (rgb-linear hex)]
    (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b))))

(defn contrast [a b]
  (let [[hi lo] (sort > [(luminance a) (luminance b)])]
    (/ (+ hi 0.05) (+ lo 0.05))))

(defn oklab [hex]
  (let [[r g b] (rgb-linear hex)
        l (Math/cbrt (+ (* 0.4122214708 r) (* 0.5363325363 g) (* 0.0514459929 b)))
        m (Math/cbrt (+ (* 0.2119034982 r) (* 0.6806995451 g) (* 0.1073969566 b)))
        s (Math/cbrt (+ (* 0.0883024619 r) (* 0.2817188376 g) (* 0.6299787005 b)))]
    [(+ (* 0.2104542553 l) (* 0.7936177850 m) (* -0.0040720468 s))
     (+ (* 1.9779984951 l) (* -2.4285922050 m) (* 0.4505937099 s))
     (+ (* 0.0259040371 l) (* 0.7827717662 m) (* -0.8086757660 s))]))

(defn delta-e [a b]
  (Math/sqrt (reduce + (map (fn [x y] (let [d (- x y)] (* d d))) (oklab a) (oklab b)))))

(defn chroma [hex] (let [[_ a b] (oklab hex)] (Math/hypot a b)))

(defn hue [hex] (let [[_ a b] (oklab hex)] (mod (Math/toDegrees (Math/atan2 b a)) 360)))

(defn hue-distance [a b] (let [d (Math/abs (- a b))] (min d (- 360 d))))

(defn- resolve-names
  "Maps each of `ks` through `table` to the hex of the colour it names,
  collecting a violation for every unassigned key or unknown colour."
  [colors table ks what]
  (reduce (fn [acc k]
            (let [n (get table k)
                  c (when n (get colors (keyword n)))]
              (cond
                (nil? n) (update acc :violations conj (str what " " (name k) " is not assigned"))
                (nil? c) (update acc :violations conj (str what " " (name k) " names unknown colour " n))
                :else (assoc-in acc [:hex k] (:hex c)))))
          {:hex {} :violations []}
          ks))

(defn evaluate [{:keys [colors roles ansi strand] :as variant}]
  (let [r (resolve-names colors roles role-keys "role")
        a (resolve-names colors ansi ansi-slots "ansi")
        unresolved (into (:violations r) (:violations a))]
    (if (seq unresolved)
      (assoc (select-keys variant [:name :title :flower :mode]) :violations unresolved)
      (let [rh (:hex r)
            ah (:hex a)
            bg (:bg rh)
            role-rows (vec (for [k role-keys
                                 :let [hex (rh k) c (contrast hex bg) m (min-contrast k)]]
                             {:role (name k) :color (get roles k) :hex hex :contrast c
                              :min m :ok (or (nil? m) (>= c m))}))
            surface-rows (vec (for [[x y] [[:bg :cursorline] [:bg :selection] [:cursorline :selection]]
                                    :let [d (delta-e (rh x) (rh y))]]
                                {:a (name x) :b (name y) :de d :ok (>= d surface-min-de)}))
            [closest-de ca cb] (first (sort-by first
                                               (for [x syntax y syntax
                                                     :when (neg? (compare (name x) (name y)))]
                                                 [(delta-e (rh x) (rh y)) x y])))
            ansi-rows (vec (for [k ansi-slots
                                 :let [hex (ah k)
                                       c (contrast hex bg)
                                       h (canonical-hue (keyword (str/replace (name k) "bright-" "")))
                                       hue-ok (or (nil? h) (<= (hue-distance (hue hex) h) ansi-hue-window))
                                       contrast-ok (or (nil? h) (>= c ansi-min-contrast))]]
                             {:slot (name k) :color (get ansi k) :hex hex :contrast c
                              :hue-ok hue-ok :contrast-ok contrast-ok :ok (and hue-ok contrast-ok)}))
            strand-role (first (for [k (concat syntax [:selection :statusline])
                                     :let [hex (rh k)]
                                     :when (and (> (chroma hex) strand-min-chroma)
                                                (<= (hue-distance (hue hex) (hue strand)) strand-hue-window))]
                                 (name k)))
            violations (vec (concat
                             (for [row role-rows :when (not (:ok row))]
                               (format "%s %.2f:1 < %s:1" (:role row) (:contrast row) (:min row)))
                             (for [row surface-rows :when (not (:ok row))]
                               (format "surfaces %s/%s ΔE %.3f < %s" (:a row) (:b row) (:de row) surface-min-de))
                             (when (< closest-de syntax-min-de)
                               [(format "syntax %s/%s ΔE %.3f < %s" (name ca) (name cb) closest-de syntax-min-de)])
                             (for [row ansi-rows :when (not (:contrast-ok row))]
                               (format "ansi %s %.2f:1 < %s:1" (:slot row) (:contrast row) ansi-min-contrast))
                             (for [row ansi-rows :when (not (:hue-ok row))]
                               (format "ansi %s hue %.0f° is over %s° from canonical"
                                       (:slot row) (hue (:hex row)) ansi-hue-window))
                             (when-not strand-role
                               [(str "no syntax, selection or statusline colour within "
                                     strand-hue-window "° of strand " strand)])))]
        (merge (select-keys variant [:name :title :flower :mode :strand])
               {:colors (vec (for [[k c] colors] {:name (name k) :hex (:hex c) :label (:label c)}))
                :roles role-rows
                :surfaces surface-rows
                :closest {:a (name ca) :b (name cb) :de closest-de}
                :ansi ansi-rows
                :strand-role strand-role
                :violations violations})))))

(defn -main [input & opts]
  (let [report (second (drop-while #(not= "--report" %) opts))
        results (mapv evaluate (json/parse-string (slurp input) true))]
    (doseq [{:keys [name violations closest]} results]
      (println (format "%-24s %s" name
                       (if (seq violations)
                         "FAIL"
                         (format "ok (closest syntax pair ΔE %.3f)" (:de closest)))))
      (doseq [v violations] (println "  -" v)))
    (when report (spit report (json/generate-string results {:pretty true})))
    (when (some (comp seq :violations) results) (System/exit 1))))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))
