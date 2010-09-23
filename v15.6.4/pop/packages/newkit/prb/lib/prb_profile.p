/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/newprb/lib/prb_profile.p
 > Purpose:         For profiling the invocation of rules
 > Author:          Aaron Sloman, May  8 1996
 > Documentation:
 > Related Files:
 */





/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:           C.all/lib/lib/profile.p
 > Purpose:        profiling where the system is doing the most work?
 > Author:         Steve Hardy 1982 A.Sloman 1991 (see revisions)
 > Documentation:  HELP * PROFILE
 > Related Files:
 */

compile_mode:pop11 +strict;

section;

global vars

	profile_gc_trace = popgctrace,  ;;; controls GC trace printing

	profile_exclude = [null],       ;;; name or procedure not to be traced

	profile_show_max = 10,          ;;; maximum number of procedures shown

	profile_interval,               ;;; interval for timer

	profile_ignore_list = [],       ;;; used by profile_ignore
									;;; procedures whose activation is
									;;; to be ignored.

;

/*
;;; Is it safe to settle this at compile time??
if member(front(sys_processor_type), [68010 68020 68030]) then
	20000
else
	10000
endif -> profile_interval;
*/

10000 -> profile_interval;  ;;; may be slower on 680X0

define global vars profile_include(pdr) -> pdr;
	;;; default procedure used to test whether a procedure should
	;;; be included in the profile table
	lvars pdr;
	pdprops(pdr) -> pdr;
	if pdr then
		if fast_member(pdr, profile_exclude) then false -> pdr endif
	endif;
enddefine;

define global vars profile_ignore(pdr) /* -> boole */;
	;;; decide whether a procedure should be ignored, i.e. its
	;;; activation not counted
	lvars pdr;
	fast_member(pdr, profile_ignore_list) /* -> boole */
enddefine;

define global vars profile_display(run_time, profile_store);
	;;; Print out the final table. User definable
	lvars run_time, total_ticks = 0, item, count = 1, profile_store, list;

	;;; calculate total number of ticks
	0 -> total_ticks;
	appproperty(
		profile_store,
		procedure(x, y); lvars x,y;
			y + total_ticks -> total_ticks endprocedure);

	;;; Print tick time * interval, and actual run time
	printf(
		total_ticks,
		run_time/100.0,             ;;; seconds
		';;; CPU Time taken: %P seconds.  Number of interrupts: %P\n');

	;;; get sorted list of active procedures
	syssort(
		[%appproperty(profile_store, conspair) %],
		procedure(x, y); lvars x,y;
			fast_back(x) fi_> fast_back(y) endprocedure)
		-> list;

	printf(';;; PERCENTAGES OF TOTAL TIME:- \n');

	;;; calculate and print the percentages
	for item in list do
		if back(item)/total_ticks < 0.1 then pr(space) endif;
		printf(front(item),back(item)*100.0/total_ticks, '    %P\t%p\n');
		count + 1 -> count;
	quitif(count > profile_show_max);
	endfor
enddefine;

define global vars rule_display(run_time, rule_store);
	;;; Print out the final table. User definable
	lvars run_time, total_ticks = 0, item, count = 1, rule_store, list;

	;;; calculate total number of ticks, with rules active
	0 -> total_ticks;
	appproperty(
		rule_store,
		procedure(x, y); lvars x,y;
			y + total_ticks -> total_ticks endprocedure);

	;;; Print tick time * interval, and actual run time
	printf(
		total_ticks,
		';;; Number of times rules active: %P\n');

	;;; get sorted list of active procedures
	syssort(
		[%appproperty(
			rule_store,
			procedure(x,y);conspair(prb_rulename(x), y) endprocedure) %],
		procedure(x, y); lvars x,y;
			fast_back(x) fi_> fast_back(y) endprocedure)
		-> list;

	printf(';;; PERCENTAGES OF TOTAL:- \n');

	;;; calculate and print the percentages
	for item in list do
		if back(item)/total_ticks < 0.1 then pr(space) endif;
		printf(front(item),back(item)*100.0/total_ticks, '    %P\t%p\n');
		count + 1 -> count;
	quitif(count > profile_show_max);
	endfor
enddefine;

lvars profile_running = false;

define global vars profile_apply(action);
	;;; The procedural interface: run the procedure action with profiling
	;;; on

	lvars total_ticks, run_time, procedure action,
		profile_store = newproperty([], 64, 0, true),
		profile_rules = newproperty([], 64, 0, true);

	dlocal
		profile_running = true,
		popgctrace,
		pop_pr_places = (`0` << 16) || 2,   ;;; See REF * pop_pr_places
		;

	unless popgctrace then
		profile_gc_trace -> popgctrace
	endunless;

	if popgctrace then
		define dlocal pop_after_gc();
			lvars count = 1, name;
			until (pdprops(caller(count)) ->> name) do
				count fi_+ 1 -> count
			enduntil;
			printf(name,';;; GC invoked by procedure  %p\n\n')
		enddefine;

	endif;


	;;; The procedure invoked by the timer. It increments the count for
	;;; the first caller with non-false pdprops not in profile_exclude.
	define lconstant profile_interrupt();
		;;; skip first three callers - apparently all in system
		lvars count = 4, pdr;

	returnunless(profile_running)(false -> sys_timer(profile_interrupt));

		while (caller(count) ->> pdr) do
			if (profile_include(pdr) ->> pdr) then
				unless profile_ignore(pdr) then
					profile_store(pdr) fi_+ 1 -> profile_store(pdr);
				endunless;
				quitloop
			endif;
			count fi_+ 1 -> count
		endwhile;

		if isprbrule(this_rule) then
			profile_rules(this_rule) fi_+ 1 -> profile_rules(this_rule)
		endif;

		;;; re-set timer
		profile_interval -> sys_timer(profile_interrupt, 2:1) ;;; 2:1 = virtual
	enddefine;


	;;; set up timer initially
	profile_interval -> sys_timer(profile_interrupt, 2:1); ;;; 2:1 = virtual

	systime() -> run_time;
	action();
	systime() - run_time -> run_time;

	false -> sys_timer(profile_interrupt);

	profile_display(run_time, profile_store);
	rule_display(run_time, profile_rules);

enddefine;


define global macro profile;
	;;; read in a command and profile it
	lvars action = [];
	dlocal popnewline = true;


	;;; read in command
	unless poplastchar == `\n` or poplastchar == `;`
	or null([%until dup(readitem()) == newline do enduntil ->; %] ->> action)
	then
		popval([procedure;  ^^action endprocedure]) -> action;
	endunless;

	unless isprocedure(action) then
		mishap(0, 'NO COMMAND GIVEN TO BE PROFILED')
	endunless;

	chain(action, profile_apply)

enddefine;

endsection;


/*  --- Revision History ---------------------------------------------------
--- John Williams, Mar 16 1992
		Fixed bug in -profile_apply- where system gets stuck in infinite
		loop if no procedure in the calling sequence satisfies
		-profile_include-
--- Aaron Sloman, Jun 24 1991
		Totally re-written, using sys_timer. Entirely new version of
		documentation in HELP PROFILE.
 */
