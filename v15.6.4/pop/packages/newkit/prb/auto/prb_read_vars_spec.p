/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_read_vars_spec.p
 > Purpose:			Read in a [VARS ...] spec
 > Author:          Aaron Sloman, Apr 20 1996
 > Documentation:
 > Related Files:	prb_read_VARS in LIB * POPRULEBASE
 */

uses poprulebase
section;

define prb_read_vars_spec(name, allow_VARS) -> vars_spec;
	;;; formats [VARS v1 v2 [v3 = <exp>] v4 [[v5 v6] = <exp>] v7]
	;;; formats [LVARS v1 v2 [v3 = <exp>] v4 [[v5 v6] = <exp>] v7]
	;;; Used for define_ruleset, define_rulefamily define_rulesystem
	;;; return false if [VARS ...] or [LVARS ...] is not at beginning
	;;; of proglist
	;;; Error if [VARS ...] and not allow_VARS

	if not(allow_VARS) and hd(proglist) == "[" and hd(tl(proglist)) == "LVARS" then
		prb_read_VARS(true, name, true);
		;;; get rid of optional semi colon? Or demand one?
		pop11_need_nextreaditem(";") ->
	elseif allow_VARS and hd(proglist) == "[" and hd(tl(proglist)) == "VARS" then
		prb_read_VARS(true, name, false);
		;;; get rid of optional semi colon? Or demand one?
		pop11_need_nextreaditem(";") ->
	else
		false
	endif -> vars_spec;

enddefine;

endsection;
