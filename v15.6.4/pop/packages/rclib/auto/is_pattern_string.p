/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/is_pattern_string.p
 > Purpose:			Recognise strings containing pattern elements
 > Author:          Aaron Sloman, May 15 1999
 > Documentation:	See HELP SYS_FILE_MATCH for pattern formats
 > Related Files:	(all the libraries concerned with file browsing.)
 */


section;
compile_mode :pop11 +strict;


define is_pattern_string(string) -> boolean;
	strmember(`*`, string)
	or strmember(`?`, string)
	or strmember(`[`, string)
	or strmember(`{`, string)
    or issubstring('/.../', string) -> boolean;
enddefine;

endsection;
