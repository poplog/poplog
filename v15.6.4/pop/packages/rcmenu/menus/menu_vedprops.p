/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menus/menu_vedprops.p
 > Purpose:			Control VED environment
 > Author:          Aaron Sloman, Jan 24 1995
 > Documentation:
 > Related Files:
 */


define global vars ved_indent();
	;;; system version leaves number on stack
	;;; change the indentation step
	unless vedargument == nullstring then
		strnumber(vedargument) -> vedindentstep
	endunless;
	vedputmessage(vedindentstep sys_>< nullstring);
	vedsetcursor();
enddefine;

define ved_winsize;
	;;; set or show vedstartwindow
	lvars num;
	if strnumber(vedargument) ->> num then
		num -> vedstartwindow
	endif;
	vedputmessage(vedstartwindow sys_>< nullstring);
	vedsetcursor()
enddefine;
		

section;

define :menu vedprops;
	'VED Ops'
	'Menu''vedprops'
	'(Set or''toggle'
	'variables)'
	['Tabs' ved_tabs]
	['Static' ved_static]
	['Break' ved_break]
	['SetWindow' vedsetwindow]
	['LMargin*' [ENTER 'lcol 1' 'Set left margin (default 1)']]
	['RMargin*' [ENTER 'rcol 72' 'Set right margin (default 72)']]
;;;	['WindowLength' [ENTER 'winsize 12' 'Set number of lines in window']]
	['TabStep*' [ENTER 'indent 4' 'Set vedindent - tab set. Default 4']]
	['Control...' [MENU control]]
	['Editor...' [MENU editor]]
	['HELP Vars' 'ref vedvars']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
