/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_polyline.p
 > Purpose:			Define polyline structure, and arrange for interactive
					extension.
 > Author:          Aaron Sloman, Mar 22 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;; Basic Tests

uses rc_window_object;

vars win1 = rc_new_window_object( 600, 20, 400, 400, true, 'win1');

rc_kill_window_object( win1);

vars end1 = rc_cons_end(0, 0);

end1 =>

rc_draw_linepic(end1);

;;; Make the window mouse sensitive and add the point
rc_mousepic(win1);
rc_add_pic_to_window(end1, win1, true);
;;; drag it around
end1 =>
;;; move it under program control
rc_move_to(end1,100,100,true);
rc_move_to(end1,0,0,true);
rc_remove_pic_from_window(end1, win1);
rc_undraw_linepic(end1);

;;; Now create a line
rc_start();
vars line1 = rc_cons_line(10,10,10,100);
line1 =>
rc_draw_polyline(line1);

;;; Change its ends
-100,100,100,100 -> rc_ends(line1);
false,false,100,-100 -> rc_ends(line1);
-100,-100,false,false -> rc_ends(line1);

rc_move_end2_to(line1, 0, 150);
rc_move_end1_to(line1, 100, -150);
rc_undraw_polyline(line1);
rc_draw_polyline(line1);
line1.datalist ==>
line1.rc_line_drawn =>

;;; Make a movie with the line
vars x, y;
for x from -100 by 30 to 160 do
	for y from 100 by -20 to -100 do
		x,y,-100,100 -> rc_ends(line1);
		syssleep(1);
	endfor
endfor;

rc_undraw_polyline(line1);


;;; Polyline Tests
uses rc_window_object;

vars win1 = rc_new_window_object( 600, 20, 400, 400, true, 'win1');

;;; Create a rc_polyline instance using these points
vars
	poly1 = rc_create_polyline([ 0 0  -20 20  -15 35  15 35  20 20], true),
	lines = rc_lines(poly1),
	;;; Get two of the ends of the lines
	end2 = rc_end2(lines(1)),
	end5 = rc_end2(lines(4));

;;; end2 is also the beginning of line 2
end2 == rc_end1(lines(2)) =>

poly1 =>
lines ==>
;;; get from ends to lines that have those ends
lines(1)=>
rc_end1_owners(rc_end2(lines(1))) =>	
rc_end2_owners(rc_end2(lines(1))) =>

vars line3 = lines(3), end31 = rc_end1(line3), end32=rc_end2(line3);
line3 ==>
line3.datalist ==>
end31, end32 =>
end31.datalist ==>
end32.datalist ==>
end31.rc_end1_owners.hd.rc_end1 ==>
end31.rc_end1_owners.hd.rc_end2 ==>
end31.rc_end2_owners.hd.rc_end1 =>
end31.rc_end2_owners.hd.rc_end2 =>


end2 =>
end5 =>

rc_start();
rc_draw_polyline(poly1);
rc_undraw_polyline(poly1);

;;; draw it again and start moving two of the ends around.
rc_draw_polyline(poly1);
rc_draw_linepic(end2);
rc_undraw_linepic(end2);
rc_move_to(end2, -20, -20, true);
rc_move_to(end2, -180, 0, true);
rc_move_to(end5, 180, 0, true);

;;; Move both ends in a circle, end5 four times as fast.
vars ang, popradians = false;
for ang from -180 by 5 to 180 do
	rc_move_to(end2, 150*cos(ang), 150*sin(ang), true);
	rc_move_to(end5, 150*cos(ang*4), 150*sin(ang*4), true);
	syssleep(1);
endfor;

;;; now do it without moving the actual end points.
for ang from -180 by 5 to 180 do
	rc_move_end_to(end2, 150*cos(ang), 150*sin(ang));
	rc_move_end_to(end5, 150*cos(ang*4), 150*sin(ang*4));
	syssleep(1);
	syssleep(1);
endfor;
lines ==>
rc_start();
rc_draw_polyline(poly1);
rc_undraw_polyline(poly1);
rc_undraw_linepic(end2);
rc_undraw_linepic(end5);

;;; Dragging tests
;;; now make end2 and end5 draggable
rc_mousepic(win1);
rc_add_pic_to_window(end2, win1, true);
rc_add_pic_to_window(end5, win1, true);

rc_draw_polyline(poly1); rc_draw_linepic(end2); rc_draw_linepic(end5);
;;; try dragging the ends around, then
rc_undraw_polyline(poly1); rc_undraw_linepic(end2); rc_undraw_linepic(end5);

rc_lines(poly1) ==>
rc_fast_drag=>
;;; Try changing how dragging is controlled
rc_draw_polyline(poly1); rc_draw_linepic(end2); rc_draw_linepic(end5);
true -> rc_fast_drag;
false -> rc_fast_drag;

;;; Make the beginning of line 1 visible and draggable
vars end1=rc_end1(lines(1));
rc_add_pic_to_window(end1, win1, true);
rc_draw_linepic(end1);

;;; Print this out before and after dragging end1
rc_lines(poly1) ==>

;;; Add some extra points, using rc_copy_end

vars newpoint1, newpoint2, newpoint3;

;;; Add a new point before end2
rc_copy_end(end2, rc_lines(poly1), 1) -> (rc_lines(poly1), newpoint1);
rc_lines(poly1) ==>
newpoint1 =>

;;; drag newpoint1 and see what changes
rc_lines(poly1) ==>
newpoint1 =>

;;; Add a new point before end1
rc_copy_end(end1, rc_lines(poly1), 1) -> (rc_lines(poly1), newpoint2);
rc_lines(poly1) ==>
newpoint2==>

;;; Insert a new point after end5
end5=>
rc_copy_end(end5, rc_lines(poly1), 2) -> (rc_lines(poly1), newpoint3);
rc_lines(poly1) ==>
newpoint3==>

end1.datalist==>
newpoint3.datalist ==>

applist([^end1 ^end2 ^ end5 ^newpoint1 ^newpoint2 ^newpoint3], rc_undraw_linepic);

rc_undraw_polyline(poly1);
rc_draw_polyline(poly1);
rc_kill_window_object( win1);
*/

uses rclib
uses rc_linepic
uses rc_mousepic
uses rc_point
uses rc_sync_display

global vars
	;;; Sensitive radius for line ends
	;

define :class rc_line_end;
    is rc_point ;
	;;; location
	slot rc_end1_owners == [];	
	slot rc_end2_owners == [];
enddefine;

define rc_cons_end(x,y) -> newend;
	instance rc_line_end;
		rc_picx = x;
		rc_picy = y;
	endinstance -> newend;
enddefine;


define :method print_instance(p:rc_line_end);
    printf('<end %P %P>', [%rc_coords(p) %])
enddefine;


define :class rc_line;
    is rc_selectable rc_linepic_movable;
	;;; location
	slot rc_line_drawn = false;
	slot rc_end1 = instance rc_line_end endinstance;	
	slot rc_end2 = instance rc_line_end endinstance;	
enddefine;


define rc_cons_line(x1, y1, x2, y2)-> line;

	instance rc_line;
	endinstance -> line;

	lvars end1 = rc_end1(line), end2 = rc_end2(line);

	x1, y1 -> rc_coords(end1);
	x2, y2 -> rc_coords(end2);

	conspair(line, rc_end1_owners(end1)) -> rc_end1_owners(end1);
	conspair(line, rc_end2_owners(end2)) -> rc_end2_owners(end2);
	
enddefine;

define rc_cons_line_using1(end1, x2, y2)-> line;

	instance rc_line;
		rc_end1 = end1;
	endinstance -> line;

	lvars end2 = rc_end2(line);

	x2, y2 -> rc_coords(end2);

	conspair(line, rc_end1_owners(end1)) -> rc_end1_owners(end1);
	conspair(line, rc_end2_owners(end2)) -> rc_end2_owners(end2);
	
enddefine;

define rc_cons_line_using2(x1, y1, end2)-> line;

	instance rc_line;
		rc_end2 = end2;
	endinstance -> line;

	lvars end1 = rc_end1(line);

	x1, y1 -> rc_coords(end1);

	conspair(line, rc_end1_owners(end1)) -> rc_end1_owners(end1);
	conspair(line, rc_end2_owners(end2)) -> rc_end2_owners(end2);
	
enddefine;

define rc_cons_line_using_ends(end1, end2)-> line;

	instance rc_line;
		rc_end1 = end1;
		rc_end2 = end2;
	endinstance -> line;

	conspair(line, rc_end1_owners(end1)) -> rc_end1_owners(end1);
	conspair(line, rc_end2_owners(end2)) -> rc_end2_owners(end2);
	
enddefine;

;;; predefine two methods defined below
define :generic rc_draw_polyline(line);
enddefine;

define :generic rc_undraw_polyline(line);
enddefine;

global vars rc_new_end_increment = 5;

define rc_copy_end(oldend, linelist, num) -> (linelist, newend);
	;;; Create a copy (newend) of the end, close to oldend
	;;; Create a new line between oldend and newend.

	;;; Depending on whether num is 1 or 2 make the line have the
	;;; new point as end1 or end2. The old point will be the
	;;; other end. The new point will have x,y incremented by
	;;; rc_new_end_increment

	lvars
		(x, y) = rc_coords(oldend),
		newend, new_line, oldlines;

	;;; Create newend and new line linking oldend and newend
	rc_cons_end(x+rc_new_end_increment, y+rc_new_end_increment) -> newend;

	instance rc_line; endinstance -> new_line;

	if num == 1 then newend, oldend else oldend, newend endif
		->(rc_end1(new_line), rc_end2(new_line));

	;;; now link the points to oldlines

	;;; Set up slot accessors for end owners
	lvars
		(procedure newendowners, procedure oldendowners) =
		if num == 1 then
		rc_end1_owners, rc_end2_owners
		else
		rc_end2_owners, rc_end1_owners
		endif;

	;;; These lines will now have to end at the new point
	oldendowners(oldend) -> oldlines;

	;;; Undraw them
	applist(oldlines, rc_undraw_polyline);

	;;; Make them end at the new point

	lvars procedure endofoldline =
		if num == 1 then rc_end2 else rc_end1 endif;

	lvars line;
	for line in oldlines do
		newend -> endofoldline(line);
	endfor;
	
	oldlines -> oldendowners(newend);
	
	;;; Now link in the new line between new and old point
	[^new_line] -> newendowners(newend);
	[^new_line] -> oldendowners(oldend);
	
	;;; now add the new line to the linelist

	lvars procedure otherendofline =
		if num == 2 then rc_end2 else rc_end1 endif;
	if otherendofline(front(linelist)) == oldend then
		if num == 1 then
			conspair(new_line, linelist) -> linelist
		else
			conspair(new_line, back(linelist)) -> back(linelist)
		endif
	else
		;;; search down the list to see where the new line should go
		lvars pair = back(linelist), lastlink = linelist;
		repeat;
			if otherendofline(front(pair)) == oldend then
				if num == 1 then
					conspair(new_line, pair) -> back(lastlink);
				else
					conspair(new_line, back(pair)) -> back(pair);
				endif;
				quitloop();
			elseif back(pair) == [] then
				mishap('Missing end in linelist', [^oldend 'NOT IN' ^linelist])
			else
				pair,back(pair) -> (lastlink,pair)
			endif;
		endrepeat;
	endif;

	;;; redraw the old lines
	applist(oldlines, rc_draw_polyline);
	;;; draw new line and new end
	rc_draw_polyline(new_line);

	rc_draw_linepic(newend);
	;;; Make the end selectable
	rc_add_pic_to_window(newend, rc_current_window_object, true);

enddefine;



define :method rc_ends(line:rc_line) ->(x1,y1,x2,y2);
	rc_coords(rc_end1(line)) -> (x1,y1);
	rc_coords(rc_end2(line)) -> (x2,y2);
enddefine;

define :method updaterof rc_ends(x1,y1,x2,y2, line:rc_line);
	;;; update ends of the line. Any values that are false are
	;;; ignored
	lvars (end1,end2)=(rc_end1(line),rc_end2(line));
	;;; draw old position, to remove it
	rc_undraw_polyline(line);
	if x1 then x1 -> rc_picx(end1) endif;
	if y1 then y1 -> rc_picy(end1) endif;
	if x2 then x2 -> rc_picx(end2) endif;
	if y2 then y2 -> rc_picy(end2) endif;
	rc_draw_polyline(line);
enddefine;

define :method print_instance(p:rc_line);
    printf('<line %P %P %P %P>', [%rc_ends(p) %])
enddefine;

define :method rc_move_end1_to(line:rc_line, x, y);
	x, y, false, false -> rc_ends(line)
enddefine;

define :method rc_move_end2_to(line:rc_line, x, y);
	false, false, x, y -> rc_ends(line)
enddefine;

define :method rc_move_end_to(line_end:rc_line_end, x, y);
	lvars line;
	;;; first remove the lines containing that end
	for line in rc_end1_owners(line_end) do
		rc_undraw_polyline(line);
	endfor;
	for line in rc_end2_owners(line_end) do
		rc_undraw_polyline(line);
	endfor;
	;;; now redraw them in their new locations
	for line in rc_end1_owners(line_end) do
		rc_move_end1_to(line, x, y);
	endfor;
	for line in rc_end2_owners(line_end) do
		rc_move_end2_to(line, x, y);
	endfor;
enddefine;

define :method rc_move_to(line_end:rc_line_end, newx, newy, draw);
	;;; ignore draw argument
	rc_undraw_linepic(line_end);
	rc_sync_display();
	rc_move_end_to(line_end, newx, newy);
	newx,newy -> rc_coords(line_end);
	rc_draw_linepic(line_end);
enddefine;

define :method rc_draw_polyline(line:rc_line);
	dlocal rc_linefunction = Glinefunction;
	unless rc_line_drawn(line) then
		rc_drawline(rc_ends(line));
		true -> rc_line_drawn(line);
	endunless;
enddefine;

define :method rc_undraw_polyline(line:rc_line);
	dlocal rc_linefunction = Glinefunction;
	if rc_line_drawn(line) then
		rc_drawline(rc_ends(line));
		false -> rc_line_drawn(line);
	endif;
enddefine;

define :class rc_polyline;
	is rc_linepic rc_selectable;
	slot rc_lines == [];
	slot rc_line_drawn == false;
enddefine;

define :method rc_draw_polyline(poly:rc_polyline);
	dlocal rc_linefunction = Glinefunction;
	applist(rc_lines(poly), rc_draw_polyline);
	true -> rc_line_drawn(poly);
enddefine;

define :method rc_undraw_polyline(poly:rc_polyline);
	if rc_line_drawn(poly) then
		applist(rc_lines(poly), rc_undraw_polyline);
		false -> rc_line_drawn(poly);
	endif;
enddefine;

;;; Now stuff for creating polylines
define rc_create_endlist(coords) -> ends;
	;;; take a list of 2N numbers and create a list of N ends
	lvars list = coords, len = stacklength();
	[%
		until coords == [] do
			if back(coords) == [] then
				erasenum(stacklength() - len);
				mishap('ODD NUMBER OF NUMBERS IN POINTLIST',[^list])
			endif;
			
			rc_cons_end(destpair(fast_destpair(coords)) -> coords)
		enduntil
	%] -> ends;
enddefine;

define rc_create_linelist(endlist, closed) -> lines;
	;;; create a polyline, open or closed, from a list of ends
	lvars point, lastend, nextend, firstend;

	destpair(endlist) -> (lastend, endlist);

	if closed then
		lastend -> firstend;
	endif;

	[%
		;;; create the lines
		for point in endlist do
			rc_cons_line_using_ends(lastend, point);
			point -> lastend;
		endfor;
		if closed then
			;;; close up the polyline
			rc_cons_line_using_ends(lastend, firstend);
		endif;
	%] -> lines;
enddefine;

define rc_create_polyline(pointlist, closed) -> pline;
	;;; pointlist should be a list of 2N numbers representing point coordinates
	;;; closed is a boolean. If true the polyline will be closed
	instance rc_polyline;
		rc_lines = rc_create_linelist(rc_create_endlist(pointlist), closed)
	endinstance -> pline;
enddefine;



/*
CONTENTS -

 define :class rc_line_end;
 define rc_cons_end(x,y) -> newend;
 define :method print_instance(p:rc_line_end);
 define :class rc_line;
 define rc_cons_line(x1, y1, x2, y2)-> line;
 define rc_cons_line_using1(end1, x2, y2)-> line;
 define rc_cons_line_using2(x1, y1, end2)-> line;
 define rc_cons_line_using_ends(end1, end2)-> line;
 define :generic rc_draw_polyline(line);
 define :generic rc_undraw_polyline(line);
 define rc_copy_end(oldend, linelist, num) -> (linelist, newend);
 define :method rc_ends(line:rc_line) ->(x1,y1,x2,y2);
 define :method updaterof rc_ends(x1,y1,x2,y2, line:rc_line);
 define :method print_instance(p:rc_line);
 define :method rc_move_end1_to(line:rc_line, x, y);
 define :method rc_move_end2_to(line:rc_line, x, y);
 define :method rc_move_end_to(line_end:rc_line_end, x, y);
 define :method rc_move_to(line_end:rc_line_end, newx, newy, draw);
 define :method rc_draw_polyline(line:rc_line);
 define :method rc_undraw_polyline(line:rc_line);
 define :class rc_polyline;
 define :method rc_draw_polyline(poly:rc_polyline);
 define :method rc_undraw_polyline(poly:rc_polyline);
 define rc_create_endlist(coords) -> ends;
 define rc_create_linelist(endlist, closed) -> lines;
 define rc_create_polyline(pointlist, closed) -> pline;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 25 1997
 */
