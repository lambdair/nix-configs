#!/usr/bin/env bb
;; Renders check.bb's JSON report as the flower-theme overview page.
;;
;;   bb page.bb <report.json> > index.html
(ns flower.page
  (:require [cheshire.core :as json]
            [hiccup2.core :as h]))

(def sample
  "A short Rust snippet as [role text] tokens per line; a nil role is plain text."
  [[[:comment "// Counts log entries by level."]]
   [[:keyword "use"] [nil " std::collections::"] [:type "HashMap"] [nil ";"]]
   [[:special "#[derive(Debug)]"]]
   [[:keyword "pub enum "] [:type "Level"] [nil " { Info, Warn, Error }"]]
   [[:keyword "const "] [:constant "MAX_RETRIES"] [nil ": "] [:type "u32"] [nil " = "] [:constant "3"] [nil ";"]]
   [[:keyword "pub fn "] [:function "summarize"] [nil "(lines: &["] [:type "&str"] [nil "]) -> "] [:type "usize"] [nil " {"]]
   [[nil "    lines.iter().filter(|l| l."] [:function "starts_with"] [nil "("] [:string "\"ERROR\""] [nil ")).count()"]]
   [[nil "}"]]])

(def css
  "body{font:14px/1.5 system-ui,sans-serif;margin:0 auto;max-width:1100px;padding:24px;background:#fafafa;color:#222}
section{margin:40px 0}
pre.code{padding:16px;border-radius:8px;font:13px/1.6 ui-monospace,monospace;overflow-x:auto}
.swatches{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:8px}
.swatch{display:flex;gap:8px;align-items:center}
.chip{width:48px;height:48px;border-radius:6px;border:1px solid #0002;flex:none}
.ansi{display:flex;gap:4px;flex-wrap:wrap}
.cell{width:40px;height:24px;border-radius:4px;border:1px solid #0002}
.table{overflow-x:auto}
table{border-collapse:collapse}
td,th{padding:2px 10px;text-align:left}
.dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:6px;border:1px solid #0002}
.bad{color:#b00}
.ok{color:#070}")

(defn- role-hex [variant]
  (into {} (map (juxt (comp keyword :role) :hex)) (:roles variant)))

(defn- code [variant]
  (let [hex (role-hex variant)]
    [:pre.code {:style (str "background:" (:bg hex) ";color:" (:text hex))}
     (for [line sample]
       [:div (for [[role text] line]
               (if role [:span {:style (str "color:" (hex role))} text] text))])]))

(defn- used-colours
  "Every named colour: first the ones the roles or ANSI slots reference, in
  the order they're first used, then any remaining named colours in their
  :colors order."
  [variant]
  (let [by-name (into {} (map (juxt :name identity)) (:colors variant))
        used (keep by-name (distinct (concat (map :color (:roles variant)) (map :color (:ansi variant)))))
        used-names (set (map :name used))]
    (concat used (remove (comp used-names :name) (:colors variant)))))

(defn- swatch [{:keys [name hex label]}]
  [:div.swatch [:div.chip {:style (str "background:" hex)}]
   [:div [:b name] [:br] [:code hex] [:br] [:small label]]])

(defn- role-table [variant]
  [:div.table
   [:table
    [:tr [:th "role"] [:th "colour"] [:th "hex"] [:th "contrast"] [:th "min"] [:th ""]]
    (for [{:keys [role color hex contrast ok] minimum :min} (:roles variant)]
      [:tr [:td role] [:td color]
       [:td [:span.dot {:style (str "background:" hex)}] [:code hex]]
       [:td (format "%.2f" (double contrast))]
       [:td (if minimum (str minimum) "–")]
       [:td (if ok "✓" "✗")]])]])

(defn- ansi-row [variant]
  [:div.ansi
   (for [{:keys [slot hex ok]} (:ansi variant)]
     [:div.cell {:style (str "background:" hex) :title (str slot " " hex (when-not ok " ✗"))}])])

(defn- section [variant]
  [:section
   [:h2 (:title variant)]
   (if (seq (:violations variant))
     [:ul.bad (for [v (:violations variant)] [:li v])]
     [:p.ok (format "All rules pass. Closest syntax pair: %s / %s (ΔE %.3f)."
                    (get-in variant [:closest :a]) (get-in variant [:closest :b])
                    (double (get-in variant [:closest :de])))])
   (when (:roles variant)
     (list (code variant)
           [:h3 "Colours"] [:div.swatches (map swatch (used-colours variant))]
           [:h3 "ANSI"] (ansi-row variant)
           [:h3 "Roles"] (role-table variant)))])

(defn -main [report]
  (let [variants (json/parse-string (slurp report) true)]
    (println
     (str "<!doctype html>"
          (h/html [:html {:lang "ja"}
                   [:head [:meta {:charset "utf-8"}]
                    [:meta {:name "viewport" :content "width=device-width,initial-scale=1"}]
                    [:title "Flower themes"]
                    [:style (h/raw css)]]
                   [:body
                    [:h1 "Flower themes"]
                    [:p "Anemone / Nemophila / Sunflower, each in dark and light."]
                    (map section variants)]])))))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))
