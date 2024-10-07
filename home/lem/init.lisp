(in-package :lem-user)

;;; UI
;; (load-theme "material-palenight")
(load-theme "nord")

(lem/line-numbers:toggle-line-numbers)
(setf lem/line-numbers:*relative-line* t)

(lem-lisp-mode/paren-coloring:toggle-paren-coloring)



;; activate vi mode
(lem-vi-mode:vi-mode)


(lem-paredit-mode:paredit-mode)
