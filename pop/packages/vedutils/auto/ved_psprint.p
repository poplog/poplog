/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_psprint.p
 > Purpose:         Print file to postscript printer using a2ps
 > Author:          Aaron Sloman, Feb  6 1992 (see revisions)
 > Documentation:   HELP * VED_PSPRINT
 > Related Files: LIB * VED_PSPRINTMR
 */

section;

lconstant
	linux = hd(sys_os_type)== "unix" and hd(tl(sys_os_type))== "linux",
	os_version = sys_obey_linerep('uname -r')(),
	sol26 = not(linux) and not(member(os_version, ['5.4' '5.5.1' '4.1.3' 'V4.0']));

global vars
	pop_default_printer,

	pop_default_font_size,

	pop_default_printfile,

	pop_default_printargs,

	pop_default_portrait_font,

	pop_printer_command,

	pop_printer_flag,

	pop_a2ps_prog =
			if linux then
				'csh /usr/bin/a2ps '
			elseif sol26 then
				'csh /bham/pd/bin/a2ps -i -nv '
			else
				'csh /bham/pd/bin/a2ps -i -nv -nb '
			endif,

	;;; if a number, and the file is longer than this,
	;;; ask the user to confirm.
	pop_check_long_file = 60,

;
unless isstring(pop_default_font_size) then
	'9' -> pop_default_font_size
endunless;

unless isstring(pop_default_portrait_font) then
	'12' -> pop_default_portrait_font
endunless;

unless isstring(pop_default_printargs) then
	if linux then
		' -i --borders=no -B --prologue=bold -o - ' -> pop_default_printargs
;;;		' -i --borders=no -B  -o - ' -> pop_default_printargs
	else
		nullstring -> pop_default_printargs
		;;; ????
		;;; ' -h ' -> pop_default_printargs
	endif
endunless;



#_IF DEF BOBCAT
	' | remsh bilbo lp ' -> pop_printer_command;

	'-d' -> pop_printer_flag;

	unless isstring(pop_default_printer) then
		systranslate('PRINTER')  -> pop_default_printer
	endunless;

	lvars  output;
#_ELSEIF DEF LINUX


	'-P' -> pop_printer_flag;
	
	unless isstring(pop_default_printer) then
		systranslate('PRINTER')  -> pop_default_printer
	endunless;
	' | lpr ' -> pop_printer_command;

#_ELSE
	' | lpr ' -> pop_printer_command;

	'-P' -> pop_printer_flag;

	unless isstring(pop_default_printer) then
		systranslate('PRINTER')  -> pop_default_printer
	endunless;

#_ENDIF


lconstant
	fontflag =
			if sol26 then '-F' elseif linux then '-f' else '-f ' endif,
	onepage = if sol26 or linux then ' -1 ' else nullstring endif,

	noheader =
		if sol26 then '-nH'
		elseif linux then '-B '
		else '-nh' endif,
	;

/*
delarg('-p', 'foo -p -1 baz')=>

*/

define lconstant delarg(flag, string) -> newstring;
	;;; produce a new version of string with flag missing
	lvars flaglen = datalength(flag), loc;

	if issubstring(flag, string) ->> loc then
		substring(1, loc-1, string) sys_><
			allbutfirst(loc+flaglen-1, string)
			-> newstring
	else
		string -> newstring;
	endif;
enddefine;

define lconstant getarg(flag,string) -> (flag_arg, outstring);
	;;; extract flag and its following argument from the string
	;;; getarg('-P', 'aaaaa -Plw bbbb') -> ('-Plw', 'aaaaa bbbb')

	lvars loc1, loc2, flag, string,
		flag_arg = false,
		outstring = false,
		len = datalength(flag);

	issubstring(flag, string) -> loc1;
	if loc1 then
		if loc1 == 1 then nullstring else substring(1, loc1 - 1, string) endif
			-> outstring;   ;;; first part of outstring

		locchar(`\s`, loc1+datalength(flag), string) -> loc2;
		if loc2 then
			substring(loc1, loc2 - loc1, string) -> flag_arg;
			outstring <> allbutfirst(loc2, string) -> outstring
		else
			allbutfirst(loc1 - 1, string) -> flag_arg;
		endif;
	else
		string -> outstring
	endif;
enddefine;

define lconstant getprinter(string) ->(printer, string);
	lvars string, printer;
	lconstant printflag = pop_printer_flag;

	if (getarg(printflag, string) ->(printer, string), printer) then
		;;; use the printer specified
	elseif issubstring(printflag, pop_default_printargs) then
		nullstring -> printer;
	elseif systranslate('PRINTER') ->> printer then
		;;; no printer specified, but use $PRINTER
		printflag sys_>< printer -> printer
	else
		;;; use default
		if isstring(pop_default_printer) then
			printflag sys_>< pop_default_printer -> printer
		else
			vederror('$PRINTER environment variable is not set')
		endif;
	endif
enddefine;


define getfontsize(string) ->(fontsize, string);
	lvars string, fontsize;
	if (getarg(fontflag, string) ->(fontsize, string), fontsize) then
		;;; use the fontsize specified
	elseif not(sol26) and
		(getarg('-F', string) ->(fontsize, string), fontsize) then
		;;; someone on a DEC Alpha may have typed '-F'
		uppertolower(fontsize) -> fontsize;
	elseif sol26 and
		(getarg('-f', string) ->(fontsize, string), fontsize) then
		;;; someone may have typed '-f'
		lowertoupper(fontsize) -> fontsize;
	elseif strnumber(string) then
		;;; left for compatibility with previous version
		fontflag sys_>< string -> fontsize;
		nullstring -> string;
	elseif issubstring(fontflag, pop_default_printargs) then
		nullstring -> fontsize
	elseif issubstring('-p', string)
	or issubstring('-p', pop_default_printargs)
	then
		;;; portrait mode, use default for portrait
		delarg('-p', string) -> string;
		fontflag sys_>< pop_default_portrait_font -> fontsize
	else
		;;; use default
		fontflag sys_>< pop_default_font_size -> fontsize
	endif;
enddefine;

define lconstant gettmpfile() -> file;
	lvars file =
	if isstring(pop_default_printfile) then
		pop_default_printfile
	else
		systmpfile('/tmp', popusername, '.out')

	endif;
enddefine;

define ved_do_print(marked_range);
	;;; print current file or marked range using a2ps

	lvars outfile, fontsize, args = vedargument, printer, loc, command;

	dlocal
		vedargument,
		pop_a2ps_prog,
		pop_file_mode = 8:600,
		pop_pr_quotes = false;


	if sol26 then
		if issubstring('-nh', args) then
			vederror('Use "-nH" for no header on new Suns')
		endif;
	elseif linux then
		if issubstring('-nH', args) or issubstring('-nh', args) then
			vederror('Use "B" for no header on Linux')
		endif
			
	elseif issubstring('-nH', args) then
			vederror('Use "-nh" for no header on DEC Alphas')
	endif;

	if issubstring('-R', args) then
		;;; portrait in linux
			pop_a2ps_prog >< ' -R ' -> pop_a2ps_prog;
			delarg('-R', args) -> args;
	elseif issubstring('-p', args) and sol26 or linux then
		;;; add -1 to print one page per sheet in portrait mode
		unless issubstring('-2', args) then
			pop_a2ps_prog >< onepage -> pop_a2ps_prog;
			delarg('-p', args) -> args;
		endunless
	endif;

	getprinter(args) -> (printer, args);

	getfontsize(args) -> (fontsize, args);

	if marked_range then

		lvars char, size = vvedmarkhi - vvedmarklo;		

		if isinteger(pop_check_long_file)
		and size > pop_check_long_file
		then
			vedsetstatus( size sys_>< 'lines. Really print?(y/n)',
				false, true);
				vedwiggle(0,vedscreenwidth);

			vedscr_read_ascii() -> char;
			unless strmember(char, 'yY') then
				vedputmessage('ABORTING');
				return();
			endunless;
		endif;

		;;; need to write marked range to temporary file
		;;; First work out temporary file, if specified.
		if (getarg('-o',args) -> (outfile, args), outfile) then
			allbutfirst(2, outfile) ->outfile;
		else
			gettmpfile() ->  outfile

		endif;

		;;; write the marked range to the temporary file.
		veddo('wr ' <> outfile);
		;;; Veddebug('written to ' >< outfile);

	else
		lvars char;		
		if isinteger(pop_check_long_file)
		and vvedbuffersize > pop_check_long_file
		then
			vedsetstatus(
				vvedbuffersize sys_>< 'lines. Really print?(y/n)',
				false, true);
				vedwiggle(0,vedscreenwidth);
			vedscr_read_ascii() -> char;
			unless strmember(char, 'yY') then
				vedputmessage('ABORTING');
				return();
			endunless;
		endif;
		;;; printing whole file. Save it to disk.
		if vedwriteable and vedchanged then ved_w1() endif;
		vedpathname -> outfile;
	endif;

	unless
		linux
		or
		issubstring('-nn', args) or issubstring('-nn', pop_default_printargs)
		or
		issubstring('-n ', args) or issubstring('-n ', pop_default_printargs)
		or isendstring('-n', args) or isendstring('-n', pop_default_printargs)
	then
		;;; turn off line numbering
		pop_a2ps_prog >< '-nn '
	else
		pop_a2ps_prog
	endunless -> command;


	veddo(
		concat_strings(
					{ ^command ^pop_default_printargs ^space
						^fontsize ^space ^args ^space
						" ^outfile "
						^(pop_printer_command, printer)}) ;;; .dup.Veddebug
					);

	vedputmessage('Use "ENTER lpq" to check print queue');
	if marked_range then
		sysdelete(outfile) ->;
	endif;
enddefine;

define ved_psprint =
	ved_do_print(%false%)
enddefine;

define ved_psprintmr =
	ved_do_print(%true%)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan  3 2003
		Revised conversion to work with a2ps in linux
--- Aaron Sloman, Feb  7 2002
	First draft atttempt to make this work with linux a2ps in redhat 7.1
--- Aaron Sloman, 24 Nov 2001
	Changed to allow getarg to cope with flags with spaces
--- Aaron Sloman, Jan 18 2001
	Made pop_pr_quotes locally false
--- Aaron Sloman, Apr 28 2000
	Changed to check for length when ved_psprintmr is used.
--- Aaron Sloman, Feb 14 1999
	Added extra checks for -nh -nH, -f and -F to cope with two versions
	of a2ps.
--- Aaron Sloman, Dec 16 1998
	Made it delete temporary file.
--- Aaron Sloman, Dec 16 1998
	made temporary files protected.

--- Aaron Sloman, Aug 10 1998
	Changed to handle new version of a2ps on solaris.

--- Aaron Sloman, Nov  5 1997
	Changed
			vedscr_read_input to vedscr_read_ascii
	as the former did not work in XVED
--- Aaron Sloman, Oct  7 1997
	Changed default portrait font to 10.
--- Aaron Sloman, Oct  4 1996
	Changed to add  pop_check_long_file
--- Aaron Sloman, Nov 19 1995
	Changed to make '-nn' the default, while allowing it to be overridden
--- Aaron Sloman, Sep 26 1994
	Made to complain if neither $PRINTER nor pop_default_printer has been
	set.
--- Aaron Sloman 22 March 1994
	Put a message at end about lpq
--- Aaron Sloman 6 march 1993
	Altered to allow file names containing spaces or other troublesom
	characters.
--- Aaron Sloman, Oct 10 1992
	Changed default printer to 'lp'
--- Aaron Sloman, Mar 13 1992
	originally based on ved_macprint, now extended and renamed.
 */
