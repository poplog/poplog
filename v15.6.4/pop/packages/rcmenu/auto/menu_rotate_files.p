/* --- The University of Birmingham 1995. ------
 > File:            $poplocal/local/auto/menu_rotate_files.p
 > Purpose:			Rotate buffers. Invoked from menu
 > Author:          Aaron Sloman, Sun Dec  5  1993
 > Documentation:	HELP * VED_MENU REF * ved_rb
 > Related Files:   LIB * VED_MENU
 */

section;

uses ved_menu;	;;; defines menu_apply

;;; Like ved_rb, but does not warp pointer

define global vars procedure menu_rotate_files();
	dlocal vedwarpcontext = false;
	menu_apply('rb', true, veddo);
enddefine;

endsection;
