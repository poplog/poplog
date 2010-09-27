/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/define_rulefamily.p
 > Purpose:         Implements define :rulefamily format
 > Author:          Aaron Sloman, Apr 17 1996 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

[VARS ...] not allowed.

define :rulefamily <name>
	[DLOCAL <global var spec>];			;;; optional
    [LVARS <popmatchvar spec>];			;;; optional
	debug = <boolean>;					;;; optional
	use_section = <boolean or name>;	;;; optional
    <..??? other initialisation information ???...>

    ruleset: <ruleset name>
    ruleset: <ruleset name>
    ......

    ....

enddefine;

;;; TEST EXAMPLES

define :ruleset fred1 ;

	rule fred11 [a][b] ==> [c]

	rule fred12 [x] [y] ==> [c] [d]
enddefine;

fred1 ==>

define :ruleset joe1;
	rule joe11 [a][b] ==> [c]

	rule fred22 [x] [y] ==> [c] [d]
enddefine;

joe1 ==>
fred1==>

untrace prb_consrulefamily;

define :rulefamily RF1;

	ruleset: fred1
	ruleset: joe1
enddefine;

RF1==>
isrulefamily(RF1) =>
isrulefamily("RF1") =>

RF1.prb_next_ruleset==>
RF1.prb_family_dlocal==>

define :rulefamily vars RF2;
	[DLOCAL [prb_walk = true]];
	[LVARS x [[y z] = 24//7] w];
	debug = true;
	use_section = true;

	ruleset: fred1
	ruleset: joe1
enddefine;

RF2 ==>
RF2.prb_next_ruleset==>
RF2.prb_family_dlocal==>

RF2.datalist =>

RF2.prb_family_prop =>
RF2.prb_family_prop.datalist ==>
(RF2.prb_family_prop)("joe1")==>
(RF2.prb_family_prop)("fred1")==>

appproperty(RF2.prb_family_prop,
	procedure(key, val);
		[[key ^key][val ^val]] ==>
	endprocedure);

RF2.prb_family_matchvars =>


*/

uses poprulebase
uses rulefamily

;;; need
;;; prb_consrulefamily(name, rulesets, next, lim, sect, debug, vec, dlvec) -> system;
uses prb_consrulefamily

section;

define vars procedure isrulefamily =
	newproperty([],64, false, "tmparg")
enddefine;

define :define_form global rulefamily;

	lvars
		familyname, dlocal_spec, type, item, cycle_limit,
		vars_spec, lvars_spec, debug, use_section;

	prb_read_header(true) ->
		(familyname, dlocal_spec, cycle_limit, vars_spec, lvars_spec, debug, use_section);

	unless familyname then
		mishap('Name missing in "define :rulefamily"', [])
	endunless;

	if vars_spec then
		mishap(familyname, 1, '[VARS ...] NOT ALLOWED IN RULEFAMILY')
	endif;

	;;; plant call of constructor, prb_consrulefamily, after planting args
	;;; and reading ruleset specs. Args are
	;;;     name, rulesets, next, lim, sect, debug, vec);

	;;; first the name
	sysPUSHQ(familyname);

	;;; now read the rulesets.
	lvars
		numrulesets = 0, firstruleset = false;

	repeat
		pop11_need_nextreaditem([ruleset enddefine ]) -> item;
		quitif(item == "enddefine");
		if item == "ruleset" then
			;;; read colon, then ruleset name.
			pop11_need_nextreaditem(":") ->;
			readitem() -> item;
			unless firstruleset then
				item -> firstruleset
			endunless;
			numrulesets + 1 -> numrulesets;
			sysPUSHQ(item);	;;; name of ruleset
		else
			;;; no other options yet
		endif;
	endrepeat;

	if firstruleset then
		;;; create a list of all the ruleset names
		sysPUSHQ(numrulesets);
		sysCALL("conslist");
		if debug then sysPUSHQ else sysPUSH endif(firstruleset);
	else
		mishap(0,'No rulesets found after "define :rulefamily"');
	endif;
	if cycle_limit then
		mishap('NO cycle_limit ALLOWED IN RULEFAMILY', [^familyname ^cycle_limit])
	endif;
	;;; dummy cycle limit
	sysPUSHQ(false);


	if isword(use_section) then
		sysPUSH
	else
		sysPUSHQ
	endif(use_section);

	if isword(debug)then
		sysPUSH
	else
		sysPUSHQ
	endif(debug);

	;;; spec for default popmatchvars
	if lvars_spec then
		sysPUSHQ(lvars_spec);
	else
		sysPUSHQ(false)
	endif;

	;;; spec for DLOCAL list
	if dlocal_spec and listlength(dlocal_spec) > 1 then
		;;; allow empty DLOCAL list
		sysPUSHQ(dlocal_spec);
	else
		sysPUSHQ(false)
	endif;


	sysCALL("prb_consrulefamily");
	sysPOP(familyname);

	;;; now store the information in the property isrulefamily
	sysPUSHQ(true);
	sysPUSHQ(familyname);
	sysUCALL("isrulefamily");
	sysPUSHQ(familyname);
	sysPUSH(familyname);
	sysUCALL("isrulefamily");

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 28 2002
		Added isrulefamily
--- Aaron Sloman, Sep 27 1998
	Alloed empty [DLOCAL] expressions
--- Aaron Sloman, May 26 1996
	Disallowed cycle_limit in rulefamily
 */
