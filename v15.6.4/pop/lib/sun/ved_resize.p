/*  --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:           C.all/lib/sun/ved_resize.p
 > Purpose:        ved command for changing the size of the (sun) window
 > Author:         Ben Rubinstein, Mar  6 1986 (see revisions)
 > Documentation:
 > Related Files:
 */
compile_mode :pop11 +strict;

/*
																bhr/ 8-11-85
	VED_RESIZE      - for use with sun windows.

		changes the size of the window, and adjusts ved to fit the new size.

	resize <lines> , <columns>          (the "," is compulsory)
	resize <lines> ,                    (the "," is optional)
	resize , <columns>                  (the "," is compulsory)
							- either argument may be an offset, e.g.
										resize 34, +5
								sets the window to 34 lines, and 5 more columns
								than it is at present.
	resize
		- use default for extension specified in VEDWIN_FILE_SIZES
			or  default specified in VEDWIN_DEFAULT_SIZE
			or  24 lines, 80 columns
	resize ?                - report the size, and don't change anything;
							also check that we're using the standard font,
							and if not record the maximum size (in
							characters) that this window can be set to.
							(this is admittedly clumsy).

*/

uses vedwin_utils;
uses vedwin_adjust;

lconstant macro (
	EXTRA_LINES	= 1,						;;; command line
	EXTRA_COLS	= [(1 + vedwin_extracols)],	;;; 1 on left for marking etc, plus
);
											;;; any needed for dropoff at right

vars vedwin_default_size;
vars vedwin_file_sizes;

vars vedwin_max_lines = 54;         ;;; for standard font
vars vedwin_max_columns = 142;      ;;; ditto

vars vedwin_text_height = 16;       ;;; ditto
vars vedwin_text_width = 8;         ;;; ditto

;;; like LMEMBER, but using "=" instead of "=="
;;;     (Weak MEMBER)
;;;
define lconstant wmember(i, l);       ;;; -> l;
	lvars i, l;
	if      l.null
	then    false
	elseif  l.hd = i
	then    l
	else    wmember(i, l.tl)
	endif
enddefine;

;;; return a window size for the appropriate file (a vector {lines columns})
;;; use that specified for the current extension in VEDWIN_FILE_SIZES, if
;;; defined; or the default in VEDWIN_DEFAULT_SIZE, if that is defined; or
;;; 24 lines,  80 columns otherwise
;;;
define lconstant resize_default_size();       ;;; -> vec;
	lvars ext x;
	if      vedwin_file_sizes.islist
	then    sys_fname_extn(vedcurrent) -> ext;
			if      (wmember(ext, vedwin_file_sizes) ->> x)
			and     x(2).isvector
			then    return(x(2))
			endif
	endif;
	if      vedwin_default_size.isvector
	then    vedwin_default_size
	else    {34 80}
	endif
enddefine;

;;; obtain two numbers from vedargument, in the syntax described at the top
;;; of the file, or mishap
;;;
define lconstant resize_argument_size() -> columns -> lines;
	lvars x ls cs columns lines;
	if      (locchar(`,`, 1, vedargument) ->> x)
	then    substring(1, x - 1, vedargument) -> ls;
			substring(x + 1, vedargument.length - x, vedargument) -> cs;
	else    vedargument -> ls;
			'' -> cs;
	endif;
	if      ls = '' or cs = ''
	or      locchar(`+`, 1, vedargument)
	or      locchar(`-`, 1, vedargument)
	then    vedwin_call5(vedwin_tty_size).explode -> lines -> columns;
			lines - EXTRA_LINES -> lines;
			columns - EXTRA_COLS -> columns;
	endif;
	define lconstant adjust(n, s) -> n;
		lvars n s rep;
		if   s = '' then return endif;
		incharitem(stringin(s)) -> rep;
		if      (rep() ->> x) = "+"     then    n + rep()
		elseif  x = "-"                 then    n - rep()
		elseif  x.isinteger and x < 0   then    n + x
		elseif  x.isinteger             then    x
		else    false
		endif   -> n;
		unless  n and rep() == termin
		do      vederror('bad argument: "' <> s <> '"')
		endunless
	enddefine;
	adjust(lines, ls) -> lines;
	adjust(columns, cs) -> columns;
enddefine;

;;; when all else fails, work out the size of the current font, by asking
;;; the tty emulator for the size in characters, and the size in pixels
;;;
define lconstant resize_get_font_size() -> tsv;
	lvars px py cx cy tsv;
	(vedwin_tty_size() ->> tsv) -> vedwin_tty_size();
	vedwin_window_size().explode -> py -> px;
	tsv(1) -> cx; tsv(2) + 1 -> cy;     ;;; 1 is for tool header
	intof((px - 10) / cx) -> vedwin_text_width;
	intof((py - 7) / cy) -> vedwin_text_height;
	intof((1152 - 10) / vedwin_text_width) - 1 -> vedwin_max_columns;
	intof((900 - 10) / vedwin_text_height) - 1 -> vedwin_max_lines;
enddefine;

define vars vedresizequery();
	lvars lines columns t;
	if      systranslate('DEFAULT_FONT')
	or      vedargument = '??'
	then    resize_get_font_size() -> t;
			vedputmessage('window is ' sys_>< (t(2) - EXTRA_LINES) sys_>< ' x '
								sys_>< (t(1) - EXTRA_COLS) sys_>< ': max is '
								sys_>< (vedwin_max_lines - EXTRA_LINES) sys_>< ' x '
								sys_>< (vedwin_max_columns - EXTRA_COLS))
	else    vedwin_call5(vedwin_tty_size).explode -> lines -> columns;
			vedputmessage('window is '
								sys_>< (lines - EXTRA_LINES) sys_>< ' lines, '
								sys_>< (columns - EXTRA_COLS) sys_>< ' columns.')
	endif;
enddefine;

define vars ved_resize();
	lvars lines columns x y ph pw top left;
	if      vedargument = '?' or vedargument = '??'
	then    vedresizequery()
	else    if      vedargument = ''
			then    resize_default_size().explode
			else    resize_argument_size()
			endif   -> columns -> lines;

		;;; allow for command line, status column, dropoff columns at right
			lines + EXTRA_LINES -> lines;
			columns + EXTRA_COLS -> columns;

		;;; clip size to maximum screen permits, minimum sensible
			max(min(lines, vedwin_max_lines), 4) -> lines;
			max(min(columns, vedwin_max_columns), 10) -> columns;
			vedputmessage('setting to '
							sys_>< (lines - EXTRA_LINES) sys_>< ' lines, '
							sys_>< (columns - EXTRA_COLS) sys_>< ' columns.');
		;;; check that window position will allow all of new size to be shown
			10 + (lines + 1) * vedwin_text_height -> ph;
			10 + columns * vedwin_text_width -> pw;
			vedwin_call5(vedwin_position).explode -> top -> left;
			if      ((top + ph > 899) ->> x)
			then    899 - ph -> top
			endif;
			if      ((left + pw > 1151) ->> y)
			then    1151 - pw -> left
			endif;
			if   x or y then {% left, top %} -> vedwin_position() endif;
		;;; set the window size, adjust ved
			{% columns, lines %} -> vedwin_tty_size();
			vedwin_adjust(lines, columns);
			vedrefresh();
	endif
enddefine;


/* ::::::::::::::::::: Index :::::::::::::::::::::::
::
::    32:  V: vedwin_default_size
::    33:  V: vedwin_file_sizes
::    35:  V: vedwin_max_lines = 54
::    36:  V: vedwin_max_columns = 142
::    38:  V: vedwin_text_height = 16
::    39:  V: vedwin_text_width = 8
::    44:  wmember(i, l);
::    58:  resize_default_size();
::    76:  resize_argument_size() -> columns -> lines
::   112:  resize_get_font_size() -> tsv
::   123:  vedresizequery()
::   139:  ved_resize()
::
::::::::::::::::::::::::::::::::::::::::::::::::::::: */


/* --- Revision History ---------------------------------------------------
--- Adrian Howard, Sep  8 1992
		Now uses sys_><
--- John Williams, Aug  5 1992
		Made -ved_resize- global
 */
