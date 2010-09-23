/* --- Copyright University of Birmingham 1993. All rights reserved. ------
 > File:            $poplocal/local/auto/vedskipheaders.p
 > Purpose:			Skip junk at top of email header
 > Author:          Aaron Sloman, Oct 15 1993
 > Documentation:
 > Related Files:	LIB * VED_GETMAIL, VED_GM, VED_NM, VED_LM
 */


section;

define vars procedure vedskipheaders();
	lvars string, line = vedline, len;
	;;; go down mail file till an interesting line is found.

	vedchardown();	
	repeat
		vedthisline() -> string;
		datalength(string) -> len;
		;;; check if in header still
		unless len > 0
		and (issubstring(': ', string) or strmember(string(1), '\s\t'))
		then
			(vedjumpto(line,1));
			quitloop();
		endunless;
	quitif(isstartstring('From: ', string) or
			isstartstring('Date: ', string) or
			isstartstring('To: ', string) or
			isstartstring('Subject: ', string));
		vedchardown();
	endrepeat;
	vedline - 1 -> vedlineoffset;
	vedrefresh();
enddefine;

endsection;
