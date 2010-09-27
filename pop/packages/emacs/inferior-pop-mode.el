;;; inferior-pop-mode.el --- Poplog processes in a buffer.

;; This file is part of Pop-mode

;; Copyright (C) 1989-1991 Brian Logan and Richard Caley
;; Copyright (C) 1996 Brian Logan

;; Authors: Brian Logan <b.s.logan@cs.bham.ac.uk>
;;          Richard Caley <rjc@cstr.ed.ac.uk>

;; Maintainer: Brian Logan <b.s.logan@cs.bham.ac.uk>
;; RCS info: $Id: inferior-pop-mode.el,v 1.19 1999/09/08 17:38:37 bsl Exp $
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

;;; Inferior pop mode - run poplog processes under GNU Emacs/XEmacs.        
;;;                                                                  
;;;         Hacked from prolog-mode bsl 17.07.89                     
;;;         Variously mutilated by RJC.                              
;;;                                                                  
;;; In its current form this is rather fragile and prone to timing problems.
;;; In an attempt to reduce these, we have switched back from using the
;;; inferior pop buffer directly for compilation (using comint-send-string)
;;; to using temporary files.  This increases the dependence on a (slow) 
;;; fileserver (which the previous version was designed to avoid), but seems
;;; to be marginally more robust.  Life would be a lot easier if ISL could be
;;; persuaded to change the Pop continuation prompt.

;;; The changelog is at the end of this file.

(require 'comint)
(require 'easymenu)
(require 'pop-mode)
(require 'pop-help-mode)

(autoload 'pop-get-help "pop-help-mode" 
  "Read the help file for this word" t)

;;; User definable variables
(defvar pop-program-name 
  (if (getenv "usepop")
      (concat (getenv "usepop") "/pop/pop/pop11")
    "pop11")
  "*Shell command for running Pop-11")

(defvar pop-program-args nil
  "*Arguments to the Pop-11 command")

(defvar pop-compilation-messages t
  "*Non nil means print messages describing what is being compiled in the 
Inferior Pop-11 buffer.")

(defvar pop-prompt-regexp
  "^\\(: \\|\\*\\* *\\)*"
  "*Regexp matching Pop-11 prompts.")

(defvar pop-dirtrackp t
  "*Non nil means inferior Pop-11 buffer should track cd commands.")

(defvar pop-command-regexp "\\((.*)\\|[^;&|]\\)+"
  "*Regexp to match Poplog `shell' commands.")

(defvar pop-cd-regexp "cd"
  "*Regexp to match Pop-11 cd macro.")

(defvar inferior-pop-filter-regexp "\\`\\s *\\S ?\\S ?\\s *\\'"
  "*Input matching this regexp are not saved on the history list.
Defaults to a regexp ignoring all inputs of 0, 1, or 2 letters.")

(defvar inferior-pop-timeout 5
  "*Maximum number of seconds to wait for inferior Pop-11 process to produce
output.  Nil means don't wait, run asynchronously, t means wait forever.")

(defvar inferior-pop-initialisation t
  "*Non nil means that emacs should attempt to initialise inferior Pop-11
itself.  Set this to nil if Poplog does the initialisation itself, e.g. in 
init.p")



;;; Internal variables

(defvar inferior-pop-mode-map nil
  "Keymap used in inferior pop mode.")

(cond ((not inferior-pop-mode-map)
       (setq inferior-pop-mode-map (copy-keymap comint-mode-map))
       (pop-mode-commands inferior-pop-mode-map)
       ;; Not bound in XEmacs - Use ^C^D instead of ^D.
       ;;(define-key inferior-pop-mode-map "\C-d" 'pop-delchar-or-maybe-eof)
       (define-key inferior-pop-mode-map "\C-c\C-d" 'pop-send-eof)

       (define-key inferior-pop-mode-map "\M-\C-i" 'pop-complete-word)
       ;; gnu convention
       (define-key inferior-pop-mode-map "\M-\C-x"  'pop-send-define) 
       ;; as close as we can get to eval-last-sexp without parsing Pop-11 ...
       (define-key inferior-pop-mode-map "\C-x\C-e" 'pop-send-line)
       (define-key inferior-pop-mode-map "\C-c\C-r" 'pop-send-region)
       (define-key inferior-pop-mode-map "\C-c\C-l" 'pop-load-file)
       ;; these are not bound by default in the XEmacs version of comint
       (define-key inferior-pop-mode-map "\M-\C-n"  'comint-next-input) 
       (define-key inferior-pop-mode-map "\M-\C-p"  'comint-previous-input) 
;       ;; rebind these from pop-mode ...
;       ;; these are the standard XEmacs bindings: switch to GNU?
;       (define-key inferior-pop-mode-map "\M-n"
;	           'comint-next-matching-input-from-input) 
;       (define-key inferior-pop-mode-map "\M-p"
;	           'comint-previous-matching-input-from-input) 
       ;; not a good idea to do indentation in this buffer
       (define-key inferior-pop-mode-map ";" 'self-insert-command)
       )) 

;; Install the process communication commands in the pop-mode keymap.
(define-key pop-mode-map "\M-\C-i" 'pop-complete-word)
(define-key pop-mode-map "\M-\C-x" 'pop-send-define) ; gnu convention
;; This is as close as we can get to eval-last-sexp without parsing Pop-11 ...
(define-key pop-mode-map "\C-x\C-e" 'pop-send-line) ; gnu convention
(define-key pop-mode-map "\C-c\C-e" 'pop-send-define)
;; There appears to be no comint default binding/function for send-region
(define-key pop-mode-map "\C-c\C-r" 'pop-send-region)
(define-key pop-mode-map "\C-c\C-b" 'pop-send-buffer)
(define-key pop-mode-map "\C-c\C-l" 'pop-load-file)

;; Install the process communication commands in the pop-help-mode keymap.
;; This is useful when reading TEACH files, which need to be compiled.
(define-key pop-help-mode-map "\M-\C-x" 'pop-send-define) ; gnu convention
;; This is as close as we can get to eval-last-sexp without parsing Pop-11 ...
(define-key pop-help-mode-map "\C-x\C-e" 'pop-send-line) ; gnu convention
(define-key pop-help-mode-map "\C-c\C-e" 'pop-send-define)
;; There appears to be no comint default binding/function for send-region
(define-key pop-help-mode-map "\C-c\C-r" 'pop-send-region)
(define-key pop-help-mode-map "\C-c\C-b" 'pop-send-buffer)
(define-key pop-help-mode-map "\C-c\C-l" 'pop-load-file)

(defvar inferior-pop-mode-hook nil
  "*Hook for customising inferior-pop-mode.")

(defconst inferior-pop-using-xemacs (string-match "XEmacs" emacs-version)
  "Nil unless using XEmacs).")

(defvar inferior-pop-buffer nil
  "Inferior Poplog mode buffer")

;; We need this so that pop-top-level-p doesn't get confused by the last
;; prompt of the previous inferior pop process in the inferior pop buffer.
(defvar inferior-pop-buffer-start nil
  "Point in the inferior-pop-buffer at which the current inferior Pop-11
process starts.")

(defvar pop-source-modes '(pop-mode)
  "*Used to determine if a buffer contains Pop-11 source code.
If it's loaded into a buffer that is in one of these major modes, it's
considered a Pop-11 source file by pop-load-file.
Used by these commands to determine defaults.")

(defvar pop-prev-l/c-dir/file nil
  "Caches the last (directory . file) pair.
Caches the last pair used in the last pop-load-file command. 
Used for determining the default in the next one.")

;; The standard way to define menus in GNU emacs is horrible (one of many
;; reasons for using XEmacs), so we use the easymenu package which works for
;; both.  It would be nice to include a pop-send-last-sexp command, but
;; this requires a pop-backward-expression or some other means of recognising
;; the last expression which is impossible without a Pop-11 parser.  We can
;; get something like the same effect by using comint-send-input, but this
;; only works in the inferior Pop-11 buffer.  When we used copy-keymap for 
;; this the keybindings don't appear in the menu, hence the use of :keys.  
;; Check if this is still necessary.
(easy-menu-define
 inferior-pop-menu
 inferior-pop-mode-map
 "Menu for Inferior Pop mode."
 '("Pop-11"
   ["Run Pop" run-pop (not (inferior-pop-process-p))]
   ["Previous prompt" (comint-previous-prompt 1)
    :active (inferior-pop-process-p) :keys "C-c C-p"]
   ["Next prompt" (comint-next-prompt 1)
    :active (inferior-pop-process-p) :keys "C-c C-n"]
   ["Copy input" comint-copy-old-input (inferior-pop-process-p)]
   "----"
   ["Compile region" pop-send-region
    :active (inferior-pop-process-p) :keys "C-c c-r"]
   ["Load file" pop-load-file
    :active (inferior-pop-process-p) :keys "C-c C-l"]
   "----"
   ["Exit Pop" comint-send-eof
    :active (inferior-pop-process-p) :keys "C-c C-d"]))


(defun inferior-pop-mode ()
  "Major mode for interacting with an inferior Pop process.

The following commands are available:
\\{inferior-pop-mode-map}

Customisation: Entry to this mode runs the hooks on comint-mode-hook,
pop-mode-hook and inferior-pop-mode-hook (in that order).

You can send text to the inferior Pop-11 process from buffers containing
Pop-11 code:
    pop-send-define sends the current definition to the Poplog process.
    pop-send-region sends the current region to the Poplog process.
    pop-send-buffer sends the current buffer to the Poplog process.

Commands:
Return after the end of the process' output sends the text from the 
    end of process to point.
Return before the end of the process' output copies the sexp ending at
    point to the end of the process' output, and sends it.
Delete converts tabs to spaces as it moves back.
Tab indents for Pop; with argument, shifts rest of expression rigidly 
    with the current line.
C-M-q does Tab on each line starting within following expression.
If you accidentally suspend your process, use \\[comint-continue-subjob]
to continue it."
  (interactive)
  (comint-mode)
  (setq comint-prompt-regexp pop-prompt-regexp)
  (use-local-map inferior-pop-mode-map)
  (setq major-mode 'inferior-pop-mode)
  (setq mode-name "Inferior Pop-11")
  (setq mode-line-process '(":%s"))
;  (setq mode-line-format 
;	"--%1*%1*-Emacs: %17b   %M   %[(%m: %s)%]----%3p--%-")
  (setq local-abbrev-table pop-mode-abbrev-table)
  (setq comint-input-filter (function pop-input-filter))
  ;; Note that we can't use add-to-list here as it only works for symbols
  ;; and we can't use adjoin as GNU Emacs doesn't have it and tryinf to use
  ;; add-hook to set the filter function lists screws up (inferior pop buffer
  ;; stays in comint mode and never makes it to inferior-pop-mode).
  (if (not (member (function pop-directory-tracker)
		   comint-input-filter-functions))
      (setq comint-input-filter-functions
	    (cons (function pop-directory-tracker)
		  comint-input-filter-functions)))
  (if (not (member (function pop-nuke-prompt-chars)
		   comint-output-filter-functions))
      (setq comint-output-filter-functions
	    (cons (function pop-nuke-prompt-chars)
		  comint-output-filter-functions)))
; (setq comint-get-old-input (function pop-get-old-input))
  (setq inferior-pop-buffer-start (point))
  (pop-syntax-table)
  (pop-mode-variables)
  ;; If we are using XEmacs add the menu to the menubar.  For GNU we don't 
  ;; have to explictly add the menu to the menubar -- menus automatically
  ;; appear and disappear when the keymaps specified by the MAPS argument to 
  ;; `easy-menu-define' are activated (yuk).
  (if inferior-pop-using-xemacs
      (easy-menu-add inferior-pop-menu))
  ;; Define the procedures to get information from the inferior Pop process
  ;; If inferior-pop-initialisation is nil, don't compile the interface
  ;; procedures.  This should be safe, as Emacs won't send anything to the
  ;; inferior pop process until it sees the Pop-11 prompt.
  (if inferior-pop-initialisation
      (pop-define-emacs-procedures))
  (run-hooks 'comint-mode-hook 'pop-mode-hook 'inferior-pop-mode-hook))


;; This used to allow multiple Poplog processes/buffers with different
;; names, but this makes it very difficult to figure out if we already
;; have a running Poplog process, and if we do, which one we should 
;; use for compiling Pop-11 code in other buffers.
(defun run-pop (cmd)
  "Run an inferior Poplog process, input and output via buffer *Pop-11*.
If there is a process already running in *Pop-11*, just switch to that buffer.
With argument, allows you to edit the command line (default is value of
pop-program-name concatenated with pop-program-args).  Runs the hooks from 
comint-mode-hook and inferior-pop-mode-hook in that order.
\(Type \\[describe-mode] in the process buffer for a list of commands.)"

  (interactive
   (let ((default-cmd (concat pop-program-name
			      (if pop-program-args
				  (concat " " pop-program-args)))))
     (list (if current-prefix-arg
	       (read-string "Run Poplog: " default-cmd)
	     default-cmd))))
  (if (not (comint-check-proc "*Pop-11*"))
      (let ((cmdlist (pop-args-to-list cmd)))
	(setq inferior-pop-buffer (apply 'make-comint "Pop-11" (car cmdlist)
					 nil (cdr cmdlist)))
	(set-buffer inferior-pop-buffer)
	(inferior-pop-mode)))
  (switch-to-buffer "*Pop-11*"))

(defun run-pop-other-frame (cmd)
  "Run an inferior Poplog process in another frame.
Input and output via buffer *Pop-11*.  If there is a process already running 
in *Pop-11*, just switch to that buffer.  With argument, allows you to edit  
the command line (default is value of pop-program-name concatenated with 
pop-program-args).  Runs the hooks from comint-mode-hook and 
inferior-pop-mode-hook in that order.
\(Type \\[describe-mode] in the process buffer for a list of commands.)"

  (interactive
   (let ((default-cmd (concat pop-program-name
			      (if pop-program-args
				  (concat " " pop-program-args)))))
     (list (if current-prefix-arg
	       (read-string "Run Poplog: " default-cmd)
	     default-cmd))))
  (if (not (comint-check-proc "*Pop-11*"))
      (let ((cmdlist (pop-args-to-list cmd)))
	(setq inferior-pop-buffer (apply 'make-comint "Pop-11" (car cmdlist)
					 nil (cdr cmdlist)))
	(set-buffer inferior-pop-buffer)
	(inferior-pop-mode)
	(put 'inferior-pop-mode 'frame-name 'Poplog)
	))
  ;; If there already is a frame for this buffer pop it up otherwise 
  ;; make a new one -- can't do with GNU Emacs, so just make a new one
  ;; and hope for the best.
  (if inferior-pop-using-xemacs
      (let ((inferior-pop-frame (buffer-dedicated-frame inferior-pop-buffer)))
	(if (frame-live-p inferior-pop-frame)
	    (raise-frame inferior-pop-frame)
	  (set-buffer-dedicated-frame
	   inferior-pop-buffer
	   (get-frame-for-buffer inferior-pop-buffer))))
    (switch-to-buffer-other-frame inferior-pop-buffer)))


(defun pop-args-to-list (string)
  "Return the args to poplog as a list."
  (let ((where (string-match "[ \t]" string)))
    (cond ((null where) (list string))
	  ((not (= where 0))
	   (cons (substring string 0 where)
		 (pop-args-to-list (substring string (+ 1 where)
						 (length string)))))
	  (t (let ((pos (string-match "[^ \t]" string)))
	       (if (null pos)
		   nil
		 (pop-args-to-list (substring string pos
						 (length string)))))))))



;;; Input and output filter functions

(defun pop-input-filter (str)
  "Don't save anything matching inferior-pop-filter-regexp"
  (not (string-match inferior-pop-filter-regexp str)))

;; The following procedure is a cut down version of the shell.el
;; equivalent which does not bother with pushd and popd.  
(defun pop-directory-tracker (str)
  "Tracks cd commands issued to inferior Pop-11 process.
This function is called on each input passed to pop11.  It watches for cd
commands and sets the buffer's default directory to track these commands."
  (let ((start (progn (string-match "^[	;\\s ]*" str) ; skip whitespace
		      (match-end 0)))
	end cmd arg1)
    (while (string-match pop-command-regexp str start)
      (setq end (match-end 0)
	    cmd (comint-arguments (substring str start end) 0 0)
	    arg1 (comint-arguments (substring str start end) 1 1))
      (cond ((eq (string-match pop-cd-regexp cmd) 0)
	     (pop-process-cd (substitute-in-file-name arg1))))
      (setq start (progn (string-match "[ ;\\s ]*" str end) ; skip again
			 (match-end 0))))))

(defun pop-process-cd (arg)
  (let ((dir (if (zerop (length arg))
		 (getenv "HOME")
	       arg)))
    (condition-case nil
	(if (file-name-absolute-p dir)
	    (cd-absolute (concat comint-file-name-prefix dir))
	  (cd dir))
      (file-error (message "Couldn't cd.")))))

(defun pop-dirtrack-toggle ()
  "Turn directory tracking on and off in an inferior Pop-11 buffer."
  (interactive)
  (setq pop-dirtrackp (not pop-dirtrackp))
  (message "Directory tracking %s" (if pop-dirtrackp "ON" "OFF")))

;; Note that this assumes that any output of the form ": : " etc. is 
;; garbage produced by the Pop-11 compiler.  This is obviously not the 
;; case, but its hard to be more discriminating.  It mostly works because
;; anything interesting, e.g. ";;; DECLARING VARIABLE foo" is preceeded 
;; and terminated by newlines, which means the prompt characters echoed
;; by the compiler are on line by themselves.   A real fix requires 
;; hacking the Pop-11 compiler.
(defun pop-nuke-prompt-chars (str)
  "Hack to get rid of the prompt characters Pop-11 echoes during compilation."
  (if (string-match "^\\(: \\)+$" str)
      (let ((inferior-pop-window (get-buffer-window inferior-pop-buffer))
	    (len (save-excursion
		     (skip-chars-backward ": "))))
	;; Nasty hack to try and catch the case where the point and the
	;; process mark have become separated, e.g. if inferior-pop-timeout
	;; is nil it is possible to compile when the process mark is not
	;; after the prompt.
	(if (< len 0)
	    (progn
	      (delete-char (+ len 2))
	      (set-window-point inferior-pop-window (point-max))
	      ;; Process output is inserted at the marker, not at point
	      (move-marker (process-mark (pop-proc)) (point-max)))))))



;;; Word completion in pop-mode and inferior-pop-mode. 

;; Note that this won't work in the *Pop-11* buffer, unless the word
;; that we are trying to complete is not after the top level prompt.
(defun pop-complete-word ()
  "Complete Pop-11 word at or before point"
  (interactive)
  (pop-backward-word 1)
  (let ((start (point))
	end wd words comp)
    (pop-forward-word 1)
    (setq end (point))
    (setq wd (buffer-substring start end))
    (message "Fetching words ... %s" "done")
    (setq words (pop-get-words-starting wd))
    (setq comp (pop-try-completion wd words))
    (cond
     ;; should this beep if there are no extensions of wd?
     ((eq comp t) t)
     ((equal comp wd)
      (with-output-to-temp-buffer "*Help*"
	;; Should add a callback here so that we can click on the completion
	;; when using XEmacs and use completion-list-mode for GNU Emacs ...
	(display-completion-list words))
      (message "Making completion list ... %s" "done"))
     (comp 
      (delete-region start end)
      (insert comp))
     (t 
      (message "No completions for \"%s\"" wd)
      (beep)))))

;; This relies on the assumption that pop will not return to the top level
;; prompt until the file containing the competions has been written by
;; emacs_match_wordswith and that pop-send-string will wait for the prompt
;; before returning, guaranteeing that the required ouput will have been
;; written to the file before we try to read it.
;; A clumsier but more robust way to do this would be to generate a command 
;; that will cause Pop-11 to write the possible completions into a temp file 
;; which we can then read.  To get the command executed we put it in a file 
;; and get Pop-11 to compile it (using pop-send-command-file).  
(defun pop-get-words-starting (string)
  "Get the searchlists from the inferior Poplog process."
  (cond ((not (inferior-pop-process-p))
	 (error "Pop-11 process not running"))
	((not (pop-top-level-p))
	 (error "Pop-11 not at top level"))
	(t
	 ;; otherwise get the wordlists from the inferior Poplog process
	 (let* ((wordlist-buffer (get-buffer-create " *Pop-11 completions*"))
		(file (make-temp-name "/tmp/emacs"))
		(command (format "emacs_match_wordswith('@a%s', '%s');\n"
				 string file))
		wordlist)
	   (if (pop-send-string command)
	       (save-excursion
		 (if (not (eq wordlist-buffer (current-buffer)))
		     (set-buffer wordlist-buffer))
		 ;; Get the words list from the Poplog output
		 (delete-region (point-min) (point-max))
		 (insert-file file)
		 (goto-char (point-min))
		 (skip-chars-forward ": ")
		 (setq wordlist (read wordlist-buffer)))
	     ;; Otherwise print a warning
	     (error "Can't build wordlists"))
	   (delete-file file)
	   wordlist))))

(defun pop-try-completion (string words)
  "Return the common substring of all completions of string which are
elements of WORDS.  Each element of WORDS is tested to see if it begins
with STRING.  All that match are compared together; the longest initial
sequence common to all matches is returned as a string.  If there is no 
match at all, nil is returned.  For an exact match, t is returned.

Like try-completion but takes a list instead of an alist."
  (if words
      (try-completion string (mapcar (function (lambda (w) (list w)))
				     words))
    nil))




;;; Functions for sending Pop-11 code to an inferior pop process.

;; The only way we can tell if the inferior Pop-11 process is currently
;; busy is to check if the process mark is after a top-level prompt. 
;; Note that these functions WILL NOT WORK in the inferior-pop-buffer as 
;; pop-top-level-p will be false in this case.  If you need to do this,
;; mark the procedure, go to the end of the buffer and compile the region.

;; This is as close as we can get to eval-last-sexp since we can't parse an
;; expression.  In the inferior pop buffer we can get the same effect with
;; pop-send-old-input.
(defun pop-send-line ()
  "Send the current line to the inferior Poplog process."
  (interactive)
  (let (start end)
    (save-excursion
      (beginning-of-line)
      (skip-chars-forward "; \t")
      (setq start (point))
      (end-of-line)
      (setq end (point))
      (pop-send-file start end "expression from"))))

(defun pop-send-define ()
  "Send the current procedure to the inferior Poplog process"
  (interactive)
  (let ((proc (pop-define-ends)))
    (pop-send-file (car proc) (cdr proc)
		   (concat "procedure" (pop-define-name) " from"))))

(defun pop-send-buffer ()
  "Send the entire buffer to the inferior Poplog process"
  (interactive)
  (pop-send-file (point-min) (point-max) "buffer"))

(defun pop-send-region (start end)
  "Send the current region to the inferior Poplog process."
  (interactive "r")
  (pop-send-file start end "region from"))

;; The comint-mode for XEmacs 19.15 is broken: killing the process leaves
;; an extent after the process mark with closed ends.  As a result any
;; final output from the process or from a subsequent process run in the
;; same buffer appears in comint-input-face.  This doesn't catch all the
;; ways the process can be killed without cleaning up the extent in the
;; inferior pop buffer, but it fixes the most common problem.
(defun pop-delchar-or-maybe-eof (arg)
  "Delete ARG characters forward, or (if at eob) send an EOF to subprocess."
  (interactive "p")
  (if (not (eobp))
      (delete-char arg)
    (cond ((and (boundp 'comint-input-extent) comint-input-extent)
	   ; Finalise the existing extent.
	   (set-extent-property comint-input-extent 'start-closed nil)
	   (set-extent-property comint-input-extent 'end-closed nil)
	   (set-extent-property comint-input-extent 'detachable t)))
    (process-send-eof)))

(defun pop-send-eof ()
  "Send an EOF to the current buffer's process."
  (interactive)
  (cond ((and (boundp 'comint-input-extent) comint-input-extent)
	 ; Finalise the existing extent.
	 (set-extent-property comint-input-extent 'start-closed nil)
	 (set-extent-property comint-input-extent 'end-closed nil)
	 (set-extent-property comint-input-extent 'detachable t)))
  (process-send-eof))

;; Richard's approach of using temporary `comments' which are deleted after
;; the command returns is tricky if the command can produce output.  If we
;; write a comment into the buffer we leave it there: as a result, 
;; pop-send-command doesn't have to use pop-send-string -- it can just do
;; its i/o in the inferior pop buffer using comint-send-string and rely on
;; the comment to make sure that pop-top-level-p returns false, blocking
;; further interaction until the current compilation has returned.  If
;;  pop-compilation-messages is nil, we write a message into the minibuffer 
;; and rely on pop-send-string not returning until we get the prompt back.
(defun pop-send-file (start end &optional what)
  "Compile the current region."
  (interactive "r")
  (if (not (pop-top-level-p))
      (error "Pop-11 not at top level")
    (let* ((file (make-temp-name "/tmp/emacs"))
	   (command (format "compile('%s');\n" file))
	   (comment (format "Compiling %s %s" what (buffer-name))))
      (write-region start end file nil 'silent)
      (pop-send-command command comment)
      (if inferior-pop-timeout
	  (delete-file file)))))

;; This is a bit of a hack but mostly seems to work except when we are 
;; compiling from a window in the same frame as a inferior-pop-buffer window.
;; For some reason point is updated when it is not at the end of buffer, which 
;; is wrong.  It is not the walk-windows which is doing this, perhaps 
;; comint-postoutput-scroll-to-bottom is doing something weird?  Windows in 
;; other frames are ok.  Note that we don't *need* to write a comment into 
;; the buffer, since Emacs won't return until we have some output from the 
;; inferior pop process, and we won't get any output until the prompt comes 
;; back or we get some other output (e.g. a warning), in which case the 
;; process mark will not be after the prompt and pop-top-level-p will be 
;; false, preventing further compilation until we do get a prompt.
(defun pop-send-command (command comment)
  "Send COMMAND to the inferior Pop-11 process for execution.
If pop-compilation-messages is non-nil, COMMENT is written into the 
inferior-pop-buffer after the mark as a reminder that the command is in 
progress, otherwise it is echoed in the minibuffer."
  (if (not (pop-top-level-p)) ; Paranoia: shouldn't be here otherwise
      (error "Pop-11 not at top level")
    (if pop-compilation-messages
      (let ((old-buffer (current-buffer))
	    (compile-comment (format "%s %s\n" comment-start comment)))
	;; Use `unwind-protect' rather than `save-excursion' to preserve
	;; the change in point made by goto-char.
	(unwind-protect
	    (let (moving old-marker-pos after-comment-pos)
	      (if (not (eq inferior-pop-buffer (current-buffer)))
		  (set-buffer inferior-pop-buffer))
	      (setq moving (= (point) (process-mark (pop-proc))))
	      (setq old-marker-pos (marker-position (process-mark (pop-proc))))
	      (save-excursion 
		(goto-char old-marker-pos)
		(insert-string compile-comment)
		;; Process output is inserted at the marker, not at point
		(set-marker (process-mark (pop-proc)) (point))
		(sit-for 0))
	      ;; Update windows of inferior pop buffer if the window's point
	      ;; was at the end of the buffer before the insertion.
	      (walk-windows
	       (function
		(lambda (window)
		  (if (and (equal (window-buffer window) inferior-pop-buffer)
			   (equal (window-point window) old-marker-pos))
		      (set-window-point window (process-mark (pop-proc))))))
	       'not-minibuffer t)
	      (if moving (goto-char (process-mark (pop-proc))))
	      ;; If we wrote the comment into the inferior pop buffer, we need
	      ;; to echo the prompt in the buffer so use comint-send-string
	      ;; rather than pop-send-string (which would eat the prompt)
	      (setq after-comment-pos
		    (marker-position (process-mark (pop-proc))))
	      (comint-send-string (pop-proc) command)
	      (if inferior-pop-timeout
		  (let ((timeout (+ (cadr (current-time)) (pop-timeout-secs))))
		    (while (and  (= (process-mark (pop-proc)) after-comment-pos)
				 (<= (cadr (current-time)) timeout))
		      ;; The only safe way to do this seems to be to sit in a
		      ;; loop until the process mark moves ...
		      (accept-process-output)))))
	  (set-buffer old-buffer)))
      (message comment)
      (pop-send-string command))))

;; Note that BUFFER doesn't have to be the inferior Pop-11 buffer, so that
;; this can be used to obtain information from the Pop-11 process without
;; messing up the user's inferior Pop-11 buffer.  Note also that this will 
;; return true if we get ANY output at all from the Pop-11 process, including 
;; the Pop-11 prompt char, mishaps etc.
(defun pop-send-string (string &optional buffer)
  "Send STRING to the inferior Pop-11 process, redirecting output to BUFFER
if this is non-nil, otherwise output is returned as a string."
  (if (pop-top-level-p)
      (if (eq buffer inferior-pop-buffer)
	  (let ((pmark (marker-position (process-mark (pop-proc)))))
	    (process-send-string (pop-proc) string)
	    (if inferior-pop-timeout
		(let ((timeout (+ (cadr (current-time)) (pop-timeout-secs))))
		  (while (and  (= (process-mark (pop-proc)) pmark)
			       (<= (cadr (current-time)) timeout))
		    ;; The only safe way to do this seems to be to sit in a
		    ;; loop until the process mark moves ...
		    (accept-process-output))))
	    (if inferior-pop-timeout
		(>= (process-mark (pop-proc)) pmark)
	      t))
	;; otherwise remember the current pop buffer and process mark
	(let* ((inferior-pop-process (inferior-pop-process-p))
	       (inferior-pop-buffer (process-buffer inferior-pop-process))
	       (inferior-pop-markpos (marker-position (process-mark
						       inferior-pop-process)))
	       (interaction-buffer (or buffer
				       (get-buffer-create
					" *Poplog interaction*")))
	       pmark pop-output)
	  (unwind-protect
	    (save-excursion
	      (if (not (eq interaction-buffer (current-buffer)))
		  (set-buffer interaction-buffer))
	      (setq buffer-read-only nil)
	      (if (not buffer)
		  (delete-region (point-min) (point-max)))
	      ;; We need this, even though we are not using comint-send-string:
	      ;; the process mark seems to contain some sort of refernce to 
	      ;; comint mode?
	      (if (not (or (equal major-mode 'inferior-pop-mode)
			   (equal major-mode 'comint-mode)))
		  ;; Set up the comint-mode variables for process-send-string
		  (comint-mode))
	      (set-process-buffer inferior-pop-process interaction-buffer)
	      ;; Since this wasn't the process buffer, the process mark doesn't
	      ;; point to it and the only sensible place to insert the output
	      ;; is at the end of the buffer.
	      (setq pmark (point-max))
	      (set-marker (process-mark inferior-pop-process)
			  pmark interaction-buffer)
	      (process-send-string inferior-pop-process string)
	      (if inferior-pop-timeout
		  (let ((timeout (+ (cadr (current-time)) (pop-timeout-secs))))
		    (while (and  (= (process-mark inferior-pop-process) pmark)
				 (<= (cadr (current-time)) timeout))
		      ;; The only safe way to do this seems to be to sit in a
		      ;; loop until the process mark moves ...
		      (accept-process-output))))
	      (setq pop-output
		    (if buffer 
			(if inferior-pop-timeout
			    (>= (process-mark inferior-pop-process) pmark)
			  t)
		      (buffer-substring (point-min) (point-max)))))
	    (set-process-buffer inferior-pop-process inferior-pop-buffer)
	    (set-marker (process-mark inferior-pop-process)
			inferior-pop-markpos inferior-pop-buffer))
	  ;; This is safe: interaction buffer is no longer the pocess buffer
	  (if (not buffer)
	      (kill-buffer interaction-buffer))
	  pop-output))))

(defun pop-load-file (file-name)
  "Load a Pop-11 file into the inferior Poplog process."
  (interactive (comint-get-source "Load Pop-11 file: " pop-prev-l/c-dir/file
				  pop-source-modes t)) ; T because LOAD 
					               ; needs an exact name
  (comint-check-source file-name) ; Check to see if buffer needs saved.
  (setq pop-prev-l/c-dir/file (cons (file-name-directory    file-name)
				    (file-name-nondirectory file-name)))
  (comint-send-string (pop-proc) (concat "load \'" file-name "\'\n")))

;; Doing it this way is probably not a good idea and its not clear what
;; the Right Thing is if its not the default: one alternative would be to
;; snarf the sexp surrounding point or the current line, whicever is the
;; larger ...
(defun pop-get-old-input ()
  "Snarf the sexp ending at point"
  (save-excursion
    (let ((end (point)))
      (backward-sexp)
      (buffer-substring (point) end))))

(defun pop-wait-for-top-level ()
  "Waits until Pop-11 process is at top level and returns t.  If this does
not happen within inferior-pop-timeout secs, gives up and returns nil."
  (if inferior-pop-timeout
      (let ((timeout (+ (cadr (current-time)) (pop-timeout-secs))))
	(while (and (not (pop-top-level-p))
		    (<= (cadr (current-time)) timeout))
	  (accept-process-output))
	(pop-top-level-p))
    t))

;; This is broken: what is should do is ensure that the process mark is after
;; a top level prompt, but the process mark goes with the process, not the 
;; buffer, so when we change the buffer process, this information is lost.
(defun pop-top-level-p ()
  "Returns t if the process mark appears to be after a Pop-11 top-level prompt.
If inferior-pop-timeout is nil, always returns t."
  (if (inferior-pop-process-p) ; work around oddities in process-status
      (if inferior-pop-timeout
	  (if (equal (process-status (inferior-pop-process-p)) 'run)
	      (let ((old-buffer (current-buffer))
		    top-level)
		(if (not (eq old-buffer inferior-pop-buffer))
		    (set-buffer inferior-pop-buffer))
		(save-excursion
		  (goto-char (process-mark (inferior-pop-process-p)))
		  (setq top-level
			(if (re-search-backward ": "
						inferior-pop-buffer-start
						t)
			    (save-restriction
			      (narrow-to-region (point) (point-max))
			      (looking-at ": +$")))))
		(set-buffer old-buffer)
		top-level))
	t)))

(defun pop-timeout-secs ()
  "Returns the Maximum number of seconds to wait for inferior Pop-11 process 
to produce output, or nil meaning don't wait."
  (if inferior-pop-timeout
      (if (equal inferior-pop-timeout t)
	  10000 ; Magic number
	inferior-pop-timeout)))

(defun pop-proc ()
  "Returns the current Poplog process."
  (or (inferior-pop-process-p)
      (error "No current process.")))

(defun inferior-pop-process-p ()
  "Returns the current Poplog process or nil if none."
  (get-buffer-process inferior-pop-buffer))

;;; GNU Emacs doesn't load the cl package by defualt.
(defun cadr (x)
  "Return the `car' of the `cdr' of X."
  (car (cdr x)))



;;; Stuff for pop-help-mode initialisation

;; It would be better to have a list of these procedures that get compiled
;; at startup, so that we can more easily extend the Pop emacs interface.
;; This string is about 215 chars long and contains no embedded newlines.
(defvar pop-wordswith-procedure
  "define emacs_match_wordswith(pattern, file); dlocal cucharout=discout(file), poplinewidth = false; '( '.pr; applist(match_wordswith(pattern), printf(% '\"%P\" ' %)); ')'.pr; 1.nl; termin.cucharout; enddefine;\n"

  "*A string containing a Pop-11 command to print a list of all
words starting with STRING to FILE.")

;; This string is about 364 chars long but there is a newline after the first
;; 221 chars, which presumably explains why Emacs/Pop-11/PTYs/whatever is 
;; causing the problem doesn't screw up.
(defvar pop-searchlists-procedure
  "define emacs_flatten_searchlists(file); dlocal cucharout=discout(file), poplinewidth = false; lvars t, l; '( '.pr; for t l in [help teach ref doc lib], [^vedhelplist ^vedteachlist ^vedreflist ^veddoclist ^popuseslist] do
printf(t, '( \"%P\" '); applist(flatten_searchlist(l), printf(%'\"%P\" '%)); ')'.pr; \ endfor; ' )'.pr; 1.nl; termin.cucharout; enddefine;\n"

  "*A string containing a Pop-11 command to print an alist containing
the Pop-11 HELP, TEACH, REF, DOC and SHOWLIB searchlists.")

;; There are several possibilities here, none of them ideal.  The simplest
;; is to test that there is a pop process and use comint-send-string
;; to send the initialisation string, relying on Unix to buffer the input 
;; until the Pop process is ready.  However in some cases it seems that if
;; pop is very slow starting up, the intialisation string gets lost.  Using 
;; comint-send-string relies on the ouput filter pop-nuke-prompt-chars to 
;; keep the buffer tidy.  Another alternative would be to use 
;; pop-send-command-file: this minimises the length of the string that must be 
;; sent to the Pop process, but leaves a temp file lying around as, unless we 
;; wait for the prompt (using pop-wait-for-top-level with the problem below), 
;; we don't know when it is safe to delete it.
(defun pop-define-emacs-procedures-old ()
  "Define the procedures which return information from the inferior
Pop process."
  (if (pop-proc) ; we want to know if the initialisation fails
      ;; Using pop-send-string here loses the banner for some reason.
      ;; This only works because the string contains at least one newline
      ;; every 256 chars?  Presumably the echoed newlines are eaten by
      ;; pop-nuke-prompt-chars which was never disabled?
      (comint-send-string (pop-proc) (concat pop-wordswith-procedure
					     pop-searchlists-procedure))
    (beep)
    (message "ERROR: Emacs initialisation failed.")))

;; This version tries to make sure that the initialisation string is not sent
;; to the inferior Pop-11 process until it is at top level and hence doesn't
;; get lost, at the risk of locking up emacs for inferior-pop-timeout seconds.
;; As above, we may get prompt chars echoed in the main interaction buffer, 
;; since pop-send-string will return after the first prompt, but 
;; pop-nuke-prompt-chars should get rid of those.
(defun pop-define-emacs-procedures ()
  "Define the procedures which return information from the inferior
Pop process."
  (if (and (pop-proc)  ; we want to know if the initialisation fails
	   (pop-wait-for-top-level))
      ;; This only works because the string contains at least one newline
      ;; every 256 chars?  Presumably the echoed newlines are eaten by
      ;; pop-nuke-prompt-chars which was never disabled?
      (progn
	(message "Initialising Pop-11 for Emacs ...")
	(pop-send-string (concat pop-wordswith-procedure
				 pop-searchlists-procedure)
			 inferior-pop-buffer)
	;; Make no promises if the user doesn't want to wait
	(if inferior-pop-timeout
	    (message "Initialising Pop-11 for Emacs ... done")))
    (beep)
    (message "ERROR: Emacs initialisation failed.")))

;; Like pop-send-file, but uses pop-send-string to hide the output in a
;; private buffer.  Again, this will not return until there is some output.
;; For use with pop-compete-word and pop-help-update-searchlists
(defun pop-send-command-file (command &optional buffer)
  "Compile the Pop-11 COMMAND, a string."
  (interactive "r")
  (let* ((file (make-temp-name "/tmp/emacs"))
	 (compile-command (format "compile('%s');\n" file))
	 pop-output)
    (write-region command nil file nil 'silent)
    (setq pop-output (pop-send-string compile-command buffer))
    ;; It would be nice to delete the file, but pop-send-string seems to
    ;; return after receiving output from the Poplog startup so we delete
    ;; the file too early.  We could wait until we are at Pop top-level
    ;; but that jsut adds more timing problems.
;    (delete-file file)
    pop-output))



;;; CHANGE LOG
;;; ===========================================================================
;;; 24th Feb 1991 rjc
;;; Split off from pop-mode.el
;;; Changed to use comint rather than shell-mode.  Removed the pop-mode 
;;; bindings from inferior-pop-mode, they clash with comint.

;;; 4th Oct 1995 bsl
;;; removed references to cmushell (now shell.el) and v18 emacs including
;;; full-copy-sparse-keymap and fixed pop-directory-tracker

;;; 5th April 1996 bsl
;;; Moved pop-help-send-string from pop-help-mode.el and renamed it
;;; pop-send-string.  Moved the emacs_searchlists initialisation from
;;; inferior-pop-mode to pop-help-update-searchlists in pop-help-mode.el: it 
;;; is now sent before every request for information.  This is slower, but 
;;; cleaner.  Added pop-top-level-p tests to pop-send-string.  Modified
;;; pop-get-words-starting to use pop-send-string.

(provide 'inferior-pop-mode)
