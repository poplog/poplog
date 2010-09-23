/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/define_menu.p
 > Purpose:			Introduce define :menu syntax for rc_control_panel
 > Author:          Aaron Sloman, Aug  3 1999 (see revisions)
 > Documentation:	
 > Related Files:   Old version was $local/menu/auto/define_menu.p
 */

/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/define_menu.p
 > Author:          Aaron Sloman, Jan 21 1995
 */

/*


	define :menu <name>
		<title>
		<optional formatting vectors>
		<description string>
		[<buttonlabel> <action>]
		[<buttonlabel> <action>]
			etc
		[TEXT .... ]
        [SCROLLTEXT] scrolling text panel with sliders for scrolling
        [GRAPHIC]    graphical fields
        [ACTIONS]    action buttons (various kinds: see HELP * RC_BUTTONS)
        [RADIO]      radio buttons (only one can be selected at a time)
        [SOMEOF]     someof buttons (sometimes referred to as toggle
                   	 buttons: any number can be turned "on" at a time)
        [SLIDERS]    for changing the value of a numerical variable
        [TEXTIN]     for text input
        [NUMBERIN]   for numeric input
		
	enddefine;

If (re)compiled it immediately (re)builds the panel unless menu_popexecute
is false, or it is inside a procedure definition.
*/


section;
uses rclib;
uses rc_control_panel

uses rcmenulib

uses menu_new_menu;

global vars menu_popexecute = true;

define lconstant try_hide(menu);
	if isrc_window_object(menu) and xt_islivewindow(rc_widget(menu)) then
		rc_hide_window(menu)
		;;; rc_kill_window_object(menu)
	endif;
enddefine;


define :define_form global menu();
	;;; get the panel's name
	lvars name = readitem();
	pop11_need_nextreaditem(";") ->;

	;;; create a global variable to refer to it
	consword(menu_startstring sys_>< name) -> name;
	sysSYNTAX(name, 0, false);

	;;;;;if menu_popexecute or not(popexecute) then
		;;; plant code to remove and re-build the menu
		sysPUSH(name);
		sysCALLQ(try_hide);
	;;;; endif;

	;;; Now build a list to give to rc_control_panel. Accept old
	;;; menu formats for now
	sysPUSHQ(popstackmark);
	repeat
		pop11_comp_expr();
	quitif(pop11_try_nextreaditem("enddefine"));
	endrepeat;
	sysCALLQ(sysconslist);
	sysPOP(name);
	;;;; if menu_popexecute or not(popexecute) then
		;;; plant code to create new menu
		sysPUSHQ(name);
		sysPUSHQ(true);
		sysCALL("menu_new_menu");
	;;;; else
		;;; the list will be in the menu's name, for construction later
	;;;; endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug  3 1999
	Converted to use rc_control_panel
 */
