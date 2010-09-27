/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_defaults.p
 > Purpose:			Used for default global variable settings
 > Author:          Aaron Sloman, Sep 13 1999
 > Documentation:	HELP RCLIB
 > Related Files:	(Similar to poprulebase)
 */


section;

compile_mode :pop11 +strict;

;;; First some procedures used to define the "define :defaults" syntax

define lconstant try_set_default(varval, newval, word);
	;;; try_set_default takes current and new values for word
	lvars varval, newval, word;

	if isundef(varval) then newval -> valof(word) endif;
enddefine;

define :define_form  rc_defaults;
	;;; A syntax word for declaring global variables and specifying their
	;;; default values.
	;;; as "define :rc_defaults ..." as in LIB RC_PROCBROWSER

	lvars identifier, value;

	dlocal prwarning = erase;

	pop11_need_nextreaditem(";") ->;

	;;; repeatedly read <identifier> = <expression> ;
	;;; Use the expression to set up the default for the identifier
	repeat
		;;; read the identifier
		itemread() -> identifier;
	quitif(identifier = "enddefine");
		pop11_need_nextreaditem("=") ->;
		;;; plant code to declare the identifier, and push its current value
		sysVARS(identifier, 0);
		sysGLOBAL(identifier);
		sysPUSH(identifier);
		;;; Plant code to compute the default value
		pop11_comp_expr();
		pop11_need_nextreaditem(";") ->;
		;;; Push the identifier itself, then call the setting procedure
		sysPUSHQ(identifier);
		sysCALLQ(try_set_default);
	endrepeat
enddefine;


global vars rc_defaults = true;

endsection;
