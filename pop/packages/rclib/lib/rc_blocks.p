/*  --- Copyright University of Birmingham 2000.  All rights reserved. ---------
 >  File:           $poplocal/local/rclib/lib/rc_blocks.p
 >		based on    $poplocal/local/lib/msblocks.p
 >  Purpose:        A SHRDLU like blocks world program
 >  Author:         David Hogg 1983, Richard Bignell, Oct 20 1986 (see revisions)
 >  Documentation:  TEACH * MSDEMO, TEACH * MSBLOCKS
 >  Related Files:  LIB * TPARSE, LIB * FACETS, LIB * RC_HAND
 */

/*
A version of LIB * MSBLOCKS modified to use rc_showtree to show parse trees.
A.Sloman. Dec. 1997
*/


/*
;;; compile then
blocks_go();

*/

/*
define --- Prerequisites
*/

global vars procedure do_pause; 	;;; defined below, used in rc_hand.p

global vars rcdebuginterrupt=vedinterrupt;
;;; vars rcdebuginterrupt=false;;


uses rc_linepic
uses rc_mousepic;
include xt_constants.ph;

uses turtle
uses rclib

uses rc_hand;

uses tparse;   ;;; uses LIB TPARSE rather than LIB GRAMMAR to get all parses

uses rc_showtree;

;;; Unfortunately facets redefines readpattern
;;; applist([readpattern where !], sysunprotect);
;;; cancel readpattern;
uses facets
;;; cancel readpattern, where, !;
;;; uses readpattern;
;;; applist([readpattern where !], sysprotect);

resetfacets();


/*
define --- Global variables
*/

global vars
	;;; flag to indicate in gblocks saved image. See mkgblocks
	blocks_saved_image = false,

	;;; flag for termination
	blocks_terminate = false,	

	;;; Windows for graphics
	blocks_win = false,
	rc_window = false,
	parse_win = false,

	;;; A picture object
	the_hand = false,	;;; see LIB RC_HAND

	;;; Some "live" picture objects
	pause_button = false,
	quit_button = false,

	;;; scale for rc_graphic picture
	X_scale = 8,
	Y_scale = 8,	;;; negated in picture

	world_width = 75,
	world_height = 35,
	bottom_margin = 25,

	;;; locations etc for windows
	blocks_winx = 400,
	blocks_winy = 20,
	blocks_win_width = world_width * X_scale,
	blocks_win_height = world_height * Y_scale + bottom_margin,
	;;; xorigin, yorigin, xscale, yscale
	blocks_win_frame = {1 ^(world_height * Y_scale) ^X_scale ^(-Y_scale)},

	parse_winx = 400,
	parse_winy = blocks_winy + blocks_win_height + 30,
	parse_win_width = 800,
	parse_win_height = 600,
;

vars chatty = true;

/*
define --- Button facilities
*/

define :class control_button;
	is rc_selectable rc_linepic;
	slot rc_button_up_handlers = {^false ^false ^false};
	slot rc_button_down_handlers = { block_button_1_down ^false ^false};
	slot rc_drag_handlers = {^false ^false ^false};
	slot rc_move_handler = false;
	slot rc_keypress_handler = false;
	slot block_button_active = false;
enddefine;

global vars blocks_wakeup = false;

define :method block_button_1_down(p:control_button, x, y, modifiers);
/*
	[block_button (rc_coords(p) x ^x y ^y ]=>
	if parse_win then
		[parse %parse_win.rc_window_frame , rc_xorigin %]=>
	endif;
	[blocks %blocks_win.rc_window_frame , rc_xorigin%]=>
*/
	if blocks_wakeup then
		;;; button should not be visible. Do nothing
	elseif block_button_active(p) then
		true -> blocks_wakeup;
		;;; remove it
		;;; rc_defer_apply(rc_undraw_linepic(%p%));
	endif;
enddefine;

define :method window_button_1_down(p:rc_window_object, x, y, modifiers);
	true -> blocks_wakeup;
	;;; rc_defer_apply(procedure(); 'Please Click on continue button' => endprocedure);
	return();
	;;; stuff for debugging
	[current ^rc_current_window_object ^x ^y] =>
	[active ^rc_active_window_object ^x ^y] =>
	if parse_win then
		[parse %parse_win.rc_window_frame , rc_xorigin %]=>
	endif;
	[blocks %blocks_win.rc_window_frame , rc_xorigin%]=>
	[p ^p x ^x y ^y ]=>
	if parse_win then
		[parse %parse_win.rc_window_frame , rc_xorigin %]=>
	endif;
enddefine;

global vars procedure do_quit;	;;; defined below

define :method quit_button_1_down(p:control_button, x, y, modifiers);
	true -> blocks_wakeup;
	;;; remove windows
	rc_defer_apply(do_quit);
enddefine;

/*

define :instance butt1:block_button;
	rc_picx = 4;
	rc_picy = 10;
	rc_pic_strings = [{0 0 'HELLO'}];
enddefine;

rc_draw_linepic(butt1);
rc_draw_linepic(pause_button);
pause_button.rc_coords =>
butt1.rc_coords =>
rc_drawline(4,4.2,10,10);

rc_mousepic(blocks_win);
rc_add_pic_to_window(butt1, blocks_win, true);

[] -> rc_window_contents(blocks_win) =>
*/

lvars do_pause_bell = true, click_counter = 0;

;;; Utility, used in rc_hand
define do_pause();
	;;; Pausing procedure. Ring bell only first time

	if do_pause_bell then
		vedscreenbell();
		false -> do_pause_bell
	endif;

	if click_counter < 6 then
		;;; Remind user the the first few times only.
		'Click on CONTINUE when ready.' =>	
		click_counter + 1 -> click_counter;
	endif;

	vedscr_flush_output();
	blocks_win -> rc_current_window_object;
	
	;;; Now wait for user to click on Continue button.
	;;; this will set blocks_wakeup true.
	dlocal blocks_wakeup = false;
	true -> block_button_active(pause_button);
	blocks_win -> rc_current_window_object;
	rc_sync_display();
	rc_draw_linepic(pause_button);
	rc_sync_display();

	lvars oldint = interrupt;
	define dlocal interrupt;
		if parse_win then
			[parse %parse_win.rc_window_frame , rc_xorigin %]=>
		endif;
		[blocks %blocks_win.rc_window_frame , rc_xorigin%]=>
		true -> blocks_wakeup;
		oldint -> interrupt;
		exitto(do_pause);
	enddefine;

	dlocal rc_sole_active_widget = rc_widget(blocks_win);

	until blocks_wakeup do
		;;; syssleep(15);
		;;; [^rc_current_window_object frame ^rc_xorigin ^rc_yorigin]=>
		syshibernate();
		blocks_win -> rc_current_window_object;
	enduntil;

	unless blocks_terminate then
		blocks_win -> rc_current_window_object;
		syssleep(rc_window_sync_time);
	endunless;

	;;; If pausing terminated by return then just do:
	;;; vedscr_read_ascii() ->;
	;;; Another possibility
	;;; pui_popuptool('PAUSING', [Continue], {200 20}, false)-> ;
	;;; Alternative variants, away from Birmingham
	;;; pop_ui_message('PAUSING', true, false) ;
	;;;pop_ui_confirm('PAUSING', [Continue], 1, true, false) -> ;
enddefine;

/*
define --- Grammar, lexicon and parsing utilities
*/


vars blocks_grammar blocks_lexicon;

[
	[s [vp] [question]]
	[question [wh_loc vbe np] [wh_thing vbe pp]
		[wh_select snp vbe pp] [vbe np pp]]
	[vp [v np pp] [v np onto_pp]]
	[onto_pp [onto_prep np]]
	[np [pn] [det snp] [det snp pp]]
	[snp [noun] [ap noun]]
	[ap [adj] [adj ap]]
	[pp [prep np]]
] -> blocks_grammar;

[
	[noun       block box table one]
	[pn         it]
	[v          put move pickup putdown]
	[vbe        is]
	[wh_loc     where]
	[wh_thing    what]
	[wh_select    which]
	[adj        white red blue green big small large little]
	[prep       on above over] ;;; (in at to under by) removed since
									;;; they are handled incorrectly.
	[onto_prep  onto]
	[det        each every the a some]
] -> blocks_lexicon;

setup(blocks_grammar,blocks_lexicon);


/*
define --- Facets library for meanings
*/

;;; First a couple of utility procedures for facets

define lconstant replace(x,y,l);

	maplist(l,
		procedure(el);
			if el.ispair then
				replace(x,y,el)
			elseif el = x then
				y
			else
				el
			endif
	endprocedure)
enddefine;


define lconstant unique(pp);
	replace("B","A",replace("A",gensym("A"),pp));
enddefine;


facet MEANING pred detr;

semrule sentrule [s ?phrase]
   MEANING(phrase) -> MEANING(self);
endsemrule;

semrule questrule1 [question [wh_thing =] [vbe =] ?pp]
	[find all suchthat ^(detr(pp)) ^(pred(pp))] -> MEANING(self);
endsemrule;

semrule questrule2 [question [wh_loc =] [vbe =] ?np]
	[WHERE ^(detr(np)) ^(pred(np))] -> MEANING(self);
endsemrule;

semrule questrule3 [question [wh_select =] ?object [vbe =] ?location]
	[which ^(pred(object)) suchthat ^(detr(location))
			^(unique(pred(location)))] -> MEANING(self);
endsemrule;

semrule questrule4 [question [vbe =] ?object ?location]
	[QUERY ^(detr(object)) ^(pred(object)) suchthat
			^(detr(location)) ^(unique(pred(location)))] -> MEANING(self);
endsemrule;

semrule vprule [vp ?v ?np ?pp]
   [PUT ^(detr(np)) ^(pred(np)) on ^(detr(pp)) ^(tl(pred(pp)))]
   -> MEANING(self);
endsemrule;

semrule vp_ontorule [vp ?v ?np ?onto_pp]
   [PUT ^(detr(np)) ^(pred(np)) on ^(detr(onto_pp)) ^(tl(pred(onto_pp)))]
   -> MEANING(self);
endsemrule;

semrule pprule [pp ?prep ?np]
	detr(np) -> detr(self);
	pred(prep) :: pred(np) -> pred(self);
endsemrule;

semrule onto_pprule [onto_pp ?onto_prep ?np]
	detr(np) -> detr(self);
	pred(onto_prep) :: pred(np) -> pred(self);
endsemrule;

semrule nprule1 [np ?pn]
	"the" -> detr(self);
	[ [lastone ?A] ] -> pred(self);
endsemrule;

semrule nprule2 [np ?det ?snp]
	detr(det) -> detr(self);
	pred(snp) -> pred(self);
endsemrule;

semrule nprule3 [np ?det ?snp ?pp]
	detr(det) -> detr(self);
	pred(snp) <> unique(pred(pp)) -> pred(self);
endsemrule;

semrule snprule1 [snp ?noun] [%pred(noun)%] -> pred(self); endsemrule;

semrule snprule2 [snp ?ap ?noun] pred(noun) :: pred(ap) -> pred(self); endsemrule;

semrule aprule1 [ap ?adj] [%pred(adj)%] -> pred(self); endsemrule;

semrule aprule2 [ap ?adj ?ap] pred(adj) :: pred(ap) -> pred(self); endsemrule;

semrule SmallRedule [noun ?x:%member(%[block box one]%)%] [isa block ?A] -> pred(self); endsemrule;

semrule tablerule [noun ?x:%member(%[table]%)%] [isa table ?A] -> pred(self); endsemrule;

semrule adjrule1 [adj ?x:%member(%[big large]%)%]
	[size large ?A] -> pred(self);
endsemrule;

semrule adjrule2 [adj ?x:%member(%[small little]%)%]
	[size small ?A] -> pred(self);
endsemrule;

semrule adjrule3 [adj ?x:%member(%[red blue green white]%)%]
	[colour ^x ?A] -> pred(self);
endsemrule;


semrule adjrule4 [adj ?x] [= ^x ?A] -> pred(self); endsemrule;

semrule preprule [prep ?x] [on ?B ?A] -> pred(self); endsemrule;

semrule ontopreprule [onto_prep ?x] [on ?B ?A] -> pred(self); endsemrule;

semrule detrule [det ?x] x -> detr(self); endsemrule;

/*
define --- Hand utilities
*/


vars setupdata, picture ;

vars handdatabase;

define :class ms_block;
	is ms_handpic;
	slot ms_name;
enddefine;

define create_blocks();
	vars block blockx, blocky, col, width, height, the_block;
	foreach [?block at ?blockx ?blocky] do
		flush([^block is =]);	;;; get rid of old versions
		lookup([colour ^block ?col]);
		lookup([size ^block ?width ?height]);

	;;; Veddebug([create ^block ^col ^width ^height]);
	;;; ([create ^block ^col ^width ^height]) ==>

		instance ms_block;
			ms_name = block;
			rc_picx = blockx;
			rc_picy = blocky;
			rc_pic_lines =
				[WIDTH ^(abs(height*rc_yscale)) COLOUR ^(ms_colour_of(col))
					[{%0, height/2.0%} {%width, height/2.0%}]];
		endinstance -> the_block;

		add([^block is ^the_block]);
	endforeach;
enddefine;

vars procedure showdata;	;;; defined below


define handmoveblock(A,B) -> done;
	lvars A, B, done = true;

	dlocal database = handdatabase;

	unless Getabove(A) then
		'Cannot getabove ' >< A >< '. Try another command or restart.' =>
		false -> done;
		return;
	endunless;

	unless Down() then
		'Cannot go down. Try another command or restart.' =>
		false -> done; return;
	endunless;

	Hold();

	unless Raise(1) then
		'Cannot Raise, so let go. Try another command or restart.' =>
		Letgo();
		Raise(1) ->;
		false -> done; return;
	endunless;

	if B == "table" then
		unless Findspace() then
		'Cannot find space, so let go. Try another command or restart.' =>
			false -> done;
			Down() ->;
			Letgo();
			Raise(1) ->;
			return()
		endunless;
	else
		unless Getabove(B) then
		'Cannot get above ' >< B =>
		'So put down held block' =>
			false -> done;
			Down() ->;
			Letgo();
			Raise(1) ->;
			return;
		endunless;

		unless Down() then
			false -> done; return()
		endunless;
	endif;
	Letgo();
	unless Raise(1) then
		false -> done; return;
	endunless;
	true -> done;
	database -> handdatabase;
enddefine;


/*

define --- Blocks data

*/

define initdata();
	[[BigRed at 20 1] 	  [colour BigRed r] 	[size BigRed 8 6]
	 [SmallRed at 62 7]   [colour SmallRed r]	[size SmallRed 3 4]
	 [BigGreen at 20 7]   [colour BigGreen g]	[size BigGreen 8 6]
	 [SmallGreen at 40 1] [colour SmallGreen g] [size SmallGreen 3 4]
	 [BigBlue at 60 1]    [colour BigBlue b]	[size BigBlue 8 6]
	 [SmallBlue at 22 13] [colour SmallBlue b]	[size SmallBlue 3 4]
	]->> handdatabase -> database;

	;;; get the picture drawn
	create_blocks();

	database -> handdatabase;

	showdata();

	drawhand(rc_coords(the_hand));
	[
		[isa block BigRed] [colour red BigRed]   [size large BigRed]
		[isa block SmallRed] [colour red SmallRed]   [size small SmallRed]
		[isa block BigGreen] [colour green BigGreen] [size large BigGreen]
		[isa block SmallGreen] [colour green SmallGreen] [size small SmallGreen]
		[isa block BigBlue] [colour blue BigBlue]  [size large BigBlue]
		[isa block SmallBlue] [colour blue SmallBlue]  [size small SmallBlue]
		[isa table table]
		[on SmallBlue BigGreen]
		[on BigGreen BigRed]
		[on BigRed table]
		[on SmallGreen table]
		[on SmallRed BigBlue]
		[on BigBlue table]
		[graspable block]
	] -> database;
enddefine;


define moveblock(box, loc, moves) -> moves;
	flush([on ^box =]);
	add([on ^box ^loc]);
	[ ^^moves [move ^box ^loc] ] -> moves;
enddefine;


define cleartop(obj, moves) -> moves;
	vars box,loc;
	if present([on ?box ^obj]) then
		cleartop(box, moves) -> moves;
		foreach [isa block ?loc] do
			unless loc == box or present([protect ^loc])
				or present([on = ^loc]) then
				moveblock(box,loc, moves)-> moves;
				return
			endunless;
		endforeach;
		moveblock(box,"table", moves) -> moves;
	endif;
enddefine;


define planmove(X,Y) -> moves;
	lvars X,Y;
	vars obj database;
	;;; Local copy of database since this is only the planning phase
	[] -> moves;
	if present([on ^X ^Y]) then return endif;
	if allpresent([[isa ?obj ^X][graspable ?obj]]) then
		cleartop(X, moves) -> moves;
		add([protect ^X]);
		unless present([isa table ^Y]) then
			cleartop(Y, moves) -> moves;
		endunless;
		moveblock(X,Y,moves) -> moves;
		remove([protect ^X]);
	endif;
enddefine;


/*
define -- Top level procedures
*/

define referenceof(det,patterns) -> result;
	lvars det patterns options result;
	which([A],patterns) -> options;
	if options == [] then
		;;; no matches
		[none] -> result
	elseif det == "a" then
		oneof(options)(1) -> result;
	elseif det == "the" then
		if length(options) == 1 then
			options(1)(1) -> result;
		else
			;;; ambiguous match
			[ambgs] -> result;
		endif;
	else
		;;; unknown determiner
		[none] -> result;
	endif;
enddefine;


define allreferencesof(det, patterns) -> objects;
lvars det patterns options item objects;
	which([A], patterns) -> options;
	if options == [] then
		[none] -> objects;
	else
		[%
			for item in options do
				item(1);
			endfor
		%] -> objects;
	endif;
enddefine;

define assign_meanings(trees) -> meanings;      ;;; apply facets to parses
	lvars trees meanings;
	maplist(trees,MEANING) -> meanings;
enddefine;

define find_references(meanings) -> meanings;   ;;; evaluate references of
	lvars mng meanings;          				;;; database terms
	vars X, Y, det1, det2;

	[%
	for mng in meanings do
		if mng matches [PUT ?det1 ?X on ?det2 ?Y] then
			[PUT ^(referenceof(det1,X)) on ^(referenceof(det2,Y))];
		elseif mng matches [find all suchthat ?det1 ?X] then    ;;; from 'what'
			[FINDALL on allof ^(allreferencesof(det1, X))];
		elseif mng matches [WHERE ?det1 ?X] then    ;;; from 'where'
			[WHERE ^(referenceof(det1,X))];
		elseif mng matches [which ?X suchthat ?det2 ?Y] then    ;;; from 'which'
			[IDENTIFY any asoneof ^(allreferencesof(det2,Y))];
		elseif mng matches [QUERY ?det1 ?X suchthat ?det2 ?Y] then ;;; from 'is'
			[QUERY ^(referenceof(det1,X)) member ^(allreferencesof(det2,Y))];
		endif;
	endfor;
	%] -> meanings;
enddefine;



define select_command(meanings) -> command; ;;; choose a command from the set
	lvars mng meanings commands; ;;; of possibles

	;;; Pattern variables.
	vars X Y;
	[] -> commands;
	for mng in meanings do
		if mng matches [PUT ?X:isword on ?Y:isword] then
			[^mng ^^commands] -> commands;
		elseif mng matches [FINDALL on allof ?X] then  ;;; 'what'
			[[FINDALL on allof ^X] ^^commands] -> commands;
		elseif mng matches [WHERE ?X:isword] then   ;;; 'where'
			[[LOCATE ^X] ^^commands] -> commands;
		elseif mng matches [IDENTIFY any asoneof ?X] then ;;; 'which'
			if length(X) > 1 then
				[[INFORM Ambiguous Reference] ^^commands] -> commands;
			else
				[[INFORM block is ^(X(1))] ^^commands] -> commands;
			endif;
		elseif mng matches [QUERY ?X member ?Y] then   ;;; 'is'
			[[CHECK ^X member ^Y] ^^commands] -> commands;
		endif;
	endfor;
	if length(commands) > 1 then    ;;; more than one possible command
		'command ambiguous or too difficult' -> command;
	elseif commands == [] then
		if meanings/==[] then   ;;; found meaning but no command
			'ambiguous or unsatisfiable reference(s)' -> command;
		else                    ;;; no meaning at all therefore no parsetree
			'could not parse the sentence' -> command;
		endif;
	else
		commands(1) -> command; ;;; the only command
	endif;
enddefine;


define remember_reference(command);
	;;; remember object for future pronoun references
	lvars command;
	vars X;
	if command matches [PUT ?X on =]
	or command matches [CHECK ?X member =]
	or command matches [INFORM block is ?X]
	or command matches [LOCATE ?X] then
		flush([lastone =]); add([lastone ^X]);
	endif;
enddefine;


define boxpr(box);
	lvars box;
	vars S, C;
	if allpresent([[isa block ^box] [size ?S ^box] [colour ?C ^box]]) then
		printf('the %p %p block', [^S ^C]);
	elseif box == "table" then
		pr('the table');
	else
		printf('Can\'t find block %p in world\n', [^box]);
	endif;
enddefine;

define improve(oldplan) -> (different, newplan);
	lvars oldplan, move, newplan=oldplan, different=false, changed=true;

	vars source before destin after nextdest;

	until not(changed) do
		for move in newplan do
			move --> [move ?source ?destin];
			if newplan matches [??before ^move [move ^source ?nextdest] ??after]
			then
				[^^before [move ^source ^nextdest] ^^after] -> newplan;
				true -> changed;
				true -> different;
				quitloop();
			endif;
			false -> changed;
		endfor;
	enduntil;
enddefine;

define do_puton(X, Y) -> result;
	lvars move, moves, different;
	
	planmove(X,Y) -> moves;
	if moves == [] then
		'It is already there!' -> result;
		return();
	elseif chatty then
		'Plan:' => moves ==>
	endif;

	improve(moves) -> (different, moves);

	if different then
		'Plan analysed and improved, New Plan:' =>
		moves ==>
	endif;

	;;; prepare to draw blocks
	blocks_win -> rc_current_window_object;
	pr('WATCH THE GRAPHIC WINDOW\n');

	for move in moves do
		vars block1, block2;
		move --> [move ?block1 ?block2];
		;;; database ==>
		[Doing ^^move]=>
		if handmoveblock(block1,block2) then
			flush([on ^block1 =]);
			add([on ^block1 ^block2]);
			[^block1 now on ^block2] =>
			;;; do_pause();
		else
			[Cannot do ^move] =>
			do_pause();
			'cannot complete command' -> result;
			return();
		endif;
	endfor;

	"done" -> result;
enddefine;


define do_command(command) -> result;
	lvars move command different word items basebox box;
	vars X Y message;

	pr(newline);
	if command matches [PUT ?X on ?Y] then
		do_puton(X,Y) -> result
	elseif command matches [INFORM ??message] then  ;;; basically from 'which'
		if chatty then message ==> endif;
		if hd(message) == "block" then
			message --> [block is ?X];
			if X == "none" then
				pr('No block satisfies the description\n');
			else
				spr('That block is'); boxpr(X);
			endif;
		else
			for word in message do
				spr(word);
			endfor;
		endif;
		npr('.');
		"done" -> result;
	elseif command matches [FINDALL on allof ?X] then  ;;; from 'what'
		for box in X do
			[] -> items;
			unless present([on ?Y ^box]) then
				pr('Nothing is on that block\n');
			else
				box -> basebox;
				while present([on ?Y ^box]) do
					[^Y ^^items] -> items;	;;; changed to reduce garbage coll
					Y -> box;
				endwhile;
				ncrev(items) -> items;
			endunless;
			unless items == [] then
				if length(items) == 1 then
					boxpr(hd(items)); pr(' is on '); boxpr(basebox); nl(1);
				else
					unless basebox == "none" do
						pr('The following blocks are on '); boxpr(basebox); nl(1);
						while tl(items) /= [] do
							boxpr(hd(items));
							spr(',');
							tl(items) -> items;
						endwhile;
						boxpr(hd(items));
						npr('.');
					endunless;
				endif;
			endunless;
		endfor;

		"done" -> result;
	elseif command matches [LOCATE ?X:isword] then      ;;; from 'where'
		if chatty then [trying to locate ^X] ==> endif;
		if present([on ^X ?Y]) then
			pr('That block is on '); boxpr(Y); nl(1);
			if present([on ?Y ^X]) then
				pr('That block is also under '); boxpr(Y); nl(1);
			endif;
		else
			boxpr(X); npr(' is not \'on\' anything');
		endif;
		"done" -> result;
	elseif command matches [CHECK ?X:isword member ?Y] then  ;;; from 'is'
		if member(X, Y) then
			pr('Yes it is\n');
		else
			pr('No it isn\'t\n');
		endif;
		"done" -> result;
	else
		command -> result
	endif;
	pr(newline);
enddefine;

define showdata();
	dlocal
		database = handdatabase;

	false -> rc_current_window_object;
	blocks_win -> rc_current_window_object;

	vars x, y, b, c, boxwidth, boxheight, the_box;

	false -> vedwriteable;
	foreach [?b at ?x ?y] do
		lookup([colour ^b ?c]);
		lookup([size ^b ?boxwidth ?boxheight]);
		;;; draw it in the internal picture
		drawbox_in_picture(c, x , y , boxwidth, boxheight);
		lookup([^b is ?the_box]);
		rc_draw_linepic(the_box);
	endforeach;
enddefine;


define clear_windows();

	if parse_win then
		rc_kill_window_object(parse_win);
		false -> parse_win;
	endif;
	if blocks_win then
		rc_kill_window_object(blocks_win);
		false -> blocks_win;
	endif;
enddefine;

vars runparser; 		;;; defined below

define do_quit;
	;;; can be redefined
	rc_clear_events();	;;; cancel all events in queue
	clear_windows();
	if vedusewindows == "x" then
		;;; just in case
		vedinput(ved_q)
	else
		if length(vedbufferlist) > 0 then ved_q(); endif;
	endif;
	false -> vedwriteable;
	true -> blocks_terminate;
	if iscaller(runparser) then exitto(runparser) endif;
enddefine;

define give_help();

pr(
'\nYou can:\
\s\s1. give a command to MOVE or PUT a block somewhere.\
\s\s2. ask where a block is, ask whether a block is on\
\t\tanother block, ask what blocks are on a block, or ask\
\t\twhich block is on another block\nExamples of things you can type:\n\
\s\s\s\sput a green block on a blue block\
\s\s\s\smove the little red block onto a big green block\
\s\s\s\sput a block on the table onto a blue block\
\s\s\s\sput the block on a block on a block on a red block\
\s\s\s\sis the big red block on the small green one\
\s\s\s\swhere is the small blue block\
\s\s\s\sput it on the table\
\s\s\s\sput the big green block on it\
\s\s\s\swhat is on the big green block\
\s\s\s\swhat is on the block on the big green one\
\n\nYou can use the UP arrow key to select one of those\
then press the RETURN key.\
To exit type \'bye\'.');
enddefine;

define showparses(trees);

	lvars oldwin = parse_win;


	lvars tree;
	for tree in trees do
		tree ==>

		'Press "CONTINUE" button (bottom left of picture)' =>
		'\tto see graphical parse tree. (There may be a delay)' =>

		do_pause();

		unless parse_win then
			rc_new_window_object(
				parse_winx,
				parse_winy,
				parse_win_width,
				parse_win_height,
				true, 'parses') -> parse_win;
				;;; syssleep(rc_window_sync_time);	
			rc_mousepic(parse_win, [button]);
			{window_button_1_down ^false ^false} -> rc_button_down_handlers(parse_win);
		endunless;

		;;; save blocks_win stuff
		false -> rc_current_window_object;
		parse_win -> rc_current_window_object;

		procedure();
			;;; prevent interference while drawing
			dlocal rc_sole_active_widget = rc_window;

			;;; create window to display parse tree
			rc_start();
			rc_sync_display();

			rc_showtree(tree, -rc_xorigin,-rc_yorigin, '6x13bold');

			;;; rc_show_window(parse_win);
			;;; syssleep(rc_window_sync_time);	
			rc_sync_display();
		endprocedure();
		
		do_pause();
		true -> oldwin;
		if parse_win then
			;;; It wasn't destroyed in the pause
			rc_kill_window_object(parse_win);
			false -> parse_win;
			;;; rc_hide_window(parse_win);
		endif;
	endfor;
enddefine;

lvars
	prompt_string1 =
		'\nMove mouse pointer to this window',
	prompt_string2 =
		'\nType a sentence - \'help\' for help - type \'bye\' to exit\n';

define process_sentence(sentence);

	unless sentence == [] or sentence == termin then
		if sentence(length(sentence)) == "?" then
			allbutlast(1, sentence) -> sentence;
		endif;
	endunless;
	pr(newline);
	if sentence = [bye] or sentence == termin then
		clear_windows();
		false -> vedwriteable;
		true -> blocks_terminate;
		vedinput(ved_q);
		return();
	elseif sentence = [help] then
		give_help();
		return();
	elseif sentence = [chatty] then
		not(chatty) -> chatty;
		npr(if chatty then 'Verbosity on' else 'Verbosity off' endif);
		return();
	elseif sentence = [no chatty] then false -> chatty;
		return();
	elseif sentence = [debug] then setpop -> interrupt;
		return();
	elseif sentence = [showdata] then
		showdata();
		return();
	elseif sentence == [] then
		pr(prompt_string2);
		return();
	endif;

	pr('Trying to analyse: \n');
	applist(sentence, spr);
	pr(newline);
	rawoutflush();

	lvars trees = listparses("s",sentence);

	if chatty and trees /== [] then
		showparses(trees);
	endif;

	lvars meanings = assign_meanings(trees);
	if chatty and meanings /== [] then
		lvars tree;
		for tree in meanings do
			tree ==>
			do_pause();
		endfor
	endif;

	find_references(meanings) -> meanings;
	if chatty and meanings /== [] then
		pr('\nPossible interpretations:\n');
		meanings ==>
		do_pause();
	endif;

	lvars command = select_command(meanings);
	if chatty then
		if command.islist then
			'Interpreting your command as: ' >< command =>
			do_pause();
		else
			command =>
		endif;
	endif;

	lvars result = do_command(command);

	unless chatty and (result = command) then result ==> endunless;

	remember_reference(command);
enddefine;

define blocks_converse();

	;;; controls "bell" on first appearance of popup
	dlocal
		do_pause_bell = true;

	repeat
		;;; Give full prompt string only once
		if prompt_string1 then
			pr(prompt_string1);
			false -> prompt_string1
		endif;
		pr(prompt_string2);
		process_sentence(readline());
		quitif(blocks_terminate);
	endrepeat;
enddefine;

define blocks_setup();
	;;; Note the parse window is created only when first needed.
	dlocal cucharout, vedprintingdone;

	clear_windows();

	;;; This array is needed as an internal map for planning (??)
	newarray([1 ^world_width 1 ^world_height], space) -> picture;
	;;; prepare for use of "display"
	[]::boundslist(picture) -> pdprops(picture);

	rc_new_window_object(
		blocks_winx,
		blocks_winy,
		blocks_win_width,
		blocks_win_height,
		blocks_win_frame,'blocks') -> blocks_win;

	syssleep(5);
	;;; rc_hide_window(blocks_win);

	;;; make the window mouse sensitive
	rc_mousepic(blocks_win,[button]);

	;;; But not directly, only via objects on it

	false
		->> rc_move_handler(blocks_win)
		-> rc_keypress_handler(blocks_win);

	{^false ^false ^false}
		->> rc_button_up_handlers(blocks_win)
		;;; ->> rc_button_down_handlers(blocks_win)
		-> rc_drag_handlers(blocks_win);

	{window_button_1_down ^false ^false} -> rc_button_down_handlers(blocks_win);

	;;; create the hand
	instance ms_hand;
		rc_picx = 41;
		rc_picy = 19;
		ms_hand_open = true;
		ms_hand_open_strings = [FONT '12x24' {-1.8 0 '/-\\'}];
		ms_hand_closed_strings = [FONT '12x24' {-1.8 0 '|-|'}];
		rc_pic_strings = [];
	endinstance -> the_hand;

	;;; Make it open
	ms_hand_open_strings(the_hand) -> rc_pic_strings(the_hand);

	;;; Now do the pause button and quit button

	lvars
		button_y = bottom_margin * 0.5 / Y_scale,
		button_height = (bottom_margin - 4.0) / Y_scale;

	instance control_button;
		rc_picx = 4;
		rc_picy = -button_y;
	    rc_mouse_limit = {10 -3 20 3};
	    rc_pic_lines =
			[WIDTH 2 [RECT {9 ^(button_height*0.5) 10 ^button_height}]];
	    rc_pic_strings =
			[FONT '8x13bold'{1 -0.5 'PAUSING:'} {10.3 -0.5 'Continue'}];
	endinstance -> pause_button;

	rc_add_pic_to_window(pause_button, blocks_win, true);

	instance control_button;
		rc_picx = 60;
		rc_picy = -button_y;
	    rc_mouse_limit = {0 -3 8 3};
	    rc_pic_lines =
			[WIDTH 2 [RECT {0 ^(button_height*0.5) 6 ^button_height}]];
	    rc_pic_strings = [FONT '8x13bold'{1 -0.5 'QUIT'}];
	endinstance -> quit_button;

	;;; install the specialised method for quitting
	"quit_button_1_down" -> rc_button_down_handlers(quit_button)(1);

	rc_draw_linepic(quit_button);
	rc_add_pic_to_window(quit_button, blocks_win, true);

	;;; Draw a line to represent the table.
	procedure();
		dlocal rc_linewidth = 3;
		rc_drawline(0,0.6,150,0.6);
	endprocedure();

	;;; set up the blocks picture
	initdata();

enddefine;

global vars pop_pr_exception;	;;; needed for V15.5
vars rc_blocks_compile; ;;; defined below

vars vedautosaving; 	;;; in case ved_autosave in use

define runparser();
	dlocal vedautowrite = false, vedautosaving = false;
	dlocal prwarning, interrupt;

	dlocal blocks_wakeup = false;
	false -> vedwriteable;

    lvars old_pr_exception = pop_pr_exception;

    define dlocal pop_pr_exception(count, mess, idstring, sev);
		;;; change warning messages
        if sev == `W` then
            erasenum(count)
        else
            old_pr_exception(count, mess, idstring, sev);
			exitfrom(runparser);
        endif
    enddefine;

	if rcdebuginterrupt then rcdebuginterrupt
	else sysexit endif -> interrupt;

	erase -> prwarning;

	if vedediting then
		if vedusedsize(vedbuffer) > 1 and not(pop_debugging) then
			ved_clear();
		endif;
		if vedusewindows /== "x" and vedscreenlength >  vedstartwindow then
			vedsetwindow()
		endif;
		false -> vedwriteable;
	endif;

	blocks_setup();

	blocks_converse();
enddefine;



/*
define --- rc_blocks subsystem

rc_blocks_compile -> last(sys_subsystem_table)(2)(1);
sys_subsystem_table ==>
*/

define rc_blocks_compile(stream);
	dlocal proglist_state = proglist_new_state(stream);
	vedscr_flush_output();
	runparser();
enddefine;


;;; In case lib ved_lockfile or ved_autosave is in use.

vars ved_lock_files, vedautosaving;
define blocks_go();
	;;; Redefined by John Gibson 30 Jan 1997

	dlocal ved_lock_files = false, vedautosaving = false;

    define go =
        vedimshell(% vededit(%['blocks.blocks' ^false "rc_blocks],
                                    vedhelpdefaults, true%) %);
    enddefine;

    ;;; this variable is set true by QUIT button or "bye"
    false -> blocks_terminate;

    'blocks.blocks' ->> ved_chario_file -> vedvedname;

    ;;; next line allows for %x (probably better to put this in
    ;;; mkgblocks)
    if popunderx then "x" -> vedusewindows endif;

    vedsetup();
    if blocks_saved_image and vedusewindows == "x" then
        vedinput(go);
        valof("xved_standalone_setup")()
    else
        go()
    endif;

enddefine;

define ved_blocks();
	blocks_go();
enddefine;

;;; subsystem code from John Gibson  27 Jan 1997
subsystem_add_new(
        "rc_blocks",
        rc_blocks_compile,
        '.blocks',
        '? ',
        [],
        'rc_blocks'
);

pr('\nTO START THE PROGRAM TYPE:-\n\tblocks_go();\nor\n\t\ENTER blocks\n');

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 10 2000
	Protected drawing of parse tree from events in other window.
--- Aaron Sloman, Sep 2 1997
	Fixed problem of screwing up coordinate frame of blocks_win

--- Aaron Sloman, Aug 19 1997
	Improved structure by separating movable from immovable picture objects

--- Aaron Sloman, Aug 17 1997
	Allowed interrupt as a way of exiting from pause, when stuck.
	Also allowed mouse button 1 to work outside window area, for the same reason.
--- Aaron Sloman, Jun 22 1997
	Made the font smaller, and created a new parse_win each time, to
	get round window manager problems. The extra garbage is probably
	worth putting up with.
--- Aaron Sloman, Mar 30 1997
	removed "hidden" when parse_win is first created.
--- Aaron Sloman, Mar 29 1997
	Various changes following reorganisation of rc_mousepic, etc.
	Improved some of the textual output.
--- Aaron Sloman, Mar 24 1997
	Turned off locking and autosaving of files.
--- Aaron Sloman, Mar 11 1997
	Fixed handling of "onto" so that it can only be start of indirect
	object
	Changed names of blocks, e.g. blockg is now SmallGreen, blockG is
	BigGreen
--- Aaron Sloman, Jan 30 1997
	More work, with help from John Gibson, to make saved image work
	properly with Xved. Redefined blocks_go, and blocks_converse
	Made to start with "hidden" windows
--- Aaron Sloman, Jan 28 1997
	Lots of changes to make xved work in saved image, including using
	xved_standalone_setup
--- Aaron Sloman, Jan 27 1997
	Switched to using subsystem as suggested by John Gibson.
	Created mkgblocks to create saved image
--- Aaron Sloman, Jan 26 1997
	Put in more error tracing and simplified rc_hand
	Made more modular, with clear globals for parameters
	Added quit button and line for table.
	Simplified representation of the hand. Only one instance
--- Aaron Sloman, Jan 23 1997
	Added control button on blocks window
--- Aaron Sloman, Jan 21 1997
	Renamed as rc_blocks. Finally converted to use rc_linepic instances
	for the blocks
--- Aaron Sloman, Jan 19 1997
	Changed to show blocks in graphic window
--- Aaron Sloman, Dec 14 1996
	Changed to use Riccardo Poli's rc_showtree program.
--- Aaron Sloman, Mar 23 1992
	added do_pause, and inserted calls to slow down block moves.
--- Aaron Sloman, Jul 17 1991
	Fixed to use vedprocesstrap instead of vedobey
--- Aaron Sloman, Apr  9 1989
	Made to respect interact_pause_time, or $MSBLOCKSPAUSE environment
	variable if -chatty- is true
--- Aaron Sloman, Jan 24 1987
	Moved new features to public library, along with TEACH * MSDEMO
	Cleaned up. Reduced number of compile time extras
--- Richard Bignell, Oct 20 1986 - this is an extension of LIB * MSBLOCKS
	to include questions.
CONTENTS (define)

 define --- Prerequisites
 define --- Global variables
 define --- Button facilities
 define :class block_button;
 define :class control_button;
 define :method block_button_1_down(p:control_button, x, y, modifiers);
 define :method window_button_1_down(p:rc_window_object, x, y, modifiers);
 define :method quit_button_1_down(p:control_button, x, y, modifiers);
 define :instance butt1:block_button;
 define do_pause();
 define --- Grammar, lexicon and parsing utilities
 define --- Facets library for meanings
 define lconstant replace(x,y,l);
 define lconstant unique(pp);
 define --- Hand utilities
 define :class ms_block;
 define create_blocks();
 define handmoveblock(A,B) -> done;
 define --- Blocks data
 define initdata();
 define moveblock(box, loc, moves) -> moves;
 define cleartop(obj, moves) -> moves;
 define planmove(X,Y) -> moves;
 define -- Top level procedures
 define referenceof(det,patterns) -> result;
 define allreferencesof(det, patterns) -> objects;
 define assign_meanings(trees) -> meanings;      ;;; apply facets to parses
 define find_references(meanings) -> meanings;   ;;; evaluate references of
 define select_command(meanings) -> command; ;;; choose a command from the set
 define remember_reference(command);
 define boxpr(box);
 define improve(oldplan) -> (different, newplan);
 define do_puton(X, Y) -> result;
 define do_command(command) -> result;
 define showdata();
 define clear_windows();
 define do_quit;
 define give_help();
 define showparses(trees);
 define process_sentence(sentence);
 define blocks_converse();
 define blocks_setup();
 define runparser();
 define --- rc_blocks subsystem
 define rc_blocks_compile(stream);
 define blocks_go();
 define ved_blocks();

*/
