/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_control.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 */

/*
-- -- "Control" menu
*/
section;

define :menu control;
	'Ved Control'
	'Menu control'
	'(Ved commands)'
	[Refresh menu_refresh]
	['EditFile*' [ENTER 'ved *' 'Editing a new file. Insert the name.']]
	[Enter vedenter]
	[Redo vedredocommand]
	[SwitchStatus vedstatusswitch]
	[Quit1 ved_q]
	[ExitAll ved_xx]
	['WindowSize' ved_setwindow]
	['MarkStart' vedmarklo]
	['MarkEnd' vedmarkhi]
	['DelRange' ved_d]
	['CopyRange' ved_t]
	['Interrupt' {'interrupt()'}]
	['PushLoc' vedpushkey]	;;; save current location
	['SwapLoc' vedexchangeposition]	;;; swap with last saved location
	['HELP Keys' 'help vedkeys']
	['HELP NcdKeys' 'help ncdxtermkeys']
	['HELP Commands' 'ref vedcomms']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
