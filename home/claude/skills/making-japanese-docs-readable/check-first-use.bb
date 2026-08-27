#!/usr/bin/env bb
;; 用語の定義行が初出行以前にあるかを確認する。
;; 使い方: check-first-use.bb <doc.html|doc.md> <terms.edn>
;; terms.edn は {"用語の正規表現" "定義行にだけ現れる正規表現"} の map。
;; HTML は <style>・目次 (<nav class="toc">)・タグを落としてから行番号を数える。
;; 未定義語が 1 つでもあれば終了コード 1。
(require '[clojure.string :as str]
         '[clojure.edn :as edn])

(defn strip-html [s]
  (-> s
      (str/replace #"(?s)<style>.*?</style>" "")
      (str/replace #"(?s)<nav class=\"toc\".*?</nav>" "")
      (str/replace #"<[^>]*>" "")))

(defn doc-lines [path]
  (->> (slurp path)
       strip-html
       str/split-lines
       (remove str/blank?)
       vec))

(defn first-line [lines re]
  (some (fn [[i l]] (when (re-find re l) i))
        (map-indexed (fn [i l] [(inc i) l]) lines)))

(let [[doc terms-path] *command-line-args*]
  (when-not (and doc terms-path)
    (println "usage: check-first-use.bb <doc> <terms.edn>")
    (System/exit 2))
  (let [lines (doc-lines doc)
        terms (edn/read-string (slurp terms-path))
        rows  (for [[term def-re] terms]
                (let [fu (first-line lines (re-pattern term))
                      fd (first-line lines (re-pattern def-re))]
                  {:term term :first fu :def fd
                   :ok (or (nil? fu) (and fd (<= fd fu)))}))
        bad   (remove :ok rows)]
    (doseq [{:keys [term first def ok]} rows]
      (println (format "%-24s first@%-5s def@%-5s %s"
                       term (or first "-") (or def "-") (if ok "" "<-- CHECK"))))
    (println "needs attention:" (mapv :term bad))
    (System/exit (if (seq bad) 1 0))))
