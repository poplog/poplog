/* --- Copyright University of Birmingham 1993. All rights reserved. ------
 > File:            $poplocal/local/auto/sysgetmailname.p
 > Purpose:			Given user name, get mail name
 > Author:          Aaron Sloman, May  5 1993
 > Documentation:	Below
 > Related Files:
 */

/*

sysgetmailname(<user name>) -> <mail name>

Looks up the user name in the aliases file. Takes and returns a string

e.g.

	sysgetmailname('axs') =>
    ** A.Sloman

*/

section;

;;; Idiosyncratic to Birmingham
global vars sys_aliases_file = '/bham/doc/aliases/aliases';

;;; Property for cache of names
lconstant mailnames = newmapping([], 8, false, true);

define global vars procedure sysgetmailname(user) -> name;
	lvars
		name,
		len = datalength(user) + 1,
		procedure aliases,
		line;

	mailnames(user) -> name;
	returnif(name);

	if sys_file_exists(sys_aliases_file) then

	line_repeater(sys_aliases_file, sysstring) -> aliases;
	repeat
		aliases() -> line;
		if line == termin then
			vederror('UNKNOWN USER - ' sys_>< user sys_>< ' (NO MAIL NAME)')
		elseif isstartstring(user, line) then
			allbutfirst(len, line) -> name;
			quitloop();
		endif
	endrepeat;
	else
		user -> name;		;;; no alias, use user name
	endif;
	name -> mailnames(user);	;;; cache

enddefine;
		
endsection;
