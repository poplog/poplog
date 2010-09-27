/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_transfer_window_contents.p
 > Purpose:         Transfer contents of one win_obj to another
 > Author:          Aaron Sloman, Jun 10 1997
 > Documentation:
 > Related Files:
 */

/*

uses rclib;
uses rc_window_object;
uses rc_mousepic;
uses rc_point;
;;; start a new window
vars win1 = rc_new_window_object( 600, 20, 400, 350, true, 'win1');

;;; Make it mouse sensitive
rc_mousepic(win1);

;;; make three mouse sensitive points
vars
    p1 = rc_new_live_point(20, 0, 6, 'a'),
    p2 = rc_new_live_point(0, 20, 7, 'b'),
    p3 = rc_new_live_point(0, -25, 15, 'c'),
;

vars win2 =
	rc_new_window_object(false, false, 400, 350, {200 175 3 3}, 'win2');

;;; transfer a copy of the points
rc_transfer_window_contents(win1, win2, true);

rc_kill_window_object( win2);

;;; Make another window
vars win2 =
	rc_new_window_object(false, false, 400, 350, {200 175 3 3}, 'win2');

;;; transfer the original points
rc_transfer_window_contents(win1, win2);

rc_kill_window_object( win1);
rc_kill_window_object( win2);

*/

section;
uses rclib;
uses rc_window_object;
uses rc_mousepic;


define rc_transfer_window_contents(win_obj1, win_obj2, /*do_copy*/);

	lvars do_copy;

	if isboolean(win_obj2) then
		win_obj1, win_obj2 -> (win_obj1, win_obj2, do_copy)
	else
		false -> do_copy
	endif;

	;;; first make sure win_obj2 is sensitive to the same things
	;;; as win_obj1
	rc_mousepic(win_obj2, rc_event_types(win_obj1));

	if do_copy then
		;;; make copies of the linepic instances in win_obj1
		maplist(rc_window_contents(win_obj1), copy)
			nc_<> rc_window_contents(win_obj2)
	else
		;;; transfer the originals
		rc_window_contents(win_obj1) <> rc_window_contents(win_obj2)
	endif
			-> rc_window_contents(win_obj2);

	;;; get ready to draw in in win_obj2
    dlocal rc_current_window_object = win_obj2;

	lvars pic;
	for pic in rc_window_contents(win_obj2) do
		rc_undrawn(pic);
		rc_draw_linepic(pic)
	endfor;

enddefine;


endsection;
