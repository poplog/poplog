/* --- Copyright University of Birmingham 2004. All rights reserved. ------
 > File: 			$poplocal/local/auto/ved_postnews.p
 >      Copyright University of Sussex 1990. All rights reserved.
 >		Previously 			C.unix/lib/ved/ved_postnews.p
 >
 > Purpose:			Send news using ved_gn
 >   	Previously			Send news using inews on local or remote machine
 >
 > Author:          Aaron Sloman, May 29 1988 (see revisions)
 >   					Revised to use ved_gn, January 2001
 > Documentation:	HELP * VED_POSTNEWS, * VED_NET
 > Related Files:   LIB * VED_NET, * VED_GN
 */

#_TERMIN_IF DEF POPC_COMPILING

;;; NB NB NB NB -- this file may need to be edited on some machines
;;; See 'MAY NEED CHANGING' comments below

/*
To use this, first create header lines, e.g. using <ENTER> postnews

Then edit tnem

Then <ENTER> postnews will post the whole file.

If your .signature file has no more than 4 lines it will be added
automatically by "inews"

<ENTER> postnews
	Puts news header on current file if it does not have one
	Posts current file if there is a news header already

<ENTER> postnews <name>
	Posts current file using rsh or remsh on remote machine <name>

<ENTER> postnews new
	Stars new temporary file with news header

<ENTER> postnews cancel
   	NO LONGER WORKS
	Sends cancel message for current news article that has been read
	in from news files. (It needs the Message-ID header line.)
	(See HELP * VED_NET for reading news)

This program is modelled partly on lib ved_send
Assign FALSE to ved_send_wait make it post in the background
*/

section;


/*
NB
This version of ved_postnews uses

sysgetmailname(user);

a Birmingham local library. If that does not exist it can be defined thus:

	define sysgetmailname(user);
		user
	enddefine;

I.e. return the user's login name as mail name.

*/

#_IF sys_autoload("sysgetmailname")
	;;; use library version
#_ELSE
	define sysgetmailname(user);
		user
	enddefine;
#_ENDIF;

uses sysdefs;	;;; Needed for DEF below

;;; popsitename is used for inserting the From: line with correct address
;;; You will almost certainly need to edit LIB popsitename
;;; e.g.  vars popsitename = '@cs.bham.ac.uk'
;;; But first try autoloading it
uses popsitename;


;;; The following variable controls whether you use the new version of postnews
;;; that is based on ved_gn, or the old version that requires inews to be
;;; available.

;;; Make the default not to use inews
global vars use_inews_postnews = false;

;;; If you make use_inuews_postnews true then you will have to edit the following

lvars
	inews_path =
		sys_search_unix_path('inews',systranslate('PATH')),

	possible_inews_files =
	   [
		% if inews_path then inews_path endif %
		  '/bham/pd/lib/news/inews'			;;; Solaris machines at Bham.cs
		  '/usr/local/bham/bin/inews'		;;; At Bham.acs
		  '/usr/lib/news/inews',			;;; default for other sites
		],

	inews_prog_file = false,	;;; set below
	inews_arg = 'inews';
;

;;; variable to get ved_postnews to add From: line automatically
global vars gn_add_From ;
if isundef(gn_add_From) then false -> gn_add_From endif;


/* REMOVE CODE FOR REMOTE POSTING. PROBABLY NEVER REQUIRED NOW

    lvars rsh_command = '/bin/rsh';			/* MAY NEED CHANGING */
    unless sys_file_exists(rsh_command) then
	    '/usr/bin/remsh' -> rsh_command;
    endunless;

    lvars rsh_command_name = sys_fname_nam(rsh_command);

    /* The next assignment can be over-ridden by an argument to ved_postnews*/
    global vars inews_remote_host;

    unless isstring(inews_remote_host) then
	    'news.cs.bham.ac.uk' -> inews_remote_host			/* WILL NEED CHANGING */
    endunless;

*/

;;; copied from lib ved_send. Used only if inews is used
global vars ved_send_wait;
unless isboolean(ved_send_wait) then true -> ved_send_wait
endunless;


define lconstant extractline(string, header_limit) -> found;
	;;; Get substring from header line starting with string
	lvars string, header_limit, found;
	vedendfile();
	if vedteststartsearch(string) and vedline < header_limit then
		allbutfirst(datalength(string), vedthisline())
	else false
	endif -> found
enddefine;

define do_fromline();
	lvars
		user = popusername,
		fullname = sysgetusername(user),
		mailname = sysgetmailname(user);

	vedinsertstring('From: '); vedinsertstring(fullname);
	vedinsertstring(' <');
	vedinsertstring(mailname);
	vedinsertstring(popsitename);
	vedinsertstring('>\n')
enddefine;

define check_fromline();
	lvars header_limit, line;
	vedpositionpush();
	vedtopfile();
	;;; find end of header
	until vedline > vvedbuffersize or vvedlinesize = 0 do
		vedchardown();
	enduntil;
	vedline -> header_limit;
	extractline('From: ', header_limit) -> line;
	unless line then
		vedjumpto(header_limit, 1);
		vedlineabove();
		do_fromline();
	endunless;
	vedpositionpop();
enddefine;

define constant cancelargs() -> string;
	;;; Work out arguments for cancelling message to inews
	lvars id, groups, domain, string, header_limit;
	vedtopfile();
	;;; find end of header
	until vedline > vvedbuffersize or vvedlinesize = 0 do
		vedchardown();
	enduntil;
	vedline -> header_limit;
	extractline('Message-ID: ', header_limit) -> id;
	extractline('Newsgroups: ', header_limit) -> groups;
	extractline('Distribution: ', header_limit) -> domain;
	unless id then
		vederror('No Message-ID: field')
	endunless;
	unless groups then
		vederror('No Newsgroups: field')
	endunless;

	if domain then ' -d ' sys_>< domain else nullstring endif -> domain;

	cons_with consstring
	{%
		explode('-c \'cancel '), explode(id), `'`,
		explode(' -n '), explode(groups),
		explode(domain) %}-> string
enddefine;


;;; This procedure is now redundant and may be withdrawn. It requires
;;; inews to be availableon the system
define lconstant oldsendnews(cancelling);
	;;; If cancelling is false send the marked range as a news file
	;;;	If true then send cancelling message for current news message
	lvars
		din, dout, line, num = 1, limit, child, dev, cancelling,
		inews_args,
		inews_prog = false,
		inews_endarg = if cancelling then cancelargs() else '-h' endif
		;

	dlocal popexit,
		;;; inews_remote_host,
	;

	max(num,vvedbuffersize) -> limit;
	until vedusedsize(vedbuffer(num)) /== 0 do
		num fi_+ 1 -> num;
		if num fi_> limit then vederror('NO MESSAGE') endif
	enduntil;

	;;; Find where the inews program is, by trying all the options
	unless inews_prog_file then
		lvars file;
		for file in possible_inews_files do
			if sys_file_exists(file) then
				file -> inews_prog_file;
				quitloop();
			endif;
		endfor;
	endunless;

	;;; set up pointer to remote machine running inews, if necessary
	if vedargument /= nullstring then
		;;;; vedargument -> inews_remote_host;
		false
	else
		inews_prog_file
	endif -> inews_prog;

	if inews_prog and (readable(inews_prog) ->> dev) then
		;;; inews available on this machine
		sysclose(dev);
		if cancelling then
			;;; send cancel message on this machine and return
			sysobey(
				inews_prog_file sys_>< space sys_>< inews_endarg
					sys_>< ' < /dev/null', `$`
					);
			return();
		else
			[^inews_arg ^inews_endarg]-> inews_args;
		endif
	else
		vederror('INEWS NOT AVAILABE')
		/*
			Remove code for remote execution: [AS] 26 May 2001
			[^rsh_command_name ^inews_remote_host
				^(inews_prog_file sys_>< space sys_>< inews_endarg)] -> inews_args;
			rsh_command -> inews_prog;
		*/
	endif;

	if sysfork() ->> child then
		vedputmessage('Command being sent in background');
		until syswait() == child do enduntil;
	else
		;;; child
		identfn -> popexit;
		[] -> vedbufferlist;
		false -> vedediting;
		;;; do an extra fork to prevent a zombie
		if not(ved_send_wait) and sysfork() then
			;;; child just exits - waited for by parent
		else
			;;; if ved_send_wait then child, else grandchild

			;;; Make the pipe.
			syspipe(false) -> din -> dout;
			if sysfork() ->> child then
				;;; still grandchild - put characters into pipe (other end closed)
				sysclose(din);
				unless cancelling then
					repeat
						veddecodetabs(subscrv(num,vedbuffer)) -> line;
						syswrite(dout,line,datalength(line));
						syswrite(dout,'\n',1);
					quitif(num == limit);
						num fi_+ 1 -> num
					endrepeat;
				endunless;
				sysclose(dout);
			else
				;;; Previously done after 'else' below. Moved here for safety
				sysclose(dout);
				din -> popdevin;
				if ved_send_wait and sysvfork() then
					;;; just exit so that offspring has no parent
				else
					;;; great-grandchild
					sysexecute(inews_prog, inews_args, false)
				endif
			endif
		endif;
		fast_sysexit();
	endif
enddefine;


define lconstant sendnews(cancelling);

	if use_inews_postnews then
		vedpositionpush();
		pr('\n** SENDING NEWS. PAUSE IN CASE OF ERROR MESSAGES FROM NEWS HOST.\n');
		pr('\n** FAILED POSTINGS MAY BE SAVED IN A FILE\n');
		oldsendnews(cancelling);
		;;; give inews time to print error message - 6 secs
		syssleep(600);
		vedrestorescreen();
		vedpositionpop();
		vedputmessage('Done');
	else
		;;; use new posting mechanism
		veddo('gn p');
	endif;

enddefine;


define do_newsheader();
	;;; For preparing news file for posting. The default strings can
	;;;  be changed
	dlocal vedbreak = false;
	vedtopfile();
	vedlineabove();
	applist([
		'Subject:\n'
		'Newsgroups: (e.g. cs.announce,cs.misc,uk.ikbs,comp.lang.lisp)\n'
		'Distribution: (e.g. one of: cs, bham, local, uk, eunet, world)\n'
		'Summary:\n'
		], vedinsertstring);

	if gn_add_From then do_fromline() endif;

;;;	vedlinebelow();
	applist([
		'Keywords:\n\n'
		'[N.B. Avoid spurious spaces in list of groups and leave blank line before your text]\n'
		], vedinsertstring);
	vedtopfile();
	vedputmessage('EDIT HEADERLINES AS APPROPRIATE - SEND USING POSTNEWS')
enddefine;


define do_postnews(cancelling);
	;;; If cancelling is true then cancel previously sent message, using
	;;; Message-ID.
	;;; Otherwise post. File should have all the headers, e.g.
	;;; 	Subject: Newsgroups: Distribution: Keywords:
	;;; if not call ved_newsheader

	lvars cancelling;

	dlocal vedchanged, cucharout,
		 vedautowrite=false, vedpositionstack,
		 pop_file_versions=1;

	;;; Prevent printout invoking vedrestorescreen
	charout -> cucharout;

	false -> vedautowrite;

	if cancelling then
		pr('\n** CANCELLING. PAUSE IN CASE OF ERROR MESSAGES FROM NEWS HOST.\n');
	else
		if gn_add_From then check_fromline() endif;
	endif;
	sendnews(cancelling);
enddefine;

define ved_postnews;
	lvars line;
	dlocal vedargument;
	if vedargument = 'new' then
		edit(systmpfile(false, 'postnews', nullstring));
		do_newsheader();
	elseif vedargument = 'cancel' then
		nullstring -> vedargument;
		do_postnews(true)
	else
		vedbuffer(1) -> line;
		if isstartstring('Subject: ',line)
		or isstartstring('Newsgroups: ',line)
		or isstartstring('References: ',line)
		or isstartstring('Distribution: ',line)
		then
			do_postnews(false)
		else
			do_newsheader()
		endif
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb  8 2004
	Changed inserted From: line format to be more up to date,
		full name <mailname@domain>
--- Aaron Sloman, May 26 2001
	Remove code for running remote shell. Not needed with news servers

	Changed to use new posting facility in GN, unless
		use_inews_postnews is true
	The default is false.

	I.e. the "inews" utility is no longer needed, since "ENTER gn post"
	can directly contact the news server.

--- Aaron Sloman, Jan  6 2001
		Made "From:" line insertion more portable
--- Aaron Sloman, Oct 20 1996
		Changed sleep time to 6 seconds.
--- Aaron Sloman, 2 Sept 1995
    Altered so as to use list possible_inews_files because of different
         locations of inews in different sites.
	Also made to use rsh whenever it exists following this change in the
		'Master version'
		Robert John Duncan, Aug 11 1992
			Removed system dependencies: now uses 'remsh' only if /usr/ucb/rsh
			doesn't exist
	Removed bug workaround that caused ved_postnews to write the file then
		run inews.

--- Aaron Sloman, May  5 1993
	Fixed to insert user's preferred mail name for new version of inews, using
		gn_add_From
--- Aaron Sloman, Sep  1 1992
	Added "Summary:" to header inserted automatically
--- Aaron Sloman, Aug  3 1992
	Changed example groups to "cs" instead of "bham"
--- Aaron Sloman, Jul 26 1992
	changed to use /bham/bin/inews, making rsh unnecessary
--- Aaron Sloman, Apr 25 1992
	Modified for Birmingham. Set remote host to new-percy. Modified
	Header produced by ved_postnews.
--- Aaron Sloman, Jun  5 1990
	Changed "cancel" to "cancelling" to prevent clash with lib cancel
--- Aaron Sloman, May 27 1990
	Tidied up, and added "cancel" option
--- Aaron Sloman, Mar 20 1990
	Transferred to Public library
	Also added 'remsh' option for non-berkeley unix.
--- Jonathan Meyer, Nov 12 1989
	Added "new" argument to ved_postnews that open tmp file.
--- Aaron Sloman, Apr 10 1989
	Changed to use fast_sysexit
--- Aaron Sloman, Mar 27 1989
	Made it set screen non-raw etc so that error messages are readable.
	There's an 8 second delay added before the PRESS RETURN message
--- Aaron Sloman, Mar 19 1989
	Changed to use SYMA as default remote host
	Changed to allow alternative start lines in the heading


         CONTENTS - (Use <ENTER> g to access required sections)

 define lconstant extractline(string, header_limit) -> found;
 define do_fromline();
 define check_fromline();
 define constant cancelargs() -> string;
 define lconstant oldsendnews(cancelling);
 define lconstant sendnews(cancelling);
 define do_newsheader();
 define do_postnews(cancelling);
 define ved_postnews;

 */
