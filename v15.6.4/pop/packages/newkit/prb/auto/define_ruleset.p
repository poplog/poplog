/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/define_ruleset.p
 > Purpose:         For defining rulesets for poprulebase
 > Author:          Aaron Sloman, Apr 16 1996 (see revisions)
 > Documentation:	HELP * POPRULEBASE, RULESYSTEMS
 > Related Files:   LIB * POPRULEBASE , LIB * RULEFAMILY
 */

/*
=======================================================================
The syntax is:


  define :ruleset <name>;
    [DLOCAL <global vars spec>];    ;;; optional
    [VARS <popmatchvar spec>];      ;;; optional
	[LVARS <popmatchvar spec>];		;;; optional
	use_sections = <boolean> ;		;;; optional
	debug = <boolean> ;				;;; optional

     RULE <name>
         <conditions>
             ==>
         <actions>

	vars .... ;						;;; optional

     RULE <name>
         <conditions>
             ==>
         <actions>

     ....
   enddefine;

Note: instead of "RULE" for rule headers "rule" is acceptable.

=======================================================================
;;; tests

define :ruleset ;
	debug = false;
	[VARS [v1 = 3, v1=>] [[v2 v3] = 10//3, v2=> v3=>] ];
	[LVARS lv1 lv2];

RULE rr1 weight 7
	[a1][b1 ?lv]
		==>
	[c2][d2]

	vars p,q;
	lvars lv = 99;	;;; this lv and the one in rr1 are different.

RULE rr2
	[c][d ?lv]		;;; should import the lv
		==>
	[e]
enddefine;

prb_rules ==>

section Testing => fred;

define :ruleset fred;
	[DLOCAL [prb_walk = false][prb_allrules = true]];
	[LVARS [v1 = 3, v1=>] [[v2 v3] = 10//3, v2=> v3=>] v4];
	use_section = false;

	RULE fred1
		[a][b]
		==>
		[c][d]

	RULE fred2 weight 3.4
		[c][d]
		==>
		[e]
enddefine;

isruleset("fred") =>
isruleset(fred) =>
endsection;

fred ==>

fred(4).datalist =>

define :ruleset RS;

	vars a,b,silly;

	rule fred1
		[a][b]
		[WHERE a > b]
		[POP11 99*a=> ]
		==>
		[c][d]
		[POP11 silly=>]

	rule fred2 weight 3.4
		[c][d]
		==>
		[e]
		[POP11 'fred2'=>]
enddefine;

RS ==>
*/

uses poprulebase;

section;

global vars syntax rule;

[rule RULE ^^vedbackers] -> vedbackers;

lvars inaprocedure = 0;
lvars
	newruleset = false,
	lastrulesetname = false;

define vars procedure isruleset =
	newproperty([],64, false, "tmparg")
enddefine;

define :define_form global ruleset;
	dlocal inaprocedure;

	if pop_vm_compiling_list /== [] then
		;;; Inside a procedure definition. Must be at execute level, so
		;;; start a new temporary compilation stream.
		inaprocedure + 1 -> inaprocedure;
		[define :ruleset] <> proglist -> proglist;
		;;; this will recursively invoke define_ruleset
		pop11_comp_stream();
		;;; It is in a procedure. Declare the rulesetname as local
		lvars id;
    	unless sys_current_ident(lastrulesetname) ->> id then
        	;;; not declared, use sysLVARS to declare
			sysLVARS(lastrulesetname, 0);
    	elseif identprops(id) /== 0 then
        	;;; mishap, e.g. op, macro or syntax word used as pattern
        	;;; variable.
			mishap(lastrulesetname, 1, 'INAPPROPRIATE RULESET NAME')
/*
    	elseif isident(id) == "perm" then
        	;;; item not declared as lex, but is declared as perm
        	;;; make it local ???
			sysLOCAL(lastrulesetname);
*/
		else
			sysLVARS(lastrulesetname, 0);
    	endunless;
		;;; assign the ruleset to it.
		sysPUSHQ();
;;;	[lastrulesetname ^lastrulesetname ^(valof(lastrulesetname))] =>
		sysPOP(lastrulesetname);
		return()
	endif;

	lvars rulename,
		rulesetname, dlocal_spec, cycle_limit, debug, vars_spec, lvars_spec, use_section,
		vars_list = [],
		;

  	sysLBLOCK(true);	
	prb_read_header(true)
		-> (rulesetname, dlocal_spec, cycle_limit, vars_spec,
				lvars_spec, debug, use_section);

	if cycle_limit then
		mishap('NO cycle_limit ALLOWED IN RULESET', [^rulesetname ^cycle_limit])
	endif;

	if vars_spec then
		subscrv(1, vars_spec)  -> vars_list;	;;; needed when reading conditions and actions
	endif;

	if inaprocedure > 0 then
		rulesetname -> lastrulesetname;
	endif;

	unless rulesetname then
		if inaprocedure > 0 then
			mishap('RULESET NAME MISSING',[])
		endif;
		"prb_rules" -> rulesetname;
		sysSYNTAX(rulesetname, 0, false);
		if vars_spec then
			unless pdprops(subscrv(2, vars_spec)) then
				"VARS_prb_rules" -> pdprops(subscrv(2, vars_spec));
			endunless
		endif;
		if lvars_spec then
			unless pdprops(subscrv(2, lvars_spec)) then
				"VARS_prb_rules" -> pdprops(subscrv(2, lvars_spec));
			endunless
		endif;
	endunless;
	;;; Initialise the ruleset
	lvars countitems = 0;

	if dlocal_spec and listlength(dlocal_spec) > 1 then
		;;; ignore empty [DLOCAL ]
		sysPUSHQ(dlocal_spec);
		countitems + 1 -> countitems;
	endif;


	if use_section and use_section /== "false" then
		countitems + 1 -> countitems;
		;;; add it to the list
		if isword(use_section) then
			sysPUSH
		else
			sysPUSHQ
		endif(use_section)
	endif;

	if vars_spec then
		countitems + 1 -> countitems;
		;;; add it to the list
		sysPUSHQ(vars_spec);
	endif;

	if lvars_spec then
		countitems + 1 -> countitems;
		;;; add it to the list
		sysPUSHQ(lvars_spec);
	endif;

	;;; flush pending stuff so that it doesn't happen in reading conditions.
	sysEXECUTE();

	lvars ruleset_vars = vars_list;

	repeat
		;;; read in rule of form
		;;; 	rule <name> [<weight>]
		;;;		<conditions> <terminator> <actions>
		;;;
		lvars name, next, item, conditions, actions, rule,
			weight = prb_default_rule_weight;

		pop11_need_nextreaditem([rule RULE enddefine vars]) -> item;
	quitif(item == "enddefine");

		while item == "vars" or item == "lvars" do
			if inaprocedure > 0 then
				mishap('NESTED RULESET DEFINITION CONTAINS ' sys_>< item,[])
			endif;
			valof(item)();	;;; cope with the declarations.
			;;; flush pending stuff so that it doesn't happen in reading conditions.
			sysEXECUTE();
			pop11_need_nextreaditem(";") -> ;
			pop11_need_nextreaditem([rule RULE enddefine vars lvars endruleset]) -> item;
		endwhile;
		readitem() -> rulename;

		unless isword(rulename) and rulename /== "[" and rulename /== ";" then
			mishap(rulename,1,'WORD NEEDED FOR NAME OF RULE')
		endunless;

		pop11_try_nextreaditem([weight]) -> next;
		if next == "weight" then
			readitem() -> weight;
			unless isnumber(weight) then
				mishap(rulename, weight, 2, 'NON-NUMBER GIVEN FOR WEIGHT IN RULE DEFINITION')
			endunless;
		endif;

		;;;; start a new LBLOCk
		sysLBLOCK(true);	
		;;; Now read the conditions, after restoring vars_list
		ruleset_vars -> vars_list;

		prb_read_conditions(vars_list) -> (conditions, item);

		;;; Now read the actions

		;;; first see if the set of non-lexical variables needs to be
		;;; extended
		lvars condition;
		for condition in conditions do
			if front(condition) == "VARS" then
				back(condition) <> vars_list -> vars_list;
			endif;
		endfor;

		prb_read_actions(vars_list, [enddefine RULE rule vars]) -> (actions, item);

		;;; Now plant the code to build the rule, and put it in the
		;;; ruleset

		sysPUSHQ(rulename);
    	sysPUSHQ(weight);
		sysPUSHQ(conditions);
		sysPUSHQ(actions);
		sysPUSHQ(rulesetname);
		sysPUSHQ([]);		;;; later should be rulevars??
		sysPUSHQ(true);
		sysCALL("init_prb_rule");
		countitems + 1 -> countitems;
		;;;; end the block
		sysENDLBLOCK();	
		;;; flush pending stuff so that it doesn't happen in reading conditions.
		sysEXECUTE();

	quitif(item == "enddefine" or item == "endruleset");
		item :: proglist -> proglist;
	endrepeat;
	;;; Create initial list for the ruleset
	;;; prb_new_rule will add items to the end of the list
	sysPUSHQ(countitems);
	sysCALL("conslist");

	if inaprocedure > 0 then
		sysENDLBLOCK();	
		sysEXECUTE();	;;; ruleset should now be in newruleset
		exitfrom(pop11_comp_stream);
	else
		;;; assign the list to the name
		sysPOP(rulesetname);
		sysPUSHQ(true);
		sysPUSHQ(rulesetname);
		sysUCALL("isruleset");
		sysPUSHQ(rulesetname);
		sysPUSH(rulesetname);
		sysUCALL("isruleset");
		sysENDLBLOCK();	
	endif;
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 28 2002
	Added isruleset, at request of Mark Gemmell
--- Aaron Sloman, Sep 27 1998
	Allowed [DLOCAL ...] to be empty so that entries controlling
	tracing can be commented out easily.
--- Aaron Sloman, May 26 1996
	Ruled out cycle_limit
	Allowed [DLOCAL ...]
--- Aaron Sloman, May  6 1996
	Made each ruleset and each rule a lexical block, and allowed "lvars"
	declarations between rules.
--- Aaron Sloman, May  1 1996
	Fixed so that [VARS ...] declarations within a rule do not affect
	following rules.

--- Aaron Sloman, Apr 17 1996
	Changed to allow "VARS" declarations in rulesets.
 */
