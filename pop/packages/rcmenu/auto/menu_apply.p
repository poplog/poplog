/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_apply.p
 > Purpose:			See below
 > Author:          Aaron Sloman, Feb  5 1995
 > Documentation:
 > Related Files:
 */


compile_mode :pop11 +varsch +defpdr -lprops +constr +global
            :vm +prmfix :popc -wrdflt -wrclos;

section;


define menu_apply(proc);
	;;; apply the procedure, raise any new file, but don't
	;;; warp context. Suitable for buttons rotating or swapping
	;;; files, etc.
	lvars procedure proc, oldfile = vedcurrentfile;
	dlocal vedwarpcontext = false;
	proc();
	if vedusewindows = "x" then
		if vedcurrentfile /== oldfile then
			true -> xved_value("currentWindow", "raised");
		endif;
		false -> wvedwindowchanged;
	endif;
enddefine;

endsection;
