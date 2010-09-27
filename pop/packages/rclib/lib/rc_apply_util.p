/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_apply_util.p
 > Purpose:			Extend rc_window procedures to rc_window_objects
 > Author:          Aaron Sloman, Jun 14 1997
 > Documentation:
 > Related Files:	LIB * RC_EXTEND_UTILS
 */

/*

uses rclib;
uses rc_window_object;

;;; Create two windows so that we can draw different pictures on them.
applist([^win1 ^win2], rc_kill_window_object);

vars
    win1 = rc_new_window_object(20, 20, 300, 250, true, 'win1'),

    win2 = rc_new_window_object(450, 20, 300, 250, true, 'win2');


win1 -> rc_current_window_object;

;;; Draw on it:
'red' -> rc_apply_util(win1, rc_foreground);

rc_drawline(0, 0, 150, 150);

'10x20' -> rc_apply_util(win1, rc_font);
rc_print_at(-80, 95, 'Hello there')

;;; Draw an oblong and a blob on it
rc_draw_ob(0, 0, 100, 100, 15, 15);
rc_draw_blob(-50, 0, 30, 'blue');


'blue' -> rc_apply_util(win2, rc_foreground);

'8x13bold' -> rc_apply_util(win2, rc_font);

win2 -> rc_current_window_object;

rc_drawline(0, 100, 100, 100);

rc_print_at(-80, 95, 'Hello there')

rc_apply_util(win1, rc_font) =>
rc_apply_util(win2, rc_font) =>

vars oldfont = rc_font, oldstyle = rc_line_style, oldwidth = rc_line_width,
	oldforeground = rc_foreground;

uses rc_extend_utils;
rc_extend_utils rc_font, rc_line_style, rc_line_width, rc_foreground;
rc_extend_utils rc_title;

rc_title(win1) =>
'WIN1' -> rc_title(win1);

3 -> rc_line_width(win1);
'blue' -> rc_foreground(win1);
win1-> rc_current_window_object;

rc_drawline(0, -100, 100, 100);
5 -> rc_line_width(win2);
'6x13bold' -> rc_font(win2);
LineOnOffDash -> rc_line_style(win2);
'green' -> rc_foreground(win2);
win2-> rc_current_window_object;

rc_drawline(0, 100, 100, -100);
rc_print_at(-100, 20, 'Greetings to all');
*/

section;
compile_mode :pop11 +strict;

uses rclib
uses rc_window_object

define rc_apply_util(item, procedure util);
	;;; apply util to rc_widget(item) if item is a win_obj, otherwise
	;;; to item.
	;;; util is a utility procedure, e.g. rc_font, rc_foreground, rc_background, etc.

	util(
		if isrc_window_object(item) then
			lvars win = rc_widget(item);
			if xt_islivewindow(win) then
				win
			else
				mishap('Window object without live widget', [^item ^util])
			endif
		elseif xt_islivewindow(item) then
			item
		else
			mishap('Window or window object needed for ' sys_>< util, [^item])
		endif)
enddefine;
			
define updaterof rc_apply_util(item, procedure util);
	;;; apply updater of util to rc_widget(item) if item is a win_obj,
	;;; otherwise to item.
	;;; util is a utility procedure, e.g. rc_font, rc_foreground, rc_background, etc.

	-> util(
		if isrc_window_object(item) then
			lvars win = rc_widget(item);
			if xt_islivewindow(win) then
				win
			else
				mishap('Window object without live widget', [^item ^util])
			endif
		elseif xt_islivewindow(item) then
			item
		else
			mishap('Window or window object needed for ' sys_>< util, [^item])
		endif)
enddefine;

lvars rc_extended = [];

define syntax rc_extend_utils;
	lvars item;
	repeat
		readitem() -> item;
		quitif( item == ";" );
		;;; ignore this word if it has already been extended
		nextif(lmember(item, rc_extended) or item == ",");
		;;; first unprotect the word
		sysPUSHQ(item);
		sysCALLQ(sysunprotect);
		;;; partially apply rc_apply_util
		sysPUSHQ(rc_apply_util);
		sysPUSH(item);
		sysPUSHQ(1);
		sysCALLQ(consclosure);
		;;; now assign to the identifier
		sysPOP(item);
		;;; and protect it
		sysPUSHQ(item);
		sysCALLQ(sysprotect);
		;;; give it an appropriate pdprops
		sysPUSHQ(item);
		sysPUSH(item);
		sysUCALLQ(pdprops);
		conspair(item, rc_extended) -> rc_extended;
	endrepeat;
	conspair(";", proglist) -> proglist;
enddefine;


endsection;
