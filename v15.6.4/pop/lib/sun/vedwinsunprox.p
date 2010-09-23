/*  --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:           C.all/lib/sun/vedwinsunprox.p
 > Purpose:		   procedures for using ved with sun windows
 > Author:         Ben Rubinstein, Mar  6 1986 (see revisions)
 > Documentation:	HELP * VEDWINSUN
 > Related Files:	LIB * VEDWIN_UTILS, VEDWIN_ADJUST
 */
compile_mode :pop11 +strict;

/* LIB VEDWINSUNPROX.P                                       bhr february 1986
*
*		This file loads and defines procedures used to adjust ved to
*	work with windows - specifically Shelltool windows - on the Sun.
*	It loads LIB VEDWIN_UTILS, which defines a suite of procedures to
*	manipulate and interrogate Shelltool windows via escape sequences;
*	and	LIB VEDWIN_ADJUST, which defines a procedure to adjust a ved to
*	work in a particular size of window.  It then defines procedures:
*		-ved_adjust-	which allows vedwin_adjust to be forcibly
*							invoked from the ved command line;
*		-ved_stretch- 	which invokes a mouse-controlled window resizing,
*							and automatically adjusts ved afterwards.
*/

uses vedwin_utils;	;;; control and interrogate shelltool windows
uses vedwin_adjust;  ;;; adjust ved to fit new window size

;;; based on /usr/cog/chriss/.mylib/ved_adjust.p
;;; adjust ved windows to CURRENT sun window size
;;;
define vars ved_adjust;
	lvars v;
	vedwin_tty_size() -> v;
	if v then
		unless v(2) == vedscreenlength and v(1) == vedscreenwidth fi_+ 2 then
			/* window has changed */
			vedwin_adjust(v(2), v(1));
			vedputmessage('window is now ' sys_>< v(2) sys_>< ' lines, '
						sys_>< v(1) sys_>< ' columns.')
		endunless;
	endif;
enddefine;

;;; invokes a "stretch" operation using the mouse, as if the user had
;;; selected the "stretch" operation from the "Tool Mgr" menu: and adjusts
;;; ved to suit the new size when the operation has been concluded.
;;;
define vars ved_stretch();
	lvars c l;
	appdata('\^[[4t', rawcharout);
	sysflush(poprawdevout);
	vedwin_call5(vedwin_tty_size).explode -> l -> c;
	vedwin_adjust(l, c);
	vedputmessage('window is now ' sys_>< l sys_>< ' lines, '
						sys_>< c sys_>< ' columns.')
enddefine;

vars vedwinsunprox = true;			;;; for "uses"


/* --- Revision History ---------------------------------------------------
--- Adrian Howard, Sep  8 1992
		Now uses sys_><
--- John Williams, Aug  5 1992
		Made -vedwinsunprox- global
--- John Gibson, Nov 11 1987
		Replaced -popdevraw- with -poprawdevout-
 */
