/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 >  File: 			$usepop/pop/packages/rclib/lib/rc_polydemo.p
 >  Purpose:        draw pretty pictures using  LIB * RC_GRAPHIC
 > Author:          Aaron Sloman, Mar 20 1995 (see revisions)
 > Documentation:   Below
 */

/*

This is a modified version of LIB RC_POLY, with a much richer interaction.

The operation rc_polydemo, repeatedly uses procedure polyspi to draw pretty
pictures, in response to four numbers typed in by the user:

	Initial length
	Increment
	Angle to turn
	Number of sides

All but the last can be positive or negative, integers or decimals.

This is based on the old LIB POLY, originally implemented circa 1977
in Pop-11 on the PDP11/40, and before that on the DEC-10 in Pop-2.

*/
section;

uses rc_graphic

global vars procedure rc_polydemo;

true -> pop_longstrings;

global vars polyhelpstrings =
[
'This program demonstrates the "RC" (Relative Coordinates) facilities
in Pop-11, the AI programming language which is part of the
University of Sussex Poplog Development Environment.

The program repeatedly asks you to type in four numbers, and it uses
those four numbers to create a picture made of a succesion of lines
of different length drawn one after another each starting where the
previous one ended. Some of the resulting pictures can be quite startling.
The program can help to teach some important ideas about numbers,
lengths and angles.'
'
1. The first number determines the length of the first line. It can be
any number large or small. However if your number is too large it will
draw off the screen, and you may not see the picture!'
'
2. The second number, the increment, determines the amount by which the
length to be drawn should be increased or decreased after each line. It
can be positive or negative, a whole number or a decimal number, e.g.
any of these is possible:
	1  -1  0.5  -1.5 -3'
'
3. The third number specifies the angle in degrees by which to turn
after drawing each line. It too can be an integer or decimal, positive
or negative. Particularly interesting results are obtained if you use
a number that divides into 360 or a multiple of 360, or a number close
to one of those. Examples are
	90 91 120 121 135 136 133 182'
'
4. The fourth number specifies how many lines to draw.

type "bye" when you want to stop.

Type CTRL C to interrupt and restart rc_poly.

Type "h" or "?" to get this explanation again.

'],

polystrings = [
					'I preferred your previous effort'
					'Practice makes perfect'
					'You\'ve been here before'
					'Everyone tries that'
					'Keep at it, you can only get better'
					'Bet you can\'t make it draw a face'
					'Beauty is in the eye of the beholder'
					'There\'s hidden beauty in numbers'
					'I think Ive seen that one before'
					'Beginner\'s luck?'
			  		'Ugh!'
		],

polyadvice =
[
	'Try a square: length 400, increment 0, angle 90, sides 4'
	'Try a square with a bigger or a smaller side'
	'Try a hexagon: length 100, increment 0, angle 60, sides 6'
	'Try the same angle with only 5 or 4 or 3 sides'
	'Can you draw a pentagon (5 sides closing up)?'
	'Try: 400 0 72 5'
	'Adding extra lines will not change the appearance: 400 0 72 50'
	'Try an 8 sided closed figure. Through what angle will lines turn?'
	'Try a small octagon: 10 0 45 8'
	'Try a growing octagon: 10 2 45 50'
	'Try the same starting from length 0, growing to 600'
	'Try again with a different increment, e.g. 1'
	'To get an N sided closed figure use an angle of 360 divided by N'
	'How many distinct sides will this have: 450 0 120 30'
	'Try to make a triangle with side length 450. Think about the angle.'
	'Triangles haves sides turning through 120 degrees (exterior angle)'
	'If you did not manage try: 450 0 120 3'
	'Try a rotating triangle: 500 0 121 360'
	'Try varying the angle for a triangle: 120.5 instead of 121'
	'Try varying the angle for a triangle: 121.5 instead of 121'
	'How many sides will this show: 100 0 40 30'
	'How many sides will this show: 0 1 40 300'
	'Try: 0 0.4 40 600'
	'Try some other angles that make sides cross over each other'
	'Try: 300 0 135 8'
	'Why does an angle of 135 make a closed figure?'
	'Try: 0 1 135 700'
	'Try a smaller increment: 0 0.75 135 900'
	'Try other increments, smaller and larger'
	'Try an angle very slightly larger than 135, e.g. 135.1'
	'Try a rotating triangle: 500 0 121 360'
	'Try a negative increment: 600 -2 120 200'
	'Try getting it to close up to the middle: 600 -2 120 300'
	'Try making the increment smaller and the number of sides bigger'
	'What happens if you slightly change the angle: 600 -1 120.5 600'
	'What happens if it shrinks to the middle, and beyond: 600 -2 120.5 600'
	'Try: 600 -1 90.5 1200'
	'Try: 600 -0.5 75.5 1200'
	'600 -0.5 75.5 2400'
	'700 -1 74 700'
	'700 -1 74.5 700'
	'700 -1 75 700'
	'700 -1 75 1400'
	'700 -0.5 75 1400'
	'700 -0.25 75 2800'
	'Try a very long side and a small turn angle: 10000 0 182 6'
	'Try more sides: 10000 0 182 180'
	'Try varying the angle with a long side: 10000 0 181 180'
	'Try: 10000 0 181.5 180'
	'Try: 10000 0 180.5 360'
	'From now on you are on your own!'
]

;
false -> pop_longstrings;


define polyspi(side, inc, ang, num);
	;;; Draw a polygonal spiral. Initial arm length is side.
	;;; inc is added at each turn.
	;;; The angle turned (to left) is ang (in degrees).
	;;; The total number of sides is num.
	;;; This is invoked by the operation -rc_poly- below

	lvars side, inc, ang, num;
	dlocal popradians = false;

	1 -> rc_xscale;
	-1 -> rc_yscale;
	rc_window_xsize >> 1 -> rc_xorigin;
	rc_window_ysize >> 1 -> rc_yorigin;
	rc_jumpto(0, 0); 45 -> rc_heading;

	;;; move to a location and heading which will cause the centre of the
	;;; spiral to be near centre of screen (very approximate).
	;;; but first normalise ang to lie in range 0 to 359
	until ang >= 0 do ang + 360 ->ang enduntil;
	until ang < 360 do ang - 360 ->ang enduntil;
	if ang > 0.5 then
		ang/2.0 -> rc_heading;
		rc_jump(min(side/(2.0*sin(ang/2.0)),side));
	endif;
	rc_turn(90 + ang/2.0);
	repeat num times
		rc_draw(side); rc_turn(ang);
		side+inc ->side;
	endrepeat;
enddefine;


define lconstant polyreadline(popprompt) -> list;
	lvars item, list,
		procedure rep = incharitem(charin);		;;; item repeater

	dlocal popnewline = true, popprompt;
	
	;;; Make a list items to next newline
	[% until (rep() ->> item) == newline do item enduntil %] -> list;

enddefine;

define polyexplain(strings);
	;;; printout the strings one at a time, pausing in between
	lvars string, strings, line;
	dlocal poplinemax = 256, poplinewidth = 256;
	for string in strings do
		npr(string);
		npr('Press RETURN to continue');
		polyreadline(nullstring) -> line;
	endfor;
	pr(newline);
enddefine;


define lconstant polygetargs() -> args_sofar;
	lvars
		line,
		num,
		args_sofar = [];

	repeat
		lvars len = length(args_sofar);
	quitif(len == 4);

		lvars num, string, item, line;
		if len == 0 then
			polyreadline('\nWould you like a hint? (y or n):') -> line;
			if line = [bye] then
				false -> args_sofar; return
			elseif line = [] then
			elseif line = [y] then
				dest(polyadvice) -> (item, polyadvice);
				npr(item);
				[^^polyadvice ^item] -> item;
			elseif hd(line) == "bye" then
				false -> args_sofar;
				return();
			elseif isnumber(hd(line)) then
				if length(line) < 5 then
					line -> args_sofar;
					nextloop
				else ;;; ignore
				endif
			endif;
		endif;
		if len > 1 then
			pr('So far you have given:');
			for num, string in
				args_sofar,
				['\n\t\tinitial length:'
				 '\n\t\tincrement:     '
				 '\n\t\tangle:         '
				 '\n\t\ttotal number:  ' ]
			do
				pr(string); pr(num)
			endfor;
		endif;
		pr(newline);

		lconstant prompts =
		[   '\n  Initial length?           '
			'\n  Amount to add each time   '
			'\n  angle to turn at corners? '
			'\n  total number of sides?    '];

		polyreadline(prompts(len + 1)) -> line;
		repeat
			quitif(line == []);
			hd(line) -> item;
			if item == "bye" then
				false -> args_sofar;
				return;
			elseif member(item, [? h]) then
				polyexplain(polyhelpstrings);
				quitloop();
			elseif isnumber(item) then
				[^^args_sofar ^item] -> args_sofar;
				tl(line) -> line
			else
				ppr([^newline ^item 'is not a number']);
				quitloop()
			endif;
		endrepeat;

	endrepeat;
	'thank you' =>
enddefine;


define rc_polydemo();
	;;; for convenient repeated use of polyspi.

	lvars args;
	dlocal
		rc_window_xsize = 650,rc_window_ysize = 650,
		rc_window_x = 200, rc_window_y = 10;

	pr(newline);     ;;; flush charout;
	rc_start();
	polyexplain(polyhelpstrings);
	repeat;
		clearstack();
		polygetargs() -> args;
		if args then
			if length(args) /= 4 then
				'Not enough arguments ' >< args =>
				nextloop
			endif;
			rc_start();
			polyspi(explode(args));
			if random(100) > 90 then
				oneof(polystrings)=>
			endif;

			ppr(['\nYour numbers were:' '\n\t' ^^args]);
			lvars angle = args(3);
			if ((360 mod angle == 0) or (720 mod angle == 0))
			and angle > 10
			and random(100) > 70
			then
				pr('\nYour angle divides 360 or 720. Try making it a little\
bigger or smaller, with a small increment and many sides');
			endif;
		else
			BYE:
			'Bye' =>
			'Type "polyoff" to make the picture go away' =>
			return();
        endif
	endrepeat;
enddefine;

define syntax poly;
	sysCALL("rc_polydemo");
	";" :: proglist -> proglist
enddefine;

define syntax polyoff;
	sysPUSH("rc_window");
	sysCALL("rc_destroy");
	";" :: proglist -> proglist
enddefine;

pr('\n  TYPE:   poly\n');

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 22 2009
	Fixed instructions - use only "bye" not CTRL-Z to sop
 */
