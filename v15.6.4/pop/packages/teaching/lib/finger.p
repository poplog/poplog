/*  --- Copyright University of Sussex 1995.  All rights reserved. ---------
 >  File:		   	C.all/lib/lib/finger.p
 >  Purpose:		Demonstration of trainable learning program
 >  Author:		 	A.Sloman 1983, updated J Cunningham, 1985 (see revisions)
 >  Documentation:  TEACH * FINGER
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

vars
	vedediting,				;;;; automatically true in VED
	counter_limit=20,		;;; user assignable
	search_limit=120,		;;; user assignable.
	possible_actions,		;;; global database of possible actions. Grows

	chatty=1;				;;; 0,1 or 2 - controls verbosity


;;; PROCEDURES DEFINED LATER:
vars
	macro start;


;;; BASIC ACTIONS


;;; Some variables used non-locally by basic operators.
;;; Could have been made LVARS or hidden in a section.
;;; Could have been passed as parameters and returned as results

vars
	continue,			;;; if false terminate action
	finger_at,			;;; block currently pointed at
	finger_at_target,	;;; required block
	counter,			;;; current counter number
	counter_target,		;;; requied countr number
	number_of_blocks,	;;; number of blocks
	search_count;		;;; controls limit of search

define decrement();
	if counter < 1 then
		false -> continue
	else
		counter - 1 -> counter;
		true -> continue
	endif
enddefine;

define increment();
	if counter >= counter_limit then
		false -> continue
	else
		counter + 1 -> counter;
		true -> continue
	endif
enddefine;

define goleft();
	if finger_at < 1 then
		false -> continue
	else
		finger_at - 1 -> finger_at;
		true -> continue
	endif
enddefine;

define goright();
	if finger_at >= number_of_blocks then
		false -> continue
	else
		finger_at + 1 -> finger_at;
		true -> continue
	endif
enddefine;

define try_action(action) -> continue;
;;; interpret an action, return <true> if ok,
;;; return <false> if "unless" condition reached
vars sub_action;
	if isword(action) then
		valof(action) -> action;
		action()
	elseif islist(action) then
		if action matches [repeat ?sub_action] then
			while try_action(sub_action) do ;;; nothing
			endwhile;
			true -> continue
		else
			for sub_action in action do
				unless try_action(sub_action) then
					false -> continue;
					return
				endunless
			endfor;
			true -> continue
		endif
	else
		mishap('Unknown finger action',[^action])
	endif
enddefine;

define show_finger(finger,counter,blocks);
;;; display initial state of problem:
	lvars x finger,counter,blocks;
	pr('\nCounter: ');
	pr(counter);
	pr('\n');
	repeat finger times
		pr('   ')
	endrepeat;
	pr(' v\n   ');
	repeat blocks times
		pr(' []')
	endrepeat;
	pr('\n  0');
	for x from 1 to blocks do
		printf(x,' %p');
		if x < 10 then pr(space) endif;
	endfor;
	pr('\n\n');
	if vedediting then vedcheck() endif;
enddefine;

define setup_finger()->blocks -> finger_loc -> counter;
	lvars blocks fingr_loc counter;
	random(counter_limit - 6) + 5 -> blocks;
	random(blocks+1) - 1 -> finger_loc;
	random(counter_limit+1) - 1 -> counter;
enddefine;

;;; PROCEDURES TO SEARCH FOR A PLAN TO ACHIEVE TARGET
;;; A state will be represented as a 3 element list:
;;;	 finger position, counter value, and list of moves.
;;; The list of moves is not needed as part of the search, but is needed
;;; afterwards, to create the new "action".

define isgoal(state);
	lvars state;
	state matches [^finger_at_target ^counter_target =]
enddefine;

define make_state(oldstate,action);
;;; returns a new state after performing the action in the old state
;;; if the action was ok
vars actions_sofar was_ok;
vars finger_at counter; ;;; local so that we don't change the real state
	oldstate --> [?finger_at ?counter ?actions_sofar];
	try_action(action) -> was_ok;
	if was_ok then
		if islist(action) and not(action(1) == "repeat") then
			return([^finger_at ^counter [^^actions_sofar ^^action]])
		else
			return([^finger_at ^counter [^^actions_sofar ^action]])
		endif
	endif
enddefine;

define isrepeatable(action) -> result;
;;; checks that action does not contain the word "repeat"
vars sub_action;
	if atom(action) then
		true -> result
	elseif action matches [repeat =] then
		false -> result
	else
		isrepeatable(hd(action)) and isrepeatable(tl(action)) -> result
	endif
enddefine;

define nextfrom(state);
vars action;
	if chatty == 1 then
		pr('.');
		if vedediting then vedcheck(); sysflush(poprawdevout)
		else sysflush(popdevout)
		endif;
	elseif chatty == 2 then
		pr('\nConsidering: ');
		pr(state(3))
	endif;
	if vedediting then vedcheck() endif;
	[%
		 for action in possible_actions do
			 make_state(state,action);
			 if isrepeatable(action) then
				 make_state(state,[repeat ^action])
			 endif
		 endfor
	 %]
enddefine;

define search(state) -> state;
;;; perform a breadth first search
vars newalternatives alternatives;
	[] -> alternatives;
	until isgoal(state) do
		if search_count > search_limit then
			false -> state;
			return
		endif;
		search_count + 1 -> search_count;
		nextfrom(state) -> newalternatives;
		[^^alternatives ^^newalternatives] -> alternatives;
		alternatives --> [?state ??alternatives]
	enduntil
enddefine;

define initial_state();
;;; make a state
	[^finger_at ^counter []]
enddefine;

;;; end of code to do breadth first search


;;; PROCEDURES TO MANAGE THE INTERACTION

define repeat_last_plan();
vars plan;
	vedscreenclear();
	rawcharout(0);
	possible_actions(1) -> plan;
	pr('Plan is: ');
	pr(plan);
	erase(try_action(plan));
	pr('\n\nResult of plan is:\n');
	show_finger(finger_at,counter,number_of_blocks)
enddefine;

define print_help();
;;; help message
	appdata(
		{
			'\nType either two numbers or one of these options:\n'
			'\tsame   - do latest plan\n'
			'\tnext   - ignore this initial state\n'
			'\tforget - reset list of actions\n'
			'\texit   - leave finger\n'
			'\tchatty {0 or 1 or 2 }  - alter verbosity\n'
			'\tactions - print out possible actions so far\n'
			'See TEACH FINGER for more details\n\n'
		}, pr);

	if vedediting then vedcheck() endif;
enddefine;

define describe_plans(actions);
;;; print out possible_actions prettily
lvars i c actions;
	pr('\nThe possible actions are:');
	1 -> c;
	for i in actions do
		printf(i,c,'\n\t(%p) %p');
		1 + c -> c
	endfor;
	nl(1)
enddefine;

define attempt(counter,finger_at number_of_blocks);
;;; read targets, and attempt to achieve them
lvars answer;
	pr('Initial state');
	show_finger(finger_at,counter,number_of_blocks);
	0 -> search_count;
	repeat
		requestline('Target finger position and target counter value? ') -> answer;
		if answer matches
			[?finger_at_target:isinteger ?counter_target:isinteger]
		then
			if finger_at_target > number_of_blocks then
				pr('not enough blocks!\n');
			elseif counter_target > counter_limit then
				pr('counter_target should not exceed ' >< counter_limit >< newline);
			elseif counter_target < 0 or finger_at_target < 0 then
				pr('No arithmetical jokes please\n');
			else quitloop
			endif;
		nextloop
		else
			if answer = [same] then
				repeat_last_plan();
				return
			elseif answer = [actions] then
				pr('\nThese are the possible actions available so far:\n');
				describe_plans(possible_actions);
				nextloop
			elseif answer = [forget] then
				[goleft goright increment decrement] -> possible_actions;
				pr('Ok.\n');
				nextloop
			elseif answer = [next] then
				return
			elseif answer = [exit] then
				exitfrom(nonmac start)
			elseif answer = [help] then
				print_help();
				nextloop
			elseif answer matches [chatty ?chatty:isinteger] then
				nextloop
			else
				pr('Sorry, I don\'t understand that.\n');
				print_help();
				nextloop
			endif
		endif;
		quitloop
	endrepeat;
	if vedediting then vedcheck() else vedscreenclear() endif;
	rawcharout(0);
	if search(initial_state()) matches [= = ?plan] then
		if length(plan) == 1 then plan(1) -> plan endif;
		if chatty == 1 or chatty == 2 then nl(1) endif;
		pr('Plan was: ');
		if plan == [] then
			pr('do nothing')
		else
			pr(plan);
			nl(1);
			unless plan matches [repeat =]
			or member(plan,possible_actions)
			then
				[^plan ^^possible_actions] -> possible_actions
			endunless
		endif
	else
		pr('\nI give up on this one\n')
	endif;
enddefine;


define macro start;
;;; control interaction
vars plan;
	pr('\n\nSee TEACH FINGER for details of this program.');
	pr('\nFor a reminder of the options type \'help\'.\n\n');
	[goleft goright increment decrement] -> possible_actions;
	repeat
		attempt(setup_finger());
		describe_plans(possible_actions)
	endrepeat
enddefine;

pr('\nType\n\tstart\n\nto start the program\n');


/* --- Revision History ---------------------------------------------------
--- John Williams, Aug  4 1995
		Now sets compile_mode +oldvar.
--- John Gibson, Nov 11 1987
		Replaced -popdevraw- with -poprawdevout-
--- Aaron Sloman, Dec  2 1986 tidied up. Improved printing
--- Aaron Sloman, Jul 19 1986 corrected 'Author' entry. Made to work in VED
*/
