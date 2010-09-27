/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_veddo.p
 > Purpose:
 > Author:          Aaron Sloman, Feb  5 1995
 > Documentation:
 > Related Files:
 */



compile_mode :pop11 +varsch +defpdr -lprops +constr +global
            :vm +prmfix :popc -wrdflt -wrclos;

;;; Define a version of veddo that doesn't warp, but raises the
;;; current window
;;; arguments are as for veddo. See REF * veddo

define menu_veddo(string, put_on_status);
	;;; Obey the string as an ENTER command.
	;;; Second argument ture gets string put on status line
	lvars string, put_on_status;
	dlocal vedwarpcontext = false;
	veddo(string, put_on_status);
	if vedusewindows = "x" then
		true -> xved_value("currentWindow", "raised");
		false -> wvedwindowchanged;
	endif;
enddefine;


section;

endsection;
