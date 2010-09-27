;;; pop-help-mode.el -- Major mode for reading Poplog help documentation.    

;; This file is part of Pop-mode

;; Copyright (C) 1990 Richard Caley
;; Copyright (C) 1996 Brian Logan

;; Authors: Richard Caley <rjc@cstr.ed.ac.uk>
;;          Brian Logan <bsl@cs.bham.ac.uk>

;; Help file editing functions by Stephen Eglen <stephene@cogs.susx.ac.uk>

;; Maintainer: Brian Logan <b.s.logan@cs.bham.ac.uk>
;; RCS info: $Id: pop-help-mode.el,v 1.19 1999/09/02 19:12:38 bsl Exp $
;; Keywords: Poplog, pop11

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
;;; pop-help-mode (was pop-sys-file-mode)
;;;                                                                  
;;;         Richard Caley 1990 and beyond.                           
;;;         Prolog support by Brian Logan.                           
;;;                                                                  
;;; A major mode for reading poplog help documentation.              
;;;                                                                  
;;; By default pop-help-mode creates one buffer for each type of help file
;;; HELP, TEACH etc.  Making pop-help-always-create-buffer non nil creates a
;;; new buffer for each file and it is up to the user to manage the resulting 
;;; buffers.  Like ved, pop-help-mode uses the Poplog searchlists to decide
;;; which directories to search for help files.  This is generally a Good 
;;; Thing but a) it can be slow and b) it won't find help files which are
;;; not in the default seachlists and where the corresponding library hasn't
;;; been loaded.  If you don't like this behaviour, you can set 
;;; pop-help-always-use-defaults to t and redefine the default searchlists in 
;;; your .emacs to include the help directories for the libraries you use.
;;;                                                                  
;;; If pop-help-short-command is set true then the commands M-X help etc. can 
;;; be used to get help rather than M-X pop-help etc.  Nice, but not for non 
;;; poplog people.                        

;;; THINGS TO DO:                                                    
;;;         A ved_?? equivalent would be nice.                       
;;;                                                                  
;;;         Some nice way of _creating_ help files. This would be    
;;;         a mix of pop-sys-file-mode and text-mode. Versions of    
;;;         ved_indexify and ved_header would be nice                
;;;                                                                  

;; Needed to determine if Pop is running and to communicate with the
;; inferior pop process.
;(require 'inferior-pop-mode)
(require 'cl)

(autoload 'run-pop "inferior-pop-mode"
  "Run an inferior Poplog process." t)
(autoload 'run-pop-other-frame "inferior-pop-mode"
  "Run an inferior Poplog process in another frame." t)
(autoload 'pop-complete-word "inferior-pop-mode" 
  "Complete the Pop-11 word at or before point." t)
(autoload 'pop-send-define "inferior-pop-mode" 
  "Send the current procedure to the inferior Poplog process" t)
(autoload 'pop-send-line "inferior-pop-mode" 
  "Send the current line to the inferior Poplog process" t)
(autoload 'pop-send-region "inferior-pop-mode" 
  "Send the current region to the inferior Poplog process." t)
(autoload 'pop-send-buffer "inferior-pop-mode" 
  "Send the entire buffer to the inferior Poplog process" t)
(autoload 'pop-load-file "inferior-pop-mode" 
  "Load a Pop-11 file into the inferior Poplog process." t)
(autoload 'inferior-pop-process-p "inferior-pop-mode" 
  "Returns the current Poplog process or nil if none." t)
(autoload 'pop-top-level-p "inferior-pop-mode" 
  "Returns t if the process mark appears to be after a Pop-11 top-level prompt.
If inferior-pop-timeout is nil, always returns t." t)
(autoload 'pop-send-string "inferior-pop-mode" 
  "Send STRING to the inferior Pop-11 process, redirecting output to BUFFER
if this is non-nil, otherwise output is returned as a string." t)



;;; User definable variables

(defvar pop-help-short-commands nil
  "*If non-nil when pop-help-mode is loaded then the commands
help, ref, doc and teach are defined as synonyms for pop-help etc. ")

(defvar pop-help-always-create-buffer nil
  "*Non-nil means always create a new buffer for each help file.")

(defvar pop-help-always-use-default-searchlists nil
  "*Non-nil means always use the default searchlists even if there
is a running Poplog process.")



;;; Internal variables

;; Default searchlists, extracted from "basepop11 +$popsavelib/startup"
;; These assume that the user's  Poplog environment variables are set
;; correctly.   Since this is so system dependent, there is not much point
;; in taking a hard line about `independence from Poplog' here.

(defconst pop-help-using-xemacs (string-match "XEmacs" emacs-version)
  "Nil unless using XEmacs).")

(defvar pop-help-default-dirs
  '("$usepop/pop/x/ved/help/"
    "$usepop/pop/x/ved/ref/"
    "$usepop/pop/x/ved/teach/"
    "$usepop/pop/x/pop/help/"
    "$usepop/pop/x/pop/ref/"
    "$usepop/pop/x/pop/teach/"
    "$usepop/pop/x/pop/doc/"
    "$poplocal/local/help/"
    "$usepop/pop/help/"
    "$poplocal/local/teach/"
    "$usepop/pop/teach/"
    "$usepop/pop/doc/"
    "$usepop/pop/ref/")
  "*List of default directories searched for Poplog HELP files")

(defvar pop-teach-default-dirs
  '("$usepop/pop/x/ved/teach/"
    "$usepop/pop/x/ved/help/"
    "$usepop/pop/x/ved/ref/"
    "$usepop/pop/x/pop/teach/"
    "$usepop/pop/x/pop/help/"
    "$usepop/pop/x/pop/ref/"
    "$usepop/pop/x/pop/doc/"
    "$poplocal/local/teach/"
    "$usepop/pop/teach/"
    "$poplocal/local/help/"
    "$usepop/pop/help/"
    "$usepop/pop/doc/"
    "$usepop/pop/ref/")
  "*List of default directories searched for Poplog TEACH files.")

(defvar pop-ref-default-dirs
  '("$usepop/pop/x/ved/ref/"
    "$usepop/pop/x/ved/help/"
    "$usepop/pop/x/ved/teach/"
    "$usepop/pop/x/pop/ref/"
    "$usepop/pop/x/pop/help/"
    "$usepop/pop/x/pop/teach/"
    "$usepop/pop/x/pop/doc/"
    "$poplocal/local/ref/"
    "$usepop/pop/ref/"
    "$usepop/pop/doc/"
    "$usepop/pop/help/"
    "$usepop/pop/teach/")
  "*List of default directories searched for Poplog REF files.")

(defvar pop-doc-default-dirs
  '("$usepop/pop/x/pop/doc/"
    "$usepop/pop/x/pop/help/"
    "$usepop/pop/x/pop/ref/"
    "$usepop/pop/x/pop/teach/"
    "$poplocal/local/doc/"
    "$usepop/pop/doc/"
    "$usepop/pop/ref/"
    "$usepop/pop/help/")
  "*List of default directories searched for Poplog DOC files.")

(defvar pop-lib-default-dirs
  '("$poplocalauto/"
    "$popsunlib/"
    "$popautolib/"
    "$popvedlib/"
    "$popvedlib/term/"
    "$usepop/pop/lib/database/"
    "$usepop/pop/x/pop/auto/"
    "$usepop/pop/x/ui/lib/"
    "$usepop/pop/x/ved/auto/"
    "$poplocal/local/lib/"
    "$popliblib/"
    "$popdatalib/"
    "$usepop/pop/x/pop/lib/"
    "$usepop/pop/x/pop/lib/Xpw/"
    "$usepop/pop/x/pop/lib/Xm/"
    "$usepop/pop/x/ved/lib/")
  "*List of default directories searched for Poplog LIB files.")

;;; !!! WARNING: NO LONGER USED !!!
(defvar usepop (or (getenv "usepop") "."))
(defvar poplocal (or (getenv "poplocal") "."))
(defvar poplib (or (getenv "poplib") "."))

(defvar pop-ploghelp-default-dirs
  (list
   (concat poplib "/ploghelp")
   (concat poplocal "/local/plog/help")
   (concat usepop "/pop/plog/local/ploghelp")
   (concat usepop "/pop/plog/help"))
  "* List of default directories where help looks for poplog prolog help files")

(defvar pop-plogteach-default-dirs
  (list
   (concat poplib "/plogteach")
   (concat poplocal "/local/plog/teach")
   (concat usepop "/pop/plog/local/teach")
   (concat usepop "/pop/plog/teach"))
  "* List of default directories where help looks for poplog prolog teach files")

(defvar pop-ploglib-default-dirs
  (list
   (concat poplib "/lib")
   (concat poplocal "/local/plog/lib")
   (concat poplocal "/local/plog/lib/lib")
   (concat poplocal "/local/plog/lib/auto")
   (concat poplocal "/local/plog/lib/contrib")
   (concat usepop "/pop/plog/local/lib")
   (concat usepop "/pop/plog/local/lib/lib")
   (concat usepop "/pop/plog/local/lib/auto")
   (concat usepop "/pop/plog/local/lib/contrib")
   (concat usepop "/pop/plog/lib")
   (concat usepop "/pop/plog/lib/lib")
   (concat usepop "/pop/plog/lib/auto")
   (concat usepop "/pop/plog/lib/contrib"))
  "* List of default directories where help looks for poplog prolog lib files")

;; The following variables will contain either the default searchlists
;; (defined above) or the searchlists extracted from the relevant ved
;; searchlists in the current pop process.  Do NOT assign to these vars.
(defvar pop-help-dirs
  "List of directories searched for Poplog HELP files")

(defvar pop-teach-dirs
  "List of directories searched for Poplog TEACH files.")

(defvar pop-ref-dirs
  "List of directories searched for Poplog REF files.")

(defvar pop-doc-dirs
  "List of directories searched for Poplog DOC files.")

(defvar pop-lib-dirs
  "List of directories searched for Poplog LIB files.")

;;; !!! WARNING NO LONGER USED !!!
(defvar pop-ploghelp-dirs
  "List of directories searched for Poplog prolog HELP files.")

(defvar pop-plogteach-dirs
  "List of directories searched for Poplog prolog TEACH files.")

(defvar pop-ploglib-dirs
  "List of directories searched for Poplog prolog LIB files.")

;; It would simplify things if we used the same keys as Pop-11.
(defconst pop-help-types
  '(("HELP"  . "help")
    ("TEACH" . "teach")
    ("REF"   . "ref")
    ("DOC"   . "doc")
    ("LIB"   . "lib")
    ("PLOGHELP"  . "ploghelp")
    ("PLOGTEACH" . "plogteach")
    ("PLOGLIB"   . "ploglib"))
  "*Association list mapping cross references to help types.")

(defvar pop-help-mode-map nil
  "Keymap used in pop help mode." )

(cond ((not pop-help-mode-map)
       (setq pop-help-mode-map (make-sparse-keymap))
       (define-key pop-help-mode-map " " 'scroll-up)
       (define-key pop-help-mode-map "\C-?" 'scroll-down)

       (define-key pop-help-mode-map "?" 'pop-get-help)
       (define-key pop-help-mode-map "/" 'pop-next-help)
       (define-key pop-help-mode-map "-" 'pop-goto-section)
       ;; the standard bindings used in the other pop modes ...
       (cond
	(pop-help-using-xemacs
	 (define-key pop-help-mode-map [(control h) p ] 'pop-get-help)
	 (define-key pop-help-mode-map [(control h) n ] 'pop-next-help)
	 (define-key pop-help-mode-map [(control h) g ] 'pop-goto-section)
	 (define-key pop-help-mode-map [(control h) t ] 'pop-help-toggle-pop-mode))
	(t (define-key pop-help-mode-map "\C-hp" 'pop-get-help)
	   (define-key pop-help-mode-map "\C-hn" 'pop-next-help)
	   (define-key pop-help-mode-map "\C-hg" 'pop-goto-section)
	   (define-key pop-help-mode-map "\C-ht" 'pop-help-toggle-pop-mode)))
       ;; these are also useful ...
       (define-key pop-help-mode-map "\M-h" 'pop-get-help)
       (define-key pop-help-mode-map "\M-n" 'pop-next-help)
       (define-key pop-help-mode-map "\M-g" 'pop-goto-section)
       ))

(defvar pop-help-type nil
  "Buffer local variable containing the type of
the current help file.")

(defvar pop-help-subject nil
  "Buffer local variable containing the subject of
the current help file.")

(defvar pop-default-type nil
  "Buffer local variable containing the default type of
documentation to look for." )

(defvar pop-index-regexp "^ \\(-- \\)+\\|^  [0-9]"
  "Regular expression matching index items")

(defvar pop-index-item nil
  "Pointer to the index item last looked at" )

(defvar pop-help-mode-hook nil
  "* Hook run on entry to pop-help-mode" )



;;; Pop-help-mode starts here
(defun pop-help-mode ()
  "Major mode for reading Poplog documentation.

Commands:
\\{pop-help-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (use-local-map pop-help-mode-map)
  (setq major-mode 'pop-help-mode)
  (setq mode-name "Poplog Help")
  (setq buffer-read-only t)
  ;; For VED files with 8 character tabs
  (setq tab-width 4)
  ;; This is normally defined in pop-mode, but we can't require pop-mode
  ;; otherwise we get a loop.  We need this if we want to compile Pop-11
  ;; code in pop-help-mode buffers and pop-compilation-messages is t.
  (make-local-variable 'comment-start)
  (setq comment-start ";;;")
  (make-local-variable 'pop-help-type)
  (make-local-variable 'pop-help-subject)
  (make-local-variable 'pop-default-type)
  (make-local-variable 'pop-index-item)
  (pop-help-set-default-dirs)
  (run-hooks 'pop-help-mode-hook))

;; Visting Poplog HELP, TEACH, REF etc. files	
(defun pop-apropos (pattern)
  "Get summary help for everything matching PATTEN"
  (interactive
   (pop-help-get-subject "Apropos"))
  (pop-help-file t "help" pattern))

(defun pop-help (subject)
  "Get Poplog help for SUBJECT"
  (interactive
   (pop-help-get-subject "Help for?"))
  (pop-help-file subject "help"))

(defun pop-teach (subject)
  "Get Poplog teach file for SUBJECT"
  (interactive
   (pop-help-get-subject "Teach for?"))
  (pop-help-file subject "teach"))

(defun pop-ref (subject)
  "Get Poplog ref file for SUBJECT"
  (interactive
   (pop-help-get-subject "Ref for?"))
  (pop-help-file subject "ref"))

(defun pop-doc (subject)
  "Get Poplog doc file for SUBJECT"
  (interactive
   (pop-help-get-subject "Doc for?"))
  (pop-help-file subject "doc"))

(defun pop-showlib (subject)
  "Get Poplog library for SUBJECT"
  (interactive
   (pop-help-get-subject "Show library"))
  (pop-help-file subject "lib"))

;;; !!! WARNING: THESE NO LONGER WORK !!!
(defun pop-ploghelp (subject)
  "Get Poplog prolog help file for SUBJECT"
  (interactive "sPlog help for? " )
  (pop-help-file subject "ploghelp"))

(defun pop-plogteach (subject)
  "Get Poplog prolog teach file for SUBJECT"
  (interactive "sPlog Teach for? " )
  (pop-help-file subject "plogteach"))

(defun pop-plogshowlib (subject)
  "Get Poplog prolog library for SUBJECT"
  (interactive "sPlog Showlib? " )
  (pop-help-file subject "ploglib"))

(defun pop-help-get-subject (prompt)
  "Prompt for the subject of a HELP/TEACH/REF/DOC/LIB request."
  (list (let* ((default-entry (downcase (current-word)))
	       (input (read-string
		       (format "%s %s: " prompt
			       (if (string= default-entry "")
				   ""
				 (format " (default %s)" default-entry))))))
	  (if (string= input "")
	      (if (string= default-entry "")
		  (error "No subject")
		default-entry)
	    input))))


;;; Movement within a help buffer

;; The regexps are quite restrictive, but there are so many new formats that
;; it seems better to do a case analysis (or re-implement whatever mess Ved
;; uses) than to try and come up with one all encompassing regexp.
(defun pop-goto-section ()
  "Jump to a section within a Poplog help file."
  (interactive)
  (beginning-of-line)
  (if (looking-at pop-index-regexp)
      (progn
	(setq pop-index-item (point))
	(skip-chars-forward " 0-9\\-\t")
	(let ((what (buffer-substring (point) (progn (end-of-line) (point)))))
	  ;; The index can come after the sections it refers to.
	  (goto-char (point-min))
	  (if (or (re-search-forward
		   (concat "^\\(--[ \t]*\\)+" (regexp-quote what)
			   "[ \t]*-*[ \t]*$") nil t)
		  (re-search-forward
		   (concat "^[0-9]+[ \t]*" (regexp-quote what)
			   "[ \t]*$") nil t))
	      (beginning-of-line)
	    (error "Can't find section \"%s\"" what))))
    (if pop-index-item
	(progn
	  (goto-char pop-index-item)
	  (next-line 1)))
    (if (not (looking-at pop-index-regexp))
	(progn
	  (goto-char (point-min))
	  (if (not (re-search-forward pop-index-regexp nil t))
	      (error "Can't find section"))))))

;; This uses a very weak notion of what constitutes a `reference'.
;; The general idea seems to be that we match everything that could be a
;; reference and it is up to the user to decide whether to call pop-get-help
;; which is responsible for working out the type of the help file.
(defun pop-next-help (n)
  "Go to next cross reference"
  (interactive "p")
  (while (> n 0)
    (if (not (re-search-forward "[^*]\\*[^*]" nil t))
	(error "No more references in this file"))
    (setq n (1- n))
    (forward-char -1))
  (forward-char -1))

(defun pop-get-help ()
  "Get help for the current word"
  (interactive)
  (let ((type (or pop-default-type "HELP"))
	 what topic start helpfile)
    (if (eql (char-after (point)) ?*)
	(forward-word 1))
    (while (and (not (eq (current-column) 0)) 
		(save-excursion (forward-char -1) (looking-at "\\sw")))
      (forward-char -1))
    (save-excursion
      (skip-chars-backward " \t\n")
      (if (eql (char-after (1- (point))) ?* )
	  (progn
	    (forward-char -1)
	    (skip-chars-backward " \n\t")
	    (let ((place (point)))
	      (skip-chars-backward "^ \n\t")
	      (setq type (buffer-substring (point) place))))))
    (if (not (setq type (assoc type pop-help-types)))
	(setq type (assoc "HELP" pop-help-types)))
    (setq what (cdr type))
    (save-excursion 
      (skip-chars-forward " \t\n")
      (setq start (point))
      (skip-chars-forward "-a-zA-Z0-9_")
      (setq helpfile (buffer-substring start (point)))
      (if (eql (char-after (point)) ?/)
	  (progn
	    (forward-char 1)
	    (setq start (point))
	    (skip-chars-forward "^ \t\n/")
	    (setq topic (buffer-substring start (point))))))
    (pop-help-file (downcase helpfile) what topic)))



;;; Utilities to get a help file, build indices etc.

;; If pop-help-always-create-buffer is non-nil we use buffer names of the
;; form *Pop TYPE subject* otherwise we use a single buffer for each type
;; called *Pop TYPE*.  In each case we remember the subject of the file in
;; the buffer local variable pop-help-subject and assume that if this matches 
;; the subject of the current call the file is still valid.  This will fail if
;; loading libraries adds new files with the same subject to the front of
;; the seachlists.  There are also a couple of special cases: if SUBJECT 
;; is "index", make an index and display it in the help buffer; if SUBJECT 
;; is t, then make an index and seach for the TOPIC (in a buffer called
;; *Pop TYPE -Aprops-*)
(defun pop-help-file (subject type &optional topic)
  "Pop up a buffer containing a Poplog help file for SUBJECT of type TYPE."
  (let* ((type (or type "help"))
	 (subject-name (if (stringp subject) subject "-Apropos- "))
	 (bufname (if pop-help-always-create-buffer
		      (concat "*Pop " (upcase type) " " subject-name "*")
		    (concat "*Pop " (upcase type) "*")))
	 buf filename line-no)
    ;; If we already have the buffer with the correct contents use that
    (cond
     ((and (get-buffer bufname)
	   ; this is redundant since the buffer name encodes the type
	   (equal (cdr (assoc 'pop-help-type
			      (buffer-local-variables (get-buffer bufname))))
		  type)
	   (equal (cdr (assoc 'pop-help-subject
			      (buffer-local-variables (get-buffer bufname))))
		  subject))
      (setq buf (get-buffer bufname)))
     ;; Aprops - build the index and search for topic
     ((eq subject t)
      (setq buf (get-buffer-create bufname))
      (save-excursion
	(set-buffer buf)
	(pop-help-clear-buffer buf)
	(pop-create-index type (pop-help-searchlist type) topic)
	(setq pop-default-type (upcase type))
	(setq subject (concat "apropos " topic))
	(setq topic (concat "* " topic " |"))
	(goto-char (point-min))
	(pop-nuke-cntl-chars buf)))
     ;; just build the index (a la Poplog `help index')
     ((equal subject "index")
      (setq buf (get-buffer-create bufname))
      (save-excursion
	(set-buffer buf)
	(pop-help-clear-buffer buf)
	(pop-create-index type (pop-help-searchlist type) nil)
	(setq pop-default-type (upcase type))
	(goto-char (point-min))
	(pop-nuke-cntl-chars buf)))
     ;; else try and find the help file and open it
     ((setq filename (pop-help-find-file subject
					 type
					 (pop-help-searchlist type)))
      (if (consp filename)
	  (progn
	    (setq line-no (cdr filename))
	    (setq filename (car filename))))
      (setq buf (get-buffer-create bufname))
      (save-excursion
	(set-buffer buf)
	(pop-help-clear-buffer buf)
	(insert-file-contents filename nil nil nil t)
	(pop-nuke-cntl-chars buf))))
    ;; If any of the above worked, we now have a buffer
    (if (not buf)
	(error "No %s file for %s, try %s index or %s %sfiles" 
	       (upcase type) subject type type type)
      (save-excursion
	(set-buffer buf)
	(if (not (eq major-mode 'pop-help-mode))
	    (pop-help-mode))
	(setq pop-help-type type)
	(setq pop-help-subject subject)
	(setq pop-index-item nil))
      (if (not (eq buf (current-buffer)))
	  (switch-to-buffer-other-window buf))
      ;; We assume that we will never never be given a topic 
      ;; with a real subject, i.e. that both topic and line-no
      ;; (the offset in a REF file) are non nil.
      (cond (topic
	     (goto-char (point-min))
	     (if (search-forward topic nil t)
		 (search-backward topic nil t)
	       (message "No information on %s in %s" topic subject)))
	    (line-no
	     (goto-line line-no))))))

(defun pop-help-clear-buffer (buffer)
  "Zap the contents of BUFFER."
  (save-excursion
    (set-buffer buffer)
    (setq buffer-read-only nil)
    (delete-region (point-min) (point-max))))

;; Find a `help' file of type TYPE (HELP, TEACH etc.) on SUBJECT in SEARCHLIST.
;; TYPE is used to generate the filename extension for showlib and plogshowlib.
(defun pop-help-find-file (subject type searchlist)
  "Finds a Poplog help file for SUBJECT of type TYPE in dirs SEARCHLIST.
Returns the name of the file, or a cons consisting of the name of a REF file 
containing an entry on SUBJECT and the line number of the entry."
  (let (path filename file)
    (setq type (or type "help"))
    (while (and (consp searchlist) (not file))
      (setq path (pop-help-frob-pathname
		  (file-name-as-directory (car searchlist))))
      (setq filename (concat path subject))
      (cond ((equal type "lib")
	     (setq filename (concat filename ".p")))
	    ((equal type "ploglib")
	     (setq filename (concat filename ".pl"))))
      (cond ((file-readable-p filename)
	     (setq file t))
	 ((file-readable-p (concat filename ".Z"))
	    ;; This assumes that we have e.g. crypt++ loaded to
	    ;; expand the compressed file when it is loaded.
	  (setq filename (concat filename ".Z"))
	  (setq file 'Z))
	 ((or (equal type "help")
	      (equal type "ref"))
	  ;; Check for ref indices Not clear if we should do this
	  ;; here or after trying all the paths in searchlist.
	  (let* ((index-file (concat path "doc_index/"
				     (substring subject 0 1)))
		 (index-buf (if (file-readable-p index-file)
				(get-buffer-create " doc_index"))))
	    (if index-buf
		(save-excursion
		  (set-buffer index-buf)
		  (pop-help-clear-buffer index-buf)
		  (insert-file-contents index-file nil nil nil t)
		  (if (re-search-forward (concat "^" subject "\\s +")
					 (point-max) t)
		      (let ((ref-file (symbol-name (read index-buf)))
			    (ref-line (read index-buf)))
			(setq filename (cons (concat path ref-file) ref-line))
			(setq file 'ref)))
		  (kill-buffer index-buf))))))
      (setq searchlist (cdr searchlist)))
    (if file filename)))
      
(defun pop-create-index (what where apropos)
  "Create an index for the help files of TYPE in directories WHERE" 
  (let ((fill-prefix "\t\t ")
	path all last start name)
    (if apropos (insert "Apropos " topic "\n\n") 
      (insert "Index of " what "files\n\n")) 
    (while (not (eq where nil)) 
      (setq path (pop-help-frob-pathname
		  (file-name-as-directory (car where))))
      (if (file-directory-p path) 
	  (setq all (append all (directory-files path t
						 (or apropos "[a-z].*")))))
      (setq where (cdr where)))
    (setq all (sort all (function equal)))

    (setq last nil)
    (while (not (eq all nil))
      (if (not (equal (car all) last))
	  (if apropos
	      (progn
		(setq start (point))
		(insert (pop-get-summary (car all)) ?\n)
		(fill-region start (point))
		(sit-for 0))
	    (progn
	      (setq name (file-name-nondirectory (car all)))
	      (insert name)
	      (if (> (current-column) 60)
		  (progn
		    (insert ?\n )
;		    (sit-for 0)
		    )
		(insert-char ? (- 20 (length name)))))))
      (setq last (car all))
      (setq all (cdr all)))))

;; Is this a replacement for the ved_? command?
(defun pop-get-summary (file)
  "Returns a one line summary of the helpfile FILE."
  (let ((name (file-name-nondirectory file))
	(buffer (get-buffer-create " sumtmp "))
	line)
    (save-excursion
      (set-buffer buffer)
      (goto-char (point-min))
      (insert-file-contents file nil nil nil t)
      (pop-nuke-cntl-chars buffer)
      (re-search-forward "^$" nil t)
      (if (re-search-forward "^\\(\\s-+[^-]\\)" nil t)
	  (beginning-of-line)
	(forward-line -1))
      (skip-chars-forward "\\s-\n")
      (setq line (buffer-substring (point) (save-excursion 
					     (end-of-line) (point))))
      (format "%20s  |  %s" (concat "* " name) line))))
	     
(defun pop-help-searchlist (type)
  "Return the searchlist for files of TYPE."
    (pop-help-update-searchlists)
    (cond
     ((string= type "help") pop-help-dirs)
     ((string= type "teach") pop-teach-dirs)
     ((string= type "ref") pop-ref-dirs)
     ((string= type "doc") pop-doc-dirs)
     ((string= type "lib") pop-lib-dirs)
     ;; Don't worry about prolog for now ...
;     ((string= type "ploghelp") pop-ploghelp-dirs)
;     ((string= type "plogyeach") pop-plogteach-dirs)
;     ((string= type "ploglib") pop-ploglib-dirs)
     ))

;; It seems that Pop-11 will only swallow 256 chars at a time.  If we try 
;; and send more, we just get garbage back.  (This also seems to happen with 
;; input pasted into an xterm window.)   Setting comint-input-chunk-size 
;; doesn't seem to help (perhaps because this doesn't add any newlines) and
;; the only reliable approach is to make sure that none of the input lines is 
;; longer than 256 chars.  This works, but is slow, as we have to wait for 
;; the `:'s to be echoed.  Worse, since we are waiting for output from the
;; process, Emacs may (and often does) return after the first `:'.
(defun pop-help-update-searchlists ()
  "Get the searchlists from the inferior Poplog process."
  (if (or pop-help-always-use-default-searchlists
	  (not (inferior-pop-process-p)))
      (pop-help-set-default-dirs)
    ;; Otherwise get the searchlists from the inferior Poplog process.
    (if (pop-top-level-p)
	(let* ((searchlist-buffer (get-buffer-create " *Poplog searchlists*"))
	       (file (make-temp-name "/tmp/emacs"))
	       (command (format "emacs_flatten_searchlists('%s');\n" file)))
	  ;; We could use pop-send-string here, since command, like a compile
	  ;; command, is < 256 chars & produces no ouput in the buffer ...
;	  (if (pop-send-command-file command)
	  (if (pop-send-string command)
	      (save-excursion
		(if (not (eq searchlist-buffer (current-buffer)))
		    (set-buffer searchlist-buffer))
		;; Set the dir vars from the Poplog output:
		;; this assumes that Poplog is going to write exactly an
		;; alist of the dirs and their types into the buffer.
		(goto-char (point-min))
		(insert-file-contents file nil nil nil t)
		(skip-chars-forward ": ")
		(pop-help-set-dirs (read searchlist-buffer)))
	    ;; Otherwise set from the defaults and print a warning
	    (beep)
	    (message "WARNING: Can't get searchlists ... using defaults")
	    (pop-help-set-default-dirs)))
    (beep)
    (message "WARNING: Pop-11 not at top level ... using default searchlists")
    (pop-help-set-default-dirs))))

;; The only reason we don't just return the ALIST is to make it easier for
;; the user to set up the the default searchlists: otherwsie they have to
;; replicate the whole ALIST to change a single entry.
(defun pop-help-set-dirs (alist)
  "(Re)set the searchlists for pop-help-mode from ALIST."
  (setq pop-help-dirs (append (cdr (assoc "help" alist))
			      (cdr (assoc "ref" alist))))
  (setq pop-teach-dirs (cdr (assoc "teach" alist)))
  (setq pop-ref-dirs (cdr (assoc "ref" alist)))
  (setq pop-doc-dirs (cdr (assoc "doc" alist)))
  (setq pop-lib-dirs (cdr (assoc "lib" alist)))
  ;; Don't worry about the Prolog stuff for now ...
;  (setq pop-ploghelp-dirs (assoc "ploghelp" alist))
;  (setq pop-plogteach-dirs (assoc "plogteach" alist))
;  (setq pop-ploglib-dirs (assoc "ploglib" alist))
  )

(defun pop-help-set-default-dirs ()
  "(Re)set the searchlists for pop-help-mode to the defaults."
  (setq pop-help-dirs pop-help-default-dirs)
  (setq pop-teach-dirs pop-teach-default-dirs)
  (setq pop-doc-dirs pop-doc-default-dirs)
  (setq pop-ref-dirs pop-ref-default-dirs)
  (setq pop-lib-dirs pop-lib-default-dirs)
  ;; Don't worry about the Prolog stuff for now ...
;  (setq pop-ploghelp-dirs pop-ploghelp-default-dirs)
;  (setq pop-plogteach-dirs pop-plogteach-default-dirs)
;  (setq pop-ploglib-dirs pop-ploglib-default-dirs)
  )

;; substitute-in-file-name : If a `~' or a `/' appears following a `/', after 
;; substitution, everything before the following `/' is discarded.  This is a
;; problem for some of the Poplog environment variables so we use this version
;; which assumes that the environment var will always be at the beginning of
;; the pathname.
(defun pop-help-frob-pathname (path)
  "Canonicalise Poplog search paths."
  (if (not (string-match "^\\(\\$[a-zA-Z0-9_]+\\)/" path))
      path
    (concat (pop-help-frob-pathname
	     (directory-file-name
	      (substitute-in-file-name
	       (substring path (match-beginning 1) (match-end 1)))))
	    (substring path (match-end 1)))))

;; Original version by Riccardo Poli, Feb 1996 -- this way is a little faster.
;; Note: would it faster to split the regexp into two cases?  Ultimately, the
;; only thing to do here is to use Poplog to strip the funny characters ...
(defun pop-nuke-cntl-chars (buffer)
  "Zap the control characters VED uses to control formatting in BUFFER."
  (save-excursion
    (set-buffer buffer)
    (buffer-disable-undo buffer)
    (goto-char (point-min))
    ; This seems to be the fastest version -- it would be nice to use the
    ; ?\^A read syntax but this doesn't seem to work with ranges so we use
    ; the chars themselves.  Still need some way of representing the chars
    ; above ASCII 128 in a portable way.
    (while (re-search-forward "_++\\|[--]" nil t)
      (replace-match "" nil nil))
    ; Handle the special case of char \235 which seems to be wrapped around
    ; the `*' preceeding a reference.
    (goto-char (point-min))
    (while (re-search-forward "\235" nil t)
      (replace-match " " nil nil))
    (buffer-enable-undo buffer)))

(defun pop-nuke-cntl-chars-slow (buffer)
  "Zap the control characters VED uses to control formatting in BUFFER."
  (save-excursion
    (set-buffer buffer)
    (buffer-disable-undo buffer)
    (goto-char (point-min))
    (while (re-search-forward "_++" nil t)
      (replace-match "" nil nil))
    (goto-char (point-min))
    (while (not (eobp))
      (let ((c (char-after (point))))
	(if (and c (or (<= c 8) (and (>= c 11) (<= c 31)) (>= c 128)))
	    (delete-char 1 nil)
	  (forward-char 1))))
    (buffer-enable-undo buffer)))

;;; Sometimes (always?) it is useful to look at a Poplog library file in
;;; pop-mode with its movement and compilation commands rather than in 
;;; pop-help-mode.  This  function simply toggles between the two, trying to
;;; preserve the buffer local vars that lets pop-help-model keep track of
;;; the buffer.
(defun pop-help-toggle-pop-mode (&optional buffer)
  "Put BUFFER in pop-mode."
  (interactive)
  (let ((buf (or buffer (current-buffer)))
	(type pop-help-type)
	(subject pop-help-subject))
    (save-excursion
      (set-buffer buf)
      (if (eq major-mode 'pop-mode)
	  (pop-help-mode)
	(pop-mode)
	;; So that pop-help-mode doesn't lose track of the buffer
	(make-local-variable 'pop-help-type)
	(make-local-variable 'pop-help-subject)
	(make-local-variable 'pop-index-item)
	;; So that we can get back again ...
	(define-key pop-mode-map "\C-ht" 'pop-help-toggle-pop-mode))
      (setq pop-help-type type)
      (setq pop-help-subject subject)
      (setq pop-index-item nil))))

;; Functions for editing Poplog help files
;; Original versions by Stephen Eglen, December 1996.

;;; Usage
;; M-x ved-heading mimics the ved `heading' command
;; M-x ved-indexify mimics the ved `indexify' command
;; See HELP * VED_INDEXIFY for more details on these commands

;; It would be nice if this did the right thing if there is already a
;; heading around point, i.e. deleted the old -'s and reinserted a new
;; string of the right length.
(defun ved-heading ()
  "Change current line into a VED style heading for a HELP file."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (delete-horizontal-space)
    (insert "-- ")
    (end-of-line)
    (just-one-space)
    (insert (make-string (- 72 (current-column)) ?- )))
  (end-of-line))

(defun ved-indexify ()
  "Make the index for the current VED help file.  Index is inserted at point.
Any old indexes are not deleted."
  (interactive)
  (let (start headings
	(toc (point)))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^-- " nil t)
	(beginning-of-line)
	(setq start (point))
	(end-of-line)
	;; should be just -, but maybe " " also here vvv
	(skip-chars-backward "- ")
	(setq headings (cons (buffer-substring start (point)) headings)))
      ; (message "headings is %s" headings)
      ; insert the table of contents
      (goto-char toc)
      (insert
       "\n         CONTENTS - (Use <ENTER> g to access required sections)\n\n")
      (setq headings (nreverse headings))
      (while headings
	(insert (format " %s\n" (car headings)))
	(setq headings (cdr headings))))))



(if pop-help-short-commands
    (progn
      (fset 'help (symbol-function 'pop-help))
      (fset 'ref (symbol-function 'pop-ref))
      (fset 'doc (symbol-function 'pop-doc))
      (fset 'teach (symbol-function 'pop-teach))
      (fset 'showlib (symbol-function 'pop-showlib))))


;;; 29th Jan 1991 rjc
;;; Fixed a problem with pop-get-help near the start of a buffer.
;;; Also made pop-next-help a little more discerning about
;;; what it considers a cross reference. 

;;; 24th Feb 1991 rjc
;;; added more directories.
;;; added the index bulding code.
;;; added pop-apropos

;;; 27th Feb 1991 bsl
;;; added pop-plogteach and pop-ploglib for prolog teach and lib files
;;; added DEL to the default key map for pop-sys-file-mode
;;; changed pop-sys-file-mode-hooks to pop-sys-file-mode-hook for compatibility
;;; with pop-mode
;;; fixed typo in pop-help-short-command(s)

;;; 22nd April 1991
;;; Now understands usepop, poplocal and poplocal emacs
;;;	variables if set to override environment.
;;; Added default type so that ref index etc work.

;;; 5th April 1996 bsl
;;; Fixed pop-help-file so that we don't trash the current buffer unless there
;;; is a file for SUBJECT.  Also added a flag to control whether we re-use the
;;; same buffer or create a new one for each file.  Modifile pop-help-find-file
;;; so that it checks the doc_index files to see if there is an entry for 
;;; SUBJECT in a ref file.

;;; 5th April 1996 bsl
;;; Moved pop-help-send-string into inferior-pop-mode.el and renamed it
;;; pop-send-string.  Moved the emacs_searchlists initialisation from
;;; inferior-pop-mode to pop-help-update-searchlists: it is now sent before
;;; every request for information.  This is slower, but cleaner.  Added
;;; pop-top-level-p tests to pop-help-define-searchlists-procedure and
;;; pop-send-string.

;;; 13th December 1996 bsl
;;; Added functions for editing a Poplog help file and made pop-help etc.
;;; prompt with a default subject.  This doesn't really add a lot, since
;;; pop-get-help would find the current word anyway, but this gives you a
;;; chance to edit the default.  Based on code form Stephen Eglen
;;; <stephene@cogs.susx.ac.uk>

(provide 'pop-help-mode)
