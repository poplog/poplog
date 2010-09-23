/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/loadrcdemo.p
 > Purpose:         Compile files in the rclib/demo library
 > Author:          Aaron Sloman, Mar 30 1997
 > Documentation:
 > Related Files:
 */

section;

global vars rcuseslist =
	if isundef(rcuseslist) then ['$poplocal/local/rclib/demo/'];
	else rcuseslist
	endif;

define constant USESRC(name);
	dlocal popuseslist = rcuseslist <> popuseslist;
	loadlib(name)
enddefine;

define syntax loadrcdemo;
	lvars name;
	dlocal popnewline = true;

	sysfileok(rdstringto([; ^termin ^newline])) -> name;

	false -> popnewline;
	if name = nullstring then
			mishap(0, 'load: NO FILENAME SUPPLIED')
	endif;

	sysPUSHQ(name);
	sysCALL("USESRC");
	";" :: proglist -> proglist
enddefine;
endsection;
