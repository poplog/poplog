/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_gnserver.p
 > Purpose:			Change the news server to be used by ved_gn
 > Author:          Aaron Sloman, Jan 16 1995 (see revisions)
 > Documentation:	Below
 > Related Files:	LIB * VED_GN, HELP * VED_GN
 */


/*

ENTER gnserver <name>

Changes <name> to be the new news server. E.g.

These two are equivalent
	ENTER gnserver cs
	ENTER gnserver percy

These two are equivalent.
	ENTER gnserver news.bham.ac.uk
	ENTER gnserver acs

Without an argument
	ENTER gnserver

simply tells you the current value of $NNTPSERVER

*/

section;
uses ved_gn;

global vars ved_gnserver_abbreviations =
	[{'acs' 'news.bham.ac.uk'}
	 {'is' 'usenet.bham.ac.uk'}
	 {'cs' 'news.cs.bham.ac.uk'}
	 {'ed' 'news.festival.ed.ac.uk'}
	];

define ved_gnserver();
	if vedargument = nullstring then
		veddo('trans NNTPSERVER')
	else
		;;; close current news connection
		veddo('gn quit');
		lvars vec, address = false;
		;;; now see if user has specified an abbreviation
		for vec in ved_gnserver_abbreviations do
			if vec(1) = vedargument then
				vec(2) -> address;
				quitloop()
			endif
		endfor;

		address or vedargument -> systranslate('NNTPSERVER')
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 16 2000
	Added new IS news server address
--- Aaron Sloman, Jul 21 1997
	Changed to allow empty argument. Shows current server
--- Aaron Sloman, Feb 17 1997
	Changed to use user definable abbreviation table
 */
