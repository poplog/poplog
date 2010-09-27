/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_popup_strings.p
 > Purpose:			display a list or vector of strings in a scrolling text widget
 > Author:          Aaron Sloman, May  6 1999 (see revisions)
 > Documentation:	
 > Related Files:	LIB * PUI_POPUPTOOL
 */

/*

vars
	strings =
	['Select your string' 'after scrolling if necessary'],
	vec =
	{%
		lvars x;
	for x to 40 do
		x ><
		'. a very useful number to display today is the number '
		>< x
	endfor;
	%};

rc_popup_strings(500, 20, vec, strings, 2, 50, '9x15') =>
rc_popup_strings(500, 20, vec, [], 2, 50, '9x15') =>
rc_popup_strings(500, 20, datalist(vec), strings, 30, 0, '9x15') =>
rc_popup_strings(500, 20, vec, strings, 20, 50, '10x20') =>

*/


compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;


section;
uses rclib
uses rc_scrolltext
uses rc_control_panel
uses rc_popup_panel

global vars rc_current_query;

define rc_popup_strings(x, y, list, strings, rows, cols, font) -> selection;
	lvars container = false;

	ARGS x, y, list, strings, rows, cols, font, &OPTIONAL container:isrc_window_object;

	lvars len, file, count, string, vec;

	dlocal rc_slider_field_radius_def = 8;

	;;; Control variable. Exit when it is made non-false.
	lvars done = false;

	;;; prepare a vector if necessary
	if list == [] or list = #_< {} >_# then
		false -> selection;
		return
	else
		if isvector(list) then list
		else
			{%	
				for file in list do
					if sysisdirectory(file) then file dir_>< '/' else file endif
				endfor %}
		endif -> vec;

		datalength(vec) -> len;

		define lconstant selection_done;
			true -> done;
		enddefine;

		define lconstant selection_accept(obj, val, button);
			true -> done;
		enddefine;
	

		lvars fields =
		  	[
			% if strings /== [] then [TEXT : ^^strings ] endif %
			[SCROLLTEXT {ident ^(ident selection)}
				{acceptor ^selection_accept}
				{font ^font}{fieldbg 'white'}
				{rows ^(min(len, rows))} {cols ^cols} : ^vec
			]
			[ACTIONS {width 80}:
				['OK' ^selection_done]
				['Cancel' [DEFER POP11 interrupt()]]]
		];
		rc_popup_panel(
			x, y, fields, 'RC_GETFILE', ident done, if container then container endif);
		unless done then false -> selection endunless;
	endif;
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug  4 2002
		changed to cope better with an empty list of strings.
--- Aaron Sloman, May 19 1999
	 Allowed optional container argument for parent rc_window_object
--- Aaron Sloman, May 13 1999
	Fixed bug if "Cancel" selected.
--- Aaron Sloman, May 11 1999
	Allowed double click instead of Ok button
--- Aaron Sloman, May  8 1999
	Added Cancel button
	Changed to use rc_popup_panel

 */
