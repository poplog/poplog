/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/interpret_specs.p
 > Purpose:			Interpret a featurespec structure
 > Author:          Aaron Sloman, Apr 22 1997 (see revisions)
 > Documentation:	HELP FEATURESPEC
 > Related Files:
 */

section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib;


;;; This translation table can be given different values in
;;; different contexts. The default is to return false
;;; This will be tried before standard_abbreviations
define vars procedure featurespec_abbreviation(item) -> result;
	false -> result
enddefine;

define vars procedure standard_featurespec_abbreviations =
	newproperty(
	[ [reactor rc_informant_reactor]
	  [ident rc_informant_ident]
	  [constrain rc_constrain_contents]
	  [itemlabel rc_informant_label]], 16, false, "perm");
enddefine;


define vars expand_spec_field_name(name) -> proc;
	;;; should return a procedure which is a field accessor
	false -> proc;
	if isprocedure(name) then name -> proc;
		return
	elseif isword(name) then
		;;; see if the word is an abbreviation, if not use it as it is
		recursive_valof(
			featurespec_abbreviation(name)
			or standard_featurespec_abbreviations(name)
			or name) -> proc
	else
		;;; this will generate a mishap
		name -> proc;
	endif;
	unless isprocedure(proc) then
		mishap('FIELD NAME OR ABBREVIATION NEEDED', [^name])
	endunless
enddefine;
	

define lconstant set_spec_slots( item, slot_inits ) with_props 2;
	;;; adapted from objectclass set_slots to allow the procedure
	;;; name to be used instead of the procedure
	until slot_inits.null do
		lvars ( field, value, slot_inits ) = slot_inits.dest.dest;
		;;; unless #| value -> recursive_valof(field)( item ) |# == 0 do
		unless #| value -> expand_spec_field_name(field)( item ) |# == 0 do
			mishap( 'EXTRA RESULTS FROM SLOT INITIALISER', [^field] )
		endunless;
	enduntil
enddefine;


define interpret_specs(obj, specs);
	;;; Specs is the final argument of a create_... procedure.
	;;; It is either a bottom level feature spec, a vector or a list of
	;;; feature specs. It is used to update slots of the objectclass
	;;; instance obj after the obj has been created with default values.

	returnunless(specs);	;;; It could be false, if so do nothing

	if isvector(specs) then
		;;; It is a bottom level featurespec, so interpret it directly
		lvars list = specs.destvector.conslist;
		set_spec_slots(obj, list);

		;;; reclaim free space
		sys_grbg_list(list);
		0 -> list;	;;; for uncleared alpha registers...

	elseif islist(specs) then
		;;; Interpret the featurespecs in the list in left to right order
		lvars sub_specs;
		for sub_specs in specs do
			interpret_specs(obj, sub_specs)
		endfor
	else
		mishap('Object specs should be list, vector or false', [^specs]);
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug  2 2002
		Expanded to use user definable table
			featurespec_abbreviation = identfn;

		accessed through
			expand_spec_field_name(name) -> proc;

--- Aaron Sloman, Jul  7 1997
	Altered to allow word instead of procedure in spec field name


         CONTENTS - (Use <ENTER> g to access required sections)

 define vars procedure featurespec_abbreviation(item) -> result;
 define vars procedure standard_featurespec_abbreviations =
 define vars expand_spec_field_name(name) -> proc;
 define lconstant set_spec_slots( item, slot_inits ) with_props 2;
 define interpret_specs(obj, specs);

 */
