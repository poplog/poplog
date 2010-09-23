/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_handle_vedwarpcontext.p
 > Purpose:			Alter value of vedwarpcontext in Ved
 > Author:			Aaron Sloman, Aug  4 2002
 > Documentation:	HELP rclib, rc_events
 > Related Files:
 */


/*

Need to look at event contexts

*/



section;

/*

;;; should be changed to make use of some version of this list?
global vars rc_no_vedwarp =
	[
          	ved_q
          	vedfileselect
    		vedsetonscreen
			vedswapfiles
			vedfileselect
			vedquitfile
			ved_rb
			ved_pop
			ved_ved
			ved
		];

*/

define vars rc_handle_vedwarpcontext(win_obj, proc);
	;;; run the process using the policy determined by win_obj,
	dlocal vedwarpcontext = false;


	if win_obj then win_obj -> rc_current_window_object; endif;

	if isprocedure(proc) then proc()
	elseif islist(proc) then
		rc_process_event(proc);	
	else
		clearstack();
		mishap('Procedure or event needed', [^proc])
	endif;

enddefine;


endsection;
