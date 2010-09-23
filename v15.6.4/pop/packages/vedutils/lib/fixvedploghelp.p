/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/lib/fixvedhelp.p
 > Purpose:
 > Author:          Aaron Sloman, Feb  2 1998
 > Documentation:
 > Related Files:
 */


global vars ved_phelp = ved_help;

sysunprotect("ved_help");
ved_ploghelp -> ved_help;
sysprotect("ved_help");
