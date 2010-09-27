/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_aspell.p
 > Purpose:			Run aspell on current file
 > Author:          Aaron Sloman, Dec 12 1998 (see revisions)
 > Documentation: 	HELP * VED_ASPELL, Shell command 'aspell help'
 > Related Files:  	LIB * VED_SPELL
 */

/*
WARNING: This is derived from LIB ved_ispell. aspell is more sophisticated
and this program does not yet take account of all the options.

User assignable global variables:

	veduserswords
		A string, the name of a file containing user's dictionary.
		The default is '$HOME/.spellwords'

	vedaspellflags
		A string, the set of flags to be given to "spell" (see 'man spell'),
		if no argument is provided for ENTER spell.

		The default value is
				' -p  ~/.aspell.english.per '


ENTER commands

	ENTER aspell
		This can be run with various flags allowed by aspell. E.g. for a
		non-interactive run, which merely produces a file of doubtful words, do
			ENTER aspell -l
		For a full list of command line options for aspell do
			ENTER aspell help
			ENTER sh aspell help
		or
			ENTER sh aspell --help

	ENTER find
		As in HELP VED_SPELL

 define ved_readuserswords;
 define ved_userswords();
 define ved_spellflags();
 define ved_find();
 define ved_storeit();
 define ved_storethem();
 define ved_findit();
 define ved_fixit();
 define ved_gfixit();
 define ved_aspell();

*/
section;

;;; Define the pathname for a file where the user stores words whose
;;; spelling is OK.
global vars veduserswords;
unless isstring(veduserswords) then
	'$HOME/.spellwords' -> veduserswords
endunless;

;;; flags to give to the aspell command. Default defined here.
global vars vedaspellflags;
unless isstring(vedaspellflags) then
	' -p  ~/.aspell.english.per ' -> vedaspellflags;
endunless;

;;; A property to store the words that the user finds OK.
global vars procedure vedgoodspellword = newproperty([], 1011, false, "perm");

define ved_readuserswords;
	;;; read the words in the user's file
	lvars word, c, nextword;
	if readable(veduserswords) then
		incharitem(discin(veduserswords)) -> nextword;

		;;; fix itemiser rules so that funny characters are OK
		for c in_string '.\'-`()[]{}/;:' do
			4 -> item_chartype(c, nextword)
		endfor;

		repeat
			nextword() -> word;
		quitif(word == termin);
			true -> vedgoodspellword(word)
		endrepeat
	else
		'' -> veduserswords;
	endif;
enddefine;


lvars lastlookatuserswords = 0;		;;; time the file last examined

define ved_userswords();
	;;; alter the default user dictionary
	unless vedargument = nullstring then
		vedargument -> veduserswords;
		0 -> lastlookatuserswords;
	endunless;
	vedputmessage('New Dictionary: ' >< veduserswords)
enddefine;


define ved_spellflags();
	;;; alter the default flags given to spell
	unless vedargument = nullstring then
		vedargument -> vedaspellflags
	endunless;
	vedputmessage(vedaspellflags);
enddefine;

define ved_find();
	;;; find next word not in user"s dictionary
	lconstant options = [ved_storeit ved_findit ved_fixit ved_fixit];

	lvars item;

	repeat
	returnif(vedatend());
	quitunless(vedgoodspellword(vednextitem() ->> item));
		vedmoveitem()->;
		if vedcolumn >= vvedlinesize then vednextline() endif;
	endrepeat;

	vedcheck();
	vedsetcursor();
	;;; found the word, offer options
	vedputmessage(""" >< item sys_>< '" is new: 1.storeit, 2.findit, 3.fixit, 4.gfixit ?');
	lvars inchar = rawcharin();
	if strmember(inchar, '\r\^?') then
		;;; ignore this one
		vedmoveitem() -> ;
		if vedcolumn >= vvedlinesize then vednextline() endif;
		chain(ved_find); ;;; start again
	elseif strmember(inchar, 'nN\r\^?') then ;;; do nothing (stop)
	else
		inchar - `0` -> inchar;
		if 0 < inchar and inchar < 5 then
			chain(valof(options(inchar)))
		else
			vederror('INAPPROPRIATE NUMBER. TYPE REQUIRED COMMAND')
		endif
	endif;

enddefine;

define ved_storeit();
	;;; save word on current line in the dictionary
	lvars newword = consword(vedthisline());
	if vedgoodspellword(newword) then
		vedputmessage('ALREADY STORED ' >< vedthisline())
	else
		vedmarklo(); vedmarkhi();
		veddo('wappdr ' sys_>< veduserswords);
		sysobey('sort -u -o ' sys_>< veduserswords
				sys_>< ' ' sys_>< veduserswords);
		vedrefreshstatus();
		true -> vedgoodspellword(newword);
		vedputmessage('STORED IT')
	endif;
	vedchardown();
enddefine;

define ved_storethem();
	;;; store all the words in marked range in the dictionary
	vedmarkfind();
	veddo('wappdr ' sys_>< veduserswords);
	sysobey('sort -u -o ' sys_>< veduserswords
		sys_>< ' ' sys_>< veduserswords);
	vedputmessage('STORED THEM')
enddefine;

define ved_findit();
	;;; Go to other file and find occurrences
	lvars string = vedthisline();
	vedswapfiles();
	vedputcommand('"' sys_>< string);
	vedredocommand();
    vedputcommand('findit')
enddefine;

define ved_fixit();
	;;; Go to other file and interactively replace occurrences
	lvars string = vedthisline();
	vedswapfiles();
	vedputcommand('s"' sys_>< string sys_>< '"');
	unless vedonstatus then vedstatusswitch() endunless;
	vedtextright();
	vedputmessage('Complete substitute command and press RETURN');
enddefine;

define ved_gfixit();
	lvars string = vedthisline();
	vedswapfiles();
	vedputcommand('gs"' sys_>< string sys_>< '"');
	unless vedonstatus then vedstatusswitch() endunless;
	vedtextright();
	vedputmessage('Complete global substitute command and press RETURN');
enddefine;


define ved_aspell();
	lconstant fvec = { 0 0};
	lvars
		interactive = false,
		mlo = vvedmarklo,
		mhi = vvedmarkhi;


	if vedargument = 'help' then
		veddo('sh aspell help');
		return();
	endif;

	if vedargument = nullstring then
		true -> interactive;
		vedaspellflags
	else
		vedaspellflags >< vedspacestring >< vedargument
	endif  -> vedargument;

	lvars
		do_list =
			issubstring('-l', vedargument)
			or issubstring('-a', vedargument);

	;;; if vedwriteable and vedchanged then ved_w1() endif;
	;;; Save VED files in case of trouble.
	veddo('w');
	if sys_file_stat(vedpathname, fvec)  then
		lvars mod_time = fvec(2);
		if do_list then
            veddo('sh cat ' >< vedpathname >< '| aspell ' >< vedargument >< ' | sort -uf ');
			;;; prepare for interactive use of ved_find, etc.
			;;; see if user's spell file changed since last read
			returnunless(
				readable(veduserswords)
			and sysmodtime(veduserswords) > lastlookatuserswords);

			vedputmessage('Reading your dictionary');
			ved_readuserswords();
			sysmodtime(veduserswords) + 1 -> lastlookatuserswords;
			vedputmessage('Dictionary read');
		else
			;;; now interactive ?
			if vedusewindows = "x" then
				;;; have to start up a new xterm window to spawn aspell
				;;; process
				sysobey('xterm -e aspell -c ' >< vedpathname);
			else
				veddo('%aspell ' >< vedargument >< ' -c ' >< vedpathname);
			endif;
		endif;

		;;; see if file was changed.
		if sys_file_stat(vedpathname, fvec) and fvec(2) > mod_time then
			lvars line = vedline, col = vedcolumn;
			veddo('qved ' >< vedpathname);

			;;; restore marked range if necessary
			if mlo <= mhi then
				vedjumpto(mlo, 1); vedmarklo();
				vedjumpto(mhi, 1); vedmarkhi();
			endif;
			vedjumpto(line, col);
		endif;
	else
		vederror('NOT ON DISC: '>< vedpathname)
	endif;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 10 2003
		Converted from ved_ispell, since ispell has been replaced by aspell
--- Aaron Sloman, Jan 16 2000
	Allowed '-l' and '-c' options and transferred facilities from
	LIB VED_SPELL
--- Aaron Sloman, Jan 26 1999
	Prevented attempting to restore marked range when unnecessary.
--- Aaron Sloman, Jan 19 1999
	Altered to reset marked range.
 */
