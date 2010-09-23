/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_pythagoras.p
 > Purpose:			demonstrates rc_transform_lines, in proof of pythagoras theorem
 > Author:          Aaron Sloman, Nov 17 2000 (see revisions)
 > Documentation:   HELP RCLIB/rc_pythagoras
 > Related Files:	rc_transform_lines
	This demonstration was inspired in part by the Java-based demonstration
	by Norman Foo at
    	http://www.cse.unsw.edu.au/~norman/Pythag.html
 */

/*

rc_pythagoras(90,120,60);

rc_pythagoras(120,90,60);
rc_pythagoras(120,50,60);

*/

section;

uses rclib
uses rc_window_object
uses rc_draw_lines
uses rc_transform_lines
uses rc_transform_pictures


define sleep_delay(hsecs);
	;;; sleep for specified number of hundredths of a second,
	;;; if hsecs non-zero
	if hsecs /== 0 then
		syssleep(hsecs)
	endif
enddefine;

;;; the lconstant procedures are not accessible after
;;; compilation of the file, except via the procedures that
;;; invoke them. To make these available for experimentation,
;;; remove all occurrences of lconstant (ENTER s"lconstant"")

define lconstant draw_closed(poly, col);
	rc_draw_lines_closed(poly, col, 2, CoordModeOrigin);
enddefine;

define lconstant draw_filled(poly, col);
	rc_draw_lines_filled(poly, col, Convex, CoordModeOrigin);
enddefine;

define lconstant rc_flash_filled(poly, col1, col2, delay, n);
	;;; flash the polygon between colour col1 and col2 n times,
	;;; delay/100ths of a second between flashes. Leave col2 at end.
	repeat n times
		sleep_delay(delay);
		draw_filled(poly, col1);
		draw_closed(poly, 'black');
		sleep_delay(delay);
		draw_filled(poly, col2);
		draw_closed(poly, 'black');
	endrepeat;
enddefine;

define lconstant draw_filled_outlined(poly, col);
	draw_filled(poly, col);
	draw_closed(poly, 'black');
enddefine;

define rc_transform_filled(poly1, poly2, col);
	;;; move picture from poly1 to poly1, using the specified colour
	;;; with 40 intermediate locations, with delay of 2/100ths of second
	rc_transform_lines(poly1, poly2, 40, col,
			Convex, CoordModeOrigin, 2, false, rc_draw_lines_filled);
	draw_filled_outlined(poly2, col);
enddefine;


define lconstant draw_three(poly1, poly2, poly3, col);
	draw_closed(poly1, col);
	draw_closed(poly2, col);
	draw_closed(poly3, col);
enddefine;


define lconstant create_polys(offset, a, b) ->
				(triangle1, newtriangle1,
					triangle2, newtriangle2,
					triangle3, newtriangle3,
					triangle4, newtriangle4,
					squarea, squareb, newsquareb, squarec);

	;;; Given right-angled triangle of side a (base) b (vertical on left)
	;;; return coordinates for all the triangles and squares needed for the
	;;; display, with a gap of size offset on left.
	;;; Note: all the triangles get translated, but only one of the squares

	lvars
		;;; get coordinates for locations where sides ab, bc, ca meet.
		abx = offset+b, aby = 0,	;;; sides a and b meet
		bcx = abx, bcy = aby + b,	;;; sides b and c meet
		cax = abx + a, cay = aby,	;;; sides c and a meet
		ab = a+b					;;; length of side of big square
		;

	lvars
		;;; original triangle
		triangle1 = [%abx, aby, bcx, bcy, cax, cay%],
		;;; translated down by distance ab
		newtriangle1 = [%abx, aby-ab, bcx, bcy-ab, cax, cay-ab%],

		;;; other triangles in first and second big square
		triangle2 = [%bcx, bcy, bcx, bcy+a, bcx+b, bcy+a%],
		;;; translated right by a, and down by a+b
		newtriangle2 = [%bcx+a, bcy-ab, bcx+a, bcy+a-ab, bcx+ab, bcy+a-ab%],

		triangle3 = [%abx+b, aby+a+b, abx+a+b, aby+a+b, abx+a+b, aby+a%],
		;;; translated left by b, down by a+b+a
		newtriangle3 = [%abx, aby-a, abx+a, aby-a, abx+a, aby-ab%],

		triangle4 = [%cax, cay, cax+b, cay+a, cax+b, cay%],
		;;; translated down by a
		newtriangle4 = [%cax, cay-a, cax+b, cay, cax+b, cay-a%],

		;;; square on side a (below original triangle)
		squarea = [%abx, aby, cax, cay, cax, cay - a, abx, aby -a %],
		;;; square on side b (left of original triangle)
		squareb = [%abx, aby, bcx, bcy, bcx-b, bcy, bcx-b, aby %],
		;;; translated down and left by amount ab = (a+b)
		newsquareb = [%abx+ab, aby-ab, bcx+ab, bcy-ab, bcx-b+ab, bcy-ab, bcx-b+ab, aby-ab %],
		;;; square on hypotenuse of original triangle
		squarec = [%bcx, bcy, bcx + b, bcy + a, cax+b, cay+a, cax, cay %];

enddefine;

define rc_pythagoras(a, b, delay);

	if a+b > 300 then
		printf('\n\nPlease use numbers that add up to under 300\ne.g.\nrc_pythagoras(90, 120, 100);\n');
		return();
	endif;

	lvars

		picwidth = max(400, round(a+b+b)+10),
		picheight = max(700, round(2*(a+b)+145)),
		y_orig = (picheight div 2) + 20,

		win = rc_new_window_object("right", "top", picwidth, picheight,
					{0 ^y_orig 1 -1}, 'Pythag');
	
	lvars
		;;; colours for the triangles and squares
		col1 = 'red',
		col2 = 'pink',
		col3 = 'yellow',
		col4 = 'orange',
		col5 = 'blue',
		col6 = 'green',
		;;; create all the lists of coordinates for the triangles and
		;;; squares
		(triangle1, newtriangle1,
		triangle2, newtriangle2,
		triangle3, newtriangle3,
		triangle4, newtriangle4,
		squarea, squareb, newsquareb, squarec)= create_polys(5, a, b);

	'lucidasans-bold-14' -> rc_font(rc_window);
	;;; draw the basic triangle
	draw_filled_outlined(triangle1, col1);
	sleep_delay(delay * 2);
	
	rc_print_at(5, a+b+70, 'A TRIANGLE');
	sleep_delay(delay * 4);

	;;; square on side a (below)
	draw_closed(squarea, 'black');
	sleep_delay(delay * 2);

	;;; square on side b (to left)
	draw_closed(squareb, 'black');
	sleep_delay(delay * 2);

	;;; square on side c (hypotenuse)
	draw_closed(squarec, 'black');
	sleep_delay(delay * 2 );

	rc_print_at(5, a+b+50, 'THREE SQUARES');
	sleep_delay(delay * 6);

	;;; now complete big square with extra triangles, each a
	;;; different colour, with black outline, going clockwise
	;;; round the figure
	draw_filled_outlined(triangle2, col2);
	sleep_delay(delay);

	draw_filled_outlined(triangle3, col3);
	sleep_delay(delay);

	draw_filled_outlined(triangle4, col4);
	sleep_delay(delay * 10);

	;;; Start transforming shapes into new big square below.
	;;; Start with square on side b: move it down and right
	;;; after flashing to draw attention to it
	rc_flash_filled(squareb, col5, 'white', delay, 3);
	rc_transform_filled(squareb, newsquareb, col5);
	draw_filled_outlined(newsquareb, 'white');
	sleep_delay(delay * 4);

	;;; move triangle 1, after flashing
	rc_flash_filled(triangle1, 'pink', col1, delay, 3);
	rc_transform_filled(triangle1, newtriangle1, col1);
	sleep_delay(delay);

	;;; Veddebug('1');

	;;; move triangle 2
	rc_flash_filled(triangle2, 'grey50', col2, delay, 3);
	rc_transform_filled(triangle2, newtriangle2, col2);
	sleep_delay(delay);

	;;; Veddebug('2');
	;;; move triangle 3
	rc_flash_filled(triangle3, 'pink', col3, delay, 3);
	rc_transform_filled(triangle3, newtriangle3, col3);
	sleep_delay(delay);

	;;; Veddebug('3');
	;;; move triangle 4
	rc_flash_filled(triangle4, 'pink', col4, delay, 3);
	rc_transform_filled(triangle4, newtriangle4, col4);
	sleep_delay(delay * 4);


	;;; Veddebug('4');
	;;; now paint the two smaller squares (sides a and b) the same colour
	draw_filled_outlined(squarea, col5);
	sleep_delay(delay * 2);
	draw_filled_outlined(squareb, col5);
	sleep_delay(delay * 2);

	;;; square on side c painted a different colour
	draw_filled_outlined(squarec, col6);

	;;; now flash the original squares and the transformed
	;;; squares
	repeat 5 times
		sleep_delay(delay);
		draw_three(squarea, squareb, squarec, 'grey90');
		sleep_delay(delay);
		draw_three(squarea, squareb, squarec, 'black');
	endrepeat;
	
	draw_filled_outlined(squareb, 'white');
	draw_filled_outlined(newsquareb, col5);
	repeat 5 times
		sleep_delay(delay);
		draw_three(squarea, newsquareb, squarec, 'pink');
		sleep_delay(delay);
		draw_three(squarea, newsquareb, squarec, 'black');
	endrepeat;

	rc_print_at(5, a+b+30, 'SQUARES+TRIANGLES=SQUARES+TRIANGLES!');
	if delay /== 0 then
		;;; pause for 5 seconds
		sleep_delay(300);
	endif;


    rc_draw_filled_rect(5, a+b+90, picwidth, 65 , "background");
	

	'lucidasans-bold-14' -> rc_font(rc_window);
	rc_print_at(5, a+b+70, 'It also works for triangles of different shapes!');
	sleep_delay(delay*3);
	rc_print_at(5, a+b+50, 'WATCH WHAT HAPPENS AS SHAPES CHANGE');
	sleep_delay(delay*3);
	rc_print_at(5, a+b+30, 'BLUE + BLUE + TRIANGLES = GREEN + TRIANGLES!');
	if delay /== 0 then
		;;; pause for 5 seconds
		sleep_delay(300);
	endif;

	;;; now get ready to deform the diagram to show shape independence

	;;; change drawing mode to over-write rather than use xor
	dlocal Glinefunction = GXcopy;
	
	lvars
		(Triangle1, Newtriangle1,
		Triangle2, Newtriangle2,
		Triangle3, Newtriangle3,
		Triangle4, Newtriangle4,
		Squarea, Squareb, Newsquareb, Squarec)= create_polys(5+b, a+b, 0);

    ;;; clear picture
	rc_start();
	rc_print_at(5, a+b+70, 'It also works for triangles of different shapes!');
	rc_print_at(5, a+b+50, 'WATCH WHAT HAPPENS AS SHAPES CHANGE');
	rc_print_at(5, a+b+30, 'BLUE + BLUE + TRIANGLES = GREEN + TRIANGLES!');
	;;; rc_print_at(5, a+b+30, 'SQUARES + TRIANGLES = SQUARES + TRIANGLES!');
	if delay /== 0 then
		;;; pause for 5 seconds
		sleep_delay(300);
	endif;

	lconstant filled_params = [^Convex ^CoordModeOrigin FILLED];

	;;; now constantly redraw the triangles and squares while
	;;; deforming them
	rc_transform_pictures(
		[	[^triangle1 ^Triangle1 ^col1 ^^filled_params]
			[^newtriangle1 ^Newtriangle1  ^col1 ^^filled_params]
			[^triangle2 ^Triangle2 ^col2 ^^filled_params]
			[^newtriangle2 ^Newtriangle2 ^col2 ^^filled_params]
			[^triangle3 ^Triangle3 ^col3 ^^filled_params]
			[^newtriangle3 ^Newtriangle3 ^col3 ^^filled_params]
			[^triangle4 ^Triangle4 ^col4 ^^filled_params]
			[^newtriangle4 ^Newtriangle4 ^col4 ^^filled_params]
			[^squarea ^Squarea ^col5 ^^filled_params]
			[^newsquareb ^Newsquareb ^col5 ^^filled_params]
			[^squarec ^Squarec ^col6 ^^filled_params]
		], 150, 1, false);


enddefine;

printf('\n\nrc_pythagoras(lengtha, lentghb, delay);\n\t(delay in 100ths of a second)');
printf('\nPlease use lengths that add up to under 200, e.g.\nrc_pythagoras(90, 120, 60);\n');


endsection;

/* --- Revision History ---------------------------------------------------
		
--- Aaron Sloman, Feb  1 2003
		Introduced sleep_delay, to make it easier to do rapid testing
		Fixed rc_transform_filled(poly1, poly2, col) to get final
		colour of new triangle right.
		Added some extra printing for the demo.		
--- Aaron Sloman, 7 Sep 2001
	Added new delays
--- Aaron Sloman, Nov 28 2000
	Expanded printing, adjusted height, and made final display smoother.
--- Aaron Sloman, Nov 21 2000
	Extended to show variable shapes at end.
 */
