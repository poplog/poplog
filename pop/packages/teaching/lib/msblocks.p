/*  --- Copyright University of Sussex 1997.  All rights reserved. ---------
 >  File:           C.all/lib/lib/msblocks.p
 >  Purpose:        A SHRDLU like blocks world program
 >  Author:         David Hogg 1983, Richard Bignell, Oct 20 1986 (see revisions)
 >  Documentation:  TEACH * MSDEMO, TEACH * MSBLOCKS
 >  Related Files:  LIB * TPARSE, LIB * FACETS, LIB * TERMHAND
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

;;; N.B. As of Jan 1987 this includes some hooks to the window manager
;;; but they will work only where a suitable library file has been
;;; defined, to replace lib mshand

;;;*******************************************************************
;;;       PARSING
;;;*******************************************************************

uses tparse;   ;;; uses LIB TPARSE rather than LIB GRAMMAR to get all parses

lconstant default_pause = 200;	;;; 2 seconds pause, default for next variable

vars interact_pause_time;	;;; assignable by user, or set in runparser


vars blocks_grammar blocks_lexicon;

[
	[s [vp] [qest]]
	[qest [wh_loc vbe np] [wh_obj1 vbe pp]
		[wh_obj2 snp vbe pp] [vbe np pp]]
	[vp [v np pp]]
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
	[wh_obj1    what]
	[wh_obj2    which]
	[adj        white red blue green big small large little]
	[prep       on onto above over] ;;; (in at to under by) removed since
									;;; they are handled incorrectly.
	[det        each every the a some]
] -> blocks_lexicon;

setup(blocks_grammar,blocks_lexicon);



;;;**********************************************************************
;;;        FACETS
;;;**********************************************************************


uses facets
resetfacets();


;;; First a couple of utility procedures for facets


define lconstant replace(x,y,l);
	lvars x,y,l;
	maplist(l,
		procedure(el);
			lvars el;
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
	lvars pp;
	replace("B","A",replace("A",gensym("A"),pp));
enddefine;


facet MEANING pred detr;

semrule sentrule [s ?phrase]
   MEANING(phrase) -> MEANING(self);
endsemrule;

semrule questrule1 [qest [wh_obj1 =] [vbe =] ?pp]
	[find all suchthat ^(detr(pp)) ^(pred(pp))] -> MEANING(self);
endsemrule;

semrule questrule2 [qest [wh_loc =] [vbe =] ?np]
	[where ^(detr(np)) ^(pred(np))] -> MEANING(self);
endsemrule;

semrule questrule3 [qest [wh_obj2 =] ?object [vbe =] ?location]
	[which ^(pred(object)) suchthat ^(detr(location))
			^(unique(pred(location)))] -> MEANING(self);
endsemrule;

semrule questrule4 [qest [vbe =] ?object ?location]
	[assert ^(detr(object)) ^(pred(object)) suchthat
			^(detr(location)) ^(unique(pred(location)))] -> MEANING(self);
endsemrule;

semrule vprule [vp ?v ?np ?pp]
   [put ^(detr(np)) ^(pred(np)) on ^(detr(pp)) ^(tl(pred(pp)))]
   -> MEANING(self);
endsemrule;

semrule pprule [pp ?prep ?np]
	detr(np) -> detr(self);
	pred(prep) :: pred(np) -> pred(self);
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

semrule blockrule [noun ?x:%member(%[block box one]%)%] [isa block ?A] -> pred(self); endsemrule;

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

semrule detrule [det ?x] x -> detr(self); endsemrule;



;;;********************************************
;;;         HAND
;;;********************************************

vars input_window parse_window interp_window picture_window;

vars holding;

;;; this should be changed according to terminal used
if vedterminalselect then
	popval([lib autov55]);	;;; for Visual 200 or Visual 55
endif;
lib mshand;
vars killwindows setupdata setup_windows;

vars handdatabase;

define inithand;
	vars database;
	false -> holding;
	[[boxR at 20 1] [colour boxR r] [size boxR 8 3]
	 [boxr at 62 4] [colour boxr r] [size boxr 3 2]
	 [boxG at 20 4] [colour boxG g] [size boxG 8 3]
	 [boxg at 40 1] [colour boxg g] [size boxg 3 2]
	 [boxB at 60 1] [colour boxB b] [size boxB 8 3]
	 [boxb at 22 7] [colour boxb b] [size boxb 3 2]
	]->> handdatabase -> database;
	newpicture(75,15);
	.showdata;
	drawhand(40,8);
enddefine;


define handmoveblock(A,B) -> done;
	lvars A,B,done;
	vars database cucharout;
	true -> done;
	define cucharout(c);
		lvars c;
		false -> done;
	enddefine;
	handdatabase -> database;
	unless Getabove(A) then
		false -> done;
		return;
	endunless;
	unless Down() then false -> done; return; endunless;
	Hold();
	unless Raise(13) then Letgo(); Raise(13) ->; false -> done; return;
	endunless;
	if B == "table" then
		unless Findspace() then
			false -> done;
			Down() ->;
			Letgo();
			Raise(13) ->;
			return()
		endunless;
	else
		unless Getabove(B) then
			false -> done;
			Down() ->;
			Letgo();
			Raise(13) ->;
			return;
		endunless;
		unless Down() then false -> done; return() endunless;
	endif;
	Letgo();
	unless Raise(13) then false -> done; return; endunless;
	true -> done;
	database -> handdatabase;
enddefine;


;;;********************************************
;;;        BLOCKS WORLD
;;;********************************************


define init;
	[
		[isa block boxR] [colour red boxR]   [size large boxR]
		[isa block boxr] [colour red boxr]   [size small boxr]
		[isa block boxG] [colour green boxG] [size large boxG]
		[isa block boxg] [colour green boxg] [size small boxg]
		[isa block boxB] [colour blue boxB]  [size large boxB]
		[isa block boxb] [colour blue boxb]  [size small boxb]
		[isa table table]
		[on boxb boxG]
		[on boxG boxR]
		[on boxR table]
		[on boxg table]
		[on boxr boxB]
		[on boxB table]
		[graspable block]
	] -> database;
	.inithand;
enddefine;


vars moves;

define moveblock(box,loc);
	lvars box,loc;
	flush([on ^box =]);
	add([on ^box ^loc]);
	[ ^^moves [move ^box ^loc] ] -> moves;
enddefine;


define cleartop(obj);
	lvars obj;
	vars box loc;
	if present([on ?box ^obj]) then
		cleartop(box);
		foreach [isa block ?loc] do
			unless loc == box or present([protect ^loc])
				or present([on = ^loc]) then
				moveblock(box,loc);
				return
			endunless;
		endforeach;
		moveblock(box,"table");
	endif;
enddefine;


;;; N.B moves used non-locally. YUCK!!

define planmove(X,Y) -> moves;
	lvars X,Y;
	vars obj database moves;
	;;; Local copy of database since this is only the planning phase
	[] -> moves;
	if present([on ^X ^Y]) then return endif;
	if allpresent([[isa ?obj ^X][graspable ?obj]]) then
		cleartop(X);
		add([protect ^X]);
		unless present([isa table ^Y]) then
			cleartop(Y);
		endunless;
		moveblock(X,Y);
		remove([protect ^X]);
	endif;
enddefine;




;;;****************************************
;;;      Top-level
;;;****************************************


vars chatty;
true -> chatty;


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


vars last_plan;

define assign_meanings(trees) -> meanings;      ;;; apply facets to parses
	lvars trees meanings;
	maplist(trees,MEANING) -> meanings;
enddefine;


define find_references(meanings) -> meanings;   ;;; evaluate references of
	lvars mng meanings;          				;;; database terms
	vars X Y det1 det2;
	[%
	for mng in meanings do
		if mng matches [put ?det1 ?X on ?det2 ?Y] then
			[put ^(referenceof(det1,X)) on ^(referenceof(det2,Y))];
		elseif mng matches [find all suchthat ?det1 ?X] then    ;;; from 'what'
			[findall on allof ^(allreferencesof(det1, X))];
		elseif mng matches [where ?det1 ?X] then    ;;; from 'where'
			[where ^(referenceof(det1,X))];
		elseif mng matches [which ?X suchthat ?det2 ?Y] then    ;;; from 'which'
			[identify any asoneof ^(allreferencesof(det2,Y))];
		elseif mng matches [assert ?det1 ?X suchthat ?det2 ?Y] then ;;; from 'is'
			[assert ^(referenceof(det1,X)) member ^(allreferencesof(det2,Y))];
		endif;
	endfor;
	%] -> meanings;
enddefine;


define select_command(meanings) -> command; ;;; choose a command from the set
	lvars mng meanings commands; ;;; of possibles
	vars X Y;
	[] -> commands;
	for mng in meanings do
		if mng matches [put ?X:isword on ?Y:isword] then
			[^mng ^^commands] -> commands;
		elseif mng matches [findall on allof ?X] then  ;;; 'what'
			[[findall on allof ^X] ^^commands] -> commands;
		elseif mng matches [where ?X:isword] then   ;;; 'where'
			[[locate ^X] ^^commands] -> commands;
		elseif mng matches [identify any asoneof ?X] then ;;; 'which'
			if length(X) > 1 then
				[[inform Ambiguous Reference] ^^commands] -> commands;
			else
				[[inform block is ^(X(1))] ^^commands] -> commands;
			endif;
		elseif mng matches [assert ?X member ?Y] then   ;;; 'is'
			[[check ^X member ^Y] ^^commands] -> commands;
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
	if command matches [put ?X on =]
	or command matches [check ?X member =]
	or command matches [inform block is ?X]
	or command matches [locate ?X] then
		flush([lastone =]); add([lastone ^X]);
	endif;
enddefine;


define boxpr(box);
lvars box;
vars S C;
	if allpresent([[isa block ^box] [size ?S ^box] [colour ?C ^box]]) then
		printf('the %p %p block', [^S ^C]);
	elseif box == "table" then
		pr('the table');
	else
		printf('Can\'t find block %p in world\n', [^box]);
	endif;
enddefine;

define improve(oldplan) -> newplan -> different;
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

define do_command(command);
	lvars move command moves different word items basebox box;
	vars X Y message;
	if command matches [put ?X on ?Y] then
		planmove(X,Y) -> moves;
		moves -> last_plan;		;;;; IS THIS USED?
		if moves == [] then return(oneof(['look no hands' 'too easy'])) endif;
		if chatty then 'Plan:' => moves ==> endif;
		improve(moves) -> moves -> different;
		if different then
			'Plan analysed and improved, New Plan:' =>
			moves ==>
		endif;
		for move in moves do
			move --> [move ?X ?Y];
			if handmoveblock(X,Y) then
				flush([on ^X =]);
				add([on ^X ^Y]);
			else
				return('cannot complete command')
			endif;
		endfor;
		return('done');
	elseif command matches [inform ??message] then  ;;; basically from 'which'
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
		return('done');
	elseif command matches [findall on allof ?X] then  ;;; from 'what'
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
		return('done');
	elseif command matches [locate ?X:isword] then      ;;; from 'where'
		if chatty then [trying to locate ^X] ==> endif;
		if present([on ^X ?Y]) then
			pr('That block is on '); boxpr(Y); nl(1);
			if present([on ?Y ^X]) then
				pr('That block is also under '); boxpr(Y); nl(1);
			endif;
		else
		boxpr(X); npr(' is not \'on\' anything');
		endif;
		return('done');
	elseif command matches [check ?X:isword member ?Y] then  ;;; from 'is'
		if member(X, Y) then
			pr('Yes it is\n');
		else
			pr('No it isn\'t\n');
		endif;
		return('done');
	else
		return(command)
	endif;
enddefine;

vars runparser;

define runshowdata();
	vars database = handdatabase;
	showdata();
enddefine;

define reshowdata();
	vars database = handdatabase;
	setupdata();
	showdata();
	database -> handdatabase;
enddefine;

define do_quit;
	;;; can be redefined
	interrupt();
enddefine;

;;; vars msdebuginterrupt=vedinterrupt;
vars msdebuginterrupt=false;;

define runparser();
	lvars tree, trees, sentence, command, result, meanings, temp,
			old_pr_exception = pop_pr_exception;
	dlocal vedargument, interrupt;

	unless isnumber(interact_pause_time) then
		;;; set up time for pausing
		systranslate('MSBLOCKSPAUSE') -> temp;
		if temp and (strnumber(temp) ->> temp) then
			temp -> interact_pause_time
		else
			default_pause -> interact_pause_time
		endif
	endunless;
	if msdebuginterrupt then msdebuginterrupt
	else sysexit endif -> interrupt;

	define dlocal pop_pr_exception(count, mess, idstring, sev);
		if sev == `W` then
			erasenum(count)
		else
			old_pr_exception(count, mess, idstring, sev)
		endif
	enddefine;

	init();
	if vedediting then
		'output' -> vedargument; ved_ved();
	endif;
	pr('type a sentence - \'help\' for help - \'bye\' to exit\n');
	repeat
		readline() -> sentence;
		unless sentence == [] or sentence == termin then
			if sentence(length(sentence)) == "?" then
				allbutlast(1, sentence) -> sentence;
			endif;
		endunless;
		pr(newline);
		if sentence = [bye] or sentence == termin then do_quit()

		elseif sentence = [help] then
			pr(
'You can give a command to MOVE or PUT a block somewhere.\
or ask where a block is, ask whether a block is on\
another block, ask what blocks are on a block, or ask\
which block is on another block\n');
			syssleep(300);
		pr(
'E.g. put a green block on a blue block\
\s\s\s\smove the little red block onto a big green block\
\s\s\s\sput a block on the table onto a blue block\
\s\s\s\smove the block on a block on a block onto a red block\n');
			syssleep(300);
		pr(
'\s\s\s\sis the big red block on the small green one\
\s\s\s\swhere is the small blue block\
\s\s\s\swhat is on the big green block\
\s\s\s\swhich block is on the big block on the small green one\n');
			syssleep(300);
			nextloop;
		elseif sentence = [chatty] then
			not(chatty) -> chatty;
			npr(if chatty then 'Verbosity on' else 'Verbosity off' endif);
			nextloop
		elseif sentence = [no chatty] then false -> chatty; nextloop
		elseif sentence = [debug] then setpop -> interrupt; nextloop
		elseif sentence = [showdata] then
			runshowdata(); nextloop
		elseif sentence = [] then
			pr('\ntype a sentence - \'help\' for help - \'bye\' to exit\n');
			nextloop;
		endif;

		pr('Trying to analyse: \n');
		applist(sentence, spr);
		pr(newline);
		rawoutflush();
		listparses("s",sentence) -> trees;
		if chatty then
			for tree in trees do
				tree ==>
			syssleep(interact_pause_time);
			endfor;
		endif;

		assign_meanings(trees) -> meanings;
		if chatty and meanings /== [] then
			for tree in meanings do
				tree ==>
				syssleep(interact_pause_time);
			endfor
		endif;

		find_references(meanings) -> meanings;
		if chatty and meanings /== [] then
			pr('\nPossible meanings:\n');
			meanings ==>
			syssleep(interact_pause_time);
		endif;

		select_command(meanings) -> command;
		if chatty then
			if command.islist then
				'Interpreting your command as: ' >< command =>
			else
				command =>
			endif;
			syssleep(interact_pause_time);
		endif;

		do_command(command) -> result;
		if vedediting then
			'output' -> vedargument;
			ved_ved();
		endif;
		unless chatty and (result = command) then result => endunless;

		remember_reference(command);
	endrepeat;
enddefine;

define go;
	dlocal vedautowrite = false;
	procedure(oldtrap);
		lvars oldtrap, startwindowlength = vedscreenlength - 17;
		oldtrap -> vedprocesstrap;
		start_vturtle(runparser,startwindowlength);
	endprocedure(%vedprocesstrap%) -> vedprocesstrap;
	vededitor(vedveddefaults, 'output');
enddefine;



/* --- Revision History ---------------------------------------------------
--- John Gibson, Jan 24 1997
		Made runparser locally redefine pop_pr_exception instead of old
		prwarning.
--- John Gibson, Nov  9 1995
		Removed pw*m stuff
--- John Gibson, Jul 31 1995
		Added +oldvar at top
--- Aaron Sloman, Jul 17 1991
	Fixed to use vedprocesstrap instead of vedobey
--- Aaron Sloman, Apr  9 1989
	Made to respect interact_pause_time, or $MSBLOCKSPAUSE environment
	variable if -chatty- is true
*/
