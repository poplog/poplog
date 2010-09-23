;;; Example init.p file for version 2.3 of pop-mode for GNU Emacs/XEmacs

;;; Emacs interface procedures.
;;; If you set the variable 'inferior-pop-initialisation' to nil in your
;;; .emacs file, then the following two procedures must be loaded for the
;;; Emacs/Poplog communication to work properly.

define emacs_match_wordswith(pattern, file); 
    dlocal cucharout=discout(file), poplinewidth = false; 
    
    '( '.pr; 
    applist(match_wordswith(pattern), printf(% '\"%P\" ' %)); 
    ')'.pr; 
    1.nl; 
    termin.cucharout; 
    enddefine;

define emacs_flatten_searchlists(file); 
    dlocal cucharout=discout(file), poplinewidth = false; 
    lvars t, l; 

    '( '.pr; 
    for t l in [help teach ref doc lib], 
	       [^vedhelplist ^vedteachlist ^vedreflist 
		^veddoclist ^popuseslist] do
        printf(t, '( \"%P\" '); 
	applist(flatten_searchlist(l), printf(%'\"%P\" '%)); 
	')'.pr;
	endfor;
 
    ' )'.pr; 
    1.nl; 
    termin.cucharout; 
    enddefine;

;;; Other things that you may find useful ...

;;; We use an alternative version of prwarning when running under Emacs.
;;; When compiling an Emacs buffer, the value of popfilename is the
;;; temporary file used for inter-process communication.
define emacs_prwarning(word);
    ;;; popfilename is false when the compiler is reading standard input?
    if popfilename then
	if issubstring('/tmp/emacs', popfilename) then
    	    printf(';;; DECLARING VARIABLE %p line %p\n', [^word ^poplinenum]);
    	else
    	    printf(';;; DECLARING VARIABLE %p in file %p line %p\n',
               	   [^word ^popfilename ^poplinenum]);
	    endif;
    else
	sysprwarning(word);
	endif;
    enddefine;
emacs_prwarning -> prwarning;
