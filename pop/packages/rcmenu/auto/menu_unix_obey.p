/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_unix_obey.p
 > Purpose:			Run Unix command invoked from a menu
 > Author:          Aaron Sloman, Sat Dec  4  1993
 > Documentation:	HELP * VED_MENU
 > Related Files:   LIB * ved_menu  See also unix menu
 */

section;

uses	vedgenshell;
uses menu_vedinput;

define global vars procedure menu_unix_obey(list);
	;;; list is either of the form [<commandstring>] or
	;;; [<commandstring> <shell pathname>]
	;;; See REF SYSOBEY for explanation of the two cases below
	;;; Also REF VEDGENSHELL, HELP PIPEUTILS

	lvars list;

	define lconstant menu_unix_obey_do(list);
		;;; run in suitable environment
		lvars list, vedarg, shell;

		dest(list) -> (vedarg, list);

		dlocal vedargument = vedarg, show_output_on_status = false;

		if list = [] then
			vedgenshell(systranslate('SHELL'), false);
		else
			 vedgenshell(hd(list), false);
		endif
	enddefine;				

	;;; menu_vedinput will do things now or later, as needed.
	menu_vedinput(menu_unix_obey_do(%list%))
enddefine;
	

endsection;
