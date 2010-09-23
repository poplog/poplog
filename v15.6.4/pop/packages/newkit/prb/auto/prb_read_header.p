/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_read_header.p
 > Purpose:         Read header for define_xxxx format
 > Author:          Aaron Sloman, Apr 21 1996
 > Documentation:	HELP RULESYSTEMS
 > Related Files:   $poplocal/local/prb/auto/define_*.p
 > 				Tests in $poplocal/local/prb/test/syntaxtests.p
 */

compile_mode :pop11 +strict;

section;

define prb_read_header(allow_section)
		-> (name, dlocal_spec, cycle_limit, vars_spec, lvars_spec, debug, use_section);
	;;; Used for reading in header, and initialisations for define_ruleset,
	;;;		define_rulefamily, define_rulesystem
	lvars
		name,
		dlocal_spec = false,
		type = false, 			;;; changed if "vars" or "constant" read in
		cycle_limit = false, 	;;; cycle_limit = <limit>;
		vars_spec = false,		;;; [VARS ....];
		lvars_spec = false, 	;;; [LVARS ...];
		debug = pop_debugging, 	;;; debug = <boolean>;
		use_section, 			;;; use_section = <boolean>;
		item
		;

	if allow_section then "false" else false endif -> use_section;

	readitem() -> item;			;;; could be "vars", "constant", or "name"

	;;; get the rulesystem name
	if item == "vars" then
		;;; the default (false -> type, i.e. variable)
		readitem() -> name;
	elseif item == "constant" then	
		;;; should handle other options
		true -> type;
		readitem() -> name;
	else
		item -> name;
	endif;

	if name = ";" then
		;;; anonymous definition. Allowed in define_ruleset
		false -> name;
	else
		 ;;; Semi-colon should terminate header	
		pop11_need_nextreaditem(";") -> ;
		if pop_vm_compiling_list == [] then
			;;; not in a procedure definition
			;;; plant global declaration, "constant" if type
			sysSYNTAX(name, 0, type);
		endif;
	endif;


	if hd(proglist) == "[" and hd(tl(proglist)) == "DLOCAL" then
		prb_read_VARS(false, name, "DLOCAL") -> dlocal_spec;
		;;; get rid of optional semi colon? Or demand one?
		pop11_need_nextreaditem(";") ->
	endif;

	;;; Now read in specifications for cycle limit, VARS spec,
	;;; whether debugging is true, whether sections should be used.
	;;; All are optional. Here are the defaults

	repeat
		if hd(proglist) == "cycle_limit" then
			readitem() -> ;
			pop11_need_nextreaditem("=") -> ;
			readitem() -> cycle_limit;
			pop11_need_nextreaditem(";") -> ;
		elseif hd(proglist) == "debug" then
			readitem() -> ;
			pop11_need_nextreaditem("=") -> ;
			readitem() -> debug;
			;;; debug should be "true" or "false", or a variable
			;;; holding a boolean as value.
			pop11_need_nextreaditem(";") -> ;
		elseif hd(proglist) == "use_section" then
			readitem() -> ;
			pop11_need_nextreaditem("=") -> ;
			readitem() -> use_section;
			if allow_section then
				;;; should be "true" or "false", or a variable
				;;; holding a boolean as value.
				if use_section == "true" then
					current_section -> use_section
				endif;
				pop11_need_nextreaditem(";") -> ;
			else
				mishap(use_section, 1, '"use_section" not permitted.')
			endif
		elseif not(vars_spec) and (prb_read_vars_spec(name, true) ->> vars_spec) then
			;;; continue
		elseif not(lvars_spec) and (prb_read_vars_spec(name, false) ->> lvars_spec) then
			;;; continue
		else
			quitloop()
			;;; and read the rest
		endif;
	endrepeat;


enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 22 1996
	Added option for [DLOCAL ...] declaration
 */
