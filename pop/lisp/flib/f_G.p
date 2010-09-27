/* --- Copyright University of Sussex 1995. All rights reserved. ----------
 > File:            C.all/lisp/flib/f_G.p
 > Purpose:         LIB * FORMAT_PRINT ~G directive
 > Author:          John Williams, Jun 30 1992 (see revisions)
 > Documentation:   HELP * FORMAT_PRINT
 > Related Files:   LIB * FORMAT_PRINT
 */

uses format_print;

section $-lisp$-fpr;

unless isdefined("float_utils") do
	syslibcompile("float_utils", f_liblist) ->
endunless;


/* Code for the ~G directive */

procedure(w, d, e, k, overflowchar, padchar, expchar);
	dlocal popdprecision = "ddecimal";

	lvars arg;
	next_f_arg() -> arg;
	f_arg_index - 1 -> f_arg_index;

	if isreal(arg) then

		/* Let _n be an integer such that (10 ** (n - 1)) <= ___arg < (10 ** n).
			(If ___arg is 0, let _n be 0).
		*/

		lvars f n;
		abs(arg) -> f;
		Upper_expt(f) -> n;

		/* If _d is omitted, first let _q be the number of digits
			needed to print ___arg with no loss of information and
			with no leading or trailing 0's; then let _d equal
			max(_q, min(_n, 7))
		*/

		if d then
			check_integer(d)
		else
			lvars q;

			procedure(f);
				lvars f;
				dlocal pop_pr_places = Max_pr_places(f);
				printlength(f) - point_size
			endprocedure(f) -> q;

			if f < 1 then
				q - 1 -> q      ;;; Skip leading 0
			endif;
			max(q, min(n, 7)) -> d
		endif;

		/* Let __dd equal _d - _n */

		lvars dd = (d - n);

		if (0 <= dd) and (dd <= d) then

			/* If 0 <= dd <= d, then ___arg is printed by the format
				directive ~__ww, __dd, false, ____________overflowchar, _______padcharF~__eeT
			*/

			/* Let __ee equal _e + 2, or 4 if _e is omitted */

			lvars ee;
			if e then
				e + 2
			else
				4
			endif -> ee;

			/* Let __ww equal _w - __ee, or false if _w is omitted */

			lvars ww;
			if w then
				check_positive(w);
				w - ee
			else
				false
			endif -> ww;

			f_proc(`F`)(ww, dd, false, overflowchar, padchar);
			true -> f_at;
			f_proc(`T`)(ee, false)

		else

			/* For all other values of __dd, ___arg is printed by the
				format directive
					~_w,_d,_e,_k,____________overflowchar,_______padchar,_______expcharE
			*/

			f_proc(`E`)(w, d, e, k, overflowchar, padchar, expchar)

		endif

	else

		false ->> f_colon -> f_at;
		f_proc(`D`)(w, false, false)

	endif
endprocedure -> f_proc(`G`);


endsection;


/* --- Revision History ---------------------------------------------------
--- John Williams, Aug 23 1995
		Removed redundant lvar declarations.
--- John Williams, Jun 30 1992
		Completely re-written, fixing BR isl-fr.4310
 */
