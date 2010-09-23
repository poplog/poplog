/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/newkit/prb/auto/define_rulesystem.p
 > File:            $poplocal/local/prb/auto/define_rulesystem.p
 > Purpose:         Implements define :rulesystem format
 > 					new version with intervals: July 1999
 > Author:          Aaron Sloman, Apr 17 1996 (see revisions)
 > Documentation:   HELP * RULESYSTEMS
 > Related Files:
 */

/*

define :rulesystem <name>
		[DLOCAL <var spec>]
    	cycle_limit = <integer> ;		;;; optional
    [LVARS <popmatchvar spec>];		;;; optional
	debug = <boolean>;				;;; optional

	with_interval = <interval>;		;;; optional

include: <rulefamily name>
    ;;; cycle_limit = <integer> ;		;;; NO LONGER ALLOWED here
include: <ruleset name>
include: <rulefamily name>
	with_limit = <integer>	;;; optional
include: <ruleset name>
	with_limit = <integer>		;;; optional
include: <rulefamily name>
	with_interval = <interval>	;;; optional
include: <ruleset name>
	with_interval = <interval> 	;;; optional
    ......

    ....

	Where an <interval> can be either
	<integer>
	<word>
	<integer>:<integer>
	<word>:<integer>

	Where the interval is a pair, the first item represents
	the activation interval and the second the cycle limit.
	E.g. 3:5 means every three time-slices run this with
	cycle limit 5. <day>:10 means every day run this with
	cycle limit 10.

enddefine;

;;; TEST EXAMPLES

define :ruleset rs1 ;
	rule rs11 [a][b] ==> [c]
	rule rs12 [x] [y] ==> [c] [d]
enddefine;

rs1 ==>

define :ruleset rs2;
	rule rs21 [a][b] ==> [c]
	rule fred22 [x] [y] ==> [c] [d]
enddefine;

rs2 ==>

define :rulefamily vars rf1;

	[LVARS x [[y z] = 24//7] [w =99]];
	debug = true;
	use_section = current_section;

	ruleset: rs1
	ruleset: rs2
enddefine;

rf1.datalist ==>

vars q = conspair(3,4);

define :ruleset rs3;
	[VARS x [[y z] = destpair(q)] w];

	rule rs31 [a][b] ==> [c]

	rule rs32 [x] [y] ==> [c] [d]
enddefine;

rs3 ==>

define :ruleset rs4;
	rule rs41 [a][b] ==> [c]

	rule rs42 [x] [y] ==> [c] [d]
	rule rs43 [x y] ==> [do rs4] [c d]
enddefine;

rs4=>


define :rulefamily rf2;
	ruleset: rs3
	ruleset: rs4
enddefine;

rf2 ==>

define :rulesystem testrs;
	[DLOCAL [prb_walk = true] [prb_allrules = true]];

	use_section = current_section;	;;; controlled by IFSECTIONS
	[LVARS sim_myself [[myx myy]=destpair(sim_myself)] foo baz];
	;;; [LVARS sim_myself myx myy];
	cycle_limit = 4;
	debug = false;

	with_interval = 2.5;

	include: rf1
	;;; cycle_limit = 4;	;;; NO LONGER ALLOWED
	include: rs3 with_interval = day;
	include: rf2 with_limit = 3
	include: rf2 with_interval = 3:4;
	include: rf2 with_interval = day:4;
enddefine;


testrs ==>
isrulesystem(testrs) =>
isrulesystem("testrs") =>


*/

uses poprulebase

section;


define vars procedure isrulesystem =
	newproperty([],64, false, "tmparg")
enddefine;


include IFSECTIONS

define lconstant plant_cycle_limit(item, rulesysname);
	sysPUSHQ("limit");
	if isword(item) then
		;;; should be a variable whose value is an integer.
		sysPUSH(item);
		sysPUSHQ(0);
		sysPUSHQ(false);
		sysCALL("fi_check");	;;; check integer >= 0
	elseif isinteger(item) then
		sysPUSHQ(item)
	else
		mishap('INTEGER NEEDED FOR CYCLE LIMIT',
			[^item rulesystem ^rulesysname])
	endif;
	sysPUSHQ(2);
	sysCALL("consvector");
enddefine;

define lconstant plant_interval(item, rulesysname, word);
	;;; should be a word (e.g. "weekly". "hourly") or an integer
	sysPUSHQ(word);
	sysPUSHQ(item);
	;;; See if there is a colon, indicating a cycle_limit
	;;; if so, create a pair with the two values
	if hd(proglist) == ":" then
		if word == "interval" then
			lvars limit_value;
			readitem() ->;
			readitem() -> limit_value;
			sysPUSHQ(limit_value);
			sysCALL("conspair");
		else
			mishap('WRONG with_interval FORMAT BEFORE "include"',
				[% item, ":", hd(tl(proglist)), "in", rulesysname%]);
		endif
	endif;
	sysPUSHQ(2);
	sysCALL("consvector");
enddefine;


define :define_form global rulesystem;

	lvars
		rulesysname, dlocal_spec, familyname, item, cycle_limit,
		vars_spec, lvars_spec,
		debug,
		use_section = false,
		;


	prb_read_header(true)
		-> (rulesysname, dlocal_spec, cycle_limit, vars_spec, lvars_spec, debug, use_section);
	unless rulesysname then
		mishap('Name missing in "define :rulesystem"', [])
	endunless;

	if vars_spec then
		mishap(rulesysname, 1, '[VARS ...] NOT ALLOWED IN RULESYSTEM')
	endif;

	;;; plant call of conslist, after reading in rulefamily names, etc.

	lvars
		numrulefamilies = 1;

	;;; Always put the name first, in a reference for easy identification
	sysPUSHQ(rulesysname);
	sysCALL("consref");

	if dlocal_spec and listlength(dlocal_spec) > 1 then
		;;; allow empty [DLOCAL
		sysPUSHQ(dlocal_spec);
		numrulefamilies + 1 -> numrulefamilies;
	endif;

	if cycle_limit then
		plant_cycle_limit(cycle_limit, rulesysname);
		numrulefamilies + 1 -> numrulefamilies;
	endif;


	;;; spec for default popmatchvars
	if lvars_spec then
		sysPUSHQ(lvars_spec);
		numrulefamilies + 1 -> numrulefamilies;
	endif;

	if hd(proglist) == "with_interval" then
	  lblock
		lvars control_value;
		readitem() ->;
		pop11_need_nextreaditem("=") ->;
		;;; read the number or interval indicator (e.g. "weekly")
		readitem() -> control_value;
		plant_interval(control_value, rulesysname, "rulesystem_interval");
		numrulefamilies + 1 -> numrulefamilies;
		;;; read surplus semi-colon if needed
		if hd(proglist) == ";" then
			readitem() ->
		endif;
	  endlblock
	endif;

	IFSECTIONS
	if use_section and use_section /== "false" then
		;;; [section ^use_section]=>
		sysPUSH(use_section),
		numrulefamilies + 1 -> numrulefamilies
	endif;

	repeat
		readitem() -> item;
		quitif(item == "enddefine");
		if item == "include" then
			;;; read colon, then rulefamily or ruleset name.
			pop11_need_nextreaditem(":") ->;
			readitem() -> item;		;;; rulesystem or rulefamily name
			;;; it's a ruleset
			sysPUSHQ(item);	;;; put the word in the list
			numrulefamilies + 1 -> numrulefamilies;

			lvars
				next = hd(proglist),
				control_value = false,
				with_limit = false,
				with_interval = false;

			if next == "with_limit" or next == "with_interval" then
				;;; gobble the word and the following "="
				readitem() ->;
				pop11_need_nextreaditem("=") ->;
				;;; read the number or interval indicator (e.g. "weekly")
				readitem() -> control_value;
				if next == "with_limit" then
					plant_cycle_limit(control_value, rulesysname);
				else
					;;; must be "with_interval"
					;;; can be followed by single value or <interval>:<limit>
					plant_interval(control_value, rulesysname, "interval");
				endif;
				;;; read surplus semi-colon if needed
				if hd(proglist) == ";" then
					readitem() ->
				endif;
			endif;

			if control_value then
				;;; create pair with ruleset or rulefamily
				sysCALL("conspair")
			endif;
		elseif item == "cycle_limit" then
			mishap('cycle_limit no longer allowed: use with_limit',[^rulesysname]);
			pop11_need_nextreaditem("=") ->;
			plant_cycle_limit(readitem(), rulesysname);
			;;; read surplus semi-colon if present
			if hd(proglist) == ";" then
				readitem() ->
			endif;
			numrulefamilies + 1 -> numrulefamilies;
		else
			mishap('Expecting "include" or "enddefine" in define :rulesystem', [^item])
			;;; no other options yet
		endif;
	endrepeat;

	;;; create a list of all the rulefamilies, etc.
	sysPUSHQ(numrulefamilies);
	sysCALL("conslist");
	sysPOP(rulesysname);

	;;; now store the information in the property isrulesystem
	sysPUSHQ(true);
	sysPUSHQ(rulesysname);
	sysUCALL("isrulesystem");
	sysPUSHQ(rulesysname);
	sysPUSH(rulesysname);
	sysUCALL("isrulesystem");

enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 28 2002
	Added isrulesystem
--- Aaron Sloman, Jul  3 1999
	No longer allowed cycle_limit between rulesets in rulesystem.
	Changed to allow interval specs
--- Aaron Sloman, Sep 27 1998
	Allowed empty [DLOCAL] to simplify commenting out trace control
	expressions.
--- Aaron Sloman, May 26 1996
	Made semi colon after "with_limit = .." or "cycle_limit = ..." optional
--- Aaron Sloman,  25 May 1996
	Allowed local limits represented by a pair, consisting of ruleset or rulefamily
	and integer.
--- Aaron Sloman, May 17 1996
	Made it include rulefamilies, and made copies of them.
--- Aaron Sloman, May 17 1996
	Fixed bug that stopped names of rulesets/families being put in the
	list.
 */
