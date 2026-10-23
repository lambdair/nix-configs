(ns dev.lispy
  "lispy 風の特殊キー。カーソルが開き括弧の直前か閉じ括弧の直後にあるときだけ
  特殊な操作として働き、それ以外の位置では打った文字をそのまま入力する。
  括弧の対応は REPL 本体と同じ reader/bracket-scan で取るので、文字列・コメント・
  文字リテラルの中の括弧や、閉じていない括弧では特殊キーにならない。"
  (:require
   [clojure-cli.repl.api :as api]
   [clojure-cli.repl.reader :as reader]
   [clojure.string :as str]
   [rewrite-clj.paredit :as pe]
   [rewrite-clj.zip :as z])
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

(defn- span-opening-at [spans open]
  (some (fn [[o _ :as s]] (when (= o open) s)) spans))

(defn- span-closing-at [spans close]
  (some (fn [[_ c :as s]] (when (= c close) s)) spans))

(defn- row-col
  "JLine の 0 始まりの位置を、rewrite-clj の 1 始まりの [行 列] にする。"
  [^String src idx]
  (let [rows (str/split (subs src 0 idx) #"\n" -1)]
    [(count rows) (inc (count (last rows)))]))

(defn- list-loc
  "開き括弧が open にあるフォームの zipper 位置。読めない入力なら nil。"
  [src open]
  (try (some-> (z/of-string src {:track-position? true})
               (z/find-last-by-pos (row-col src open)))
       (catch Exception _ nil)))

(defn- rewrite!
  "フォームに f を当てた結果でバッファを置き換え、(place 新しい文字列) の位置に
  カーソルを置く。place が nil を返したら位置は書き込んだ末尾のまま。f が nil を
  返すか例外を投げたら何もしない。"
  [^LineReader rdr src open f place]
  (when-let [out (try (some-> (list-loc src open) f z/root-string)
                      (catch Exception _ nil))]
    (let [buf (.getBuffer rdr)]
      (.clear buf)
      (.write buf ^String out)
      (when-let [idx (place out)]
        (.cursor buf (int idx))))))

(defn- keep-open
  "開き括弧より前が変わらない編集の後、同じ開き括弧のフォームの side の位置。"
  [[open _] side]
  (fn [out]
    (some-> (span-opening-at (:spans (reader/bracket-scan out)) open)
            (side-index side))))

(defn- keep-close
  "閉じ括弧より後が変わらない編集の後、同じ閉じ括弧のフォームの side の位置。"
  [src [_ close] side]
  (fn [out]
    (let [close' (- (count out) (- (count src) close))]
      (some-> (span-closing-at (:spans (reader/bracket-scan out)) close')
              (side-index side)))))

(defn- bracket-right!
  "カーソル位置の括弧を右へ動かす。閉じ括弧なら右の要素を取り込み (slurp)、
  開き括弧なら最初の要素を外へ出す (barf)。"
  [rdr src _ [open :as span] side]
  (if (= side :right)
    (rewrite! rdr src open #(pe/slurp-forward-into % {:from :current}) (keep-open span side))
    (rewrite! rdr src open #(some-> % z/down pe/barf-backward) (keep-close src span side))))

(defn- bracket-left!
  "カーソル位置の括弧を左へ動かす。閉じ括弧なら最後の要素を外へ出し (barf)、
  開き括弧なら左の要素を取り込む (slurp)。"
  [rdr src _ [open :as span] side]
  (if (= side :right)
    (rewrite! rdr src open #(some-> % z/down pe/barf-forward) (keep-open span side))
    (rewrite! rdr src open #(pe/slurp-backward-into % {:from :current}) (keep-close src span side))))

(defn- splice!
  "括弧を外し、カーソルを中身の端に置く。"
  [rdr src _ [open close] side]
  (rewrite! rdr src open pe/splice
            (fn [out]
              (if (= side :left)
                open
                (- (count out) (- (count src) close))))))

(defn- raise!
  "親のフォームをこのフォームで置き換える。親より前は変わらないので、
  親の開き括弧の位置が新しい開き括弧になる。"
  [rdr src spans span side]
  (when-let [p (parent spans span)]
    (rewrite! rdr src (first span) pe/raise (keep-open p side))))

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
   ">" bracket-right!
   "<" bracket-left!
   "/" splice!
   "r" raise!
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
