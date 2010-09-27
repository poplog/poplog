/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            $poplocal/local/auto/ved_master.p
 > Purpose:			Get master version of current file
 > Author:          Aaron Sloman, Aug 24 1989 (see revisions)
 > Documentation: HELP * VED_MASTER
 > Related Files: LIB * NEWMASTER,  LIB * GETMASTER, LIB * VED_DIFF
 */

/*
Gets master version of current file, using 'File:' line of header
or second last line, of documentation file.

<ENTER> master [ <flags> ] [ <system> ]

    <flags>

        if present, must start with "-" and can contain any of
        d, q, or f, in any order, with no spaces.

        If `d` is present, then run ved_diff on the original and the
            new file

        If `q` is present, then quit the present file.

        If `f` is present, then look in the frozen masters

    <system>
        if present, can be any of
            unix, vms, bsd, sysv
        or any of the directory names in $popmaster, e.g.

            C.all, C.vms, S.mips, S.symmetry


If <system> is not specified, then it tries, in order:
            C.all, C.unix, C.bsd

since local library files, if they have master versions, will have them
in one of these directories.


*/

section;

define global ved_master;
	lvars char, file, flags, masterdir, quitting, rundiff,
		waslocal = false,
		args = [],

	;

	lconstant
		hyphenstring = '--- ',
		filestring = '--- File: local',
		errstring = 'NOT ENOUGH INFORMATION TO IDENTIFY MASTER FILE',
		popmaster = '$popmaster/',
		frozmaster = '$frozmaster/',
		;

	if vvedbuffersize < 2 then vederror(errstring) endif;

	;;; allow lone q, or d, for backward compatibility
	if vedargument = 'q' then
		'-q' -> vedargument
	elseif vedargument = 'd' then
		'-d' -> vedargument;
	elseif vedargument = '-f d' then
		'-fd' -> vedargument;
	elseif vedargument = '-f q' then
		'-fq' -> vedargument;
	endif;

	if isstartstring('-', vedargument) then
		;;; split flags
		lblock lvars loc;
		if locchar(`\s`, 1, vedargument) ->> loc then
			substring(1, loc fi_- 1, vedargument) -> flags;
			skipchar(`\s`, loc, vedargument) -> loc;
			allbutfirst(loc fi_- 1, vedargument) -> vedargument;
		else
			vedargument -> flags;
			nullstring -> vedargument;
		endif
		endlblock
	else
		nullstring -> flags
	endif;

	strmember(`q`, flags) -> quitting;
	strmember(`d`, flags) -> rundiff;

	if strmember(`f`, flags) then frozmaster else popmaster endif -> masterdir;

	unless sysisdirectory(masterdir) then
		vederror(masterdir sys_>< ' IS NOT A DIRECTORY')
	endunless;

	;;; Now find what the current file is. Save search state
	dlocal vvedanywhere, vvedoldsrchdisplay, vvedsrchstring, vvedsrchsize;

	vedpositionpush();
	vedjumpto(1,1);

	if vedtestsearch('File:', false) and vedline < 10 then
		;;; crummy test for whether it is a program file

		vedcolumn + 6 -> vedcolumn;
		while (vedcurrentchar() ->> char) == `\s` or char == `\t` do
			vedcharright()
		endwhile;
		allbutfirst(vedcolumn - 1, vedthisline()) -> file;
	elseif isstartstring(hyphenstring, vedbuffer(vvedbuffersize))
	and isstartstring(hyphenstring, (vedbuffer(vvedbuffersize - 1) ->> file))
	then
		;;; Some sort of documentation file
		if issubstring_lim('Distribution: ', 5, 5, false, file) then
			;;; it's a local documentation file with old style footer. Get
			;;; info in third last line
			vedbuffer(vvedbuffersize - 2) -> file;
			true -> waslocal;
			if isstartstring(filestring, file) then
				allbutfirst(datalength(filestring), file) -> file
			else
				vederror(errstring)
			endif
		else
			;;; assume it's a documentation file, with name in 2nd last line
			allbutfirst(4, file) -> file;
			;;; get rid of trailing space+hyphens, if any
			strmember(`\s`, file) -> char;
			if char then
				substring(1, char-1, file) -> file
			endif
		endif
	elseif issubstring('/help/', vedpathname) ->> char then
		;;; probably a HELP file without a footer
		allbutfirst(char - 1, vedpathname) -> file;
		true -> waslocal;	;;; pretend local
	elseif issubstring('/teach/', vedpathname) ->> char then
		;;; probably a TEACH file without a footer
		allbutfirst(char - 1, vedpathname) -> file;
		true -> waslocal;	;;; pretend local
	else vederror(errstring)
	endif;

	if isstartstring('$usepop/master/', file) then
		allbutfirst(15, file) -> file;
	elseif isstartstring('$poplocal/local/', file) then
		allbutfirst(15, file) -> file;
		true -> waslocal;
		if isstartstring('/auto/ved', file) then
			;;; Then VED file in local/auto: master probably in lib/ved
			'/lib/ved' dir_>< allbutfirst(5,file) -> file
		elseif isstartstring('/lib/ved', file) then
			;;; Then VED file in local/lib: master probably in lib/ved
			'/lib/ved' dir_>< allbutfirst(4,file) -> file
		elseif isstartstring('/auto/', file)
		or isstartstring('/lib/', file) then
			'/lib' dir_>< file -> file
		else
			;;; leave it
		endif;
	endif;

	if (member(vedargument, ['vms' 'sysv' 'bsd' 'unix'])
			or isstartstring('C.', vedargument)
			or isstartstring('S.', vedargument))
		and not(waslocal)
	then
		;;; could be C.all or C.bsd, etc. so remove first bit and
		;;; pretend it was local
		allbutfirst(locchar(`/`,2,file), file) -> file;
		true -> waslocal
	endif;

	if waslocal then
		lblock
			lvars
				tempfile, dev, dir, found = false,
				;;; default places to look, at Sussex
				trydirs =
					[%masterdir dir_>< 'C.all/',
				  	masterdir dir_>< 'C.unix/',
				  	masterdir dir_>< 'C.bsd/'%]
					;

			if isstartstring('C.', vedargument)
			or isstartstring('S.', vedargument) then
	 			[%masterdir dir_>< vedargument%] -> trydirs
			elseif vedargument = 'vms' then
	 			[%masterdir dir_>< 'C.vms'%] -> trydirs
			elseif vedargument = 'sysv' then
	 			[%masterdir dir_>< 'C.systemv'%] -> trydirs
			elseif vedargument = 'unix' then
	 			back(trydirs) -> trydirs
			elseif vedargument = 'bsd' then
	 			back(back(trydirs)) -> trydirs
			endif;

			for dir in trydirs do
				if readable(dir dir_>< file ->> tempfile) ->> dev then
					true -> found;
					sysclose(dev); tempfile -> file;
					quitloop();
				endif
			endfor;

			unless found then vederror('NO MASTER FILE FOR ' sys_>< file)
			endunless;
		endlblock;

	else
		masterdir dir_>< file -> file;
	endif;

	vedpositionpop();

	if rundiff then vedtopfile() endif;

	if quitting then
		vedqget(vededitor(%vedhelpdefaults, file%));
	else
		vededitor(vedhelpdefaults, file);
	endif;

	if rundiff then ved_diff() endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan  6 1991
	Extended to cope with help or teach files lacking a footer
--- Aaron Sloman, Jan  6 1991
	Generalised to new format ENTER master <flags> <type>
--- Aaron Sloman, Jan  5 1991
	Allowed arguments vms, bsd, sysv, unix, or anything starting 'C.'
--- Aaron Sloman, Dec 15 1990
	Made to go to top of original file if "d" argument given
--- Aaron Sloman, Dec 11 1990
	Added option to get frozen master version, using "-f" flag
--- Aaron Sloman, Oct 23 1990
	Fixed to cope with old style footers with 'Distribution: ' line
--- Aaron Sloman, Oct  3 1990
	Added ENTER master q option
 */
