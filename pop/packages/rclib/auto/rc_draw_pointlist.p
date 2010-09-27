/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_pointlist.p
 > Purpose:         Draw pointlist as open or closed polyline
 > Author:          Aaron Sloman, Jan 12 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;; TESTS

rc_start();

;;; open polyline
rc_draw_pointlist([{0 0} {0 100} {100 100} {100 0}], false);
;;; closed
rc_draw_pointlist([{0 0} {0 100} {100 100} {100 0}], true);

*/

compile_mode :pop11 +strict;

section;

define rc_draw_pointlist(pointlist, closed);
	;;; Drawing a polyline, open or closed.
	lvars point, lastx, lasty, nextx, nexty, firstx, firsty;

	if closed then
		explode(destpair(pointlist) -> pointlist) ->( firstx, firsty);
		(firstx, firsty) -> (lastx,lasty);
	else
		explode(destpair(pointlist) -> pointlist) -> (lastx, lasty)
	endif;

	;;; Draw connected lines to the rest
	fast_for point in pointlist do
		explode(point) -> (nextx,nexty);
		rc_drawline(lastx, lasty, nextx ->> lastx, nexty ->> lasty);
	endfor;
	if closed then
		;;; close up the polyline
		rc_drawline(lastx, lasty, firstx, firsty)
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 25 1997
	Renamed as rc_draw_pointlist (was rc_draw_*polyline)
 */
