/* --- Copyright University of Birmingham 1992. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_purgemail.p
 > Purpose:			Delete backup VED mail files
 > Author:          Aaron Sloman, Sep 25 1992
 > Documentation:
 > Related Files:	LIB * VED_GETMAIL, HELP * VED_GETMAIL
 */



section;

uses ved_getmail;

define ved_purgemail();
/*
	vedputmessage('Deleting backup mail files. Please wait');
	sysobey('/bin/rm ' sys_>< sysfileok(vedmailfile)
		sys_>< '*- ', `$`);
*/
	veddo('purgefiles ' sys_>< sysfileok(vedmailfile) sys_>< '*- ');
	vedputmessage('DONE');
enddefine;

endsection;
