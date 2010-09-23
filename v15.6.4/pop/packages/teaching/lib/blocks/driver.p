/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 *  File:           C.all/lib/lib/blocks/driver.p
 *  Purpose:        load the msblocks demo
 *  Author:         Roger Evans 1983 ?(see revisions)
 *  Documentation:  TEACH * BLOCKS (only roughly relevant)
 *  Related Files:  LIB * HAND , files in $usepop/pop/lib/lib/blocks/
 *					also $usepop/pop/lib/demo/mkblocks (or VMS version)
 *					LIB * FACETS
 */

interrupt; identfn -> interrupt;    ;;; prevent attempt to refresh screen
uses hand;
-> interrupt;

vars refresh;
vars lexicon;

load $usepop/pop/lib/lib/blocks/utils.p
load $usepop/pop/lib/lib/blocks/blocks.p

vars lower raise op down left right hold letgo putontable;

define refresh(X,Y);
	vars m c sx sy ox oy;
	Vpage();
	showdata();
	if holding then lookup([colour ^holding ?c]);
					lookup([size ^holding ?sx ?sy]);
					lookup([held ?ox ?oy]);
					drawbox(c,Wx-ox,Wy-oy,sx,sy);
	endif;
	drawhand(X,Y);
	for m from 15 by 1 to 21 do Vcl(m) endfor;
	rawcharout(0);
enddefine;

define reset;
	vars m;
	gravon;
	[[box1 isblock][box1 at 40 1]
		[colour box1 R] [hue box1 red] [size box1 8 3] [big box1]
	 [box2 isblock][box2 at 20 1]
		[colour box2 B] [hue box2 blue] [size box2 7 3] [big box2]
	 [box3 isblock][box3 at 22 4]
		[colour box3 r] [hue box3 red] [size box3 4 2] [little box3]
	 [box4 isblock][box4 at 60 1]
		[colour box4 Y] [hue box4 yellow] [size box4 10 1] [little box4] [big box4]
	 [box5 isblock][box5 at 58 2]
		[colour box5 b] [hue box5 blue] [size box5 5 4] [little box5]
	 [box6 isblock][box6 at 22 6]
		[colour box6 g] [hue box6 green] [size box6 3 3] [little box6]
	 [box7 isblock][box7 at 55 6]
		[colour box7 G] [hue box7 green] [size box7 15 2] [big box7]
	 [hand ishand]
	 [table istable]
	] -> database;
	newpicture(75,15);
	false -> holding;
	refresh(27,8);
enddefine;

identfn -> popsetpop;
charin ->cucharin;
charout -> cucharout;


define start; .reset.gravity.blocks; enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov  9 1988 fixed previous fix to header
--- Aaron Sloman, Sep  8 1987 declared lexicon, fixed header
 */
