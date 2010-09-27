/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:           $poplocal/local/auto/ved_alias.p
 > Purpose:		   Looking for a mail alias
 > Author:         Aaron Sloman, 29 July 1993 (see revisions)
 > Documentation:  HELP * VED_ALIAS
 > Related Files:
 */


section;
define lconstant tryaliases();
	lvars oldfile = vedcurrentfile;
	
	veddo('aliases ' sys_>< vedargument);

	if vedcurrentfile /== oldfile then
		vedjumpto(1,1);

		if isstartstring('sh ', vedthisline()) then
			vedlinedelete();
		endif;
		vedmarklo();
	endif;

enddefine;


define ved_alias;
	lvars n, lim, string, char, arglen,
		alias, full, device, mailrc,
		found = false,
	;


	dlocal vedbreak = false, vedautowrite = false;

	if strmember(`\s`, vedargument) then
		sysparse_string(vedargument) -> string;
		unless listlength(string) == 2 then
			vederror('alias <mailrcfile> <string>');
		endunless;
		dl(string) -> (mailrc, vedargument)
	else
		'$HOME/.mailrc' -> mailrc
	endif;

	if vedargument = '*' then
		nullstring -> vedargument
	elseif vedargument = nullstring then
		;;; no argument given. Try item next to cursor
		vedexpandchars(`f`)() sys_>< nullstring -> vedargument;
	endif;

	lvars loc = strmember(`,`, vedargument);
	if loc then substring(1, loc-1, vedargument) -> vedargument endif;

	datalength(vedargument) -> arglen;

	lvars line, repeater = vedfile_line_repeater(mailrc);

	repeat
		repeater() -> line;

		if line == termin then
			vedputmessage('NO MORE IN ' sys_>< mailrc);
			syssleep(100);
			quitloop()
		elseif (datalength(line) + 1 ->> n) <= arglen then
			;;; alias line not long enough
		elseif isstartstring('alias ',line) then
			if issubstring_lim(vedargument,7,n - arglen,n,line) then
				substring(7,n-7,line) -> string;
				locchar(`\s`,1,string) -> lim;
				substring(1, lim - 1, string) -> alias;
				allbutfirst(lim, string) -> full;
			repeat
				vedputmessage(
					consstring(#|
						explode('1:['),
						explode(alias),
						explode('] 2:['),
						explode(full),
						explode('] DEL(more),RET(stop)') |#));

				vedinascii() -> char;
				if strmember(char, '\rq') then
					return()
				elseif strmember(char, '12') then
					;;;if vedargument = nullstring then vedwordright() endif;
					true -> found;
					strmember(`\s`, string) -> lim;
					if char == `1` then
						allbutlast(datalength(string) - lim + 1, string) -> string
					elseif char == `2` then
						allbutfirst(lim, string) -> string
					endif;
					vedinsertstring(string); vedinsertstring(',\n\s\s\s\s');
					quitloop();
					;;;return()
				elseif char == `?` then
					vedputmessage('1= insert alias, 2=insert expansion, DEL= continue, RET= stop');
					vedinascii() ->
				elseif char == `\^L` then
					vedrefresh()
				else quitloop()
				endif
			endrepeat
			endif
		endif
	endrepeat;
	unless found then tryaliases(); endunless;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 11 2003
	Changed tab to 4 spaces for indentation. A spurious tab at the end
	can interact badly with ved_send
--- Aaron Sloman, Aug  2 2003
	Changed to put each entry on a separate line, with commas at end.
--- Aaron Sloman, Jul 11 1999
	Checked for comma in alias, and if so truncated.
--- Aaron Sloman, Oct 1994
	Created HELP VED_ALIAS
--- Aaron Sloman, Aug 1 1993
	Made it cope with arbitrarily long lines in .mailrc file by using
	vedfile_line_repeater
--- Aaron Sloman, Jul 27 1993
	Made it look in general aliases database if not found in .mailrc
 */
