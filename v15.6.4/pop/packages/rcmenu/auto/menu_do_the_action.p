/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_do_the_action.p
 > Purpose:			Performing actions, once selected
 > Author:          Aaron Sloman, Feb  5 1995
 > Documentation:
 > Related Files:
 */



compile_mode :pop11 +varsch +defpdr -lprops +constr +global
            :vm +prmfix :popc -wrdflt -wrclos;

section;

uses menulib;
uses menu_vedinput;
uses menu_interpret_action;

define menu_do_the_action(P);
	lvars P;
	if isprocedure(P) then
		menu_vedinput(menu_apply(%P%))
	elseif islist(P) then
		menu_interpret_action(P)
	elseif isvector(P) and isstring(P(1)) then
		menu_vedinput(compile(%stringin(P(1))%))
	elseif isstring(P) then
		menu_vedinput(menu_veddo(%P,true%))
	else
		;;; delay compilation of menu_name_of_box
		mishap('UKNOWN ACTION TYPE IN'
					<>
				valof("menu_name_of_box")(menu_current_box),
				[^P])
	endif;
	menu_vedinput(vedcheck<>vedsetcursor);
enddefine;


endsection;
