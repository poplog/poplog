;;; pop-mode.el --- major mode for editing Pop-11 code.

;; This file is part of Pop-mode

;; Copyright (C) 1989-1991 Richard Caley and Brian Logan
;; Copyright (C) 1996 Brian Logan

;; Authors: Richard Caley <rjc@cstr.ed.ac.uk>
;;          Brian Logan <bsl@cs.bham.ac.uk>

;; Maintainer: Brian Logan <b.s.logan@cs.bham.ac.uk>
;; RCS info: $Id: pop-mode.el,v 1.26 2003/08/26 09:52:34 bsl Exp $
;; Keywords: processes, poplog, pop11

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;;
;;; Pop-11 mode and inferior Pop-11 mode for XEmacs/GNU Eemacs.
;;;
;;;         Written by Richard Caley and Brian Logan.
;;;
;;;         Flavours information by Angela Marie Gilham.
;;;
;;; This code was written to allow Pop-11 development to be done in Emacs
;;; with (almost) as much support as in in Ved.  Specifically it allows
;;; code to be loaded from an emacs buffer into a running Pop-11 and it
;;; allows Poplog documentation to be read from emacs (see pop-help-mode.el).
;;;
;;; Note since emacs will only recognise 2 characters as a start of comment
;;; token, pop-mode treats `;;' as the Pop-11 start of  comment character.
;;; I have never seen that in Pop-11 code anywhere other than as a comment
;;; start, but you never know ...  Second, and more significantly, the code
;;; will only understand either PL-I style /*...*/ comments or ';;;' end of
;;; line coments not both.  (This is a limitation of GNU Emacs -- the XEmacs
;;; version of Pop-11 mode does not have this problem).  In general this is
;;; not a problem.  Most people only use one or the other inside procedures.
;;; Set the variable pop-use-pl1-comments as apropriate. I have it off since
;;; I use PL-I style comments only as block comments at file level and
;;; end-of-line comments inside my code.
;;;
;;; The indentation code and pop-closeit cope with most pop-11 constructs
;;; I have come across.  Basically they cover my coding style and that used
;;; in code I have to maintain.  Please extend  the lists of keywords and
;;; indentation data to cover more syntax.  Please send any such extensions
;;; to me and I will put them in any new versions.

;;; THINGS TO DO:
;;; Make it understand all of pop syntax (probably impossible on a turing
;;; machine :-(

(require 'cl)
(require 'add-log)
(require 'easymenu)
(require 'font-lock)

(autoload 'run-pop "inferior-pop-mode"
  "Run an inferior Poplog process." t)
(autoload 'run-pop-other-frame "inferior-pop-mode"
  "Run an inferior Poplog process in another frame." t)
(autoload 'pop-complete-word "inferior-pop-mode"
  "Complete the Pop-11 word at or before point." t)
(autoload 'pop-send-define "inferior-pop-mode"
  "Send the current procedure to the inferior Poplog process" t)
(autoload 'pop-send-region "inferior-pop-mode"
  "Send the current region to the inferior Poplog process." t)
(autoload 'pop-send-buffer "inferior-pop-mode"
  "Send the entire buffer to the inferior Poplog process" t)
(autoload 'inferior-pop-process-p "inferior-pop-mode"
  "Returns the current Poplog process or nil if none." t)

(autoload 'pop-help "pop-help-mode"
  "Read Poplog help file" t )
(autoload 'pop-teach "pop-help-mode"
  "Read Poplog teach file" t )
(autoload 'pop-doc "pop-help-mode"
  "Read Poplog doc file" t )
(autoload 'pop-ref "pop-help-mode"
  "Read Poplog ref file" t )
(autoload 'pop-showlib "pop-help-mode"
  "Read Poplog lib file" t )
(autoload 'pop-get-help "pop-help-mode"
  "Read the help file for the current word" t)

;(autoload 'pop-ploghelp "pop-help-mode"
;  "Read Poplog Prolog help file" t )
;(autoload 'pop-plogteach "pop-help-mode"
;  "Read Poplog Prolog teach file" t)
;(autoload 'pop-plogshowlib "pop-help-mode"
;  "Read Poplog Prolog lib file" t)

;;; add pop mode to auto mode list if necessary
(if (not (assoc "\\.p$" auto-mode-alist))
    (setq auto-mode-alist (nconc auto-mode-alist '(("\\.p$" . pop-mode)))))



;; The following variables are meant for YOU gentle reader.

(defvar pop-use-pl1-comments nil
  "*GNU Emacs can parse either pl1 style /* */ comments or end of line
comments but not both (XEmacs supports both comment styles and ignores this
variable).

Non nil means that buffers contain only /* */ style comments, otherwise they
contain only end of line comments.")

(defvar pop-label-regexp
  "\\(\\sw\\|\\s_\\)+\\s-*:\\s-*"
  "*regular expression matching Pop-11 labels")

(defvar pop-declaration-indent-step 5
  "* Distance to indent lines following a declaration (eg \"vars\" )" )

(defvar pop-label-indent 4
  "* Distance that labels are outdented relative to the
surrounding code" )

(defvar pop-indentation-info
  '(("define" 0 4)
    ("enddefine" -4 0)
    ("procedure" 0 4)
    ("endprocedure" -4 0)

    ("flavour" 0 4)
    ("endflavour" -4 0)
    ("defmethod" 0 4)
    ("enddefmethod" -4 0)

    ("instance" 0 4)
    ("endinstance" -4 0)

    ("if" 0 8)
    ("unless" 0 8)
    ("then" 0 -4)
    ("elseif" -4 8)
    ("elseunless" -4 8)
    ("else" -4 4)
    ("endif" -4 0)
    ("endunless" -4 0)

    ("while" 0 8)
    ("endwhile" -4 0)

    ("for" 0 8)
    ("fast_for" 0 8)
    ("do" 0 -4)
    ("endfor" -4 0)
    ("endfast_for" -4 0)
    ("foreach" 0 8)
    ("endforeach" -4 0)

    ("until" 0 8)
    ("enduntil" -4 0)

    ("repeat" 0 8)
    ("times" 0 -4)
    ("forever" 0 -4)
    ("endrepeat" -4 0)

    ("switchon" 0 8)
    ("case" -4 8)
    ("notcase" -4 8)
    ("andcase" -4 4)
    ("notandcase" -4 4)
    ("orcase" -4 4)
    ("notorcase" -4 4)
    ("endswitchon" -8 0)
    )
  "* An association list which determines how Pop-11 structures are
indented.  Each entry starts with a string giving the name of a syntax
word. This is followed by two numbers, the first gives the change in
indentation of the current line while the second gives the change in
indentation of succeeding lines.

Thus the default entry for \"else\" is (\"else\" -4 4) This outdents
the else, to line up with the if, and indents the following code.")

(defvar pop-declaration-starters
  '("recordclass"
    "vectorclass"
    "vars"
    "lvars"
    "section"
    "constant"
    "lconstant")
  "* List of words which start declarations in Pop-11.  All words
which start constructs terminated by a semicolon (e.g. vars)")

(defvar pop-declaration-modifiers
  '("global"
    "procedure"
    "constant"
    "lconstant"
    "lvars"
    "syntax"
    "macro"
    "updaterof")
  "* List of words which modify declarations.")

(defvar pop-interesting-declaration-modifiers
  '("updaterof"
    "macro"
    "syntax"
    ":class"
    ":mixin"
    ":singleton"
    ":method"
    ":wrapper"
    ":instance"
    ":rulesystem"
    ":rulefamily"
    ":ruleset"
    ":rule")
  "* List of words which modify declarations which are interesting
enough to be included in the comment which closes it.")

(defvar pop-definition-starters
  '("define"
    "flavour"
    "defmethod"
    "instance"
    "recordclass"
    "vectorclass"
    "section"
    "vars"
    "lvars"
    "constant"
    "lconstant")
  "* List of words which start definitions in Pop-11.  Used to
find the start of a definition ")

(defvar pop-definition-enders
  '("enddefine"
    "endsection"
    "endflavour"
    "enddefmethod"
    "endinstance")
  "* List of words used to end definitions in Pop-11")

(defvar pop-open-close-assoc
  '(("define" . "enddefine")
    ("procedure" . "endprocedure")
    ("flavour" . "endflavour")
    ("defmethod" . "enddefmethod")
    ("instance" . "endinstance")
    ("if" . "endif")
    ("unless" . "endunless")
    ("while" . "endwhile")
    ("until" . "enduntil")
    ("fast_for" . "endfast_for")
    ("for" . "endfor")
    ("foreach" . "endforeach")
    ("repeat" . "endrepeat")
    ("switchon" . "endswitchon"))
  "* Association list of open-close pairs.  Used to scan
over structures.")

(defvar pop-closeit-define-comments t
  "* If non nil, pop-closit adds a comment after closing a definition,
naming the thing defined and any keywords listed in
pop-interesting-declaration-modifiers.")

(defvar pop-file-author (user-full-name)
  "*The name to use in the author field in a Pop-11 file header.")

(defvar pop-file-copyright (user-full-name)
  "*The name of the person or organisation which holds the copyright
on a Pop-11 file.")



;;; pop-mode's internal variables.
;;; Many of these are compiled form the above alists when pop-mode is run.

(defvar pop-syntax-regexp nil)

(defvar pop-syntax-table nil
  "Syntax table for Pop-11")

(define-abbrev-table 'pop-mode-abbrev-table ())

(defvar pop-mode-abbrev-table nil
  "Abbrev tabe in use in pop-mode buffers.")

(defvar pop-mode-map (make-sparse-keymap)
  "Key Map for Pop-11 mode")

(defvar pop-declaration-starters-regexp nil
  "Regular expression matching all declaration starting words.")

(defvar pop-declaration-modifiers-regexp nil
  "Regexp matching declaration modifiers")

(defvar pop-interesting-declaration-modifiers-regexp nil
  "Regular expression matching interesting declaration modifiers")

(defvar pop-definition-start-regexp nil
  "Regular expression matching the start of a (top level) definition.")

(defvar pop-definition-starters-regexp nil
  "Regular expression matching the start of a definition")

(defvar pop-definition-enders-regexp nil
  "Regular expression matching the end of a definition")

(defvar pop-opener-regexp nil
  "Regular expression matching only beginning of structure syntax words")

(defvar pop-closer-regexp nil
  "Regular expression matching only end of structure syntax words")

;; If we are not using XEmacs we assume we are using GNU Emacs and that
;; that we are using versions 19.13/19.29 respectively.
(defconst pop-using-xemacs (string-match "XEmacs" emacs-version)
  "Nil unless using XEmacs).")

;; Set up symbol table.
;; This is a bit of a mess, since there are so many special cases.  In general
;; a word is a quoted unquoted sequence of alphanumeric characters (the first
;; character of which must be alphabetic), or a sequence of sign characters
;;  ! # $ & = - ~ ^ | \ @ + * : < > ? /
;; or a compound of alphanumeric and sign sequences joined by the _ character
;; For example, foo123 +++ fast_++ and ++_lists_++ are all legal.  As far as I
;; can see, the only characters which can't form part of a Pop-11 word are:
;; " % ( ) ' ` { [ } ] ; , .
;; It is not clear why rjc's syntax table places many of these characters in
;; the `symbol constituent' class (syntax class _)
(defun pop-syntax-table ()
  (if (not pop-syntax-table)
      (progn
	(setq pop-syntax-table (make-syntax-table))
	(set-syntax-table pop-syntax-table)

	(modify-syntax-entry ?\\ "\\" pop-syntax-table)
	(modify-syntax-entry ?\" "\"" pop-syntax-table)
	(modify-syntax-entry ?' "\"" pop-syntax-table)
	(modify-syntax-entry ?` "\"" pop-syntax-table)
	(modify-syntax-entry ?: "_" pop-syntax-table)
	(modify-syntax-entry ?_ "_" pop-syntax-table)
	(modify-syntax-entry ?! "_" pop-syntax-table)
	(modify-syntax-entry ?# "_" pop-syntax-table)
	(modify-syntax-entry ?$ "_" pop-syntax-table)
	(modify-syntax-entry ?& "_" pop-syntax-table)
	(modify-syntax-entry ?= "_" pop-syntax-table)
	(modify-syntax-entry ?- "_" pop-syntax-table)
	(modify-syntax-entry ?~ "_" pop-syntax-table)
	(modify-syntax-entry ?^ "_" pop-syntax-table)
	(modify-syntax-entry 124 "_" pop-syntax-table) ; ?|
	(modify-syntax-entry ?@ "_" pop-syntax-table)
	(modify-syntax-entry ?+ "_" pop-syntax-table)
	(modify-syntax-entry ?< "_" pop-syntax-table)
	(modify-syntax-entry ?> "_" pop-syntax-table)
	(modify-syntax-entry ?? "_" pop-syntax-table)
	(modify-syntax-entry ?% "$%" pop-syntax-table)
	;; `,' and `.' should be class `.' ...
	(modify-syntax-entry ?, "_" pop-syntax-table)
	(modify-syntax-entry ?. "_" pop-syntax-table)
	(modify-syntax-entry ?\( "()" pop-syntax-table)
	(modify-syntax-entry ?\) ")(" pop-syntax-table)
	(modify-syntax-entry ?\[ "(]" pop-syntax-table)
	(modify-syntax-entry ?\] ")[" pop-syntax-table)
	(modify-syntax-entry ?\{ "(}" pop-syntax-table)
	(modify-syntax-entry ?\} "){" pop-syntax-table)
        ;; Support both Pop-11 comment styles.
	;; This is totally broken: GNU Emacs suppoosedly supports two
	;; comment styles, but this only works for C++ and other languages
	;; where the both comment styles have the *same* first character.
	(cond
	 (pop-using-xemacs
	  (modify-syntax-entry ?/  "_ 14" pop-syntax-table)
	  (modify-syntax-entry ?*  "_ 23" pop-syntax-table)
	  (modify-syntax-entry ?\; "_ 56" pop-syntax-table) ; ?;
	  (modify-syntax-entry ?\n "> b" pop-syntax-table))
	 (pop-use-pl1-comments
	  (modify-syntax-entry 59 "_" pop-syntax-table) ; ?;
	  (modify-syntax-entry ?\n " " pop-syntax-table)
	  (modify-syntax-entry ?/ "_ 14" pop-syntax-table)
	  (modify-syntax-entry ?* "_ 23" pop-syntax-table))
	 (t
	  (modify-syntax-entry 59 "_ 12" pop-syntax-table) ; ?;
	  (modify-syntax-entry ?\n ">" pop-syntax-table)
	  (modify-syntax-entry ?/ "_" pop-syntax-table)
	  (modify-syntax-entry ?* "_" pop-syntax-table))))
    (set-syntax-table pop-syntax-table)))


;; Need this for inferior-pop-mode
(defun pop-mode-variables ()
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'pop-indent-line)
  (make-local-variable 'comment-column)
  (setq comment-column 40)
  (make-local-variable 'comment-indent-function)
  (setq comment-indent-function 'pop-comment-indent)
  (make-local-variable 'comment-start)
  (make-local-variable 'comment-end)
  (make-local-variable 'comment-start-skip)
  (make-local-variable 'parse-sexp-ignore-comments)
  ;; More Emacs version hacking
  (cond
   (pop-using-xemacs
    ;; We do this like c++ mode and assume that comment-region etc
    ;; will use end of line comments ...
    (setq comment-start ";;;")
    (setq comment-end "")
    (setq comment-start-skip ";;;\\s-*" )
    (setq parse-sexp-ignore-comments t))
   (pop-use-pl1-comments
    (setq comment-start-skip "/\\* *" )
    (setq comment-start "/* ")
    (setq comment-end " */")
    (setq parse-sexp-ignore-comments t))
   (t
    (setq comment-start-skip ";;; *" )
    (setq comment-start ";;; ")
    (setq comment-end "")
    (setq parse-sexp-ignore-comments nil))))

(defun pop-mode-commands (map)
  (define-key map "\n"     'pop-newline-indent)
  (define-key map ";"      'pop-semicolon-indent)
  (define-key map "\e]"    'pop-closeit)

  (define-key map "\e\C-h" 'pop-mark-define)
  (define-key map "\e\C-@" 'pop-mark-structure)

  (define-key map "\e\C-p" 'pop-indent-define)
  (define-key map "\e\C-q" 'pop-indent-sexp)
  (define-key map "\e\C-r" 'pop-indent-region)

  (define-key map "\e\C-a" 'pop-beginning-of-define)
  (define-key map "\e\C-e" 'pop-end-of-define)
  (define-key map "\e\C-f" 'pop-forward-sexp)
  (define-key map "\e\C-b" 'pop-backward-sexp)
  (define-key map "\ef"    'pop-forward-word)
  (define-key map "\eb"    'pop-backward-word)

  ;; Invoking pop-help-mode: this is useful even if there is no pop process.
  (if pop-using-xemacs
        (define-key map [(control h) p ] 'pop-get-help)
    (define-key map "\C-hp" 'pop-get-help)))
(pop-mode-commands pop-mode-map)

;; The standard way to define menus in GNU emacs is horrible (one of many
;; reasons for using XEmacs), so use the easymenu package which works for both.
(easy-menu-define
 pop-mode-menu
 pop-mode-map
 "Menu for Pop-11 mode."
 '("Pop-11"
   ["Beginning of procedure" pop-beginning-of-define t]
   ["End of procedure" pop-end-of-define t]
   ["Indent procedure" pop-indent-define t]
   ["Indent region" pop-indent-region (mark)]
   ["Comment region" comment-region (mark)]
   ["Uncomment region" pop-uncomment-region (mark)]
   ["Mark procedure" pop-mark-define t]
   "----"
   ["Run Pop" run-pop-other-frame t]
   ["Compile procedure" pop-send-define (inferior-pop-process-p)]
   ["Compile region" pop-send-region (inferior-pop-process-p)]
   ["Compile buffer" pop-send-buffer (inferior-pop-process-p)]
   ["Load file" pop-load-file (inferior-pop-process-p)]))


(defun pop-mode ()
  "Major mode for editing Pop-11 code.

Commands:
\\{pop-mode-map} "
  (interactive)
  (kill-all-local-variables)
  (use-local-map pop-mode-map)
  (setq major-mode 'pop-mode)
  (setq mode-name "Pop-11")
  (setq local-abbrev-table pop-mode-abbrev-table)
  (setq pop-syntax-regexp
	(list-to-regexp pop-indentation-info
			'car '(lambda (x) (concat "\\<" x "\\>"))))
  (setq pop-opener-regexp
	(list-to-regexp pop-open-close-assoc 'car))
  (setq pop-closer-regexp
	(list-to-regexp pop-open-close-assoc 'cdr))
  (setq pop-declaration-starters-regexp
	(list-to-regexp pop-declaration-starters))
  (setq pop-declaration-modifiers-regexp
	(concat (list-to-regexp pop-declaration-modifiers) "\\|[0-9]+" ))
  (setq pop-interesting-declaration-modifiers-regexp
	(concat (list-to-regexp pop-interesting-declaration-modifiers) "\\|[0-9]+" ))
  (setq pop-definition-start-regexp
	(concat "^\\(" (list-to-regexp pop-definition-starters) "\\)"))
  (setq pop-definition-starters-regexp
	(list-to-regexp pop-definition-starters) )
  (setq pop-definition-enders-regexp
	(list-to-regexp pop-definition-enders nil
			'(lambda (x) (concat "^[ \t]*" x))))
  (pop-syntax-table)
  (pop-mode-variables)
  ;; If we are using XEmacs add the menu to the menubar.  For GNU Emacs we
  ;; don't have to explictly add the menu to the menubar -- menus automatically
  ;; appear and disappear when the keymaps specified by the MAPS argument to
  ;; `easy-menu-define' are activated (yuk).
  (if pop-using-xemacs
      (easy-menu-add pop-mode-menu))
  (run-hooks 'pop-mode-hook))



;;; Indentation commands.

(defun pop-indent-define ()
  "Indent the definition containing or following point."
  (interactive)
  (save-excursion
    (let (end)
      (pop-end-of-define)
      (setq end (point))
      (pop-beginning-of-define)
      (pop-indent-region (point) end))))

(defun pop-indent-sexp ()
  "Indent the sexp following point."
  (interactive)
  (let ((end (save-excursion (pop-forward-sexp) (point))))
    (pop-indent-region (point) end)))

(defun pop-indent-region (start end)
  "Indent all lines in region."
  (interactive "m\nd")
  (if (not (markerp start))
      (setq start (set-marker (make-marker) start)))
  (if (not (markerp end))
      (setq end (set-marker (make-marker) end)))
  (save-excursion
    (let (pop-cache-valid
	  (lines (count-lines start end)))
      (if ( < lines 20)
	  (setq lines -1))
      (goto-char start)
      (while (< (point) (marker-position end))
	(if (< 0 lines)
	    (if (eq (mod lines 10) 0)
		(message "%d lines" lines))
	  (setq lines (1- lines)))
      (pop-indent-line)
      (setq pop-cache-valid t)
      (forward-line 1))
    (if (>= lines 0) (message "Done")))))


(defun pop-indent-line ()
  "Indent the current line as a pop-11 statement. Looks at
the previous line and checks for indentation."
  (interactive)
  (let ((indent (calculate-pop-indent))
	where)
    ;; calaculte-pop-indent is broken -- it returns negative values
    ;; if the preceeding code is badly formatted (i.e. formatted using
    ;; different pop-indentation-info) : bsl 06/11/95
    (if (< indent 0)
	(setq indent 0))
    (if (eq indent nil )
	(setq indent 0)
      (if (eq indent t)
	  (setq indent (calculate-pop-indent-within-comment))))
    (save-excursion
      (beginning-of-line)
      (skip-chars-forward " \t")
      (setq where (point))
      (if (<= (current-column) indent)
	  (indent-to indent)
	(progn
	  (move-to-column indent)
	  (if (save-excursion (backward-char 1) (looking-at "\t"))
	      (backward-char 1))
	  (delete-region (point) where)
	  (indent-to indent))))
    (if (< (current-column) indent)
	(move-to-column indent))))

(defun pop-semicolon-indent ()
  "Inserts a semicolon and then indents the line."
  (interactive)
  (insert-char ?; 1)
  (indent-for-tab-command))

(defun pop-newline-indent ()
  "Indent for new line."
  (interactive)
  (let ((pop-cache-valid))
       ;(indent-for-tab-command) revised 17.07.89 bsl
       ;(setq pop-cache-valid t)
    (newline)
    (indent-for-tab-command)))


;; The following variables are used to cache information relating to the
;; indentation of lines.  This allows us to re-use information from the last
;; call if, as is often the case, it is still valid.  Testing for validity
;; is hard, so we compromise.  We assume the cache is valid if a marker at
;; the begining of the last line is still there and has not moved (and, of
;; course, if this is the following line ).

;; Programatic calls of pop-indent line which can assure validity (e.g.
;; pop-indent-region and pop-newline-indent) locally set pop-cache-valid to
;; t, thus forcing use of the cache.

(defvar pop-cache-line-info nil)
(defvar pop-cache-parse-start nil)
(defvar pop-cache-state nil)
(defvar pop-cache-decls nil)
(defvar pop-cache-where nil)
(defvar pop-cache-where-marker (make-marker))
(defvar pop-cache-valid nil)

(defun calculate-pop-indent ()
  "Return appropriate indentation for current line as Pop-11 code.
Returns the column to indent to (an integer), nil if the line starts inside
a string, t if in a comment."
  (save-excursion
    (beginning-of-line)
    (let ((indent-point (point))
	  (case-fold-search nil)
	  (parse-sexp-ignore-comments t) ;locally do this globally may not
	  old-state old-decls decls line-info state parse-start info indent
	  next-line)
      (if (or pop-cache-valid
	      (and (eql pop-cache-where
			(marker-position pop-cache-where-marker))
		   (eql pop-cache-where
			(save-excursion (forward-line -1) (point)))))
	  ;; Cached information is valid
	  (progn
	    (goto-char (setq parse-start pop-cache-parse-start))
	    (setq line-info pop-cache-line-info)
	    (setq old-state (setq state pop-cache-state))
	    (setq decls pop-cache-decls))
	;; Cached information is not valid, find the enclosing define
	(if (not (looking-at pop-definition-starters-regexp))
	    (pop-beginning-of-define))
	(setq parse-start (point))
	(setq line-info (list (list 0 (point) nil)))
	(setq old-state (setq state '(0 nil nil nil nil)))
	(setq decls nil))

      (while (< (point) indent-point)
	(setq next-line (save-excursion
			  (end-of-line)
			  (parse-partial-sexp (point) indent-point nil t nil)
			  (beginning-of-line)
			  (skip-chars-forward " \t\n") ;
			  (point)))
	(setq old-decls decls)
	;; look for declaration starts and ends
	(if (looking-at pop-declaration-starters-regexp)
	    (setq decls (cons (car state) decls)))
	(if (and decls
		 (eql (car decls) (car state))
		 (looking-at "[^\n;]*;\\s-*$"))
	    (setq decls (cdr decls)))
	(while (and line-info
		    state
		    (<= (car state) (car (car line-info))))
	  (setq line-info (cdr line-info)))
	(setq line-info (cons (list (car state) (point) old-decls) line-info))
	(setq parse-start (point))
	(setq old-state state)
	(setq state (parse-partial-sexp (point)
					(min next-line indent-point)
					nil nil state)))

      (setq pop-cache-line-info line-info)
      (setq pop-cache-state old-state)
      (setq pop-cache-parse-start parse-start)
      (setq pop-cache-decls old-decls)
      (setq pop-cache-where indent-point)
      (set-marker pop-cache-where-marker indent-point)

      (cond ((or (nth 3 state) (nth 4 state))
	     (nth 4 state))
	    (t
	     (if (> (car state) (car (car line-info)))
		 ;; we have pushed a level, indent to start of expression
		 (progn
		   ;; goto containing expression
		   (goto-char (car (cdr state)))
		   (forward-char 1)
		   ;; special case for "[%"
		   ;; should not be needed since % is defined as a
		   ;; bracket, however emacs is broke.
		   (if (looking-at "[ \t]*%")
		       (progn
			 (skip-chars-forward " \t")
			 (forward-char 1)))
		   (skip-chars-forward " \t")
		   (setq indent (current-column)))
	       ;; Otherwise goto last line at same level	
	       (while (< (car state) (car (car line-info)))
		 (setq line-info (cdr line-info)))
	       (goto-char (nth 1 (car line-info)))
	       (skip-chars-forward " \t")
	       (setq indent (current-column)))
	     (skip-chars-forward " \t\n\f")
	     (setq indent (+ indent
			     (* (- (length decls)
				   (length (nth 2 (car line-info))))
				pop-declaration-indent-step)))
	     (setq next-line (save-excursion
			       (goto-char indent-point)
			       (forward-line 1)
			       (point)))
	     (while (< (point) indent-point)
	       (if (and (looking-at pop-syntax-regexp)
			(setq info (assoc (next-word) pop-indentation-info)))
		   (setq indent (+ indent (nth 2 info)))
		 (if (and (not decls)
			  (looking-at pop-label-regexp))
		     (progn
		       (setq indent (+ indent pop-label-indent)))))
	       (forward-sexp 1)
	       (skip-chars-forward "\t\n\f ")
	       (if (and (< (point) next-line)
			(looking-at pop-syntax-regexp)
			(setq info (assoc (next-word) pop-indentation-info )))
		   (setq indent (+ indent (nth 1 info)))
		 (if (and (not decls)
			  (looking-at pop-label-regexp))
		     (setq indent (- indent pop-label-indent)))))
	     indent)))))

(defun calculate-pop-indent-within-comment ()
  "Return the indentation amount for line, assuming that
the current line is to be regarded as part of a block comment."
  (let (end star-start)
    (save-excursion
      (beginning-of-line)
      (skip-chars-forward " \t")
      (setq star-start (= (following-char) ?\*))
      (skip-chars-backward " \t\n")
      (setq end (point))
      (beginning-of-line)
      (skip-chars-forward " \t")
      (and (re-search-forward "/\\*[ \t]*" end t)
	   star-start
	   (goto-char (1+ (match-beginning 0))))
      (current-column))))

(defun pop-comment-indent ()
  (save-excursion
    (let ( next)
      (end-of-line)
      (save-excursion
	(beginning-of-line)
	(parse-partial-sexp (point) (point-max) nil t)
	(setq next (point)))
      (if (< (point) next)
	  (calculate-pop-indent)
	(max (1+ (current-column)) comment-column)))))



;;; Region commands.

(defun pop-mark-define ()
  "Mark the current procedure."
  (interactive)
  (let ((proc (pop-define-ends)))
       (push-mark (car proc))
       (goto-char (cdr proc))
       (message "Mark set")))

(defun pop-mark-sexp (n)
  "Set mark after N sexps."
  (interactive "p")
  (let ((i 0) where)
    (save-excursion
      (while (< i n)
	(pop-forward-sexp)
	(setq i (1+ i)))
      (setq where (point)))
    (set-mark where)
    (message "Mark set")))

(defun pop-uncomment-region (start end)
  "Uncomment each line in region."
  (interactive "r")
  (comment-region start end -1))



;;; Movement commands.

(defun pop-beginning-of-define (&optional num)
  "Move back to beginning of definition.
With argument, do this N times."
  (interactive "p")
  (setq num (or num 1))
  (if (not (looking-at pop-definition-start-regexp))
      (forward-line 1))
  (while (> num 0)
    (re-search-backward pop-definition-start-regexp nil 'bob)
    (setq num (1- num))))


;; With a negative argument, this goes back N defuns then forward to
;; the end of the Nth defun.
(defun pop-end-of-define (&optional num)
  "Move to end of definition.
With argument, do this N times."
  (interactive "p")
  (setq num (or num 1))
  ;; we should trap the case where num is 0
  (if (> num -1 )
      (let ((pos (point)))
	(forward-char 1)
	(pop-beginning-of-define)
	(while (or (> num 0 ) (>= pos (point)))
	  (re-search-forward pop-definition-start-regexp nil 'bob)
	  (beginning-of-line)
	  (pop-forward-sexp)
	  (setq num (1- num))
	  (forward-line 1)
	  (beginning-of-line)))
    (progn
      (pop-beginning-of-define (- 1 num))
      (pop-end-of-define 1))))


(defun pop-forward-sexp (&optional n)
  "Move forward across one sexp.
With argument, do this N times."
  (interactive "p")
  (or n (setq n 1))
  (while ( > n 0 )
    (let* ((them (catch 'syntax (pop-end-of-sexp)))
	   (what (car them))
	   (end (cdr them)))
      (if (< end 0 )
	  (progn
	    (goto-char (- end))
	    (error "Unmatched %s" what))
	(goto-char end)))
    (setq n (1- n))))


(defun pop-backward-sexp (n)
  "Move backwards across one sexp.
With argument, do this N times."
  (interactive "p")
  (or n (setq n 1))
  (while (> n 0)
    (backward-sexp 1)
    (let ((start (point)))
      (while (or (and (> (point) (point-min))
		      (> start (save-excursion (pop-forward-sexp)
					       (point))))
		 (looking-at pop-closer-regexp))
	(backward-sexp 1)))
    (setq n (1- n))))


(defun pop-forward-word (n)
  "Move forward over a Pop-11 word.
With optional argument, do this N times."
  (interactive "p")
  (while (> n 0)
    (forward-word 1)
    (skip-chars-forward "_")
    (while (looking-at "\\sw")			
      (forward-word 1)
      (skip-chars-forward "_"))
    (setq n (1- n))))


(defun pop-backward-word (n)
  "Move backward over a Pop-11 word.
With optional argument, do this N times."
  (interactive "p")
  (while (> n 0)
    (forward-word -1)
    (skip-chars-backward "_")
    (while (and (> (point) 0)
		(save-excursion (forward-char -1)
				(looking-at "\\sw")))
      (forward-word -1)
      (skip-chars-backward "_"))
    (setq n (1- n))))

;; This does all the work for pop-[forward|backward]-sexp and hence
;; for pop-[beginning|end]-of-define, pop-indent-[define|sexp] and
;; pop-mark-sexp.  Comments are for debugging purposes ...
(defun pop-end-of-sexp (&optional finish)
  "Returns a pair ( what . end ) where what is a pop syntax opener and
end is the point in the file at which it ends. If end is negative then there
was an unclosed structure of type what *starting* at end"
  (setq finish (or finish (point-max)))
  (save-excursion
    (let ((parse-sexp-ignore-comments t) ;locally do this globally may not
	  start end last opener closer closer-regexp)
      (forward-sexp 1)
      (setq end (point))
      (setq start (save-excursion (backward-sexp 1) (point)))
      (setq last start)
      ; move forward one `expression' as defined by the (broken) syntax
      ; table -- find out if what we just skipped over was an opener and
      ; if it was find the associated closer, otherwise these are nil.
      ;; Note that we could do this with pop-next-sexp and match data
      (setq opener (buffer-substring start end))
      (setq closer (assoc opener pop-open-close-assoc))
      ; if the opener is one that starts a definition, eat any modifiers
      (if (string-match pop-definition-starters-regexp opener)
	  (while (looking-at pop-declaration-modifiers-regexp)
	    (forward-sexp 1)))
      ; we should now be after the opener and any whitespace ...
      ; if closer is non nil (i.e. there was an opener, then do the
      ; following, otherwise simply return a pair of the `opener' (which
      ; wasn't an opener as it didn't have a closer) and point.
      (if closer
	  (progn
	    ; get a regexp that matches the closer
	    (setq closer-regexp (concat (regexp-quote (cdr closer)) "\\>"))
	    (while (and (pop-next-sexp)
			; check that we have moved, i.e. that there are more
			; sexps, and that we are not at the end of the buffer
			(not (or (= (point) last)
				 (>= (point) finish)
				 (looking-at pop-closer-regexp)
				 (looking-at pop-definition-enders-regexp))))
	      ;; this should be more efficient than rjc's version since
	      ;; we aren't recursing for every structure, only the openers
	      (if (looking-at pop-opener-regexp)
		  (goto-char (cdr (pop-end-of-sexp finish)))
		(setq last (point))))
	    ; if that didn't leave just before the closer, then we have
	    ; reached the end of the current defun (or limit) without
	    ; finding the closer for the current opener -- throw an error
	    (if (not (looking-at closer-regexp))
		(throw 'syntax (cons opener (- start))))
	    ; otherwise move forward over the closer -- this is the tricky
	    ; bit, if \; is not part of the closer, forward-sexp leaves us
	    ; on the semicolon and the next forward structure doesn't work
	    ; ?but why doesn't it work?
	    (forward-sexp 1)))
      (cons opener (point)))))


;; This effectively replaces pop-skip-over-white-space (so much for the
;; syntax table).  There must be a better way, unfortuately forward-sexp
;; always returns nil ...  Also fix this so that it works with negative
;; arguments.  It might also be a good idea to fix this so that it returns
;; nil if we can't move over n sexps, for example when we are at then end
;; of the last sexp in the buffer.
(defun pop-next-sexp (&optional num)
  "Move to the start of the next sexp following point.
With optional arg, do this N times."
  (let ((num (or num 1))
	(start (point)))
    ;; work out if we are at the end of an sexp
    (forward-sexp)
    (backward-sexp)
    (if (> (point) start)
	(if (eq num 1)
	    (point)
	  (forward-sexp num)
	  (backward-sexp num)
	  (point))
      (forward-sexp (1+ num))
      (backward-sexp num)
      (point))))

(defun pop-define-ends ()
  "Return the start and end of the current procedure as a pair."
  (let ( start end )
    (save-excursion
      (pop-beginning-of-define)
      (setq start (point))
      (pop-forward-sexp)
      (setq end (point)))
    (cons start end)))



;;; Completion

;; pop-closit closes the last open sexp, e.g. inserts an endfor after a for.
;; When closing a `define' it adds a comment naming the thing defined and
;; possibly the fact that it is a macro etc.
(defun pop-closeit (n)
  "Close the last N sexps.
If the structure being closed is a define and pop-closeit-define-comments
is non nil, adds a comment naming the thing defined and any keywords listed
in pop-interesting-declaration-modifiers."
  (interactive "p")
  (let ((place (point))
	what
	start)
    (save-excursion
      (setq start (save-excursion (pop-beginning-of-define) (point)))
      (condition-case nil
	  (progn
	    (goto-char (scan-lists (point) -1 1))
	    (goto-char (scan-lists (point) 1 -1))
	    (skip-chars-forward " \t%" ))
	('error (goto-char start)))
      (if (< (point) start)
	  (goto-char start))
      (let* ((them (catch 'syntax (pop-end-of-sexp place))))
	(setq start  (- (cdr them)))
	(if (or (< start 0 ) (> start place))
	    (error "Nothing unclosed"))
	(goto-char start)
	(setq what (car them))))
    (beginning-of-line)
    (if (not (looking-at "[ \t]*\n"))
	(progn
	  (end-of-line)
	  (newline 1)))
    (insert-string (cdr (assoc what pop-open-close-assoc)))
    (insert-string ";")
    (if (and pop-closeit-define-comments
	     (equal what "define"))
	(progn
	  (insert-string "    ;;; ")
	  (insert-string (pop-define-name start))))
    (pop-indent-line)))

(defun pop-define-name (&optional where)
  "Returns the name of the current define, or the one starting
at WHERE, if that is given. The name  will include any `interesting'
keywords in the declaration. See pop-interesting-declaration-modifiers"
  (interactive "d")
  (save-excursion
    (let ((name ""))
      (if where
	  (goto-char where)
	(pop-beginning-of-define))
      (forward-sexp 1)
      (pop-skip-over-whitespace)
      (while (looking-at pop-declaration-modifiers-regexp)
	(if (looking-at pop-interesting-declaration-modifiers-regexp)
	    (setq name (concat name " "
			       (buffer-substring (point)
						 (progn
						   (forward-sexp 1)
						   (point)))))
	  (forward-sexp 1))
	(pop-skip-over-whitespace))
      (let ((start (point)))
	(forward-sexp 1)
	(concat name " " (buffer-substring start (point)))))))

;; Still used in pop-define-name
(defun pop-skip-over-whitespace ()
  "Moves forward over whitespace and comments. This is a little
weird."
  (interactive)
  (let* (parse-sexp-ignore-comments
	 nocom)
    (setq parse-sexp-ignore-comments t)
    (setq nocom (save-excursion (forward-sexp) (point)))
    (setq parse-sexp-ignore-comments nil)
    (while (not (eql (save-excursion (forward-sexp) (point)) nocom))
      (forward-sexp))
    (skip-chars-forward " \t\n\f")))



;;; File headers and CHANGELOG entries

;;; Create a header at the top of a Poplog file in the "standard"
;;; Sussex/Birmingham format.
(defun pop-insert-file-header (&optional file)
  "Add a Poplog file header comment at the beginning of FILE."
  (interactive)
  (let* ((file-name (or (and file (expand-file-name file))
		       buffer-file-name))
	(user-name (or pop-file-author (user-full-name)))
	(date (substring (current-time-string) 4 10))
	(year (substring (current-time-string) -4 nil))
	(copyright (format  "Copyright %s %s. All rights reserved."
			    pop-file-copyright year))
	;; By convention, the length of the line should be 76 characters.
	;; The following centres the copyright notice ...
	(left-padding (max 0 (- 38 4 (floor (length copyright) 2))))
	(right-padding (max 0 (- 38 2 (ceiling (/ (length copyright) 2)))))
	(left-heading (concat "/* " (make-string left-padding ?-)))
	(right-heading (concat (make-string right-padding ?-) "\n")))
    (if (not file-name)
	;; Perhaps this should prompt for a file name rather than just failing
	(message "ERROR: no file for buffer %s" (buffer-name))
      (goto-char (point-min))
      (undo-boundary)
      (insert (format "%s %s %s > File:            %s\n > Purpose:         \n > Author:          %s, %s %s\n > Documentation:   \n > Related Files:   \n > RCS Info:        $Id: pop-mode.el,v 1.26 2003/08/26 09:52:34 bsl Exp $\n */\n\n" left-heading copyright right-heading file-name user-name date year)))
    ;; It might be a good idea to delete any existing header at this point
    ;; on the other hand, we may want to copy information from an existing
    ;; header ...
))

;; A version of add-change-log-entry, modified for Poplog revision log
;; conventions: i.e. the revision log is at the end of the file to which the
;; log entry relates.  It would be nice to use change-log-mode for this, but
;; it is a major mode and trashes pop-mode.  For the moment, we just use
;; filladapt mode (which is already on by default in our pop-mode buffers)
;; or auto-fill-mode in the case of GNU Emacs.  Perhaps we should snarf the
;; comment text in a temp buffer (as in VC) and insert it into the pop
;; buffer ...
(defun pop-add-revision-log-entry (&optional whoami)
  "Find revision log comment and add an entry for today.
Optional arg (interactive prefix) non-nil means prompt for user name and site."
  (interactive "P")
  (or add-log-full-name
      (setq add-log-full-name (user-full-name)))
  (or add-log-mailing-address
      (setq add-log-mailing-address user-mail-address))
  (if whoami
      (progn
        (setq add-log-full-name (read-string "Full name: " add-log-full-name))
	;; Note that some sites have room and phone number fields in
	;; full name which look silly when inserted.  Rather than do
	;; anything about that here, let user give prefix argument so that
	;; s/he can edit the full name field in prompter if s/he wants.
	(setq add-log-mailing-address
	      (read-string "Mailing address: " add-log-mailing-address))))

  (if buffer-file-name
      (let ((file-name buffer-file-name)
	    (defun (pop-define-name)))
    ;; This seems a more reasonable default, given that the log is in this file
    (find-file-other-window file-name)
    ;; This should be rewritten for revision logs, as change-log-mode is a
    ;; major mode and trashes pop-mode.  For the moment, we just use
    ;; filladapt mode (which is already on by default in our pop-mode
    ;; buffers) or auto-fill-mode in the case of GNU Emacs
;    (or (eq major-mode 'change-log-mode)
;	(change-log-mode))
    (auto-fill-mode 1)
    (undo-boundary)
    (goto-char (point-min))

    ;; Search for a Revision History comment, or make one at the end of the file
    (if (search-forward "/* --- Revision History" nil 'eob)
	(forward-line 2)
      (insert "\n/* --- Revision History ---------------------------------------------------\n\n\n\n\*/\n")
      (forward-line -3))

    (if (looking-at (concat (regexp-quote (substring (current-time-string)
						     0 10))
			    ".* " (regexp-quote add-log-full-name)
			    "  <" (regexp-quote add-log-mailing-address)))
	(forward-line 1)
      (insert (current-time-string)
	      "  " add-log-full-name
	      "  <" add-log-mailing-address ">\n\n\n")
      (forward-line -2))

    ;; Make a new entry
    (while (looking-at "\\sW")
      (forward-line 1))
    (while (and (not (eobp)) (looking-at "^\\s *$"))
      (delete-region (point) (save-excursion (forward-line 1) (point))))
    (insert "\n\n\n")
    (forward-line -2)
    (indent-to left-margin)
    (insert "* ")
    ;; Now insert the function name, if we have one.
    (if defun
	(progn
	  ;; Make it easy to get rid of the function name.
	  (undo-boundary)
	  (insert defun " : "))))
    ;; If there is no file for this buffer, we should prompt for a filename ...
    (message "ERROR: no file for buffer %s" (buffer-name))
    (beep)))



;;; Utilities

(defun list-to-regexp (list &optional fn mod)
  "Make a regular expression which matches the strings in LIST
If FN is given it is used to process elements of LIST before they are used.
MOD, if given is used to process the individual regular expressions before
they are concatenated together"
  (let ((l () ) re)
    (if (not mod)
	(setq mod 'identity))
    (if (not fn)
	(setq fn 'identity))
    (while (consp list)
      (setq re (apply mod
		      (regexp-quote (apply fn (car list) nil))
		      nil))
      (setq l (cons "\\|" (cons re l)))
      (setq list (cdr list)))
    (apply (function concat) (cdr l))))


(defun looking-at-oneof (list)
  "t if point is at the start of one of the words in LIST"
  (let* ((fl nil) (i list)
	 (start (point))
	 (word (save-excursion (forward-word 1)
			       (buffer-substring start (point)))))
    (while (and i (not fl))
      (if (equal word (car i))
	  (setq fl t))
      (setq i (cdr i)))
    fl))

(defun next-word ()
  (buffer-substring
   (point)
   (save-excursion
     (forward-word 1)
     ( while (equal (char-after (point)) ?_ )
       (forward-word 1))
     (point) )))



;;; Pop11 keywords to highlight in font-lock-mode
;;; font-lock-keywords are used for tokens not covered by the standard
;;; syntax table entries, i.e. anything which isn't a comment or a string.

;; Note: can't have docstrings in GNU Emacs face declarations, but GNU
;; requires expressions for the face names so we can use the var docstrings.
(defvar pop-vars-declaration-face 'pop-vars-declaration-face
  "Face for Pop-11 variable and constant declarations.")

(defvar pop-struct-declaration-face 'pop-struct-declaration-face
  "Face for Pop-11 class and record declarations.")

;; Defining the faces: this is not as simple as it should be.  XEmacs is
;; straightforward: font-lock works on window systems and ttys and the face
;; functions are fail safe, but as usual, GNU is broken and we need to make
;; sure we are running X or similar, since font-lock doesn't work for ttys.
;; Note that, at the moment, if someone tries to use font-lock in pop-mode
;; with GNU emacs on a tty the struct and vars faces will be undefined, but
;; font-lock won't work anyway.

;; It would be nice to base the declaration faces on
;; font-lock-function-name-face since vars and structs are also top level
;; declarations and in case the user has already defined a
;; function-name-face.
(cond (pop-using-xemacs
       ;; XEmacs font-lock-function-name-face is bold black by default.
       ;; Face for Pop-11 variable and constant declarations other than procs
       (make-face 'pop-vars-declaration-face)
       (make-face-bold 'pop-vars-declaration-face)
       ;; Face for Pop-11 class and record declarations.
       (make-face 'pop-struct-declaration-face)
       (make-face-bold 'pop-struct-declaration-face))
      (window-system
       ;; GNU font-lock-function-name-face is not bold blue by default.
       ;; Face for Pop-11 variable and constant declarations other than procs
       (make-face 'pop-vars-declaration-face)
       (set-face-foreground 'pop-vars-declaration-face "firebrick")
       ;; Face for Pop-11 class and record declarations.
       (make-face 'pop-struct-declaration-face)
       (set-face-foreground 'pop-struct-declaration-face "brown")))

(defconst pop-font-lock-keywords-1 nil
 "For consideration as a value of `pop-font-lock-keywords'.
This does fairly subdued highlighting.")

(defconst pop-font-lock-keywords-2 nil
 "For consideration as a value of `pop-font-lock-keywords'.
This does a lot more highlighting.")

(setq pop-font-lock-keywords-1
      (purecopy
       (list
	;; Highlight procedure and method definitions -- this is tacky,
	;; it assumes that anything that starts with a colon is a keyword
	;; like :class
	(cons
	 "^define\\s +\\([^: \t\n(){};,]+\\)"
	 '(1 font-lock-function-name-face))

	;; Procedure variables wherever they occur
	(cons
	 "procedure\\s +\\([^ \t\n(){};,]+\\)"
	 '(1 font-lock-function-name-face))

	;; Handle updaters as a special case
;	(cons
;	 "^define\\s +\\([^ \t\n(){};,]+\\s +\\)*updaterof\\s +\\([^: \t\n(){};,]+\\)"
;	 '(2 font-lock-function-name-face))

	;; Handle methods as a special case
	(cons
	 "^define\\s +\\([^ \t\n(){};,]+\\s +\\)*:method\\s +\\([^: \t\n(){};,]+\\)"
	 '(2 font-lock-function-name-face))

	;; Highlight other declarations/definitions (classes, rules)
	(cons
	 (concat
	  "^define\\s +"
	  "\\(" (mapconcat 'identity
			   '(":class" ":mixin" ":singleton"
			      ":method" ":wrapper" ":instance"
			     ":ruleset" ":rule")
			   "\\|") "\\)\\s +"
	  "\\([^ \t\n(){};,]+\\)")
	 '(2 pop-struct-declaration-face))

	;; Highlight structure (class + record) variables wherever they occur
	(cons
	 (concat
	  "\\(" (mapconcat 'identity
			   '("recordclass" "vectorclass" "defclass")
			   "\\|") "\\)\\s +"
	  "\\([^ \t\n(){};,]+\\)")
	 '(2 pop-struct-declaration-face))

	;; Highlight vars and constants -- since this is hopeless in the
	;; general case, we change the problem and highlight the keywords
	;; when they are used in external declarations.  It is up to the
	;; user to work out what follows, just like the other keywords
	(cons
	 (concat
	  "^\\(" (mapconcat 'identity
			    '("vars" "lvars" "constant" "lconstant")
			    "\\|") "\\)\\s +")
	 '(1 font-lock-keyword-face))
	)))

;; In the tradition of font-lock this does quite a lot of highlighting
;; still have to work out what to do for the other declararions such as
;; recordclass etc.  Also problems with keywords such as `vars' appearing
;; as declaration modifiers ...
(setq pop-font-lock-keywords-2
      (purecopy
       (list
	;; Highlight procedure definitions -- this is tacky, it assumes that
	;; anything that starts with a colon is a keyword like :class
	(list
	 "^\\(define\\)\\s +\\([^: \t\n(){};,]+\\)"
	 '(1 font-lock-keyword-face)
	 '(2 font-lock-function-name-face))

	;; Procedure variables wherever they occur
	(list
	 "\\(procedure\\)\\s +\\([^ \t\n(){};,]+\\)"
	 '(1 font-lock-keyword-face)
	 '(2 font-lock-function-name-face))

	;; Highlight other declarations/definitions (methods, classes and
	;; rules)
	(list
	 (concat
	  "^\\(define\\)\\s +"
	  "\\(" (mapconcat 'identity
			   '(":class" ":mixin" ":singleton"
			     ":method" ":wrapper" ":instance"
			     ":rulesystem" ":rulefamily" ":ruleset" ":rule")
			   "\\|") "\\)\\s +"
	  "\\([^ \t\n(){};,]+\\)")
	 '(1 font-lock-keyword-face)
	 '(2 font-lock-reference-face)
	 '(3 pop-struct-declaration-face))

	;; Highlight structure (class + record) variables
	(list
	 (concat
	  "^\\(" (mapconcat 'identity
			   '("recordclass" "vectorclass" "defclass")
			   "\\|") "\\)\\s +"
	  "\\([^ \t\n(){};,]+\\)")
	 '(1 font-lock-keyword-face)
	 '(2 pop-struct-declaration-face))

	;; Highlight vars and constants -- since this is hopeless in the
	;; general case, we change the problem and highlight the keywords
	;; when they are used in external declarations.  It is up to the
	;; user to work out what follows, just like the other keywords
	(cons
	 (concat
	  "\\<\\(" (mapconcat 'identity
			    '("global" "vars" "lvars" "dlocal" "dlvars"
			      "constant" "lconstant")
			    "\\|") "\\)\\s +")
	 '(1 font-lock-keyword-face))

	;; Highlight openers and closers (see HELP *SYSWORDS)
	;; The obvious approach of using "[ \t\n]" as a prefix doesn't work
	;; for openers or closers at the beginning of a line: "font-lock
	;; regular expressions should not match text which spans lines.
	;; While font-lock-fontify-buffer handles multi-line patterns
	;; correctly, updating when you edit the buffer does not, since it
	;; considers text one line at a time."
	(cons
	 (concat
	  "\\(^\\|\\s-+\\)\\("
	  (mapconcat 'identity
		     '("for" "in" "on" "from" "to" "by" "till" "do" "endfor"
		       "fast_for" "endfast_for"
		       "while" "endwhile"
		       "until" "enduntil"
		       "repeat" "times" "forever" "endrepeat"
		       "switchon" "case" "andcase" "orcase"
		       "notcase" "notandcase" "notorcase" "endswitchon"
		       "if" "then" "elseif" "else" "endif"
		       "unless" "elseunless" "endunless"
		       "and" "or"
		       "instance" "endinstance" "slot" "is"
		       "endprocedure" "enddefine"
		       )
		     "\\|")
	  ;; should be only whitespace following?
	  "\\)[ \t\n(){};,-]")
	 2)
	)))

(defconst pop-font-lock-keywords
  (if font-lock-maximum-decoration
      pop-font-lock-keywords-2
    pop-font-lock-keywords-1)
  "*Pop-11 keywords to highlight in font-lock-mode")

;; We don't need to do this for XEmacs as font-lock-mode is quite clever
;; about working out what the keywords for a mode might be called, but every
;; little helps
(cond (pop-using-xemacs
       (put 'pop-mode 'font-lock-keywords 'pop-font-lock-keywords))
      (window-system
       (font-lock-add-keywords 'pop-mode pop-font-lock-keywords)))


;;; pop-mode.el ends here
(provide 'pop-mode)
