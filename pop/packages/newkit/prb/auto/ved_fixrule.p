/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/ved_fixrule.p
 > Purpose:         Convert a poprulebase rule to new format, in VED
 > Author:          Aaron Sloman, Apr 16 1996 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
	ENTER fixrule
		Converts the rule
	ENTER fixrule f
		Converts it as first rule, preceded by ruleset header.
	ENTER fixrule l
		Treats it as last rule, leaving 'enddefine;'
	ENTER fixrule fl
		First and last rule, i.e. only one.

Note: if there is no ruleset name, then this inserts prb_rules as the
ruleset name, as a reminder that that is the default.

Using "define :ruleset .... enddefine" you no longer need to declare
ruleset identifiers and initialise them to []. It's done automatically.

See the next three global variables, to control defaults.
*/

section;

global vars
    ;;; use "RULE" if true, "rule" if false, as rule header. Both are
    ;;; accepted by define :ruleset. I think "RULE" stands out better.
	use_RULE = true,

	;;; replace ";" with "==>" between conditions and actions if true.
	use_==>,

	;;; if true, leave ruleset name in comment after each rule name
	leave_ruleset = true,
	;

define ved_fixrule();
	lvars item;
	dlocal vedbreak = false;
	;;; mark the rule definition, and go to first line
	ved_mcp();
	vedjumpto(vvedmarklo, 1);

	if strmember(`f`, vedargument) then
		;;; It's the first rule, so insert define :ruleset <name> ;
		;;; First copy header line, and go to the start
		vedthisline();vedlineabove();vedinsertstring();
		vedscreenleft();
		;;; move past "define" and ":"
		unless vedmoveitem()  = "define" and vedmoveitem() == ":"
		then
			mishap(vedthisline(), 1, 'Rule should start with "define :"')
		endunless;
		;;; delete "rule"
		vedwordrightdelete();
		vedinsertstring('ruleset ');
		;;; delete name of rule
		vedwordrightdelete();
		;;; is there a ruleset name?
		vednextitem() -> item;
		if item == "in" then
			vedwordrightdelete();
			;;; go past ruleset name
			vedwordright();
		else
			vedinsertstring('prb_rules');
		endif;
		vednextitem() -> item;
		if item == ";" then
		else
			vedcharinsert(`;`); vedcleartail();
		endif;
		vednextline();
		;;; Put in blank line after new header
		vedcharinsert(`\r`);
	endif;
	;;; delete up to ":" in old header, leaving 'rule <name>'
	veddo('ds :');
	;;; delete colon
	vedwordrightdelete();
	if use_RULE then
		;;; capitalise "rule"
		veddo('ucw')
	else
		ved_mm();
	endif;
	;;; leave name
	ved_mm();

	if leave_ruleset then
		vednextitem() -> item;
		if item == "in" then
			vedinsertstring(' ;;; ');
			ved_mm();
			ved_mm();
			vedinsertstring('\n    ');
		elseif item == ";" then
			vedwordrightdelete();
			if use_==> then
				vedinsertstring('\n    ==>\n    ');
			else
				vedinsertstring('\n    ;\n    ');
			endif;
		elseif item == "[" then
			vedinsertstring('\n    ');
		else
			;;; delete stuff to right of <name>
			vedcleartail();
		endif
	endif;
	;;; fix separator between conditions and actions?
	if use_==> then
		;;; risky. Could change a POP11 or WHERE action, etc.
		veddo('gsr/  ;@z/    ==>/');
		;;; in case that failed???
		veddo('gsr/\\t;@z/\\t==>/');
	endif;
	;;; Go to end, and delete "enddefine;" if necessary
	vedjumpto(vvedmarkhi, 1);
	unless strmember(`l`, vedargument) then
		;;; not the last rule, so delete 'enddefine;'
        ;;; should probably check!
		vedlinedelete();	
	endunless;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May  5 1996
	Changed to allow ";" preceeded by tab
 */
