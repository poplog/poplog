/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_name_of_box.p
 > Purpose:
 > Author:          Aaron Sloman, Feb  5 1995
 > Documentation:
 > Related Files:
 */



compile_mode :pop11 +varsch +defpdr -lprops +constr +global
            :vm +prmfix :popc -wrdflt -wrclos;

section;
uses menulib;

uses menu_new_menu

define menu_name_of_box(propbox) -> name;
	lvars propbox, name = menu_lists(propbox);
	if name then name(1) -> name endif;
enddefine;


endsection;
