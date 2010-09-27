/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/async_do_action.p
 > Purpose:         Perform selected button action associated with object
 > Author:          Aaron Sloman, Jan  4 1997
 > Documentation:
 > Related Files:	Based LIB * MENU_DO_THE_ACTION
 */


compile_mode :pop11 +strict;

section;

uses async_vedinput;
uses menulib;
;;; uses menu_interpret_action;


define async_do_action(Object, Action);
	;;; Object may be a button, etc.
	;;; Action of types allowed in button, i.e. string (ved command)
	;;; word (procedure name), procedure, vector containing string
	;;; with Pop11 instructions, or list of type handled in LIB VED_MENU
	recursive_valof(Action) -> Action;
	if isprocedure(Action) then
		async_vedinput(async_apply(%Action%))
	elseif islist(Action) then
		;;; use word to postpone autoloading till necessary
		valof("menu_interpret_action")(Action)
	elseif isvector(Action) and isstring(Action(1)) then
		async_vedinput(compile(%stringin(Action(1))%))
	elseif isstring(Action) then
		async_vedinput(async_veddo(%Action,true%))
	else
		mishap('UKNOWN ACTION TYPE ' [^Object ^Action])
	endif;
	async_vedinput(vedcheck<>vedsetcursor);
enddefine;



endsection;
