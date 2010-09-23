/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_vman.p
 > Purpose:         Get an index to man files, and then run man
 > Author:          Aaron Sloman, Feb 26 1993 (see revisions)
 > Documentation:	HELP VED_VMAN
 > Related Files:	LIB * VED_MAN
 */

compile_mode :pop11 +strict;

uses ved_g

section;

include sysdefs

lvars
	solaris = false,
	sunos = false;

#_IF DEF SUNOS

#_IF DEF SYSTEM_V

	true -> solaris;

#_ELSE

	true -> sunos;

#_ENDIF

#_ENDIF




;;; Global constants and variables used below

;;; This may need to be changed locally
global vars
	vman_default_dirs = ['/usr/man' '/usr/local/man'];	;;; default list of "man" directories

lconstant
	;;; String to go on first line of VMAN index file
	man_message = 'VMAN INDEX: MAN FILES FOUND (put cursor on one then REDO or ENTER vman)',

	;;; Two menu strings used by get_man_dir
	menu1 = '*:all 1:commands 2:system calls 3:routines 4:devices ?:others :',

	menu2 = '5:files 6:games 7:misc 8:admin l:local n:new o:old ?:others :',

	name_terminators = '\s\t.',

	;;; Boolean flag specifying whether this is a SVR5 type system
	hp_system = issubstring('hp', hd(sys_machine_type)),
	sysv_type = (sys_os_type(3) > 5.0 or hp_system),
;


;;; Get default command for running "ls" on library directories
;;; to produce the right kind of multi-column format for each
;;; man directory
#_IF sysv_type

	global vars vman_ls_command = '/bin/ls -xL';

#_ELSEIF sys_file_exists('/usr/5bin/ls')

	global vars vman_ls_command = '/usr/5bin/ls -xL';

#_ELSE

	global vars vman_ls_command = '/bin/ls -CL';

#_ENDIF

define lconstant unpack_manpath() -> dir_list;
	;;; break $MANPATH into a list of directory names
	lvars	dir_list, string = systranslate('MANPATH'), dir;

	if string then
		[%sys_parse_string(string, `:`)%] -> dir_list;
		[%
			for dir in dir_list do
				if sys_file_exists(dir) then dir endif
			endfor
		%]
	else
		vman_default_dirs
	endif -> dir_list;
enddefine;

define lconstant get_man_dir() -> sub_dir;
	;;; Ask user which "man" category is wanted, using the categories
	;;; shown in the menu1 and menu2 strings. "*" gets everything.

	lvars menu, char, sub_dir, first = true;

	lconstant char_string = '0';

	if vedargument = nullstring then

		;;; show menu1 or menu2. If "?" is typed switch menus
    	repeat
			if first then menu1 else menu2 endif -> menu;
			vedsetstatus(menu, false, true);
			vedwiggle(0,vedscreenwidth);
			vedscr_read_input() -> char;
			if char = `?` then
				not(first) -> first
			elseif strmember(char, 'lno*12345678') then
				quitloop
			elseif char = `\^L` then vedrefresh();
			else
				vedscreenbell()
			endif
		endrepeat;
		char -> subscrs(1, char_string);
		char_string
	else
		vedargument
	endif -> sub_dir;


	if sysv_type then 'man' sys_>< sub_dir sys_>< '*'
	else 'man' sys_>< sub_dir
	endif -> sub_dir;
	;;; Veddebug([sub_dir ^sub_dir]);
enddefine;

define lconstant nextname() -> name;
	;;; Get the next name to right of cursor, and move cursor to its right.

	lvars
		char, name,
		col = vedcolumn,
		startcol = vedcolumn,
		line = vedthisline();;

	;;; first move right off spaces, tabs, or dot character to start of name
	while col <= vvedlinesize
	and strmember(subscrs(col, line), name_terminators)
	do
		col fi_+ 1 -> col;
	endwhile;
	col -> startcol;

	;;; find next space tab or dot character, ending name
	until col > vvedlinesize
	or strmember(subscrs(col, line), name_terminators)
	do
		col fi_+ 1 -> col;
	enduntil;
	;;; now extract the name
	substring(startcol, col - startcol, line) -> name;
	;;; move cursor to end of name
	col -> vedcolumn;
enddefine;

define lconstant thisname() -> name;
	;;; return file name under or to right of VED cursor
	;;; also move VED cursor to right of the name
	lvars name,
		col = vedcolumn,
		line = vedthisline();

	;;; find beginning of name by moving left to space tab
	until col == 1 or strmember(fast_subscrs(col, line), '\s\t') do
		col fi_- 1 -> col;
	enduntil;
	col -> vedcolumn;
	nextname() -> name;
enddefine;

define lconstant vman_get_file();
	;;; Inside vman index file. Get man file

	lvars filename, volume = false, file_arg, man_args;

	min(vedcolumn, vvedlinesize) -> vedcolumn;
	thisname() -> filename;
	;;; Veddebug(filename);

	if filename = 'in' or filename = 'rpc' then
		;;; for some reason these prefixes are not part of man argument
		vedcharright();
		thisname() -> filename
	endif;

	if sunos and vedcurrentchar() == `.` then
		;;; man file name followed numeral or something like "2v"
		;;; extract this to form part of argument for "man"
		vedcharright();
		nextname() -> volume;
		;;; Veddebug(volume);
		volume sys_>< space sys_>< filename;
		if solaris then
			'-s ' sys_>< volume sys_>< space sys_>< filename
		else
			volume sys_>< space sys_>< filename;
		endif
	else filename
	endif  -> man_args;
	;;; Veddebug(man_args);

	;;; Now build up the "man" command and give it to veddo, e.g. to
	;;; simulate something like "ENTER man 2v dup"
	lvars oldfile = vedcurrentfile;
	veddo('man ' sys_>< man_args);
enddefine;

define lconstant vman_build_index();
	;;; Invoked outside a Vman index file. So create the index
	lvars
		oldfile = vedcurrentfile,
		dir,  command, man_section, sub_dir,

		man_subdir = get_man_dir(),		;;; get user selection

		man_dirs = unpack_manpath(),	;;; get "man" search list
	;

	;;; Veddebug([man_subdir ^man_subdir]);

	lvars
	 	sub_dirs =
		[%	;;; make a list of sub-directories
			for dir in man_dirs do
				dir dir_>< man_subdir -> sub_dir;
				if sysv_type
				or strmember(`*`, sub_dir)
				or sys_file_exists(sub_dir) then
					sub_dir
				endif;
				;;; in case there are SGML man files, add "sman" type directories
				;;; Veddebug([dir ^dir]);
				if dir = '/usr/man' then
					dir dir_>< ('s' <> man_subdir) -> sub_dir;
					;;; Veddebug([sub_dir ^sub_dir]);
					sub_dir;
				endif
			endfor
		%];

	if sub_dirs == [] then
		vederror('NO SUCH MAN DIRECTORIES AS :- man/' <> man_subdir)
	endif;

	;;; build up a string to form the argument for veddo
    consstring
	(#| explode('sh '),
			explode(vman_ls_command), `\s`,
			for sub_dir in sub_dirs do
				explode(sub_dir), `\s`
			endfor
		|#) -> command;

	;;; Veddebug(command);

	veddo(command);
	;;; That should have created lists of relevant man files, in a
	;;; new VED buffer. Check.
	if oldfile == vedcurrentfile then
		vederror('NO MAN FILES FOUND')
	endif;

	;;; prevent time-wasting preliminary screen output
	dlocal vedediting = false;

	;;; Insert instructions at top of file.
	;;; (Also used to identify this later as a vman file)
	vedtopfile();
	vedlineabove(); vedinsertstring(man_message);

	;;; Make sure visible area starts at top of file
	0 -> vedlineoffset;
	;;; insert blank line
	vedlinebelow();
	;;; Now remove the line produced by vedgenshell, starting "sh"
	vednextline();
	if isstartstring('sh ', vedthisline()) then
		nullstring -> vedthisline()
	else
		vedlineabove();
	endif;

	if length(sub_dirs) > 1 or sysv_type then
		;;; Now prepare an index to directories, using ved_indexify
		;;; Assume eachline starting with `/` names a directory
		;;; Go to top and start searching for directories, deleting
		;;; references to empty directories.
		vedtopfile();
		while ved_try_search('@a@/', #_< [nowrap] >_#) do
			if issubstring(' No ', vedthisline()) then
				vedlinedelete();
				vedcharup();
			endif;
			vedcharright();
		endwhile;
		vedtopfile();
		;;; Now prepare an index to directories, using ved_indexify
		veddo('gs;@a/;-- /;');
		veddo('indexify');
	else
		;;; There's only one sub-directory. Insert its pathname
		vedlinebelow();
		vedinsertstring(hd(sub_dirs))
	endif;

	;;; go back to top line, with instructions
	vedtopfile();
	vedputcommand('vman');
	chain(vedrefresh);
enddefine;


global vars procedure ved_vman_init;

define lconstant default_ved_vman_init();
	vedset keys
		"ENTER vman" = esc esc 1
	endvedset
	identfn -> ved_vman_init
enddefine;

;;; assign default value
if isundef(ved_vman_init) then
	 default_ved_vman_init -> ved_vman_init
endif;

define global ved_vman();
	;;; if inside vman index file, get man file, otherwise build
	;;; vman index file.
	ved_vman_init();

	if vvedbuffersize > 1 and vedbuffer(1) = man_message then
		;;; inside a "vman" index file. Get the name and find the file.
		vman_get_file();
	else
		;;; build the indexfile
		vman_build_index();
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr 21 2002
		added uses ved_g, to ensure ved_g_string defined.
--- Aaron Sloman, Jul 25 2000
		Added `.` to terminators, and changed to use ordinary
		man command on solaris, ignoring man file suffix.
--- Aaron Sloman, Jul 17 1999
	Extended to add 'sman' type files, required for Solaris 7
	Also changed to use sys_parse_string
--- Aaron Sloman, Aug 30 1998
	Fixed to allow more than one dot in file name, e.g. rpc.ttdbserver.1m
--- Aaron Sloman, Nov 12 1995
	Extended to cope with extra man? directories in Solaris (as for
		hp systems)
	Allowed an explicit argument to be given to avoid interrogation.
	Changed to use ved_try_search

--- Aaron Sloman, May 16 1993
	Fixed to work with solaris "man" command, which uses "-s" for
	section names
--- Aaron Sloman, Mar  7 1993
	Fixed to work with HP machines
	Fixed to work properly with "l" option.
	Tidied up and separated out the HELP file.
 */
