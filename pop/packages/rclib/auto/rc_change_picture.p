/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_change_picture.p
 > Purpose:			Allow a (movable) object to change its appearance
 > Author:          Aaron Sloman, Jul  8 2000
 > Documentation:	HELP RCLIB and below
 > Related Files:
 */

/*
;;; TESTS for method defined below

rc_change_picture(pic, newx, newy, newlines, newstrings);
	if either of newlines or newstrings is false, the corresponding
	old slot value is retained

;;; required for tests
uses rclib
uses rc_linepic
uses rc_window_object
uses rc_opaque_mover

vars
    win1 = rc_new_window_object(
              "right", "top", 400, 400, true, 'win1');

define :class dragpic;
    is rc_keysensitive rc_selectable rc_opaque_movable;
	;;; Use rc_opaque_movable because the background is uniform.
	;;; Could also use rc_linepic_movable instead, but thick lines
	;;; then produce odd effects, though they work on arbitary
	;;; backgrounds. See HELP rclib_problems
enddefine;

define :instance drag1:dragpic;
    rc_picx = 100;
    rc_picy = 50;

    ;;; define the object's graphical appearance: a square and a
    ;;; rectangle, overlapping
    rc_pic_lines =
        [WIDTH 2 COLOUR 'blue'
            [SQUARE {-40 40 80}]
            [CLOSED {-45 20} {45 20} {45 -20} {-45 -20}]
        ];

    ;;; and two strings
    rc_pic_strings =
        [FONT '9x15bold'
            [COLOUR 'red' {-22 -5 'drag1'}]
            [COLOUR 'green' {-22 -35 'hello'}]];
enddefine;

rc_draw_linepic(drag1);
rc_add_pic_to_window(drag1, win1, true);
rc_move_by(drag1, -5, -5, true);


;;; test the new method below. Try some new pictures and strings

vars
	pics1 = rc_pic_lines(drag1),
	pics2 = copydata(pics1);

	6 -> pics2(2); 'brown' -> pics2(4);

vars
	strings1 = rc_pic_strings(drag1),
	strings2 = copydata(strings1);
	'10x20' -> strings2(2);

pics1==>
pics2==>
strings1==>
strings2==>

rc_change_picture(drag1, 0, 0, pics2, false);
rc_change_picture(drag1, 0, 20, pics1, false);
rc_change_picture(drag1, 20, 20, pics2, strings1);
rc_change_picture(drag1, 0, 20, pics1, strings2);

repeat 4 times
	rc_change_picture(drag1, 0, 0, pics1, strings1);
	syssleep(50);
	rc_change_picture(drag1, 20, 20, pics2, false);
	syssleep(50);
	rc_change_picture(drag1, 0, 20, false, strings2);
	syssleep(50);
	rc_change_picture(drag1, -20, 20, pics1, false);
	syssleep(50);
endrepeat;

rc_start();
drag1.rc_pic_lines ==>
drag1.rc_pic_strings ==>
*/



section;

uses rclib
uses rc_linepic

define :method rc_change_picture(pic:rc_linepic_movable, newx, newy, newlines, newstrings);

	rc_undraw_linepic(pic);

    ;;; move without displaying
	rc_move_to(pic, newx, newy, false);

	;;; change picture if necessary
	if newlines then
		newlines -> rc_pic_lines(pic);
	endif;

	;;; change strings if necessary
	if newstrings then
		newstrings -> rc_pic_strings(pic);
	endif;
	rc_draw_linepic(pic);

enddefine;

endsection;
