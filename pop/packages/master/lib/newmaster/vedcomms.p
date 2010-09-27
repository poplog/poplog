/* --- Copyright University of Sussex 1992.  All rights reserved. ---------
 > File:            $poplocal/local/lib/newmaster/vedcomms.p
 > Purpose:         VED commands for running NEWMASTER
 > Author:          Robert Duncan and Simon Nichols, May 1987 (see revisions)
 > Documentation:   HELP * NEWMASTER
 > Related Files:
 */


section $-newmaster =>
	ved_newmaster,
	ved_getmaster,
;

;;; command:
;;;		table of NEWMASTER commands

define command =
	newproperty([], 16, false, "perm");
enddefine;

;;; option:
;;;		table of options, re-initialised for each command

define vars option(key);
	lvars key;
	false;
enddefine;

;;; getarg:
;;;		gets the next argument from a list

define lconstant getarg(key, args) -> (arg, args);
	lvars key, arg, args;
	if null(args) then
		newmaster_error(false, 'Missing argument to option: %p', [^key]);
	endif;
	dest(args) -> (arg, args);
enddefine;

;;; getname:
;;;		gets the next filename argument from a list:
;;;		returns '.' (meaning the current file) if the list is empty

define lconstant getname(key, args) -> (arg, args);
	lvars key, arg = '.', args;
	unless null(args) then
	    dest(args) -> (arg, args);
	endunless;
enddefine;

;;; getbackname:
;;;		special case for option "recover": gets a filename argument, but
;;;		optionally preceded by a specific back-number

define lconstant getbackname(key, args) -> (arg, args);
	lvars key, arg, args, n = false;
	getname(key, args) -> (arg, args);
	if arg /= nullstring and isnumbercode(arg(1)) then
		strnumber(arg) -> n;
		getname(key, args) -> (arg, args);
	endif;
	[^n ^arg] -> arg;
enddefine;

;;; option_table:
;;;		list of available options, searched in order

lconstant option_table = [
		/* NAME		OPTION		COMMAND?	ARGUMENT?	   */
	    {comment	comment		^false		^getarg			}
	    {doc		doc			^false		^false			}
	    {delete		delete		delete		^getname		}
	    {force		force		^false		^false			}
	    {get		get			get			^getname		}
		{history	history		history		^getname		}
	    {install	install		install		^false			}
	    {lock		lock		^false		^false			}
	    {local		local		^false		^false			}
	    {LOCAL		local		^false		^false			}
		{mark		mark		mark		^getarg			}
	    {name		name		^false		^getarg			}
		{quit		quit		^false		^false			}
	    {recover	recover		recover		^getbackname	}
	    {rm			delete		delete		^getname		}
	    {transport	transport	install		^false			}
		{unlock		unlock		unlock		^getname		}
	    {user		user		^false		^getarg			}
	    {USER		user		^false		^getarg			}
	    {version	version		^false		^getarg			}
	],
;

;;; init_options:
;;;		initialises the -options- property from a list of arguments
;;;		and returns the principal command to run

define lconstant init_options(args, get) -> action;
	lconstant NAME = 1, OPTION = 2, COMMAND = 3, ARG = 4;
	lvars arg, args, entry, get, action = false;
	;;; principal action for "getmaster" is to get the current file
	if get then ("get", '.') -> (action, option("get")) endif;
	until null(args) do
		dest(args) -> (arg, args);
	    if isstartstring('-', arg) then allbutfirst(1, arg) -> arg endif;
	    nextif(arg = nullstring);
		for entry in option_table do
			if isstartstring(arg, entry(NAME)) then
				true -> option(entry(OPTION));
				if entry(COMMAND)  then
					if action and action /== entry(COMMAND) then
						newmaster_error(
							false,
							'Incompatible options: %p/%p',
							[% action, entry(COMMAND) %]);
					endif;
					entry(COMMAND) -> action;
					;;; command may be different from the option itself:
					;;; make sure it's selected
					unless option(action) then
						true -> option(action);
					endunless;
				endif;
				if entry(ARG) then
					;;; needs an argument
					entry(ARG)(entry(OPTION), args) -> (arg, args);
					arg -> option(entry(OPTION));
				endif;
				nextloop(2);
			endif;
		endfor;
		if get then
			;;; assume it's an explicit file name to get:
			;;; this will override the '.' default
			['get' ^arg ^^args] -> args;
			false -> get;
		else
			newmaster_error(false, 'Unknown option: %p', [^arg]);
		endif;
	enduntil;
enddefine;

;;; parse_arguments:
;;;		break a string into a list of arguments, where an argument is
;;;		any sequence of non-whitespace characters, or a normal Pop11 string
;;;		if enclosed in string quotes.

define lconstant parse_arguments(string);
	lvars string, c, input = incharitem(stringin(string)), n = 0;
	[%	until (nextchar(input) ->> c) == termin do
			if item_chartype(c) == 6 then		;;; whitespace
				unless n == 0 then consstring(n), 0 -> n endunless;
			elseif item_chartype(c) == 7 then	;;; string quote
				unless n == 0 then consstring(n), 0 -> n endunless;
				c -> nextchar(input);
				input();
			else
				c, n + 1 -> n;
			endif;
		enduntil;
		unless n == 0 then consstring(n) endunless;
	%];
enddefine;


;;; -----------------------------------------------------------------------

define lconstant do_command(get);
	lvars	get, action, pdr;
	dlocal	option = newproperty([], 8, false, "perm");

	;;; Process arguments
	init_options(parse_arguments(vedargument), get) -> action;

	;;; Special cases
	if option("local") then
		if option("version") and option("version") /= 'local' then
			newmaster_error(false, 'Not a local version: %p',
				[% option("version") %]);
		endif;
		'local' -> option("version");
	endif;

	;;; Default action is to add file header or revision note
	unless action then "header" -> action endunless;
	unless command(action) ->> pdr then
		newmaster_error(action, 'missing command procedure');
	endunless;
	pdr();
enddefine;

define global vars ved_newmaster =
	do_command(% false %);
enddefine;

define global vars ved_getmaster =
	do_command(% true %);
enddefine;

endsection;		/* $-newmaster */


/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Mar 16 1992
		Made option processing table-driven.
		Amalgamated "newmaster" and "getmaster" commands.
		Moved to the newmaster lib directory.
--- Robert John Duncan, Dec 10 1990
		Added "delete" option
--- Rob Duncan, Jun  6 1990
		Improved handling of master version information.
--- Rob Duncan, Jul  3 1989
	    Changed the option processing to use -getopt- rather than always
		using the itemiser: this means that file names as arguments no
		longer need string quotes (although they're still accepted if used).
 */
