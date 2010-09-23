/*  --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:           C.all/lib/sun/vedwin_utils.p
 > Purpose:        procedures to control and interrogate sun windows
 > Author:         Ben Rubinstein, Mar  6 1986 (see revisions)
 > Documentation:
 > Related Files:
 */
compile_mode :pop11 +strict;

/*
	procedures to manipulate sun windows, using the new features of the
	version 2.0 tty emulator.  These procedures implement the escape
	sequences mechanism described on page 29 of the "Changes 1.1 to 2.0"
	manual.

		All procedures which return any result return only one result
	(a two element vector in the case of those which are supposed to return
	an x and y value); only one attempt to read a value will be made; and
	if the attempt fails, FALSE will be returned (this is never a valid
	result).

		Procedures which use these primitives should therefore be prepared
	to accept FALSE instead of a word, string, or vector; alternately, the
	procedure "call5", defined in this file, may be used.  This takes one
	argument, a procedure; it calls this procedure up to five times, until
	it gets a non-false result; if it calls the procedure five times
	without success it mishaps, with the message "cannot read tty value"
	and the name of the procedure.

	The procedures are listed below:

VEDWIN_HIDE();
VEDWIN_EXPOSE();
VEDWIN_REFRESH();

VEDWIN_OPEN();
VEDWIN_CLOSE();
VEDWIN_GET_OPEN_OR_CLOSED() -> word;        ;;; "o" or "c"


file -> VEDWIN_ICON_FILE();             ;;; filename, a string or word; if
										;;; a word, prepends '$popiconlib'
										;;; and appends '.ic'

VEDWIN_ICON_FILE() -> file;             ;;; this just returns the last string
										;;; sent to the updater, or FALSE

VEDWIN_ICON_LABEL(string);
string -> VEDWIN_ICON_LABEL();

string -> VEDWIN_TOOL_HEADER();
VEDWIN_TOOL_HEADER() -> string;

{columns, lines} -> VEDWIN_TTY_SIZE();      ;;;  size in characters
VEDWIN_TTY_SIZE() -> {columns lines};       ;;;

{width, height} -> VEDWIN_WINDOW_SIZE();    ;;; size in pixels
VEDWIN_WINDOW_SIZE() -> {width height};     ;;;

{left, top} -> VEDWIN_POSITION();
VEDWIN_POSITION() -> {left top};

VEDWIN_INTERACTIVE_MOVE();
VEDWIN_INTERACTIVE_STRETCH();

*/

section;

uses get_tty_report;

vars vedwin_extracols = 2;   ;;; number of columns to leave at right,
									;;; for dropping off.

define vars vedwin_tool_header() -> string;
	lvars string;
	get_tty_report('\^[[21t', '\^[]l', `\\`) -> string;
	allbutlast(1, string) -> string;
enddefine;

define updaterof vedwin_tool_header(string);
	lvars string;
	appdata('\^[]l' <> string <> '\^[\\', rawcharout);
	sysflush(poprawdevout)
enddefine;


define vars vedwin_icon_label() -> string;
	lvars string;
	get_tty_report('\^[[20t', '\^[]L', `\\`) -> string;
	allbutlast(1, string) -> string;
enddefine;

define updaterof vedwin_icon_label(string);
	lvars string;
	appdata('\^[]L' <> string <> '\^[\\', rawcharout);
	sysflush(poprawdevout)
enddefine;


vars vedwin_last_icon_file = false;

define vars vedwin_icon_file();
	vedwin_last_icon_file
enddefine;

define updaterof vedwin_icon_file(file);
	lvars file;
	if file.isword then
		'$popiconlib/' >< file <> '.ic' -> file
	elseunless file.isstring do
		mishap(file, 1, 'word or string needed for file name')
	endif;
	appdata('\^[]I' <> (file.sysfileok) <> '\^[\\', rawcharout);
	file -> vedwin_last_icon_file;
	sysflush(poprawdevout)
enddefine;

;;; report window size in characters: returns FALSE (if message was garbled
;;; somewhere) or a vector of two integers, as {columns, lines}
;;;
;;;  N.B.  Due to a bug in Sun's tty emulator, this returns the wrong numbers
;;; when applied to a graphics tool tty window - i.e. it returns the size of
;;; the whole window, including graphics part.
;;;
define vars vedwin_tty_size();
	lvars columns lines s r;
	get_tty_report('\^[[18t', '\^[[8;', `t`) -> s;
	if      s
	then    incharitem(stringin(s)) -> r;
			r() -> lines;
			if      lines.isinteger
			and     r() == ";"
			then    r() -> columns;
					if      columns.isinteger
					and     r() == termin
					then    {% columns, lines %}
					else    false
					endif
			else    false
			endif
	else    false
	endif
enddefine;

;;; set the size of the window:
;;;         takes a vector giving the size in characters, as {columns, lines}
;;;
define updaterof vedwin_tty_size(vec);
	lvars vec;
	appdata('\^[[8;' sys_>< subscrv(2, vec) <>';'
			sys_>< subscrv(1, vec) <> 't', rawcharout);
	sysflush(poprawdevout)
enddefine;

;;; get the size of the window:
;;;     returns a vector giving the size in pixels, as
;;;         {width, height}
;;;
define vars vedwin_window_size();         ;;; -> {width height}
	lvars width height s r;
	get_tty_report('\^[[14t', '\^[[4;', `t`) -> s;
	if      s
	then    incharitem(stringin(s)) -> r;
			r() -> height;
			if      height.isinteger
			and     r() == ";"
			then    r() -> width;
					if      width.isinteger
					and     r() == termin
					then    {% width, height %}
					else    false
					endif
			else    false
			endif
	else    false
	endif
enddefine;

;;; set the size of the window:
;;;     takes a vector giving the size in pixels, as
;;;         {width, height}
;;;
define updaterof vedwin_window_size(vec);
	lvars vec;
	appdata('\^[[4;' sys_>< subscrv(2, vec) <> ';'
				sys_>< subscrv(1, vec) <> 't', rawcharout);
	sysflush(poprawdevout)
enddefine;

;;; get the position of the current window
;;;     returns the number of pixels (in the x and y dimensions) of the
;;;     top left of the window, from the top left of the screen, as
;;;     a two-element vector,  {x, y}
;;;
define vars vedwin_position();
	lvars left top s r;
	get_tty_report('\^[[13t', '\^[[3;', `t`) -> s;
	if      s
	then    incharitem(stringin(s)) -> r;
			r() -> top;
			if      top.isinteger
			and     r() == ";"
			then    r() -> left;
					if      left.isinteger
					and     r() == termin
					then    {% left, top %}
					else    false
					endif
			else    false
			endif
	else    false
	endif
enddefine;

;;; set the position of the window, by specifying the number of pixels in the
;;; x and y directions of the top left of the window from the top left of the
;;; screen - as a vector, {x, y}
;;;
define updaterof vedwin_position(vec);
	lvars vec;
	appdata('\^[[3;' sys_>< subscrv(2, vec) <> ';'
			sys_>< subscrv(1, vec) <> 't', rawcharout);
	sysflush(poprawdevout)
enddefine;

define vars vedwin_open();
	appdata('\^[[1t', rawcharout);
	sysflush(poprawdevout)
enddefine;

define vars vedwin_close();
	appdata('\^[[2t', rawcharout);
	sysflush(poprawdevout)
enddefine;

define vars vedwin_get_open_or_closed() -> word;      ;;; "o" or "c"
	lvars word;
	get_tty_report('\^[[11t', '\^[[', `t`) -> word;
	if      word = '1'
	then    "o"
	elseif  word = '2'
	then    "c"
	else    false
	endif   -> word
enddefine;


define vars vedwin_expose();
	appdata('\^[[5t', rawcharout);
	sysflush(poprawdevout);
enddefine;

define vars vedwin_hide();
	appdata('\^[[6t', rawcharout);
	sysflush(poprawdevout)
enddefine;


define vars vedwin_refresh();
	appdata('\^[[7t', rawcharout);
	sysflush(poprawdevout)
enddefine;

define vars vedwin_interactive_stretch();
	appdata('\^[[4t', rawcharout);
	sysflush(poprawdevout)
enddefine;

define vars vedwin_interactive_move();
	appdata('\^[[3t', rawcharout);
	sysflush(poprawdevout)
enddefine;

;;; the reporter forms of the procedures above send an escape sequence to
;;; the terminal, and expect a complex sequence back,  which  they analyse
;;; to extract the required value.  If something goes wrong in the
;;; transmission or reception of one or the other, the procedure returns
;;; FALSE.
;;;
;;;     This procedure therefore makes up to five attempts to call
;;; the given procedure, and if FALSE is returned five times mishaps.
;;;
define vars vedwin_call5(proc);
	lvars proc;
	repeat  5 times
		if  .proc.dup then return else erase endif
	endrepeat;
	mishap(proc.pdprops, 1, 'cannot read tty value');
enddefine;

constant vedwin_utils = true;

endsection;



/* --- Revision History ---------------------------------------------------
--- John Gibson, Dec 14 1992
		Made all vars, call5 -> vedwin_call5
--- Simon Nichols, Jun 12 1991
		Declared parameters and/or output locals as lvars in
		-vedwin_tool_header-, -vedwin_icon_label- -vedwin_icon_file-,
		-vedwin_get_open_or_closed- and -call5- (see bugreport davidy.43).
--- John Gibson, Nov 11 1987
		Replaced -popdevraw- with -poprawdevout-
 */
