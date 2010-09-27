/*  --- Copyright University of Sussex 1996.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/hand.p
 >  Purpose:        active hand for blocks library.
 >  Author:         Jon Cunningham??? (see revisions)
 >  Documentation:
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; uses lib active. Works only on visual 20 terminal.
uses popturtlelib

vars Vpoint;
unless isprocedure(Vpoint) then
	apply(procedure;
	vars cucharout; erase -> cucharout;;    ;;; supppress warning message
	popval([lib active;])
	endprocedure);
endunless;

;;;  User macros

define macro lower x;   x, ".", "Lower", ";"   enddefine;

define macro raise x;   x, ".", "Raise", ";"   enddefine;

define macro up;        13, ".","Raise", ";"   enddefine;

define macro right x;   x, ".", "Across", ";"  enddefine;

define macro left x;    "-", x, ".", "Across", ";" enddefine;

define macro down;      ".","Down",";"     enddefine;

define macro hold;      ".","Hold",";"     enddefine;

define macro letgo;     ".","Letgo",";"    enddefine;

define macro putontable;".","Findspace",";"enddefine;

define macro restart;   ".", "demodata", ".", "Starthand", ";" enddefine;

vars isgrave gravity; false -> isgrave;

define macro gravon;    true -> isgrave; .gravity; enddefine;

define macro gravoff;   false -> isgrave;          enddefine;

define macro getabove c;
	dl([Getabove(% if c = "^" then .readitem else """,c,"""endif %);])
enddefine;

define macro stepacross x;
	dl([if ^x<0 then repeat - ^x times Across(-1) endrepeat
			else repeat ^x times Across(1) endrepeat endif;])
enddefine;

define macro commands;
	'Commands are: \n    up  down  hold  letgo  gravon  gravoff\
	putontable  restart  holding=>\
	raise n  lower n  left n  right n\
	getabove c  (where c is the colour of the block eg # + etc)\
type CTRL-C to redraw picture\n',".","pr",";"
enddefine;


define 4 ===> x;
	;;; for error messages
	;;; Scroll();
	x =>
enddefine;

vars holding, Wx, Wy;
false->holding;

define drawclaw;
	if holding then "H"->picture(Wx,Wy)
	else   "/"->picture(Wx-1,Wy);
		"-"->picture(Wx,Wy);
		"\"->picture(Wx+1,Wy)
	endif
enddefine;

define drawhand(atx,aty);
	"-" ->> picture(atx-1,15) ->> picture(atx,15) -> picture(atx+1,15);
	jumpto(atx,14);
	"|"->paint;
	drawto(atx,aty);
	atx->Wx;
	aty->Wy;
	.drawclaw
enddefine;

define clearclaw;
	space->picture(Wx,Wy);
	unless holding then
		space->>picture(Wx-1,Wy) ->picture(Wx+1,Wy)
	endunless
enddefine;

define drawbox(c,x,y,zbx,zby);
	vars h,i;
	for h from x to zbx+x-1 do
		for i from y to zby+y-1 do
			c -> picture(h,i);
		endfor;
	endfor;
enddefine;

define drawthebox(p);
	vars ox,oy,sx,sy;
	if holding then
		lookup([size ^holding ?sx ?sy]);
		lookup([held ?ox ?oy]);
		if p=space then space->paint else lookup([colour ^holding ?paint])
		endif;
		drawbox(paint,Wx-ox,Wy-oy,sx,sy)
	endif
enddefine;


define overlaps x1 y1 w1 h1 x2 y2 w2 h2;
	max(x1,x2) < min(x1+w1,x2+w2)
		and
	max(y1,y2) < min(y1+h1,y2+h2)
enddefine;

define newrect(x,y,w,h,ac,upp);
	if ac < 0 then x + ac else x endif;
	if upp < 0 then y + upp else y endif;
	w + abs(ac);
	h + abs(upp);
enddefine;

define inside(boxlist,listbox);
	vars xframe,yframe,wframe,hframe,x,y,w,h,box;
	listbox.dl->hframe->wframe->yframe->xframe;
	until boxlist=[] do
		boxlist.hd->box;
		boxlist.tl->boxlist;
		box.dl->h->w->y->x;
		if xframe>x or yframe>y or xframe+wframe<x+w or yframe+hframe<y+h
		then return(false) endif;
	enduntil;
	true
enddefine;

define badpath(ac,upp);
	vars shape,sx,sy,ox,oy,b,shtemp;
	if holding then
		lookup([size ^holding ?sx ?sy]);
		lookup([held ?ox ?oy]);
		[%[% newrect(Wx,Wy,1,15-Wy,ac,upp) %],
			 [% newrect(Wx-2,15,5,1,ac,upp) %],
			 [% newrect(Wx-ox,Wy-oy,sx,sy,ac,upp)%]%]->shape
	else [%[% newrect(Wx,Wy+1,1,14-Wy,ac,upp)%],
			 [% newrect(Wx-2,15,5,1,ac,upp) %],
			 [% newrect(Wx-1,Wy,3,1,ac,upp)%] %]->shape
	endif;
	if not(inside(shape,[1 1 75 28])) then
		'cannot move through pictureframe' ===>;
		"pictureframe"
	else
		foreach [?b at ?ox ?oy] do
			lookup([size ^b ?sx ?sy]);
			shape->shtemp;
			if member(true,[%
						 until shtemp=[] do
							 overlaps(shtemp.hd.dl,ox,oy,sx,sy);
							 shtemp.tl->shtemp
						 enduntil%])
			then    ('cannot move through ' >< b) ===>;
				return(b)
			endif;
		endforeach;
		false
	endif
enddefine;

vars Raise;
define Lower(a);
	if a<0 then Raise(-a);
	elseif not(badpath(0,-a)) then
		drawthebox(space);
		.clearclaw;
		"|"->paint;
		jumpto(Wx,Wy);
		if Wy-a<1 then 1->Wy
		else Wy-a->Wy
		endif;
		drawto(Wx,Wy);
		.drawclaw;
		drawthebox(undef)
	endif
enddefine;

define Raise(a);
	if a<0 then Lower(-a)
	elseif not(badpath(0,a)) then
		drawthebox(space);
		space->paint;
		.clearclaw;
		jumpto(Wx,Wy);
		if Wy+a>14 then 14->Wy
		else Wy+a->Wy
		endif;
		drawto(Wx,Wy);
		.drawclaw;
		drawthebox(undef)
	endif
enddefine;

define Across(x);
	vars newx;
	unless badpath(x,0) then
		Wx+x->newx;
		drawthebox(space);
		.clearclaw;
		jumpto(Wx,Wy);
		space -> paint;
		drawto(Wx,15);
		jumpto(Wx-2,15);
		drawto(Wx+2,15);
		jumpto(Wx,Wy);
		drawto(newx,Wy);
		drawhand(newx,Wy);
		drawthebox(undef);
		.gravity;
	endunless
enddefine;

define Down;
	vars x,box,y,lx,rx,ox,sx,sy,d;
	1 -> d;
	if holding then
		lookup([size ^holding ?sx =]);
		lookup([held ?ox =]);
		Wx-ox+sx-1->rx;
		Wx-ox->lx
	else   Wx-1->lx;Wx+1->rx
	endif;
	foreach [?box at ?x ?y] do
		unless x > rx then
			lookup([size ^box ?sx ?sy]);
			unless x+sx <= lx or y+sy <= d then
				y+sy->d
			endunless
		endunless
	endforeach;
	if holding then lookup([size ^holding = ?sy]); d+sy->d endif;
	Lower(Wy-d)
enddefine;

define Hold;
	vars box,x,y,sx,sy;
	if holding then 'Already holding'===>;
	else
		foreach [?box at ?x ?y] do
			unless x>Wx do
				lookup([size ^box ?sx ?sy]);
				if y+sy=Wy and x+sx>Wx then
					.clearclaw;
					box->holding;
					remove([^box at ^x ^y]);
					add([held %Wx-x,Wy-y%]);
					.drawclaw;
					return
				endif
			endunless
		endforeach;
		'nothing to hold'===>;
	endif
enddefine;

define Letgo;
	if not(holding) then 'nothing held'===>;
	elseif picture(Wx-1,Wy)/=space
			or picture(Wx+1,Wy)/=space
	then 'can\'t open claw'===>;
	else
		lookup([held ?ox ?oy]);
		remove([held = =]);
		add([^holding at %Wx-ox,Wy-oy%]);
		false->holding;
		.drawclaw;
		.gravity;
	endif
enddefine;

define Getabove(c);
	vars b,x,sx;
	if present([colour ?b ^c]) then
		if holding==b then ('holding ' >< b ><' coloured '>< c)===>;
		else
			unless Wy=14 then up endunless;
			lookup([^b at ?x =]);
			lookup([size ^b ?sx =]);
			sx//2->sx; .erase;
			Across(x+sx-Wx)
		endif
	else ('nothing coloured '>< c) ===>;
	endif
enddefine;

define Findspace;
	vars sx,p,x,b,rx,tx,done;
	if holding then
		up;
		lookup([size ^holding ?sx =]);
		sx-1->sx;
		for (false->done;1->>p->rx) step rx->p till done do
			true->done;
			foreach [?b at ?x =] do
				if x >= p then
					unless p+sx<x then
						false->done;
						lookup([size ^b ?tx =]);
						if x+tx>rx then x+tx->rx endif
					endunless
				else lookup([size ^b ?tx =]);
					unless x+tx<=p then
						false->done;
						if x+tx>rx then x+tx->rx endif
					endunless
				endif
			endforeach;
			if done and (lookup([held ?tx =]); p+tx<3) then false->done;
				3-tx->rx endif
		endfor;
		Across(p+tx-Wx);
		down;
	else 'not holding' ===>;
	endif
enddefine;

define balanced(x,y,sx);
	vars yt llim rlim xmid;
	unless y=1 or x=1 or x+sx>75 then
		y-1 -> yt;  x -> llim;  x+sx-1 -> rlim;
		while (picture(llim,yt) == space) and (llim < rlim) do
			llim+1 -> llim
		endwhile;
		while (picture(rlim,yt) == space) and (llim <= rlim) do
			rlim-1 -> rlim
		endwhile;
		x+(sx-1)/2 -> xmid;
		if rlim < llim then 0
		elseif llim > xmid and picture(x-1,yt) == space then -1
		elseif rlim < xmid and picture(x+sx,yt) == space then 1
		else return(true)
		endif;
		false;
	else
		true;
	endunless;
enddefine;

define gravity;
	vars box x y sx sy p dir ax ex moved globalmoved;
	if isgrave then
		false -> globalmoved;
		foreach [?box at ?x ?y] do
			false -> moved;
			lookup([size ^box ?sx ?sy]);
			lookup([colour ^box ?p]);
			until balanced(x,y,sx) do
				-> dir; true ->> globalmoved -> moved;
				if dir = 0 then
					drawbox(space,x,y+sy-1,sx,1);
					y-1 -> y;
					drawbox(p,x,y,sx,1);
				else
					if dir > 0 then x; x+sx else x+sx-1; x-1 endif
					-> ax -> ex;
					drawbox(space,ex,y,1,sy);
					drawbox(p,ax,y,1,sy);
					x+dir -> x;
				endif;
			enduntil;
			if moved then
				remove([^box at = =]);
				add([^box at ^x ^y]);
			endif;
		endforeach;
		if globalmoved then gravity() endif;
	endif;
enddefine;

define showdata;
	vars database x y b c zbx zby;
	while [?b at ?x ?y].present do
		lookup([colour ^b ?c]);
		lookup([size ^b ?zbx ?zby]);
		drawbox(c,x,y,zbx,zby);
		remove([^b at ^x ^y])
	endwhile
enddefine;

define demodata;
	false -> holding;
	[[box1 at 40 1] [colour box1 +] [size box1 8 3]
	 [box2 at 20 1] [colour box2 #] [size box2 7 3]
	 [box3 at 22 4] [colour box3 *] [size box3 4 2]
	 [box4 at 60 1] [colour box4 !] [size box4 10 1]
	]->database
enddefine;

define Starthand;
	newpicture(75,15);
	.showdata;
	drawhand(22,8);
enddefine;

'\nFor commands type:    commands\nBegin with:           restart\
\nTry the commands:     restart getabove *  down hold putontable\n'.pr;
interrupt();


/* --- Revision History ---------------------------------------------------
--- John Williams, Jan  3 1996
		Moved from C.all/lib/lib to C.all/lib/obsolete
--- Robert John Duncan, Oct 11 1994
		Added popturtlelib
 */
