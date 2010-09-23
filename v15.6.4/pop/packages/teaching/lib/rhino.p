/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/lib/rhino.p
 > Purpose:        Demonstration of use of VED as interface for a game
 > Author:         Aaron Sloman, Aug 24 1986 (see revisions)
 > Documentation:  See below
 > Related Files:  $poplocal/local/com/mkrhino
 >	--- Copyright University of Sussex 1986.  All rights reserved. ---------
 */

/*
The play(N) command starts the game of rhino with N rhinos. Use the number
keys on keypad to move the hunter ("H") in 8 directions. Try to get
him back to camp "C" without being eaten by rhinos ("R") which appear
as soon as they start moving. A Rhino starts moving if there is nothing
in the line of sight between it and the hunter.

After each successful return to camp the number of rhinos is increased
by one.

The shell command file MKRHINO makes a saved image that can be run with
a numerical argument specifying initial number of rhinos required.

Trees are represented by "@". The hunter, but not rhinos can move diagonally
between trees.
Refresh screen with keypad 5, abort with "0" restart with "."
*/
uses vturtle;

lconstant
	RHINOFILE='rhinofile',
	debugging=false,
	treeword="@",
	treechar=`@`,
	XMAX=79,
	YMAX=23,
	rhinomessage=' Rhinos. Keys "5"- refresh, "." - restart, 0 - abort.',
	procedure terrainmap=newanyarray([1 ^XMAX 1 ^YMAX],`\s`,inits,subscrs),
munchstring=
'\
  @     @  @   @  @    @  @@@@@@  @    @    @@\
  @@   @@  @   @  @@   @  @    @  @    @    @@\
  @ @ @ @  @   @  @ @  @  @       @@@@@@    @@\
  @  @  @  @   @  @  @ @  @    @  @    @\
  @     @  @@@@@  @   @@  @@@@@@  @    @    @@\
\
';

	;

vars TREEFACTOR=45;	;;; controls density of trees

define lconstant procedure setlocation(x,y,word,char);
	lvars x,y,word,char;
	if word then word -> picture(x,y) endif;	;;; might be hidden
	char -> terrainmap(x,y)
enddefine;

define lconstant procedure visible(hx,hy,rx,ry)->bool;
	;;; is the hunter's location visible from the rhino's?
	lvars hx,hy,rx,ry,inc,dx,dy,stepx,bool=true,char;
	hx - rx -> dx; hy - ry -> dy;
	if dx == 0 and dy == 0 then
		true -> bool; return
	endif;
	;;; decide whether to increment x or y
	if abs(dx) >= abs(dy) then
		true,
	else
		;;; increment y, but pretend it's x!
		hx, hy -> hx -> hy;
		rx, ry -> rx -> ry;
		dx, dy -> dx -> dy;
		false
	endif -> stepx;
	;;; rx will step by  sign(dx), i.e. 1 or -1
	;;; set inc, the increment for the variable which changes less
	if dy == 0 then 0 else (1.0 * dy) / abs(dx) endif -> inc;

	sign(dx) -> dx;
	for rx from rx by dx to hx do
		terrainmap(if stepx then rx, round(ry) else round(ry), rx endif) -> char;
		if char == treechar or char == `C` then false -> bool; return endif;
		ry + inc -> ry;
	endfor;
enddefine;

define lconstant procedure trystep(rpoint,hx,hy)->hit;
	;;; find step from rhino location to hunter location if possible
	lvars rpoint,
		  rx=front(rpoint),ry=back(rpoint),
		  hx,hy,dx,dy,x,y,hit=false,change,char,
		  vis=visible(hx,hy,rx,ry);
	if vis then
		;;; get new coordinates in single step, then check if clear
		sign(hx-rx) -> dx; sign(hy-ry) -> dy;
		ry + dy -> y;
		rx + dx -> x;
		terrainmap(x,y) -> char;
		if char /== treechar and char /== `C` and char /== `R` then
			;;; check if illegal diagonal move
			if dy /== 0 and dx /== 0
			and terrainmap(rx,ry+dy) == treechar
			and terrainmap(rx+dx,ry) == treechar then
				return	;;; can't move diagonally between trees
			else
			;;; move rhino
				x -> front(rpoint); y -> back(rpoint);
				setlocation(rx,ry,space,`\s`);
				setlocation(x,y,"R",`R`);
				if x == hx and y == hy then true -> hit endif;
			endif
		endif;
	endif;
enddefine;

define lconstant procedure distance(x1,y1,x2,y2);
	sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
enddefine;

define lconstant procedure pointinpic()->x->y;
	lvars x,y,;
	;;; find an unoccupied location, not on map boundary
	repeat
		random(XMAX fi_- 2) fi_+ 1 -> x;	;;; x between 2 and XMAX - 1
		random(YMAX fi_- 2) fi_+ 1 -> y;
		quitif(terrainmap(x,y)==`\s`)
	endrepeat;
enddefine;

define lconstant procedure setcamp() ->cx->cy;
	lvars cx,cy,cex=XMAX/2, cey=YMAX/2;
	;;; find a point not too close to centre
	repeat
		pointinpic()->cx->cy;
		quitif(distance(cx,cy,cex,cey) > XMAX/5)
	endrepeat;
	setlocation(cx,cy,"C",`C`);
enddefine;

define lconstant procedure sethunter(cx,cy) ->hx->hy;
	lvars hx,hy,cx,cy;
	;;; find a location of hunter far enough from camp
	repeat
		pointinpic()->hx->hy;
	quitif(distance(hx,hy,cx,cy) > (XMAX/3))
	endrepeat;
	setlocation(hx,hy,"H",`H`);
enddefine;

define lconstant procedure getrhinos(num) -> places;
	;;; don't draw on screen if draw is false - just return list of points
	lvars n=0,x,y,num,places=[];
	until n == num do
		pointinpic()->x->y;
		n fi_+ 1 -> n;
		conspair(x,y) :: places -> places;
		setlocation(x,y,if debugging then "R" else false endif,`R`)
	enduntil
enddefine;

define lconstant procedure settrees(rhinos);
	lvars x,y,rhinos,numtrees,treeratio;
	newpicture(XMAX,YMAX);			;;; set new turtle picture - used VED
	false -> vedwriteable;
	vedputmessage(nullstring);
	fast_for x to XMAX do
		setlocation(x,1,treeword,treechar);
	endfast_for;
	fast_for x to XMAX do
		setlocation(x,YMAX,treeword,treechar)
	endfast_for;
	fast_for y from 2 to YMAX fi_- 1 do
		setlocation(1,y,treeword,treechar)
	endfast_for;
	fast_for y from 2 to YMAX fi_- 1 do
		setlocation(XMAX,y,treeword,treechar)
	endfast_for;
	;;; How many trees? Get more when there are more rhinos, but not too many
	min(round(XMAX*YMAX/6),rhinos * TREEFACTOR) -> numtrees;
	max(numtrees,150) -> numtrees;			;;; and at least 150
	;;; how many locations per 10,000 should be trees?
	round(10000*numtrees/((XMAX-2)*(YMAX-2))) -> treeratio;
	;;; now insert spaces or trees into array
	fast_for x from 2 to XMAX-1 do
		fast_for y from 2 to YMAX-1 do
			if random(10000) fi_> treeratio then
				`\s` -> terrainmap(x,y)
			else
				setlocation(x,y,treeword,treechar);
			endif;
		endfast_for
	endfast_for;
	sysflush(popdevraw);
enddefine;


vars restartplay;	;;; defined in play1
vars procedure rhinorefresh; ;;; defined below

define  lconstant procedure getmove(hx,hy) -> (x, y);
	lvars hx,hy,dx,dy,char,x,y;
	repeat
		rawcharin() -> char;
		if char == `.` then restartplay();
		elseif char == `0` then interrupt()
		else
			lvars proc = vedgetproctable(char);
			if proc == ved_timed_esc then
				rhinorefresh();
				nextloop();
			elseif proc == vedcharup then
				0,1
			elseif proc == vedcharupright then
				1,1
			elseif proc == vedcharright then
				1, 0
			elseif proc == vedchardownright then
				1, -1
			elseif proc == vedchardown then
				0, -1
			elseif proc == vedchardownleft then
				-1, -1
			elseif proc == vedcharleft then
				-1, 0
			elseif proc == vedcharupleft then
				-1, 1
			else
				mishap('unrecognized key', [^proc])
			endif -> (dx, dy);
			hx + dx -> x; hy + dy -> y;
		quitif(terrainmap(x,y) /== treechar)
		endif;
	endrepeat;
	setlocation(hx,hy,space,`\s`);
	setlocation(x,y,"H",`H`);
enddefine;


define lconstant procedure play1(rhinos) -> win;
	lvars hx,hy,cx,cy, rhinos, win=true,
		rhinoplaces, point, hit;

	define restartplay;
		false;  ;;; result for win
		exitfrom(play1)
	enddefine;


	settrees(rhinos);
	setcamp() ->cx->cy;
	sethunter(cx,cy) -> hx -> hy;
	getrhinos(rhinos) -> rhinoplaces;
	vedputmessage(rhinos >< rhinomessage);
	repeat 3 times
		vedwiggle(YMAX-cy+1,cx);
		vedwiggle(YMAX-hy+1,hx)
	endrepeat;
	;;; now get moves repeatedly and display result
	repeat
		"H" -> picture(hx,hy); ;;; set cursor at hunter
		getmove(hx,hy) -> (hx, hy);
		if hx==cx and hy==cy then true -> win; return endif;
		for point in rhinoplaces do
			trystep(point,hx,hy)->hit;
			if hit then restartplay(); return endif
		endfor;
	endrepeat;
enddefine;


define play(rhinos);
	lvars rhinos,win,ans,message;
	dlocal vedstartwindow=24, popturtlefile=RHINOFILE;

	define dlocal interrupt;
		chainfrom(play,
					procedure;
						if vedcurrent = RHINOFILE then ved_q() endif;
						unless vedediting then vedscreenreset() endunless
					endprocedure)
	enddefine;

	
	define dlocal rhinorefresh();
		vedrefresh();
		vedputmessage(rhinos >< rhinomessage);
	enddefine;


	;;; next bit to enable rhino to be invoked from outside ved
	unless vedediting then
		play(%rhinos%)<>interrupt -> vedprocesstrap;
		popval([ved ^popturtlefile]);
		return;
	endunless;
	identfn -> vedprocesstrap;

	repeat
		play1(rhinos)-> win;
		unless win then
		procedure();
			vars vedwindowlength=16;
			ved_clear();
			vedscreencontrol(vvedscreenclear);
			pr(munchstring);
			false -> vedprintingdone;
			rhinorefresh();
		endprocedure();
		endunless;
		if win then
			rhinos fi_+ 1 -> rhinos;
			'WELL DONE - '
		else 'BAD LUCK - '
		endif -> message;
		repeat
			vedputmessage(message >< rhinos >< ' rhinos now. Play again? y/n');
			rawcharin() -> ans;
		quitif(strmember(ans,'ynYN'))
		endrepeat;
	quitif(strmember(ans,'nN'));
	endrepeat;
	interrupt();
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 20 1997 	
	Changed to determine ved key via vedgetproctable.
 */
