/* --- Copyright University of Birmingham 1992. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_tli.p
 > Purpose:         transcribe line in (tlo out)
 > Author:          Aaron Sloman, Oct  1 1992
 > Documentation: 	HELP INOROUT
 > Related Files:	LIB * VED_TLO, * VED_MLI, * VED_MLO, * VED_TLLI
 */

section;

define lconstant test_arg(arg) -> num;
	lvars arg, num = strnumber(arg);
	if num then ;;; OK, it's a number
	elseif arg = nullstring then 1 -> num
	else
		vederror('NON-NUMBER ARGUMENT: ', <> vedargument)
	endif
enddefine;

define lconstant copy_or_delete_line(do_copy, num);
	;;; "copy" num lines if do_copy is true, otherwise delete them
	;;; If num is negative, get lines before this one
	lvars do_copy, num, midfile;
	dlocal vvedmarkhi, vvedmarklo;
	if num > 0 then
		vedline,
		num - 1 + vedline
	elseif num < 0 then
	;;; if num is negative prepare to go back some lines,
	;;; but check that there are enough lines
		if vedline + num < 1 then
			vederror('NOT ENOUGH PRECEDING LINES: ' sys_>< num)
		endif;
		vedline + num,
		vedline - 1
	else
		vedline.dup
	endif -> (vvedmarklo, vvedmarkhi);

	vedline /== 1 -> midfile;	;;; not on first line
	if do_copy then ved_copy() else ved_d() endif;
	;;; adjust cursor location
	repeat
		if num < 0 then 0
		elseif do_copy then num
		elseif midfile then 1
		else 0
		endif
	times
		vedchardown()
	endrepeat
enddefine;


define lconstant procedure ved_t_or_m_lo(do_copy);
	;;; Transcribe, if do_copy is true, or move line out to other file
	lvars do_copy, num = test_arg(vedargument);

	dlocal vveddump, vedargument = nullstring;

	copy_or_delete_line(do_copy, num);
	vedswapfiles();
	ved_y();
	repeat abs(num) times vedchardown(); endrepeat;
	vedswapfiles();
enddefine;

define lconstant procedure ved_t_or_m_li(do_copy);
	;;; Transcribe, if do_copy is true, or move line in from other file
	lvars do_copy, num = test_arg(vedargument);

	dlocal vveddump, vedargument = nullstring;

	vedswapfiles();
	copy_or_delete_line(do_copy, num);
	vedswapfiles();
	;;; suppress ved_y changing files
	dlocal vedargument = nullstring;
	ved_y();
	repeat abs(num) times vedchardown(); endrepeat;
enddefine;


;;; Now define the user procedures

;;; transcribe line in
define ved_tli =
	ved_t_or_m_li(%true%)
enddefine;

;;; move line in
define ved_mli =
	ved_t_or_m_li(%false%)
enddefine;

;;; transcribe line out
define ved_tlo =
	ved_t_or_m_lo(%true%);
enddefine;

;;; move line out
define ved_mlo =
	ved_t_or_m_lo(%false%);
enddefine;

endsection;
