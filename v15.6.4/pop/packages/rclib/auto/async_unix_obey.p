/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/async_unix_obey.p
 > Purpose:			Run Unix command invoked from a button, etc.
 > Author:          Aaron Sloman, Apr 21 1997
 > Documentation:
 > Related Files:
 */


section;

uses	vedgenshell;
uses async_vedinput;

define global vars procedure async_unix_obey(list);
	;;; list is either of the form [<commandstring>] or
	;;; [<commandstring> <shell pathname>]
	;;; See REF SYSOBEY for explanation of the two cases below
	;;; Also REF VEDGENSHELL, HELP PIPEUTILS

	lvars list;

	define lconstant async_unix_obey_do(list);
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

	;;; async_vedinput will do things now or later, as needed.
	async_vedinput(async_unix_obey_do(%list%))
enddefine;
	

endsection;
