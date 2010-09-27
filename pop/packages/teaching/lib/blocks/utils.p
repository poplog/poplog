/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 |  File:           $usepop/master/C.all/lib/lib/blocks/utils.p
 |  Purpose:        utilities for a blocks demo
 |  Author:         Roger Evans (see revisions)
 |  Documentation:  TEACH * BLOCKS (only roughly relevant)
 |  Related Files:  other files in $usepop/pop/lib/lib/blocks,
 |					also $usepop/pop/lib/demo/mkblocks (also VMS version)
 |					LIB * FACETS
 */

vars vp handle_err num res Exit_proc locof;
vars trylastblock, lastblock; false ->> trylastblock-> lastblock;

define preprocess(text);
	vars x,y;
	if text matches [pick up ??y] then
		[pick ^^y] -> text;
	endif;
	if text matches [put down ??y] then
		[put ^^y] ->text;
	endif;
	if text matches [??x of ??y] then
		[^^x ^^y] -> text;
	endif;
	if text matches [let go ??y] then
		[let ^^y] -> text;
	endif;
	if text matches [??x ?y:isinteger] then
		y -> num; x -> text;
	else 5 -> num;
	endif;
	text;
enddefine;

vars one_off;

define 4 ===> x;
	Vcl(17); Vcl(18);
	rawoutflush();
	if x.islist then pr(hd(x))
	else handle_err(x);
	endif;
	rawoutflush();
	clearstack();
	exitfrom(one_off);
enddefine;

define 4 ====> x;
	false -> lastblock;
	x ===>
enddefine;

define myreadline;
	Vcl(22);Vcl(21);
	rawoutflush();
	pr('(if you need help type "help")');
	Vcl(19);Vcl(20);
	rawoutflush();
	if dup(readline()) == termin then Exit_proc() endif;
enddefine;

vars lexicon;	;;; see blocks.p
define checkword(w);
	vars m;
	for m in lexicon do
		if member(w,tl(m)) then return; endif;
	endfor;
	[%'I\'m afraid I don\'t know the word \"' >< w >< '\".'%] ===>
enddefine;


define one_off();
	vars s text cucharin cucharout;
	charin -> cucharin; charout -> cucharout;
	if (vp(preprocess((myreadline() ->> text))) ->> s) then
		.res(s);
		trylastblock -> lastblock;
		[%''%] ===>
	else
		;;; parse failed - was there an unknown word?
		applist(text,checkword);
		;;; checkword returns only if all words recognised
		[%'I don\'t understand that'%] ===>
	endif;
enddefine;


define blocks;
	repeat forever .one_off;rawoutflush(); endrepeat;
enddefine;


define det_proc(list);
	vars box ans;
	[] -> ans;
	forevery list do [^^ans ^box] -> ans endforevery;
	if ans == [] then
		[%'I can\'t find one'%] ====>
	endif;
	ans;
enddefine;

define the_proc(list);
	vars reff; det_proc(list) -> reff;
	if length(reff) == 1 then hd(reff)->>trylastblock;
	else [%'I don\'t know which one you mean'%] ====>
	endif;
enddefine;

define a_proc(list);
	hd(det_proc(list)) ->> trylastblock;
enddefine;


define getlastblock;
	unless dup(lastblock) do
		[%'I don\'t know which thing you are talking about'%] ===>
	endunless;
enddefine;

define to_proc(box);
	vars x xs;
	unless present([^box isblock]) then [%'I don\'t know where you mean'%] ===> endunless;
	lookup([^box at ?x =]);
	lookup([size ^box ?xs =]);
	xs//2 -> xs; .erase;
	[%Raise(%13%),Across(%xs + x - Wx%),Down%]
enddefine;

define drop_proc(box);
	if box == "default"
	or box == holding then
		Letgo()
	else
		[%'I\'m not holding it'%] ===>
	endif;
enddefine;

define put_proc(box);
	Down(); drop_proc(box);
enddefine;

define go_proc(A1,A2,A3);
	if A1 then .A1 endif;
	if A2 then .A2 endif;
	if A3 then .A3 endif;
enddefine;

define get_proc(box);
	if box == "default" then [%'I don\'t know what to get'%] ====> endif;
	unless present([^box isblock]) then [%'I can\'t'%] ===> endunless;
	if holding then Letgo() endif;
	(partapply(go_proc,to_proc(box))).apply; Hold();
	unless box = holding then Letgo(); [%'I can\'t'%] ===> endunless;
enddefine;

define pick_proc(box);
	if box == "default" then [%'I don\'t know what to get'%] ====> endif;
	unless present([^box isblock]) then [%'I can\'t'%] ===> endunless;
	unless box = holding then
		get_proc(box);
	endunless;
	Raise(13);
enddefine;

define move_proc(box,loc);
	unless box == "default" then get_proc(box) endunless;
	;;; had to delay facet 'locof' evaluation - else hand is in wrong place!
	(partapply(go_proc,locof(loc))).apply;
enddefine;

define open_proc(box);
	unless box == "default" or box == "hand" then [%'I can\'t'%] ===> endunless;
	Letgo();
enddefine;

define close_proc(box);
	unless box == "default" or box == "hand" then [%'I can\'t'%] ===> endunless;
	Hold();
	holding -> lastblock;
enddefine;

define Exit_proc();
	clearstack();
	Vcl(17); Vcl(18); rawoutflush();nl(5); 'Goodbye\n'.pr;
	interrupt();
enddefine;

define Help;
	Vpage();
	rawoutflush();
	'N A T U R A L   L A N G U A G E   U N D E R S T A N D I N G\n'.pr;
	'-----------------------------------------------------------\n\n\n'.pr;
	'This is a demonstration of a program which understands VERY SIMPLE English.\n'.pr;
	'\nIt is a simulated robot hand which can pick up and move around toy\n'.pr;
	'blocks of different colours and sizes\n\n'.pr;
	'You type in the commands you want it to execute, and it tries to\n'.pr;
	'do them on the screen.\n\n'.pr;
	'The blocks are red,yellow,blue and green - little ones are "painted"\n'.pr;
	'r y g b, big ones are R Y G B.\n\n'.pr;
	'The words and phrases you can use are as follows : \n'.pr;
	'   pick up, put down, let go of, drop, get, go to, move, open, close,\n'.pr;
	'   go up N, go down N, go left N, go right N, (where N is a number)\n'.pr;
	'   the a an red yellow blue green block box\n'.pr;
	'   brick thing hand it big small little large\n\n'.pr;
	'If you use words it doesn\'t know it will say so.\n\n'.pr;
	'Please press the key marked "return" to start'.pr;
	requestline(' ');
	refresh(Wx,Wy);
enddefine;

vars translations;

[ [%'cannot move through pictureframe','I can\'t do that'%]
  [%'Already holding','I\'m already holding it'%]
  [%'can\'t open claw','There\'s not room to open the hand'%]
] -> translations;

compile('$usepop/pop/lib/lib/blocks/fits.p');

define handle_err(x);
	vars y;
	if translations matches [== [^x ?y] ==] then
		pr(y)
	elseif x fits 'cannot move through *' then
		pr('There\'s something in the way')
	endif;
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 8 1987 fixed header information
 */
