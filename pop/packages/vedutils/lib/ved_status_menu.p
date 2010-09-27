/* --- Copyright University of Birmingham 1993. All rights reserved. ------
 > File:            $poplocal/local/lib/ved_status_menu.p
 > Purpose:			Create a set of menus for display on status line
 > Author:          Aaron Sloman, May 30 1993
 > Documentation:	See below
 > Related Files:
 */


/*
HELP VED_STATUS_MENU                                   A.Sloman May 1993

LIB VED_STATUS_MENU
This provides two procedures ved_make_options and ved_status_menu, to be
used for creating menus to display on the command line.


         CONTENTS - (Use <ENTER> g to access required sections)

 -- Creating options and menus
 -- Displaying the menu and running the selected action
 -- Example 1 VED utilities.
 -- Example 2, Making VED's dired utilities available by menu

-- Creating options and menus -----------------------------------------
ved_make_options(optionlist, statuswidth) -> vector
	Takes two arguments a list and an integer, and returns a vector
	containing a property and a vector of strings for menus.

	The list is a list of 3 element lists each consisting of
		- A character code
		- An action (a word, a string, or a list containing a string)
		- A string to be included in menus
	as illustrated in the example below.

	The integer is the current statusline width.

	ved_make_options creates a property mapping character codes to
	actions, and a vector of menustrings derived from the the last
	item in each list.

-- Displaying the menu and running the selected action ----------------

ved_status_menu(vector);
	Takes a word or a vector. The word should have as its value a vector
	of a suitable type.
	The vector determines a set of menus to be displayed and actions to
	be performed on the basis of selection from the menus.
	The vector should contain
	1. a property mapping characters to actions as described above,
	2. a vector of menu strings as created by ved_make_options.

	ved_status_menu displays menus one at a time on the status line
	till the user makes a choice by choosing one of the characters in
	the property.

	It then "performs" the action selected, as follows.

	If the action is a string, it is given as argument to veddo.

	If the action is a list containing a string the string is put on the
	status line for the user to complete, then type RETURN.

	If the is a vector then it is assumed to represent a sub-menu of
	options, and ved_status_menu is applied to it.

	If the action is a word its valof must be either a procedure, which
	is run or a vector suitable to give to ved_make_options.

	Pressing RETURN always gets the next menu string, and after the last
	string takes you back to the first one.

	CTRL-L can be used to refresh the screen if it gets corrupted
	before you make a choice.

Two examples of use follow.


-- Example 1 VED utilities. -------------------------------------------
;;; The following could remind users of the main VED file manipulation
;;; facilities.

uses ved_status_menu.p

global vars
	file_optionlist =
			[
			 [`f` vedfileselect 'f(show menu of files)']
			 [`q` ved_q 'q(quit this file)']
			 [`w` ved_w 'w(save all files)']
			 [`t` vedtopfile 't(go to top)']
			 [`e` vedendfile 'e(go to end)']
			 [`m` vedmarklo 'm(mark first)']
			 [`M` vedmarkhi 'M(mark last)']
			 [`s` ['/<string>'] 's(search forward)']
			 [`r` ['s/<string1>/<string2>'] 'r(replace)']
			 [`R` ['gs/<string1>/<string2>'] 'R(Global replace)']
			 [`d` vedlinedelete 'd(delete line)']
			 [`D` ved_yankl 'D(undelete line)']
			 [`a` identfn 'a(abort menu)']
			 ;;; next line refers to the next menu, below
			 [`\^D` dired_optionlist '^D(Dired options)']
			]
;

ved_make_options(file_optionlist, 78) -> file_optionlist;


vedsetkey('\^v', ved_status_menu(%"file_optionlist"%));



-- Example 2, Making VED's dired utilities available by menu ----------
;;;The following could go in your vedinit.p to make ved_dired options
;;; readily available

uses ved_status_menu.p

global vars
	dired_optionlist =
			[
			 [`.` 'dired .' '.(list this dir)']
			 [`/` 'dired -d .' '/(current subdirs)']
			 [`e` 'dired' 'e(expand)']
			 [`E` 'qdired' 'E(q and expand)']
			 [`u` 'dired -dcd' 'u(unexpand)']
			 [`h` 'help dired.short' 'h(dired help)']
			 [`l` 'dired -l' 'l(ls -l)']
			 [`t` 'dired -lt' 't(ls -lt)']
			 [`\^?` 'dired -rm' 'DEL(delete)']
			 [`m` ['dired -mv'] 'm(move or rename)']
			 [`M` ['dired -mvd'] 'M(rename in situ)']
			 [`d` 'dired -d' 'd(show subdirs)']
			 [`c` ['dired -cp'] 'c(copy)']
			 [`C` ['dired -cpd'] 'C(copy in dir)']
			 [`r` 'dired -r' 'r(set dired read only)']
			 [`w` 'dired -w' 'w(set writeable)']
			 [`p` 'dired -peek' 'p(peek at file)']
			 [`*` ['dired '] '*(dired with pattern)']
			 ;;; next line refers to previous menu
			 [`f` file_optionlist 'f(file menu)']
			 [`a` identfn 'a(abort)']
			]
;
ved_make_options(dired_optionlist, 78)-> dired_optionlist;

vedsetkey('\^X', ved_status_menu(%"dired_optionlist"%));

*/


section;

;;; compile_mode :pop11 +strict;

define global procedure ved_make_options(optionlist, statuswidth) -> vec;
	lvars
		optionlist, statuswidth, options, menus,
		item, char, entry, string,
		menu_start = '[',
		menu = menu_start, menulist = [];

	lconstant morestring = 'CR(more)]';

	statuswidth - datalength(vedstatusheader) - 6 -> statuswidth;
	lvars maxlen = statuswidth - datalength(morestring);

	;;; create property, and list of menu strings.
	newproperty([], listlength(optionlist), false, "perm") -> options;

	for item in optionlist do
		unless listlength(item) == 3 then
			mishap('MENU ITEM SHOULD HAVE [CHAR ACTION STRING]', [^item])
		endunless;
		dl(item) -> (char, entry, string);
		;;; update property with options, after checking
		if options(char) then
			mishap(
				'Same Character With Two Options: ' <> fill(char,' '),
				[%options(char), entry%])
		else
			entry -> options(char);
		endif;
		;;; build menus
		if datalength(string) + datalength(menu) <= maxlen then
			menu <> string <> vedspacestring -> menu
		else
			;;; save old menu and start new one.
			[^^menulist ^(menu <> morestring)] -> menulist;
			menu_start <> string <> vedspacestring -> menu
		endif
	endfor;
	;;; Now build the menu vector
	{% explode(menulist), menu<>morestring %} -> menus;
	{% options, menus%} -> vec;
enddefine;

define global procedure ved_status_menu(vector);
	lvars vector, options, menus, menu, char, option,
		menu_num = 1,
		menu_size;

	dlocal vedwiggletimes = 2;

    recursive_valof(vector) -> vector;

	explode(vector) -> (options, menus);

	;;; if it's a word get the value
	recursive_valof(options) -> options;
	recursive_valof(menus) -> menus;
	datalength(menus) -> menu_size;

	;;; Get user option
	;;; show first menu then if "?" is typed rotate menus
    repeat
		subscrv(menu_num, menus) -> menu;
		vedsetstatus(menu, false, true);
		vedwiggle(0,vedscreenwidth);
		vedscr_read_input() -> char;
		if char == `?` or char == `\r` then
			;;; rotate menus
			(menu_num rem menu_size) + 1 -> menu_num
		elseif options(char) ->> option then
			;;; option found
			quitloop
		elseif char == `\^L` then vedrefresh();
		else
			vedscreenbell()
		endif
	endrepeat;

	;;; Now use the option
	if isword(option) then
		recursive_valof(option) -> option;
	endif;

	if isprocedure(option) then
		chain(option)
	elseif isvector(option) then
		chain(option, ved_status_menu)
	elseif isstring(option) then
		chain(option,veddo)
	elseif islist(option) then
		vedenter();
		vedinsertstring(front(option));
		vedcharright();
	else
		vederror('Something wrong: - ' sys_>< option)
	endif;
enddefine;

endsection;
