/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_day.p
 > Purpose:			Insert current date into the file, after a space
 > Author:          Aaron Sloman, Dec 14 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;
section;

define ved_day();
	;;; insert date in format  14 Dec 1995
	;;; Allow for version that does not include 'GMT' type string

	lvars month,day,year, datelist;
	[% sys_parse_string(sysdaytime()) %] -> datelist;
	explode(datelist);
	if length(datelist) == 6 then
		-> (,month,day,,,year);
	else
		-> (,month,day,,year);
	endif;
	vedinsertstring(day);
	vedinsertstring(vedspacestring);
	vedinsertstring(month);
	vedinsertstring(vedspacestring);
	vedinsertstring(year);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb  6 1999
	Altered to cope with version of linux poplog which does not include
	'GMT' in string
--- Aaron Sloman, Mar 27 1997
	Changed so that it no longer inserts a leading space.
 */
