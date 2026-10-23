(ns dev.lispy
  "lispy 風の特殊キー。カーソルが開き括弧の直前か閉じ括弧の直後にあるときだけ
  特殊な操作として働き、それ以外の位置では打った文字をそのまま入力する。
  括弧の対応は REPL 本体と同じ reader/bracket-scan で取るので、文字列・コメント・
  文字リテラルの中の括弧や、閉じていない括弧では特殊キーにならない。"
  (:require
   [clojure-cli.repl.api :as api]
   [clojure-cli.repl.reader :as reader])
  (:import
   [org.jline.reader LineReader]))

(set! *warn-on-reflection* true)

(def enabled?
  "C-x l で切り替える。偽のあいだは特殊キーもすべて文字として入力される。"
  (atom true))

(defn- parent
  "span を囲む最も内側の span。spans は閉じた順に並ぶので、囲むもののうち
  最初に現れるものが最も内側になる。トップレベルなら nil。"
  [spans [open close]]
  (some (fn [[o c :as s]] (when (and (< o open) (< close c)) s)) spans))

(defn- siblings
  "span と同じ親を持つ span を、開き括弧の位置の順に並べたもの。"
  [spans span]
  (let [p (parent spans span)]
    (sort-by first (filter #(= p (parent spans %)) spans))))

(defn- target
  "カーソルが括弧の位置にあれば [span side] を返す。side は閉じ括弧の直後なら
  :right、開き括弧の直前なら :left。`(a)(b)` の境目は閉じ括弧の側を優先する。"
  [spans cursor]
  (or (some (fn [[_ close :as s]] (when (= close cursor) [s :right])) spans)
      (some (fn [[open _ :as s]] (when (= open cursor) [s :left])) spans)))

(defn- side-index [[open close] side]
  (if (= side :left) open close))

(defn- eval-form!
  "フォームを評価し、結果を入力行の上に出す。入力は送信しない。"
  [_ src _ [open close] _]
  (let [{:keys [value err]} (api/eval-code (subs src open close))]
    (api/print-above [{:text (str "=> " (or value err) "\n") :style {:faint true}}])))

(defn- move-to! [^LineReader rdr idx]
  (when idx (.cursor (.getBuffer rdr) (int idx))))

(defn- sibling!
  "隣のフォームへ同じ側のまま移る。step が 1 なら次、-1 なら前。"
  [step]
  (fn [rdr _ spans span side]
    (let [sibs (vec (siblings spans span))
          i (.indexOf ^java.util.List sibs span)]
      (move-to! rdr (some-> (get sibs (+ i step)) (side-index side))))))

(def ^:private actions
  {"j" (sibling! 1)
   "k" (sibling! -1)
   "h" (fn [rdr _ spans span _] (move-to! rdr (some-> (parent spans span) (side-index :left))))
   "l" (fn [rdr _ spans span _] (move-to! rdr (some-> (parent spans span) (side-index :right))))
   "d" (fn [rdr _ _ span side] (move-to! rdr (side-index span ({:left :right :right :left} side))))
   "e" eval-form!})

(defn- special
  "括弧の位置なら action を実行し、それ以外では打った文字を入力する。"
  [^LineReader rdr action]
  (let [buf (.getBuffer rdr)
        src (.toString buf)
        spans (:spans (reader/bracket-scan src))
        [span side] (when @enabled? (target spans (.cursor buf)))]
    (if span
      (action rdr src spans span side)
      (.callWidget rdr LineReader/SELF_INSERT))))

(defn install
  "clojure-cli.repl.edn の :keybindings から呼ばれる。"
  [^LineReader rdr]
  (doseq [[k action] actions]
    (api/bind-key rdr k (api/widget #(special rdr action))))
  (api/bind-key rdr (api/key-sequence "C-x l")
                (api/widget
                 (fn []
                   (swap! enabled? not)
                   (api/print-above [{:text (str "lispy keys " (if @enabled? "on" "off") "\n")
                                      :style {:faint true}}])))))
