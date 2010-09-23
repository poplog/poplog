/* --- Copyright University of Sussex 1998. All rights reserved. ----------
 > File:            C.all/src/poplog_main.p
 > Purpose:
 > Author:          John Gibson (see revisions)
 > Documentation:   REF *SYSTEM
 */

;;;-------------  SETTING UP THE NORMAL POPLOG SYSTEM ------------------------

#_INCLUDE 'declare.ph'
#_INCLUDE '../lib/include/subsystem.ph'

global constant
		procedure (strnumber, sys_fname_path, sys_fname_nam, sys_parse_string,
					syssetup),
		poptitle,
	;

global vars
		poparglist0, poparg0, poparglist, popversion, popheader
	;

section $-Sys;

constant
		_image_ident
		procedure (Init_path_dir_list),
	;

endsection;


	/* Uncomment out next line to enable cpu checking */
;;; lconstant macro CPU_CHECKING_ENABLED = true;


;;; ----------------------------------------------------------------------

section $-Sys;

	/*  This procedure gets run after setting up poparglist0 etc, but
		before locking the pre-heap and trying to restore saved image args.
		It returns the search directory list and default extension to be
		used for the latter.
	*/

define $-Pop$-Pre_Init_Restore();
	lvars trans, arg0, dev;

	'\n' <> poptitle <> popversion -> popheader;

#_IF DEF UNIX

	;;; check to see if was invoked by login (arg0 has - prepended)
	;;; compile login program if so (to set up env list)
	poparg0 -> arg0;
	if datalength(arg0) fi_> 0 and fast_subscrs(1,arg0) == `-` then
		allbutfirst(1, arg0) ->> arg0 -> fast_front(poparglist0);
		if (readable('$HOME/.login.p') ->> dev) then
			pop11_compile(dev)
		else
			mishap(0, 'CAN\'T FIND LOGIN INIT FILE: $HOME/.login.p')
		endif
	endif;

	;;; get arg0, the name under which the image was invoked
	;;; and see if there's a env var translation with 'pop_' prepended
	if systranslate('pop_' <> sys_fname_nam(arg0)) ->> trans then
		;;; arg0 translated
		;;; separate into args (unless begins with :),
		;;; and make them arg1, arg2, etc
		[%	if datalength(trans) /== 0 and fast_subscrs(1,trans) == `:` then
				trans
			else
				sys_parse_string(trans)
			endif
		%] nc_<> poparglist ->> fast_back(poparglist0) -> poparglist;
		;;; replace original arg0 with 'basepop11'
		sys_fname_path(arg0) dir_>< 'basepop11' -> fast_front(poparglist0)
	endif;

#_ENDIF

	;;; return directory list and default extension for trying
	;;; to restore initial saved images
	Init_path_dir_list('popsavepath'), '.psv'
enddefine;


;;; ----------------------------------------------------------------------

uses ($-pop_setpop_compiler);	;;; so setpops will reset to a compiler

	/*  Poplog_main is the entry procedure for the normal POPLOG system
		(as specified by -e option to poplink command in "pgcomp").
		It is called after failing to restore saved images.
	*/
define Poplog_Main();

	;;; No saved images restored, so if this is not the normal Poplog
	;;; image, then just return
	returnunless(_zero(_image_ident!(w)));

	;;; (interrupt is sysexit at this point)
	unless subsystem then "pop11" -> subsystem endunless;
	syssetup();		;;; standard subsystem startup
	interrupt();	;;; sysexit unless redefined
enddefine;



;;; --- CPU CHECKING ---------------------------------------------------

section;

constant
		procedure (sys_host_id, sysdaytime, dest_characters)
	;

endsection;

	/*	This procedure is called by -Setup_system- in setpop.p
		after setting up, but before trying to restore saved images.
		To ensure that systems with or without this check have the
		same base point for the heap, any structures this procedure
		creates in the heap are erased after calling it.

		It MUST NOT therefore `leave anything behind' in the sense of
		assigning structures to global variables or global data structures.

		In particular, this means IT MUST NOT USE consword.
	*/
define $-Pop$-Cpu_Id_Check();

		;;; max. length of an input line
	lconstant LINEMAX = 256;

		;;; read a list of licenced hosts from the file _____fname
	define lconstant read_hostid_list(fname);
		lvars fname, fdev, n, buffer = inits(LINEMAX);
		[%	if sysopen(fname, 0, "line") ->> fdev then
				false -> device_encoding(fdev);
				until (sysread(fdev, buffer, LINEMAX) ->> n) == 0 do
					substring(1, n-1, buffer);
				enduntil;
				sysclose(fdev);
			endif;
		%];
	enddefine;

		;;; prompt for a password for this host __id and ____type and add it
		;;; to the file _____fname
	define lconstant ask_user(fname, id, type);
		lvars fname, id, type;
		;;; prompt for new password
		printf(pop_internal_version/10000.0, poptitle, '%p%p');
		unless id = nullstring and type = nullstring then
			printf(' on host ');
			unless id = nullstring then printf(id, '%S') endunless;
			unless type = nullstring then printf(type, '(%S)') endunless;
		endunless;
		printf('\nPLEASE ENTER PASSWORD (CONSULT SUPPLIER IF NECESSARY)\n');
		;;; read it
		lvars buffer = inits(LINEMAX);
		lvars n = sysread(popdevin, buffer, LINEMAX);
		lvars passwd = substring(1, n, buffer);
		;;; open hostid file
		lvars fdev;
		unless sysopen(fname, 2, "line") ->> fdev then
			;;; first time
			syscreate(fname, 2, "line") -> fdev;
		endunless;
		false -> device_encoding(fdev);
		;;; skip to end
		until sysread(fdev, buffer, LINEMAX) == 0 do enduntil;
		;;; append new password
		syswrite(fdev, passwd, datalength(passwd));
		sysclose(fdev);
	enddefine;

		;;; check this host __id against the encrypted ___________hostid_list
	define lconstant check_suffix(id, hostid_list);
		lvars id, hostid_list;

		define lconstant encrypt(passwd);
			lvars passwd;

			define lconstant fold(encryption) -> result;
				lvars encryption, len, half_len, i, result;
				datalength(encryption) -> len;
				consstring(#|
					if len && 1 /== 0 then
						;;; uneven length so include last char as first
						encryption(len)
					endif;
					len >> 1 -> half_len;
					fast_for i to half_len do
						`0` + ((encryption(i) + encryption(i+half_len)) rem 10)
					endfor
				|#) -> result;

				;;; force encryption to be less than 14 digits
				if datalength(result) > 14 then fold(result) -> result endif
			enddefine;

			lconstant remainder = 89;
			lvars x, total = 0;
			fast_for x in_string passwd do total + x -> total endfor;
			fold(consstring(#|
				fast_for x in_string passwd do
					dest_characters((x + total) rem remainder);
					total * x + x -> total
				endfor
			|#));
		enddefine;

		define lconstant in_hostid_list();
			lmember_=(encrypt(), hostid_list)
		enddefine;

		define lconstant still_time(year, month, stop_year, stop_month);
			lvars year, month, stop_year, stop_month;
			year < stop_year or year == stop_year and month <= stop_month;
		enddefine;

		returnif(in_hostid_list('ALWAYS' <> id)) (true);

		lconstant
			monthname	= { 'JAN' 'FEB' 'MAR' 'APR' 'MAY' 'JUN'
							'JUL' 'AUG' 'SEP' 'OCT' 'NOV' 'DEC'},
			yearname	= {'1998' '1999' '2000' '2001' '2002'},
			NMONTHS		= datalength(monthname),
			NYEARS		= datalength(yearname),
			;

		lvars year, month, date = lowertoupper(sysdaytime());
		lvars this_year = 0, this_month = 0;
		fast_for year to NYEARS do
			if issubstring(yearname(year), date) then
				year -> this_year;
				quitloop;
			endif;
		endfor;
#_IF DEF WIN32
		;;; ____date doesn't include the month name: starts with DD/MM/YYYY
		strnumber(substring(4, 2, date)) or 0 -> this_month;
#_ELSE
		fast_for month to NMONTHS do
			if issubstring(monthname(month), date) then
				month -> this_month;
				quitloop;
			endif;
		endfor;
#_ENDIF
		fast_for year to NYEARS do
			fast_for month to NMONTHS do
				if in_hostid_list(monthname(month) <> yearname(year) <> id)
				and still_time(this_year, this_month, year, month)
				then
					return(true);
				endif;
			endfor;
		endfor;

		false
	enddefine;      /* check_suffix */

	define lconstant hexstring(x);
		lvars x;
		dlocal pop_pr_radix = 16;
		x >< nullstring
	enddefine;

	returnunless(DEF CPU_CHECKING_ENABLED and _zero(_image_ident!(w)));

	unless systranslate('popsys') then
		mishap(0, 'popsys NOT SET UP');
	endunless;
	lvars fname = '$popsys/' dir_>< 'cpu.dat';

	;;; construct a list of licenced host ids
	lvars hostid_list = read_hostid_list(fname);

	;;; get this host id & type as strings
	lvars hostid, hosttype;
#_IF DEF VMS
	dl(sys_host_id()) -> (hostid, hosttype);
	;;; machine id number -- remove bits 16-23 and clear bit 15
	hexstring( ((hostid>>24)<<16) || (hostid&&16:7FFF) ) -> hostid;
	hexstring(hosttype) -> hosttype;
#_ELSE
	if sys_host_id() ->> hostid then
		fast_front(hostid) -> hostid;
		unless isstring(hostid) then
			hexstring(hostid) -> hostid;
		endunless;
	else
		;;; no host id
		nullstring -> hostid;
	endif;
	nullstring -> hosttype;
#_ENDIF

	;;; check host id or type against licenced host ids
	returnif(check_suffix(hostid, hostid_list));
	unless hosttype = nullstring then
		returnif(check_suffix('NONUNIQUE' <> hosttype, hostid_list));
	endunless;

	;;; no matching ID in host list, therefore prompt for password
	ask_user(fname, hostid, hosttype);
	;;; ... and try again
	chain($-Pop$-Cpu_Id_Check);
enddefine;


endsection;     /* $-Sys */


/* --- Revision History ---------------------------------------------------
--- John Gibson, Mar 20 1998
		Changed _image_ident to be a pointer to a word containing the value,
		rather than the value itself (AIX doesn't support the latter).
--- Robert Duncan, Mar  4 1998
		Changed CPU check dates to 2002.
--- John Gibson, Apr 10 1997
		Set device_encoding false in Cpu_Id_Check
--- Robert Duncan, Nov  6 1996
		Fixed Cpu_Id_Check for Win32 (different date format)
--- John Gibson, Dec  4 1995
		Uses lmember_= instead of mem*ber
--- Robert John Duncan, Aug 11 1995
		Changed _________remainder value in encrypt to 89 for Version 15
--- John Gibson, Jul 29 1995
		Made Poplog_Main assign "pop11" to subsystem if false
--- Robert John Duncan, May 23 1995
		Restricted CPU checking to just the normal system, i.e. where
		_image_ident is 0.
--- Robert John Duncan, May  2 1995
		Fixed the CPU check to recognise when the current year is beyond
		the stop year (!). Reorganised so that the host id (and type) is
		displayed with the password prompt to save users having to type
		obscure shell commands to get hold of it.
--- John Gibson, Jan 28 1995
		Changed _________remainder value in encrypt to 97 for normal system.
--- John Gibson, Dec 12 1994
		Changed CPU check dates to 1998.
--- John Gibson, Jun 17 1993
		Moved pop_setpop_compiler to subsystem_compile.p
--- John Gibson, Jan 23 1993
		Made Poplog_Main call interrupt after syssetup (instead of setpop).
--- John Gibson, Jan 11 1993
		o syssetup now moved to syssetup.p
		o pop_setpop_compiler now subsystem-sensitive
--- John Gibson, Oct 20 1992
		Uses sys_parse_string
--- John Gibson, Sep 30 1991
		Changed replacement for arg0 after pop_X translation to 'basepop11'
		instead of 'pop11'
--- Simon Nichols, Aug 23 1991
		In cpu checking code, changed mishap message to specify popsys
		rather than usepop if popsys is undefined.
--- John Gibson, May 23 1991
		Removed call of sys_process_special_popargs
--- John Williams, Jan 11 1991
		-syssetup- now only assigns -setpop- to -interrupt- if
		-interrupt- has not been changed by the user.
--- John Gibson, Dec 15 1990
		Made -ask_user- print POPLOG Version, etc.
--- John Gibson, Dec  1 1990
		Added cpu checking code
--- John Gibson, Oct 27 1990
		Renamed =setpop_compile- directly as -pop_setpop_compiler-
--- John Gibson, Oct 26 1990
		Replaced -popdevin- with -pop_charin_device-
--- John Williams, Oct  4 1990
		Added -syssetup-
--- Simon Nichols, Oct  2 1990
		Changed -Poplog_Main- to make the call of -pop11_xsetup-
		independent of the value of -pop_noinit-.
--- Simon Nichols, Oct  1 1990
		Renamed -sys_xstartup- to be -pop11_xsetup-.
--- Simon Nichols, Sep  7 1990
		Changed -Poplog_Main- to take account of special arguments.
--- John Williams, Jul  2 1990
		-setpop_compile- now calls -popsetpop-
--- Ian Rogers, Jan 17 1990
		Added $Sys$-poptitle
--- John Gibson, Aug 15 1989
		Changed test for terminal input in -Poplog_Main- to use
		-On_line_tty_input-, and -setpop- now always assigned to
		-interrupt-, regardless of whether this is true.
--- John Gibson, Aug 10 1989
		Code for dealing with initial arguments reorganised and rewritten.
		Restoring of saved images now done in new file init_restore.p
--- John Gibson, Aug  2 1989
		Unix version now uses sys_fname... procedures.
--- John Gibson, May  5 1989
		Sys$-Poplog_Main is now the entry procedure for the full Poplog
		system (specified by -e option to poplink command in "pgcomp").
		Put file into section Sys.
--- Roger Evans, Mar 20 1989
		Moved poparg0 initialisation to setpop.p
--- Roger Evans, Mar 16 1989
		Added poparg0
--- John Gibson, Jun 24 1988
		Replaced -Poplog_no_init_restore- with _image_ident value (set
		up by poplink)
--- John Gibson, Jun 20 1988
		Changed -Try_init_command- so that first arg starting with `:`
		indicates POP-11 code to compile in VMS as well as Unix, rather
		than `"`.
--- John Gibson, Mar  9 1988
		Now poplog_main.p (previously sysinit.p)
 */
