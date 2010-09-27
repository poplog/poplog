;;; -*- Mode: emacs-lisp; -*-
;;; Example .emacs file for pop-mode

;; Make sure Emacs can find the .elc files.  For example, if the .elc files
;; are in $popcontrib/emacs, you could do something like the following:
;;(setq load-path
;;      (append (list (substitute-in-file-name "$popcontrib/emacs"))
;;	      load-path))

(setq auto-mode-alist (append '(("\\.p$" . pop-mode)) auto-mode-alist))

(autoload 'pop-mode "pop-mode" "Major mode for editing Pop-11 code" t)
(autoload 'run-pop "inferior-pop-mode" "Run an inferior Poplog process." t)
(autoload 'run-pop-other-frame "inferior-pop-mode"
  "Run an inferior Poplog process in another frame." t)

(autoload 'pop-help "pop-help-mode" "Read a Poplog HELP file" t nil)
(autoload 'pop-teach "pop-help-mode" "Read a Poplog TEACH file" t nil)
(autoload 'pop-doc "pop-help-mode" "Read a Poplog DOC file" t nil)
(autoload 'pop-ref "pop-help-mode" "Read a Poplog REF file" t nil)
(autoload 'pop-showlib "pop-help-mode" "Read a Poplog LIB file" t nil)
(autoload 'pop-apropos "pop-help-mode" 
  "Get summary help for everything matching PATTERN" t)

;;; If you are using XEmacs and want to use the function menu package,
;;; uncomment the following:

;(require 'func-menu)
;(define-key global-map 'f8 'function-menu)
;(define-key global-map "\C-cg" 'fume-prompt-function-goto)
;(define-key global-map '(shift button3) 'mouse-function-menu)
;(define-key global-map '(meta  button1) 'fume-mouse-function-goto)

;;;; Function menu Pop-11 support
;;;; Brian Logan <b.s.logan@cs.bham.ac.uk>
;(defvar fume-function-name-regexp-pop11
;  ;; This is fairly permissive -- it will match some ill-formed procedure 
;  ;; names but it should match nearly all legal names (except those 
;  ;; containing the sign character `:').  The idea is to ignore define :class
;  ;; etc but allow methods as a special case
;  "^\\s *define\\s +\\(:method\\s +\\)*\\([^:\(;]+\\)"
;  "Expression to get Pop-11 procedure names.")

;(setq fume-function-name-regexp-alist
;      (append '((pop-mode . fume-function-name-regexp-pop11))
;	      fume-function-name-regexp-alist))

;(defun fume-find-next-pop11-function-name (buffer)
;  "Searches for the next Pop-11 procedure in BUFFER."
;  (set-buffer buffer)
;  (if (re-search-forward fume-function-name-regexp nil t)
;      (let ((beg (match-beginning 2))
;            (end (match-end 2)))
;        (cons (buffer-substring beg end) beg))))

;(setq fume-find-function-name-method-alist
;      (append '((pop-mode . fume-find-next-pop11-function-name))
;	      fume-find-function-name-method-alist))
