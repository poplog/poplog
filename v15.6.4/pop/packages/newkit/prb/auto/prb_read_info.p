/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_read_info.p
 > Purpose:
 > Author:          Aaron Sloman, Oct 29 1994
 > Documentation:
 > Related Files:
 */

/* FACILITIES FOR READ and MENU ACTIONS AND INTERACTION */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
include WID.ph

uses poprulebase;

uses prb_replace;

uses prb_assoc_memb;
uses prb_interact;
uses prb_print_menu;
;;; uses macro WID defined in lib poprulebase

section $-prb;

;;; The next procedure currently handles both READ and MENU actions.
;;; They should be separated out.

;;; The following dynamic variables are needed in the next procedure
vars Pmessage, Pconstraint, P_act, P_item, P_test, P_rest, ANSWER;


define prb_read_and_add(rule_instance, action, with_menu);
	;;; Handle "READ" and "MENU" actions.
	lvars action, rule_instance, oldvars = popmatchvars, with_menu,
		options, mappings, rule = prb_ruleof(rule_instance);

	;;; All the following must be dynamic locals
	dlocal Pmessage, Pconstraint = #_< [==] >_#,
		P_act, P_item, P_test, P_rest, ANSWER;

	dlocal prb_remember, popmatchvars;	;;; may be altered by prb_interact

	if with_menu then
		action --> #_< [MENU ? ^WID Pmessage:isvector ?? ^WID P_rest] >_#;
	else
		action --> #_< [READ ? ^WID Pmessage ?? ^WID P_rest] >_#;
	endif;

	if isvector(last(P_rest)) then
		;;; It's an explanation: ignore it here.
			allbutlast(1,P_rest) -> P_rest;
	endif;

	last(P_rest) -> P_act;

	if with_menu then
		[OR ^(applist(Pmessage(2), front))] -> Pconstraint;
		if datalength(Pmessage) == 3 then
			Pmessage(3)
		else
			false
		endif -> mappings;
		$-prb_print_menu(%Pmessage(1), Pmessage(2)%) -> Pmessage;
	else
		if length(P_rest) == 2 then
			front(P_rest) -> Pconstraint
		endif
	endif;

	repeat
		prb_interact(Pmessage, action, rule_instance, false) -> ANSWER;
		if ANSWER matches Pconstraint
		or	(Pconstraint matches #_< [ : ? ^WID P_test] >_# and length(ANSWER) ==1
			and valof(P_test)(front(ANSWER)))
		or (Pconstraint matches #_< [LOR ?? ^WID P_test] >_# and member(ANSWER,P_test))
		or (Pconstraint matches #_< [OR ?? ^WID P_test] >_#
			and ANSWER matches #_< [? ^WID P_item] >_#
			and member(P_item,P_test))
		then
			if with_menu then
				front(ANSWER) -> ANSWER;
				if mappings then
					$-prb_assoc_memb(ANSWER, mappings) -> P_item;
					if P_item then P_item -> ANSWER endif;
					;;; otherwise use original ANSWER
				endif;
				if P_act matches #_< [? ^WID P_item] >_# then
					prb_do_action(
						prb_value(prb_replace("ANSWER", ANSWER, P_item)),
						rule, rule_instance)
				else
					$-prb_assoc_memb(ANSWER, P_act) -> P_item;
					if P_item then
						prb_do_action(prb_value(P_item), rule, rule_instance)
					else
						mishap(ANSWER,action,2, 'NO ACTION FOR ANSWER TYPED')
					endif
				endif
			elseunless P_act == [] then
				prb_do_action(
						prb_value(prb_replace("ANSWER", ANSWER,P_act)),
						rule, rule_instance)
			endif;
			return()
		else [^ANSWER does not match ^Pconstraint] =>
		endif;
	endrepeat
enddefine;

endsection;

define global vars procedure prb_read_info =
	$-prb$-prb_read_and_add(%false%)
enddefine;

define global vars procedure prb_menu_interact =
	$-prb$-prb_read_and_add(%true%)
enddefine;

define global vars procedure prb_pause_read(rule_instance, action);
	lvars rule_instance, action;
		if prb_pausing then
			;;; wait for user to press return
			$-prb$-prb_read_and_add(
				rule_instance, #_< [READ '' [==] []] >_#, false)
		endif
enddefine;


endsection;
