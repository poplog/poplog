/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_interpret_action.p
 > Purpose:			Interpreting menu panel actions
 > Author:          Aaron Sloman, Feb  5 1995
 > Documentation:
 > Related Files:
 */


compile_mode :pop11 +varsch +defpdr -lprops +constr +global
            :vm +prmfix :popc -wrdflt -wrclos;

section;

uses menulib;
uses menu_new_menu;
uses menu_vedinput;
/*
-- Interpreting menu actions
*/
;;; menu_unix_obey defined separately

define menu_interpret_action(action);
	;;; This procedure is run when the action is a list.
	;;; Only certain keywords are currently recognized.
	;;; More may be later.
	lvars action, key = hd(action);
	if key == "ENTER" then
		valof("menu_set_command")(tl(action));
	elseif key == "MENU" then
		menu_new_menu(action(2), false);
	elseif key == "POP11" then
		menu_vedinput(compile(%tl(action)%));
	elseif key == "POPNOW" then
		compile(tl(action));
	elseif key == "VEDDO" then
		;;; should be followed by a string
		menu_vedinput(veddo(%tl(action)(1), true%));
	elseif key == "UNIX" then
		;;; postpone autoloading, via valof
		valof("menu_unix_obey")(tl(action))
	else
		mishap('UNRECOGNIZED TYPE OF MENU ACTION', [^action])
	endif;
enddefine;


endsection;
