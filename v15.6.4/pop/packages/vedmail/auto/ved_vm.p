/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_vm.p
 > Purpose:			Easy reading of previous mail files
 > Author:          Aaron Sloman, Jan 15 1997
 > Documentation:   HELP * VED_GETMAIL
 > Related Files:	LIB * VED_GETMAIL
 */

section;

define ved_vm();
	veddo('ved ' sys_>< vedmailfile sys_>< vedargument)
enddefine;

endsection;
