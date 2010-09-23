/* --- Copyright University of Birmingham 1995. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_sortmr.p
 > Purpose:			Sort marked range by field
 > Author:          Aaron Sloman, Mar 14 1995 (see revisions)
 > Documentation:	HELP * VED_SORTMR
 > Related Files:   HELP * VED_SMR LIB * VED_SMR
 */

/*
NOTE:
The program attempts to minimise garbage collections. Hence the
complexity involved in the use of the sub-procedure field_before.
*/


section;
compile_mode :pop11 +strict;

global vars
	ved_sortmr_spacer = `\s`,

	;;; Characters which are treated as one space if there's more
	;;; than one in succession.
	ved_sortmr_skip = '\s\t';


define vars procedure field_before(s1, s2, startloc, endloc, caseless) -> result;
	;;; Check whether a specified field of s1 is alphabetically before
	;;; a specified field of s2.

	;;; s1 and s2 are strings, startloc and endloc are procedures,
	;;; caseless is a boolean to control mapping of upper to lower case
	;;; result is a boolean

	;;; If "caseless" is the integer 0 then assume the field
	;;; contains an integer and sort on that.

	;;; If either string is empty, treat that as earlier

	;;; The comparison starts at a location startloc(s1) in s1,
	;;; and startloc(s2).
	;;; It ends at locations defined by
	;;;		endloc(s1, startloc(s1))
	;;;		endloc(s2, startloc(s2))

	lvars s1, s2,
		caseless, result,
		index1, index2,
		lim1, lim2,
		procedure(startloc, endloc),
		;

	returnif(s1 = nullstring)(true -> result);
	returnif(s2 = nullstring)(false -> result);

	;;; omit checks for speed?
	check_string(s1);
	check_string(s2);

	;;; get start and end indices and check that they are integers
	fi_check(startloc(s1), 0, false) -> index1;
	fi_check(startloc(s2), 0, false) -> index2;

	endloc(s1, index1) -> lim1;
	endloc(s2, index2) -> lim2;

	;;; Stop if at end of string1
	returnif(lim1 == 0)(true -> result);

	;;; Stop if at end of string2
	returnif(lim2 == 0)(false -> result);

	if caseless == 0 then	
		;;; Check  numerical fields for numerical comparison
		lblock
		lvars
			num1=0, num2=0,
			finished1 = false,
			finished2 = false;
		repeat
			;;; Get characters from the two fields an increment number
			if finished1 then
			elseif index1 fi_> lim1 then
				true -> finished1
			else
				;;; another character in field 1, increase the number
				10 fi_* num1 fi_+ (fast_subscrs(index1, s1) fi_- `0`) -> num1
			endif;

			if finished2 then
			elseif index2 fi_> lim2 then
				true -> finished2
			else
				10 fi_* num2 fi_+ (fast_subscrs(index2, s2) fi_- `0`) -> num2
			endif;
			if finished1 and finished2 then
				num1 fi_<= num2 -> result;
				return()
			endif;
			index1 fi_+ 1 -> index1;
			index2 fi_+ 1 -> index2;
		endrepeat
		endlblock;
	else
		;;; use only alphabetic comparison
		lblock;	
		lvars char1, char2;
		repeat
			;;; check if one or other field is exhausted
		returnif(index1 fi_> lim1)(true -> result);

		returnif(index2 fi_> lim2)(false -> result);

			;;; check if one or other has alphabetically prior character
			fast_subscrs(index1,s1) -> char1;
			fast_subscrs(index2,s2) -> char2;
			if caseless then
				uppertolower(char1) -> char1;
				uppertolower(char2) -> char2;
			endif;

			 unless char1 == char2 then
				(char1 fi_< char2) -> result;
				return();
			endunless;

			index1 fi_+ 1 -> index1;
			index2 fi_+ 1 -> index2;
		endrepeat;
		endlblock;
	endif;
	;;; no difference found, so
	false -> result;
enddefine;

define vars ved_sortmr();
	;;; sort marked range using nth field

	lvars top, field, flag,
		caseless = false,
		reverse = false,
		skipping,
		args = sysparse_string(vedargument);


	dlocal vveddump, ved_sortmr_spacer;

	if args == [] then
		[1] -> args
	endif;

	destpair(args) -> (field, args);

	while isstring(field) do
		field -> flag;
		if flag = '-i'  or flag = '-f' then
			;;; ignore case or "fold" upper into lower case
			if caseless == 0 then goto CASERR endif;
			true -> caseless
		elseif flag = '-n' then
			if caseless then
				CASERR:
				vederror('-i and -n are incompatible')
			endif;
			0 -> caseless;	;;; use numeric comparison
		elseif flag = '-r' then
			true -> reverse
		elseif isstartstring('-c', flag) then
			subscrs(3, flag) -> ved_sortmr_spacer;
			if ved_sortmr_spacer == `\\` and datalength(flag) > 3 then
				lvars char;
				subscrs(4, flag) -> char;
				if char == `t` then `\t`
				elseif char == `r` then `\r`
				elseif char == `b` then `\b`
				elseif char == `n` then `\n`
				elseif char == `e` then `\e`
				elseif char == `s` then `\s`
				else
					goto ERR
				endif -> ved_sortmr_spacer
			endif
		else
			ERR:
			vederror('UNKNOWN FLAG: ' <> flag)
		endif;

		if args == [] then 1 -> field; quitloop
		else destpair(args) -> (field, args)
		endif;

    endwhile;

	strmember(ved_sortmr_spacer, ved_sortmr_skip) -> skipping;

	unless isinteger(field) then
		vederror('FIELD-SPEC SHOULD BE AN INTEGER: 'sys_>< field)
	endunless;

	unless args == [] then
		vederror('SPURIOUS ARGUMENT ' sys_>< args)
	endunless;


	define lconstant start_from(string) ->loc;
		lvars string, loc, fieldnum = field;
		if fast_subscrs(1,string) == ved_sortmr_spacer then
			if fieldnum == 1 then
				0-> loc;
				return()
			else
				fieldnum - 1 -> fieldnum;
			endif
		endif;
		0 -> loc;
		if skipping then
			;;; Repeated occurrences of the spacer all count
			repeat
				skipchar(ved_sortmr_spacer, loc fi_+ 1, string) -> loc;
				unless loc then
					nullstring -> vedargument;
					ved_y();
					vederror('Not enough fields in: ' >< string);
				endunless;
			returnif(fieldnum == 1);
				fieldnum fi_- 1 -> fieldnum;

				locchar(ved_sortmr_spacer, loc, string) -> loc;
				unless loc then datalength(string) + 1 -> loc endunless;
			endrepeat;
		else
			repeat
			returnif(fieldnum == 1);
				fieldnum fi_- 1 -> fieldnum;

 				locchar(ved_sortmr_spacer, loc fi_+ 1, string) -> loc;
				unless loc then
					nullstring -> vedargument;
					ved_y();
					vederror('Not enough fields in: ' >< string);
				endunless;
			endrepeat;
		endif
	enddefine;

	define lconstant end_at(string, lastloc) ->lastloc;
		;;; return the right hand boundary of the string
		lvars string, loc, lastloc;
		if fast_subscrs(1, string) == ved_sortmr_spacer then
			if field == 1 then return() endif
		endif;

		locchar(ved_sortmr_spacer, lastloc fi_+1, string) -> loc;

		if loc then
			loc fi_- 1
		else datalength(string)
		endif -> lastloc;
	enddefine;

	define lconstant orderstrings(string1, string2)->bool;
		lvars string1, string2, bool;
		
		field_before(
			string1, string2,
			start_from, end_at, caseless) -> bool;
	enddefine;

	vedmarkfind();
	vedline -> top;
	;;; in case of disaster, save the file.
	if vedchanged and vedwriteable then ved_w1() endif;
	;;; Delete marked range. Puts a list of the strings in vveddump
	ved_d();

	lvars oldinterrupt = interrupt;
	define dlocal interrupt();
		;;; if interrupted, yank vveddump back in
		nullstring -> vedargument;
		ved_y();
		oldinterrupt();
	enddefine;

	;;; Do a non-copying sort
	syssort(
			vveddump,
			false,
			if reverse then orderstrings <> not else orderstrings endif
			) -> vveddump;
	(top - 1) sys_>< nullstring -> vedargument;
	ved_y();

	'SORTED' -> vedmessage;

	sys_grbg_list(vveddump);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 20 1995
	Added the numeric sort option indicated by flag '-n'
	Added 1 to each index so as not to check the separator character

 */
