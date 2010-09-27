/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $local/rclib/lib/rc_hand.p
 > Purpose:			New version of LIB * MSHAND, based on rc_linepic
 > Author:          Aaron Sloman, Jan 18 1997 (see revisions)
 > Documentation:
 > Related Files:	LIB * RC_BLOCKS
 */

/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/lib/mshand.p
 >  Purpose:        a robot hand for the blocks world demo with badpath recovery
 >  Author:         David Hogg, Richard Bignell, Oct 20 1986 (see revisions)
 >  Documentation:	TEACH * MSDEMO
 >  Related Files:  LIB * PWMHAND
 */

#_TERMIN_IF DEF POPC_COMPILING

uses rclib
uses objectclass
uses rc_linepic
uses rc_window_object

uses turtle;

global vars the_hand;	;;; created in blocks_go
global vars procedure picture;	;;; an array created later

;;; global variables defined in rc_blocks.p

global vars
	;;; scale for rc_graphic picture
	X_scale,
	Y_scale,	;;; negated in picture

	world_width,
	world_height,
;

;;; Define a handpic class with two instances open_hand and
;;; closed_hand, corresponding to the two states the hand
;;; can be in. These are drawn differently.
define :mixin ms_handpic;
    is rc_linepic_movable;
enddefine;

define :class ms_hand; is ms_handpic;
	slot ms_hand_open = true;
	slot ms_hand_open_strings;
	slot ms_hand_closed_strings;
enddefine;

define :method make_open(h:ms_hand);
	if ms_hand_open(h) then
		mishap('Hand already open', [^h])
	else
		true -> ms_hand_open(h);
		;;; get rid of old picture
		rc_draw_linepic(h);
		ms_hand_open_strings(h) -> rc_pic_strings(h);
		rc_draw_linepic(h);
	endif;
enddefine;
		

define :method make_closed(h:ms_hand);
	if ms_hand_open(h) then
		false -> ms_hand_open(h);
		;;; get rid of old picture
		rc_draw_linepic(h);
		ms_hand_closed_strings(h) -> rc_pic_strings(h);
		rc_draw_linepic(h);
	else
		mishap('Hand already closed', [^h])
	endif;
enddefine;

/*
define :instance the_hand:ms_hand
	rc_picx = 37;
	rc_picy = 15;
	ms_hand_open = true;
	ms_hand_open_strings = [FONT '12x24' {-2 0 '/-\\'}];
	ms_hand_closed_strings = [FONT '12x24' {-2 0 '|-|'}];
	rc_pic_strings = [];
enddefine;

rc_undraw_all([^the_hand]);
rc_draw_linepic(the_hand);
make_closed(the_hand);
rc_draw_linepic(the_hand);
make_open(the_hand);
rc_move_to(the_hand, 50, 16, true);
move_claw_to(54,14);
*/


;;; declared in rc_blocks
vars world_width, world_height;

;;; Globals concerned with the HAND.
vars Wx, Wy;

define 6 ===> x;
lvars x;
	;;; for error messages
	x =>
enddefine;

define lconstant drawclaw;
	;;; used to draw in the internal picture.
	if present([held == ]) then "H" -> picture(Wx,Wy)
	else
		"/" -> picture(Wx - 1,Wy);
		"-" -> picture(Wx, Wy);
		"'\\'" -> picture(Wx + 1,Wy)
	endif
enddefine;

define  /* lconstant */  move_claw_to(x, y);
	rc_move_to(the_hand, x, y, true);
enddefine;

define drawhand(atx,aty);
	;;; "-" ->> picture(atx - 1,15) ->> picture(atx,15) -> picture(atx + 1,15);
	;;;;jumpto(atx,14);
	"|" -> paint;
	jumpto(atx,aty);
	drawto(atx,aty);
	atx -> Wx;
	aty -> Wy;
	move_claw_to(Wx, Wy);
enddefine;

define lconstant clearclaw;
	space -> picture(Wx,Wy);
	unless present([held ==]) then
		space ->> picture(Wx - 1,Wy) -> picture(Wx + 1,Wy)
	endunless
enddefine;

global vars procedure ms_colour_of =
	newproperty(
		[[b 'blue'][r 'red'][g 'green'][^space 'white']], 8, false, "perm");


define drawbox_in_picture(paint, x, y, blockwidth, blockheight);
	;;; draw the block in the internal image
	lvars h, i, paint, x, y, blockwidth, blockheight;
	for h from x to blockwidth + x - 1 do
		for i from y to blockheight + y - 1 do
			paint -> picture(h,i);
		endfor;
	endfor;
enddefine;


define drawthebox(paint);
	vars paint, held_block;
	;;; Needs to be changed. "p" is paint or a colour
	vars ox,oy,sx,sy,the_block;
	if present ([held ?held_block ?ox ?oy]) then
		if paint /== space then
			lookup([colour ^held_block ?paint]);
			lookup([^held_block is ?the_block]);
			rc_move_to(the_block, Wx-ox, Wy-oy, true)
		endif;
		;;; update the internal image
		lookup([size ^held_block ?sx ?sy]);
		drawbox_in_picture(paint, Wx-ox, Wy-oy, sx, sy);
	endif
enddefine;


define  /* lconstant */  overlaps(x1,y1,w1,h1,x2,y2,w2,h2);
	;;; does the box x1, y1, w1, h1 overlap the box at x2,y2,w2,h2
	max(x1,x2) < min(x1 + w1, x2 + w2)
		and
	max(y1,y2) < min(y1 + h1, y2 + h2)
enddefine;

define  /* lconstant */  newrect(x,y,w,h,ac,up);
	;;; specify a rectangle that must be clear for motion of block
	;;; x,y is location of block, w, h width and height, and
	;;; ac and up give direction of motion (across and up)
	lvars x,y,w,h,ac,up;
	if ac < 0 then x  +  ac else x endif;
	if up < 0 then y  +  up else y endif;
	w  +  abs(ac);
	h  +  abs(up);
enddefine;

define  /* lconstant */  inside(boxlist,framebox);
	lvars xframe,yframe,wframe,hframe,x,y,w,h,box;
	framebox.dl ->(xframe, yframe, wframe,  hframe);
	for box in boxlist do
		box.dl -> (x, y, w, h);
		if xframe > x or yframe > y
			or xframe + wframe < x + w
			or yframe + hframe < y + h
		then return(false)
		endif;
	endfor;
	true
enddefine;


define badpath(ac,up) -> result;
	;;; ac is amount across, up is amount up (or down)
	;;; One or other should be 0
	lvars shapes;
	vars held_block, sx, sy, ox, oy, b;	;;; pattern variables
	if present([held ?held_block ?ox ?oy]) then
;;;'Holding ' >< held_block ===>
		;;; Holding a block. It must move also
		lookup([size ^held_block ?sx ?sy]);
		[%
			if ac == 0 then
				[% newrect(Wx, Wy, 3, 2, ac, up) %]
			else
			 	[% newrect(Wx - 2, Wy + 1, 3, 2, ac, up) %],
			endif,
			[% newrect(Wx - ox, Wy - oy, sx, sy, ac, up)%]%]
	else
		[%
			if ac == 0 then
				[% newrect(Wx, Wy, 3, 2, ac, up)%],
			else
			 	[% newrect(Wx - 2, Wy + 1, 3, 2, ac, up) %],
			endif
		%]
	endif -> shapes;
;;; [shapes ^shapes] ==>
	if not(inside(shapes, [1 1 ^world_width ^world_height])) then
		'cannot move through pictureframe' ===>;
		"pictureframe" -> result
	else
		foreach [?b at ?ox ?oy] do
			lookup([size ^b ?sx ?sy]);
			lvars descr;
			for descr in shapes do
				if overlaps(descr.dl,ox,oy,sx,sy) then
					('cannot move through ' >< b) ===>;
					return(b -> result)
				endif
			endfor;
		endforeach;
		false -> result
	endif
enddefine;


define  /* lconstant */  balanced(x,y,sx) -> result;
	lvars yt llim rlim xmid;

	unless y==1 or x==1 or x + sx > 75 then
		y - 1 -> yt;  x -> llim;  x + sx - 1 -> rlim;
		while (picture(llim,yt) == space) and (llim < rlim) do
			llim + 1 -> llim
		endwhile;
		while (picture(rlim,yt) == space) and (llim <= rlim) do
			rlim - 1 -> rlim
		endwhile;
		x + (sx - 1)/2.0 -> xmid;
		if rlim < llim then 0
		elseif llim > xmid and picture(x - 1,yt) == space then  -1
		elseif rlim < xmid and picture(x + sx,yt) == space then 1
		else return(true)
		endif;
		false;
	else
		true;
	endunless -> result;
enddefine;

vars Raise;		;;; defined below

define Lower(a) -> outcome;
	if a < 0 then
		Raise(-a);
		return()
	endif;
	if not(badpath(0, - a)) then
		drawthebox(space);
		clearclaw();
		move_claw_to(Wx, Wy);
		;;; "|" -> paint;
		;;; jumpto(Wx,Wy);
		max(1, Wy - a) -> Wy;
		;;; drawto(Wx,Wy);
		move_claw_to(Wx, Wy);
		drawthebox(undef);
		do_pause();
		true
	else
		false
	endif -> outcome
enddefine;

define Raise(a) -> outcome;
	if a < 0 then
		Lower(-a);
		return()
	endif;
	if Wy >= world_height - 3 then
		;;; already at top
		true -> outcome;
		return();
	endif;
	;;; going up so go to the top
	world_height - Wy - 3 -> a;
	if not(badpath(0,a)) then
		drawthebox(space);
		space -> paint;
		clearclaw();
		move_claw_to(Wx, Wy);
		;;;;do_pause();
		jumpto(Wx,Wy);
		min(world_height - 1, Wy + a) -> Wy;
		move_claw_to(Wx, Wy);

		drawto(Wx,Wy);
		drawclaw();
		drawthebox(undef);
		do_pause();
		true
	else
		false
	endif -> outcome
enddefine;

define Across(x) -> outcome;
	lvars newx;
	unless badpath(x,0) then
		if x > 0 then
			'Going right' ===>
		elseif x < 0 then
			'Going left' ===>
		endif;
		;;; find actual bound
		if x > 0 then
			min(world_width, Wx + x)
		else
			max(1, Wx + x)
		endif -> newx;

		drawthebox(space);
		clearclaw();
		jumpto(Wx,Wy);
		move_claw_to(Wx, Wy);	;;; redundant?
		space -> paint;
		drawto(Wx,world_height);
		jumpto(Wx - 2,world_height);
		drawto(Wx + 2,world_height);
		jumpto(Wx,Wy);
		drawto(newx,Wy);
		drawhand(newx,Wy);
		move_claw_to(newx, Wy);
		drawthebox(undef);
		do_pause();
		true
	else
		false
	endunless -> outcome
enddefine;

define Down() -> outcome;
'Moving Down' ===>
	lvars lx,rx,d,outcome;
	vars x,box,y,ox,bsx,bsy,sx,sy;
	1 -> d;
	if present([held ?held_block ?ox =]) then
		lookup([size ^held_block ?bsx ?bsy]);
		Wx - ox + bsx - 1 -> rx;
		Wx - ox -> lx
	else
		Wx - 1 -> lx; Wx + 1 -> rx;
		false -> held_block;
	endif;
	foreach [?box at ?x ?y] do
		unless x > rx then
			lookup([size ^box ?sx ?sy]);
			unless x + sx <= lx or y + sy <= d then
				y + sy -> d
			endunless
		endunless
	endforeach;
	if held_block then
		d + bsy -> d
	endif;
	Lower(Wy - d) -> outcome;
enddefine;

define Hold();
	vars box,x,y,sx,sy;
	if present([held ==]) then
		'Already holding ' >< held_block ===>;
	else
		foreach [?box at ?x ?y] do
			unless x > Wx do
				lookup([size ^box ?sx ?sy]);
				if y + sy == Wy and x + sx > Wx then
					clearclaw();
					;;; box -> held_block;
					remove([^box at ^x ^y]);
					add([held ^box %Wx - x,Wy - y%]);
					make_closed(the_hand);
					move_claw_to(Wx, Wy);
					drawclaw();
					do_pause();
					return
				endif
			endunless
		endforeach;
		'Nothing to hold (something wrong?)'===>;
	endif
enddefine;

define Letgo;
	vars held_block,ox,oy;
	if not(present([held ==])) then
		'Nothing to let go (something wrong?)'===>;

	elseif picture(Wx - 1,Wy) /== space
			or picture(Wx + 1,Wy) /== space
	then
		;;; This needs checking
		'Can\'t open claw'===>;
	else
		lookup([held ?held_block ?ox ?oy]);
		remove(it);
		add([^held_block at %Wx - ox,Wy - oy%]);
		make_open(the_hand);
		move_claw_to(Wx, Wy);
		drawclaw();
		do_pause();
	endif
enddefine;

define Getabove(b) -> outcome;
	vars x,sx;
	lvars oldy = Wy;
	if present([held ^b ==]) then
		('Cannot get above block already held: ' >< b)===>;
	else
		'Moving above ' >< b ===>
		unless Wy >= world_height - 3 then
			if Raise(1) then
				true -> outcome;
			else
				'Cannot move above ' >< b ===>
				false -> outcome;
				return;
			endif;
		endunless;
		lookup([^b at ?x =]);
		lookup([size ^b ?sx =]);
		sx div 2 -> sx;
		if Across(x + sx - Wx) then
			true -> outcome;
		else
			'Cannot move sideways to be above ' >< b ===>
			Lower(Wy - oldy) -> ;   ;;; undo the Raise
			false -> outcome; return;
		endif;
	endif
enddefine;

define Findspace() -> outcome;
	vars held_block, sx, x, b, tx, ox;
	lvars p, rx, outcome;
	if present([held ?held_block ?ox =]) then
		unless Wy >= world_height - 3 then
			Raise(1) -> outcome;
			unless outcome then
				'Cannot go up at ' >< [^x ^y] ===>
				return();
			endunless;
		endunless;
		lookup([size ^held_block ?sx =]);
		sx - 1 -> sx;
		1->> p -> rx;
		lvars done = false;
		;;; Find a block with suitable space
		until done do
			true -> done;
			foreach [?b at ?x =] do
				if x >= p then
					unless p + sx < x then
						false -> done;
						lookup([size ^b ?tx =]);
						if x + tx > rx then x + tx -> rx endif
					endunless
				else
					lookup([size ^b ?tx =]);
					unless x + tx <= p then
						false -> done;
						if x + tx > rx then x + tx -> rx endif
					endunless
				endif
			endforeach;
			if done and p + ox < 3 then
				false -> done; 3 - ox -> rx
			endif;
			rx -> p
		enduntil;

		if Across(p + ox - Wx) then
			true -> outcome;
		else
			'Cannot go across ' >< (p + ox - Wx) ===>
			Down() -> ;
			false -> outcome;
			return;
		endif;
		;;; 'Going down at ' >< [^Wx ^Wy] ===>
		if Down() then
			true -> outcome;
		else
			'Cannot go down at ' >< [^Wx ^Wy] ===>
			'Going back across' ===>
			Across(-(p + ox - Wx)) -> ;  ;;; undo the Across
			do_pause();
			'Now going down' ===>
			Down() -> ;              ;;; undo the Raise
			false -> outcome;
			return;
		endif;
	else 'Cannot find space when not holding anything' ===>;
	endif
enddefine;

vars rc_hand = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 26 1997
	removed gravity. See LIB MSHAND
--- Aaron Sloman, Jan 26 1997
	Simplified representation of the hand. Only one instance
--- Aaron Sloman, Jan 21 1997
	Converted to use linepic instances for the blocks
--- Aaron Sloman, Jan 24 1987
	Moved new features of local lib termhand to public library, and
	slightly tidied up, including use of lvars,  /* lconstant */ , inserting
	some missing declarations.
--- Richard Bignell, Oct 20 1986  -  this is an extension of LIB * MSHAND to
	allow LIB * MSDEMO to restore itself after a bad path is encountered
	in a move.
	Various procedures altered to return a true/false result

CONTENTS (define)

 define :mixin ms_handpic;
 define :class ms_hand; is ms_handpic;
 define :method make_open(h:ms_hand);
 define :method make_closed(h:ms_hand);
 define :instance the_hand:ms_hand
 define 4 ===> x;
 define lconstant drawclaw;
 define  /* lconstant */  move_claw_to(x, y);
 define drawhand(atx,aty);
 define lconstant clearclaw;
 define drawbox_in_picture(paint, x, y, blockwidth, blockheight);
 define  drawthebox(paint);
 define  /* lconstant */  overlaps(x1,y1,w1,h1,x2,y2,w2,h2);
 define  /* lconstant */  newrect(x,y,w,h,ac,upp);
 define  /* lconstant */  inside(boxlist,listbox);
 define  /* lconstant */  badpath(ac,upp);
 define  /* lconstant */  balanced(x,y,sx) -> result;
 define Lower(a) -> outcome;
 define Raise(a) -> outcome;
 define Across(x) -> outcome;
 define Down() -> outcome;
 define Hold();
 define Letgo;
 define Getabove(b) -> outcome;
 define Findspace() -> outcome;

*/
