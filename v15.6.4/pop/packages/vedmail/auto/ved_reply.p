/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:            $usepop/pop/packages/vedmail/auto/ved_reply.p
 > Purpose:			Reply to email message
 > Author:          Aaron Sloman, Updated Sept 1994 (see revisions)
 > Documentation:	See below
 > Related Files:	LIB * VED_RESPOND
 */

/* --- Copyright University of Sussex 1989.  All rights reserved. ---------
 > File:           C.unix/lib/ved/ved_reply.p
 > Purpose:		   Begin reply to Unix message in VED
 > Author:         Aaron Sloman, Nov  1 1986 (see revisions)
 > Documentation:  HELP * VED_REPLY, * VED_MAIL
 > Related Files:  LIB * VED_MCM * VED_MDIR  * VED_SEND, *VED_MAIL
 */

/*
This can be used with a Unix format mail file in the VED buffer. It assumes
that mail messages start with 'From 'at the beginning of a line.

If the cursor is in a mail message then
	<ENTER> reply
starts a header for a message to the sender, with same subject. The new
message is a marked range.
	<ENTER> sendmr
can then be used to send the mail.

	<ENTER> Reply

is similar, but attempts to produce a 'Cc: ' line with names of the others
who received the original message.

Either command can be given an optional extra argument which is either a
file name, in which case the reply will go into a file of that name, or
a line number, in which case the reply will go after that line, or
one of
	@t	- above Top of current current message
	@z  - end of file
	.	- above current line

NOTES:

Deals with various formats of UNIX mail headers but probably not completely.

Reply tries to clean up addresses of people at the current site in the
Cc: list.
*/

section;

;;;; EDIT LIB POPHOST FOR DIFFERENT SITES IF NECESSARY
uses pophost;
lconstant
	hostname= pophost("systemname"),
	Ccstring='Cc: ',
	Ccstrings=['Cc: ' 'cc: ' 'CC: ' 'Cc:\t' 'cc:\t' 'CC:\t'];


global vars popsitename;
unless isstring(popsitename) then
	'@' sys_>< pophost("sitemailname") ;;; see lib pophost
		-> popsitename
endunless;

global vars vedReplyCcSeparate;

if isundef(vedReplyCcSeparate) then
	true -> vedReplyCcSeparate
endif;


/* UTILITY PROCEDURES */

define lconstant charsbetween(start,fin,string) with_props 501;
	;;; put characters in string between start and fin on stack;
	lvars start,fin,string;
	min(fin,datalength(string)) -> fin;
	fast_for start from start to fin do
		subscrs(start,string)
	endfor
enddefine;


define lconstant prune_leader(string) -> string;
	;;; remove leading tabs or spaces from string
	lvars lim = datalength(string), i, c;
	fast_for i from 1 to lim do
		quitunless((subscrs(i, string) ->>c) == `\s` or c== `\t`);
	endfor;
	unless i == 1 then allbutfirst(i-1, string) -> string endunless;
enddefine;


global vars
	vedPruneSiteName;

if isundef(vedPruneSiteName) then
	false -> vedPruneSiteName
endif;


define lconstant prunesitename(string) -> string with_props 505;
	;;; does nothing if vedprunsitename is false
	;;; get rid of occurrences of popsitename in string
	lvars string, len = datalength(popsitename), start = 1, found;
	;;; could be a lot more efficient

	if vedPruneSiteName then
		if issubstring(popsitename,string) then
			consstring (#|
			 		while issubstring(popsitename, start, string) ->> found do
				 		charsbetween(start, found fi_-1, string);
				 		found fi_+ len -> start;
			 		endwhile,
			 		charsbetween(start,datalength(string) ,string)
			 	|#) -> string
		endif;
	endif;
enddefine;


define lconstant Veddo(vedcommand) with_props 600;
	;;; vedcommand is a substitute command. Do it without messages
	lvars line, edit=vedediting;
	dlocal vedcommand;
	vedtrimline(); copy(vedthisline()) -> line;
	false -> vedediting;
	space sys_>< vedcommand -> vedcommand;
	veddocommand();
	edit -> vedediting;
	unless line = vedthisline() then vedrefreshrange(vedline,vedline,undef)
	endunless
enddefine;

define lconstant vedgetrest(string) -> string with_props 601;
	;;; used to get continuation of "To:" or "CC:" line, etc.
	;;; if next line starts with space or tab
	lvars string, line, strings;
	prune_leader(string) -> string;
	repeat
		vednextline();
		vedthisline() -> line;
	quitif(vvedlinesize == 0 or strmember(`:`,line)
			or not(strmember(line(1),'\s\t')));
	sysparse_string(string) <> sysparse_string(line) -> strings;
	destpair(strings) -> (string, strings);
	for line in strings do
		string  sys_>< vedspacestring sys_>< line -> string
	endfor;
	endrepeat;
enddefine;

define lconstant vedtryfind(string,lo,hi) -> found with_props 602;
;;; String can be a string or list of strings
;;; Assume current message is between lines lo and hi.
;;; Try to locate line starting with string between lo and hi

	vedjumpto(lo,1);
	repeat
		if vvedlinesize == 0 then false -> found; return() endif;
		veddecodetabs(vedthisline()) -> found;
		if isstring(string) then
			returnif(isstartstring(string, found));
		else ;;; string must be a list of strings...
			lvars item;
			for item in string do
				;;; return pair containing key and line found
				if isstartstring(item, found) then
					;;; return pair containing key and line found
					conspair(item, found) -> found;
					return();
				endif;
			endfor;
		endif;
		vedchardown();
		if vedline > hi then false -> found; return() endif;
	endrepeat
enddefine;


global vars
	FromKey = 'From: ',
	ved_replyfields = ['Reply-To: ' 'Reply-to: ' ^FromKey 'Sender: '],
	;;; controls whether From: line is included along with Reply-To line.
	ved_inreplyfield = 'In-Reply-To: ',
	ved_message_idfields = ['Message-ID: ' 'Message-Id: '],
	ved_references_field = 'References: ',
	;;; make this true to have sender as well as Reply-To: address
	;;; in To: list.
	ved_include_sender = true;

define lconstant vedgetsender(lo,hi) -> line with_props 603;
	;;; Get name of sender from 'From: ...... <name>'
	lvars lo, hi, line, m, n, temp, key, len, From = false;
	;;; 'lo' is line of top of message, 'From 'line.

	for key in ved_replyfields do
		datalength(key) -> len;
		vedtryfind(key, lo, hi) -> line;
		if line then
			unless key = FromKey then
				;;; found a reply-to line
				if ved_include_sender then
					;;; find the sender as well as Reply-To: field
					vedtryfind(FromKey, lo, hi) -> From;
				endif;
				if From then
					;;; extend the from line with sender
					;;; Veddebug(['From found' ^From]);
					line >< ',' >< allbutfirst(6,From) -> line;
					;;; Veddebug(['Sender and Replyto' ^line])
				endif;
			endunless;
			quitloop
		endif;
	endfor;

	if line then
			;;; assume what's after 'From: ' is name
			prunesitename(allbutfirst(len, line)) -> line;
	else
		;;; Sometimes there is no 'From: ' line. So get 'From ' line.
		;;; This is not reliable
		subscrv(lo, vedbuffer) -> line;
		if isstartstring('From ',line) then
			skipchar(`\s`,5,line) -> lo;
			locchar(`\s`,lo,line) -> hi;
			prunesitename(substring(lo, hi - lo, line))
		else false
		endif -> line
	endif
enddefine;

define lconstant vedgetsubject(lo,hi) -> subject with_props 604;
	;;; Get subject from line 'Subject: ...   '
	lvars lo,hi,subject;
	vedtryfind('Subject: ', lo, hi) -> subject;
	if subject then
		;;; Add "Re:" to indicate that it is a reply to a message on
		;;; same subject, unless it's there already
		if issubstring('Re:', subject) then
			copy(subject) -> subject		;;; to be safe
		else
			'Subject: Re: ' sys_>< allbutfirst(9, subject) -> subject
		endif;
		vedgetrest(subject) -> subject;
		;;; Veddebug(subject);
	else 'Subject: ' -> subject
	endif
enddefine;


define lconstant vedgetCc(lo,hi,) -> Cc with_props 605;
	;;; get Cc: line
	lvars lo, hi, Cc, line;

	vedtryfind(Ccstrings, lo, hi) -> Cc;
	if Cc then
		;;; extract the string from the pair
		back(Cc) -> Cc;
		prunesitename(Cc) -> Cc
	endif;

	if Cc then
		;;; add the following line if it starts with space or tab
		vedgetrest(Cc) -> Cc;
		if Cc then prunesitename(Cc) -> Cc endif;

		;;;Veddebug(Cc);
		unless hasstartstringin(Cc, Ccstrings) then
			Ccstring sys_>< Cc -> Cc
		endunless
	endif
enddefine;

define lconstant vedgetTo(lo,hi,) -> string with_props 606;
;;; get 'To: ' line, in case there are other recipients
	lvars lo, hi, string, line;
	vedtryfind('To: ', lo, hi) -> string;
	if string then
		prunesitename(allbutfirst(3, string))-> string;
		;;; Check if no other recipients
		if vedissubitem(popusername, 1, string)
		and datalength(string) - datalength(popusername) < 2
		then nullstring -> string
		endif;
		vedgetrest(string) -> string;
		if string = nullstring then false -> string
		else
			prunesitename(string) -> string;
		endif;
	endif
enddefine;


define lconstant vedgetfield(key, lo, hi) -> field;
	;;; Get field starting with key.
	;;; key is a string, or list of strings to try

	vedtryfind(key, lo, hi) -> field;
	if field then
		;;; extract the string and if appropriate, the key
		if ispair(key) then destpair(field) ->(key, field) endif;
		;;; remove field stuff from beginning of string
		allbutfirst(datalength(key), field) -> field;
    	;;; see if there is a continuation
	 	vedgetrest(field) -> field;
	endif;
	;;; Veddebug([key ^key field ^field]);
enddefine;

define lconstant vedgetmesssageid(lo,hi) -> messageid;
	lvars lo,hi,messageid;
	vedgetfield(ved_message_idfields, lo, hi) -> messageid;
	;;; Veddebug([messageid ^messageid]);
enddefine;

define lconstant vedgetreferences(lo,hi) -> references;
	;;; Get references from line 'References: ...   '
	lvars lo,hi,references;
	vedgetfield(ved_references_field , lo, hi) -> references;
	;;; Veddebug([references ^references]);
enddefine;

define lconstant vedtry(proc,lo,hi);
	;;; if proc returns a result, so will vedtry
	lvars proc,lo,hi;
	vedpositionpush();
	proc(lo,hi);
	vedpositionpop()
enddefine;

define lconstant veddoreply(all_?) with_props ved_reply;
;;; ENTER reply starts reply to sender. ENTER Reply starts reply to all
;;; all_? is a boolean. If true, reply to all recipients incl Cc: list
	lvars
		sender, subject, From, Cc, To, messageid, references,
		lo, hi, all_?, Where,
		oldvedediting = vedediting, oldc=vedchanged;
	dlocal vvedmarkprops, vedediting, vedbreak=false, vedautowrite=false,
		;;; localise search state variables.
		ved_search_state;

	unless subscrs(1, popsitename) == `@` then
		'@' sys_>< popsitename -> popsitename
	endunless;
	if vedargument = nullstring then
		false -> Where
	else
		;;; find out where to insert reply
		unless (strnumber(vedargument) ->> Where) then
			vedargument -> Where
		endunless;
	endif;
	vedmarkpush();
	false -> vvedmarkprops;
	ved_mcm();
	vvedmarklo -> lo; vvedmarkhi -> hi;
	vedmarkpop();

	vedtry(vedgetmesssageid,lo,hi) -> messageid;

	vedtry(vedgetreferences,lo,hi) -> references;
	unless references then nullstring -> references endunless;

	vedtry(vedgetsender,lo,hi) -> sender;
	vedtry(vedgetsubject,lo,hi) -> subject;

	if all_? then
		vedtry(vedgetCc,lo,hi) -> Cc;
		;;; Veddebug(Cc);
		vedtry(vedgetTo,lo,hi) -> To;
		;;; Veddebug([To ^To ^(datakey(To))]);
		;;; append To: list to Cc: list
		if Cc then
			if To then
				Cc sys_>< ','  sys_>< To -> Cc
			endif
		elseif To then
			Ccstring sys_>< To -> Cc
		else
			;;; Cc is already false
		endif;
	else false -> Cc
	endif;

	;;; Veddebug(Cc);
	;;; Find where to start reply
	if Where = '@t' then lo
	elseif Where = '@z' then vvedbuffersize fi_+ 1
	elseif Where = '.' then vedline
	else Where
	endif -> Where;
	if isinteger(Where) then
		vedjumpto(Where,1); vedlineabove();
	elseif isstring(Where) then
		if Where = '@x' then
			vedswapfiles(); vedendfile();
		elseif Where(1) == `@` then
			vedlocate(allbutfirst(1, Where)); vedlineabove();
		else	;;; argument must have been file name
			ved_ved();	vedendfile();
		endif;
		vedlinebelow();
	else hi -> vedline;
		vedsetlinesize();
		unless vvedlinesize == 0 then vedlinebelow() endunless
	endif;
	unless vedline==1 then vedlinebelow() endunless;
	unless vedline >= vvedbuffersize then
		vedlinebelow(); vedlinebelow(); vedcharup();
	endunless;
	;;; insert 'From ' line to conform to mail format.
	vedcheck();
	vedmarklo();
	vedinsertstring('From '); vedinsertstring (sysgetusername(popusername));
	vedlinebelow();
	vedinsertstring('To: ');
	vedinsertstring(sender);
	;;; remove trailing comma
	Veddo('gsl/,@z//');
	;;; insert line breaks if there are commas in To: list
	vedmarklo();vedmarkhi();
	Veddo('sgsr/,/,@n\t/');
	unless vvedmarklo == vvedmarkhi then
		vedjumpto(vvedmarkhi, 1)
	endunless;
	;;; Veddebug([Inserted ^sender]);

	vedlinebelow(); vedinsertstring(subject);

	;;; insert messageid
	if messageid then
		vedlinebelow();
		vedinsertstring(ved_inreplyfield); vedinsertstring(messageid);
	endif;

	;;; insert references
	if messageid or references /== nullstring then
		vedlinebelow();
		vedinsertstring(ved_references_field);
		unless datalength(references) == 0 then
			vedinsertstring(references);
			vedcharright();
		endunless;
		;;; make sure at least messageid is in references field.
		if messageid then vedinsertstring(messageid) endif;

	endif;

	if Cc then
		;;; insert copy list
		vedlinebelow(); vedinsertstring(Cc); vedcharinsert(`,`);
		false -> vedediting;
		;;; now clean up junk and replace spaces with commas
		;;; Veddo('gsl/ /,/');
		;;; get rid of redundant occurrences of hostname
		Veddo('gsl"@@'  sys_>< hostname sys_>< '.uucp,","');
		Veddo('gsl",'  sys_>< hostname sys_><'!","');
		Veddo('gsl"@@' sys_>< hostname sys_><',","');
		;;; Get rid of sender (already in To: line) ???
		;;; Veddo('gsl",'  sys_>< sender  sys_><',","');
		;;; Get rid of oneself
		Veddo('gsl",' sys_>< popusername sys_>< ',","');
		while issubstring(',,', vedthisline()) do
			Veddo('gsl/,,/,/');
		endwhile;
		Veddo('gsl/,@z//');		;;; remove trailing comma
		Veddo('gsl/:,/: /');
		oldvedediting -> vedediting;
		;;; if nothing left, delete Cc: line
		if issubstring(vedthisline(), Ccstring) then vedlinedelete()
		else
			if vedReplyCcSeparate then
				;;;break up Cc: line
				vedmarklo(),vedmarkhi();
				Veddo('gsr/, /,');
				Veddo('gsr/,/,@n\s\s\s\s');
                vedrefreshrange(vvedmarklo, vvedmarkhi, undef);
			else
				vedtextright(); vedcheck(); vedrefreshrange(vedline,vedline,undef);
			endif;
		endif;
		vedcharup(); vedtextright();vedmarkhi();
	endif;
	if oldc then oldc + 1 else 1 endif -> vedchanged;
	chain(ved_mcm<>vedrefresh);
enddefine;

define global vars procedure ved_reply =
	veddoreply(%false%)
enddefine;

define global vars procedure ved_Reply =
	veddoreply(%true%)
enddefine;

endsection;

nil -> proglist;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  7 2009
	Altered to cope with 'wrapped' Subject line.
--- Aaron Sloman, Feb  7 2007
	Fixed some problems with continuation lines, and dealt with missing
	references field	
--- Aaron Sloman, Jan 30 2007
	Altered to insert In-Reply-To: field and References: field
	(Users who don't want them can delete them before sending.)

--- Aaron Sloman, Jan  1 2007
	extract_mailnames no longer used. So removed.
	Extended Ccstrings to allow tabs after ':'
	Allow name on From: line to be included in To: along with Reply-To: address
		If ved_include_sender is non false (new default).

--- Aaron Sloman, Jul 12 2004
		Added global variable vedPruneSiteName to control whether
		local addresses are truncated. Made the default false,
		which changes the behaviour.

--- Aaron Sloman, Aug  2 2003
	Changed to put each Cc name on separate line. Remove by making
	vedReplyCcSeparate  false

--- Aaron Sloman, Feb  7 2000
	Added Tabs in Cc strings.

--- Aaron Sloman, Jul 23 1999
	Extended to cope with missing To: line (e.g. newsgroup copies)

--- Aaron Sloman, Aug 29 1997
	Added 'Reply-to: ' as well as 'Reply-To: ' as recognized field.

--- Aaron Sloman, May 22 1997
	Changed to cope with 'cc:' and 'CC:' as well as 'Cc'
	(Uses hasstartstringin)

--- Aaron Sloman, Feb  2 1995
		Altered to make it extract the names properly from
			Reply-To or Sender fields.
		Altered to cope with sender fields in this format:
	 		phayes@cs.uiuc.edu (Pat Hayes)
		instead of only
			Tom Khabaza <tomk@isl.co.uk>
--- Aaron Sloman, Sept 12 1994
		Altered to allow 'Reply-To: ' or 'Sender: ' fields to be used.
		Introduced ved_replyfields = ['Reply-To: ' 'From: ' 'Sender: '];
		Thanks to help from Roger Evans
--- John Williams, Jun  3 1992
		Fixed BR jamesg@cogs.susx.ac.uk.1 by renaming lvar -where-
		to -Where-
--- Aaron Sloman, May 29 1989
	Localised VED search state variables in veddoreply
--- Aaron Sloman, May 21 1989
	It occasionally merged To: line with Cc: line. Now fixed. Further
	Tidying and replaced :pdr_valof with new define syntax
--- Aaron Sloman, April 6 1989
	Changed to cope with more complex From:, To:, Cc: lines, and
		remove occurrences of popsitename more effectively
--- Aaron Sloman, Mar  5 1989
	Simplified vedgetsubject. Made it insert "Re:" after subject, if
	it isn't already there. Used pdr_valof

         CONTENTS - (Use <ENTER> g to access required sections)

 define lconstant charsbetween(start,fin,string) with_props 501;
 define lconstant prune_leader(string) -> string;
 define lconstant prunesitename(string) -> string with_props 505;
 define lconstant Veddo(vedcommand) with_props 600;
 define lconstant vedgetrest(string) -> string with_props 601;
 define lconstant vedtryfind(string,lo,hi) -> found with_props 602;
 define lconstant vedgetsender(lo,hi) -> line with_props 603;
 define lconstant vedgetsubject(lo,hi) -> subject with_props 604;
 define lconstant vedgetCc(lo,hi,) -> Cc with_props 605;
 define lconstant vedgetTo(lo,hi,) -> string with_props 606;
 define lconstant vedgetfield(key, lo, hi) -> field;
 define lconstant vedgetmesssageid(lo,hi) -> messageid;
 define lconstant vedgetreferences(lo,hi) -> references;
 define lconstant vedtry(proc,lo,hi);
 define lconstant veddoreply(all_?) with_props ved_reply;
 define global vars procedure ved_reply =
 define global vars procedure ved_Reply =

 */
