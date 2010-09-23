/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_send.p
 > Purpose:			Modified version of ved_send(mr) using sendmail
 > Author:          Aaron Sloman, Sep 30 1998 (see revisions)
 > Documentation:  HELP * SEND, * VED_GETMAIL
 > Related Files:  LIB *VED_SENDMR, VMS LIB *VED_SEND, MAN * mailx
 >					$usepop/pop/lib/ved/ved_send.p
 */

/* --- Copyright University of Sussex 1992.	 All rights reserved. ---------
 > File:		   $poplocal/local/auto/ved_send.p
 > File:		   C.unix/lib/ved/ved_send.p
 > Purpose:		   send file or range as mail, allows .mailrc Cc and Bcc specs
 > Author:		   Mark Rubinstein and A.Sloman 1985 (see revisions)
 */

;;; compile_mode :pop11 +strict;

include sysdefs.ph;		;;; to work out a default name for the mail program

section;
;;; In Birmingham used with LIB ved_autosave. dlocalised below
global vars vedautosave_min_write;

/* variable to control whether whole process done in the background */
global vars ved_send_wait;
unless isboolean(ved_send_wait) then
	false -> ved_send_wait;
endunless;

/* variable to control whether environment variable $record is removed */
global vars ved_send_record;
unless isboolean(ved_send_record) then
	false -> ved_send_record;	;;; default is not to copy
endunless;

/* variable to control whether From line is inserted in file */
global vars vedinsert_From;
unless isboolean(vedinsert_From) then
	true -> vedinsert_From;
endunless;

/* variable to control whether commas inserted in .mailrc entries*/
global vars vedinsert_commas;
unless isboolean(vedinsert_commas) then
	;;; original default was true
	false -> vedinsert_commas;
;;;	true -> vedinsert_commas;
endunless;


/*  vedindent_From controls whether lines in message starting with 'From '
		are indented with ">" in file.
	Suppressed if whole file sent, and if ved_sendmr is called with arguments.
*/
global vars vedindent_From;
unless isboolean(vedindent_From) then
	true -> vedindent_From;
endunless;

/* variable to control whether aliases are parsed before mail program */
global vars ved_send_aliases;
unless isboolean(ved_send_aliases) then
	true -> ved_send_aliases;
endunless;

/* Variable to control whether special ved chars are included in mail
See REF * vedfile_line_consumer */
global vars ved_send_plain_text;
unless isboolean(ved_send_plain_text) then
	;;; default is to strip special characters
	1 -> ved_send_plain_text;
endunless;

/* Variable specifying mail domain for From: line. May be autolodable */
unless (identprops("popsitename") == undef
    and sys_autoload("popsitename")
    and isstring(valof("popsitename")))
or isstring(valof("popsitename"))
then
	'@cs.bham.ac.uk' -> valof("popsitename")
endunless;

/* the user's .mailrc file */
global vars vedmailrc;

lvars mailrc = false;	;;; set when program is run

/* The user must have the option to use a different mailrc for VED-based
   mail and non-VED-based mail. Also it must NOT be computed at top level
   in the file. Must be done at run time. Can then be put in saved images,
   etc.
*/

lconstant default_mailrc = '$HOME/.mailrc';

lvars
	lastlookatmailrc = 0,
	reading_mailrc = false;

constant procedure aliases =
	newanyproperty([], 257, 1, 257, syshash, nonop =, false, false, false);

/* acceptable prefixes to find at file top */
lconstant
	to_prefixes = ['TO' 'To' 'to'],
	re_prefixes =
		['RE' 'Re' 're' 'Subject' 'subject' 'Subj' 'SUBJ' 'subj' 'SUBJECT'],
	cc_prefixes = ['CC' 'Cc' 'cc'],
	bcc_prefixes = ['BCC' 'BCc' 'Bcc' 'bcc'];


/* Mailer to use */

global vars ved_send_mailer = '/usr/lib/sendmail';

/*
unless isstring(ved_send_mailer) then
#_IF DEF SYSTEM_V
	 '/usr/bin/mailx'
#_ELSE
	 '/usr/ucb/Mail'
#_ENDIF
	-> ved_send_mailer
endunless;

*/

global vars ved_send_new_format = true;

/* Parse a string using spaces, tabs and commas as separators,
unless ved_send_new_format is true, in which case use only commas*/

define lconstant parse_string(str) -> stringlist;
	lvars c, i, str,
		lim = datalength(str),
		separators =
			if vedinsert_commas then ',\s\t', else ',' endif,
		;

	;;; remove leading spaces and tabs from string
	fast_for i from 1 to lim do
		unless strmember(subscrs(i, str), '\s\t') then
			if i fi_> 1 then
				allbutfirst(i fi_- 1, str) -> str
			endif;
			quitloop()
		endunless;
	endfor;
	
	[%
		if ved_send_new_format then
			sys_parse_string(str, `,`);
;;; sys_parse_string changed after V15.5
#_IF pop_internal_version > 155000
			;;; remove possibly empty string at end
			if last(str) == `,` then -> endif;
#_ENDIF
		else
			;;; split where separators occur
			fast_for i to lim do
				unless strmember(fast_subscrs(i, str) ->> c, separators) then
					/* found beginning of an entry */
					cons_with consstring {%
						repeat
							c;
						quitif(i == lim);
							fast_subscrs(i fi_+ 1 ->> i, str) -> c;
						quitif(strmember(c, separators));
						endrepeat
						%};
				endunless;
			endfast_for
		endif
	%] -> stringlist;
enddefine;


/* convert tabs to spaces - doesn't copy string */
define lconstant tabs_to_spaces(str) -> str;
	lvars str, i;
	fast_for i to datalength(str) do
		if fast_subscrs(i, str) == `\t` then
			`\s` -> fast_subscrs(i, str);
		endif;
	endfast_for;
enddefine;

define lconstant count_ok(bool, line);
	lvars bool;
	unless bool then
		vederror('Premature end of ALIAS in MAILRC line: ' sys_>< line);
	endunless;
enddefine;

define lconstant full_email_name(alias) -> alias;
	if reading_mailrc
		or strmember(`@`, alias) or strmember(`<`, alias) or strmember(`(`, alias) then
		alias
	else
		;;; first remove any leading or trailing spaces
		lvars
			len = datalength(alias),
			first_char = skipchar(`\s`, 1, alias),
			last_char = skipchar_back(`\s`, len, alias);
		if first_char then
			;;; Veddebug([first ^first_char last ^last_char]);
			if first_char /== 1 or last_char /== len then
				substring(first_char, last_char+1-first_char, alias) -> alias
			endif
		else
			mishap('NON-EMPTY ALIAS EXPECTED', [^alias])
		endif;
	
		lvars username = sysgetusername(alias);
		if username then
			username <> ' <' <> alias <> popsitename <> '>'
		else
			alias
		endif
	endif -> alias
enddefine;

define lconstant expand_local_address(name, alias);
	;;; alias is a string. See if it needs to be expanded with user name
	;;; Veddebug(alias);
	full_email_name(alias) -> aliases(name)
enddefine;

lvars expand_depth = 0;

/* expands aliases and checks for recursion depth limit being exceeded */

define lconstant checkentry(name, alias);
	lvars each, newalias = nullstring, needcomma ;

	dlocal expand_depth;

	define lconstant recheck(entry);
		lvars entry, alias;
		;;; see if the entry needs further expansion
		aliases(entry) -> alias;
		if islist(alias) then
			;;; expand to a string
			checkentry(entry, alias);
			aliases(entry);
		else
			if alias then
				expand_local_address(entry, alias);
				aliases(entry)
			else
				;;; Veddebug(entry);
				full_email_name(entry)
			endif
		endif;
	enddefine;


	expand_depth fi_+ 1 -> expand_depth;
	if expand_depth fi_> 25 then
		mishap(name, alias, mailrc, 3, 'Recursive Mail Alias')
	endif;

	if islist(alias) then
		false -> needcomma;		;;; controls whether commas inserted
		fast_for each in maplist(alias, recheck) do
			newalias, if needcomma then sys_>< "," endif,
				sys_>< each	 -> newalias;
			true -> needcomma;
		endfor;
		;;; Store the expanded alias string
		newalias -> aliases(name);
	else
		expand_local_address(name, alias);
	endif;
	
enddefine;


/* try to read the mailrc file - just look for aliases (going to a depth of
 * 25 before mishapping.
 */

define lconstant tryreadmailrc;
	lvars dev, i, count, line, n, name;

	;;; make sure strings are used as separators
	dlocal ved_send_new_format = false;

	unless mailrc then
		;;; Set up mailrc. This should be done once only
		if isstring(vedmailrc) then vedmailrc
		elseif systranslate('MAILRC') ->> mailrc then
		else 	default_mailrc
		endif.sysfileok -> mailrc
	endunless;

	/* find if we can access the mailrc file and if we need to */
	returnunless(sys_file_exists(mailrc) and sysmodtime(mailrc) > lastlookatmailrc);
	/* read in mailrc file and process lines starting with 'alias' */

	clearproperty(aliases);
	sysopen(mailrc, 0, "line") -> dev;
	0 -> line;
	lvars buffer = inits(1024);
	until (sysread(dev, buffer, 1024) ->> count) == 0 do
		line fi_+ 1 -> line;
		tabs_to_spaces(buffer) ->;
		nextunless((skipchar(`\s`, 1, buffer) ->> i) and i <= count);
		/* something on this line */
		if issubstring_lim('alias', i, i, false, buffer) then
			/* it's an alias */
			;;; Check that there's something after 'alias '
			count_ok((skipchar(`\s`, i fi_+ 6, buffer) ->> i) and i <= count, line);
			count_ok((locchar(`\s`, i, buffer) ->> n) and n <= count, line);

			;;; get the string following 'alias ', i.e. the alias to be expanded
			substring(i, n fi_- i, buffer) -> name;
			;;; check that there's more on the line
			count_ok((skipchar(`\s`, n, buffer) ->> i) and i <= count, line);

			if buffer(i) == `"` and buffer(count fi_- 1) == `"` then
				/* if whole alias enclosed in " marks, remove them */
				i fi_+ 1 -> i;
				count fi_- 1 -> count;
			endif;
			;;; store the mapping between the alias and the expansion
			(parse_string(substring(i, count fi_- i,buffer))) -> aliases(name);
;;;			(parse_string(substring(i, count fi_- i,buffer)).dup.Veddebug) -> aliases(name);
		endif;
	enduntil;
	sysclose(dev);
	sysmodtime(mailrc) + 1 -> lastlookatmailrc;
	dlocal reading_mailrc = true;
	;;; Veddebug('checking entries');
	appproperty(aliases, checkentry);
	;;; Veddebug('aliases checked');
enddefine;

/*
;;; test next procedure

onlywhitespace('')=>
onlywhitespace('\s\s\t')=>
onlywhitespace('\t')=>
onlywhitespace('a')=>
onlywhitespace('\s\s\t\t\sx\t')=>
*/

define lconstant onlywhitespace(string) -> boolean;

	if string = nullstring or string = vedspacestring then
		true -> boolean;
	else
		lvars char, index, len = datalength(string);
		fast_for index to len do
			unless strmember(subscrs(index, string),'\s\t') then
				false -> boolean; return()
			endunless;
		endfor;
		true -> boolean
	endif;
enddefine;


/* Expand aliases in -line-.  Return 'transformed' line, i.e. expanded. Pipes
 * are left for the mailer to cope with.
 */
define lconstant check_aliases(line) -> line;
	lvars line, alias, name;

	;;; Veddebug('Checking ' >< line);

	/* see if we are using aliases */
	returnunless(ved_send_aliases);

	/* see if we can/need to update the alias property */
	tryreadmailrc();

	/* perform alias substitution */
	if onlywhitespace(line) then
		vederror('Names missing on line ' sys_>< vedline >< ' (may have tab)');
	endif;

	;;; prepare translated version
	lvars strings = parse_string(line);
	
	consstring(#|
		fast_for name in strings do
			if aliases(name) ->> alias then
				check_aliases(alias)
			else
				;;; Veddebug('Getting full email name ' ><name);
				full_email_name(name);
			endif.explode, `,`;
		endfor;
		;;; endfast_for;
		/* get rid of last comma */
		erase();
		|#) -> line;
	;;; Veddebug('Checked ' >< line);

enddefine;


/* simple logging of outgoing mail */
define lconstant writelog(tolist, subject, cclist, bcclist);
	lvars tolist subject cclist bcclist outfile dout;
	/* place to store short records of outgoing mail */
	if systranslate('MAILREC') ->> outfile then
		;;;vedputmessage('Logging in ' sys_>< outfile);
		discappend(outfile) -> outfile;
		outfile(`\n`);
		appdata(% outfile %) -> dout;
		dout(sysdaytime());
		dout('\nTo: '); dout(tolist);
		unless cclist = nullstring then
			dout('\nCc: '); dout(cclist);
		endunless;
		unless bcclist = nullstring then
			dout('\nBcc: '); dout(bcclist);
		endunless;
		unless subject = nullstring then
			dout('\nRe: '); dout(subject);
		endunless;
		outfile(termin);
	endif;
enddefine;


/* pipe the marked range through sendmail
 * specify subject, cc list and bcc list.
 * Function must not
 * be called with a null tolist!  vvedmarklo *must* be <= vvedmarkhi!!
 */
define lconstant runmailer(tolist, subject, cclist, bcclist);

	lvars
		child, mailer_arglist,
			procedure (consume)
		;
	dlocal vedediting, vedbufferlist, popexit, vedcommand;

	define lconstant do_mail(mailer, args);
		lvars mailer, args, child, dout, din, line, len, nulldev;
		dlocal poprawdevin, popdevout, vvedmarklo;
		syspipe(false) -> din -> dout;
		0 -> vedscreencharmode;	;;; in case there are error messages
		rawoutflush();
		sysopen('/dev/null',2,false) -> nulldev;

		if sys_fork(true) ->> child then
			/* this is still parent */
			sysclose(din);
			/* stuff the marked range to the mail program */
			if vvedmarklo <= vvedmarkhi then
				;;; non-empty body
				vedfile_line_consumer(dout, ved_send_plain_text) -> consume;
				repeat
					vedbuffer(vvedmarklo) -> line;
					if datalength(line) fi_> 0
					and fast_subscrdstring(1,line) == `~` then
						;;; turn leading "~" into "~~"
						'~' <> line -> line;
					endif;
					consume(line);
				quitif(vvedmarklo == vvedmarkhi);
					vvedmarklo + 1 -> vvedmarklo;
				endrepeat;
			endif;
/*
;;; This bit needed only when it's piped through mailx

			/* and now stuff the additional parameters as escapes */
			unless (length(subject) ->> len) == 0 then
				syswrite(dout, '~s' sys_>< subject sys_>< '\n', len fi_+ 3);
			endunless;
			unless (length(cclist) ->> len) == 0 then
				syswrite(dout, '~c' sys_>< cclist sys_>< '\n', len fi_+ 3);
			endunless;
			unless (length(bcclist) ->> len) == 0 then
				syswrite(dout, '~b' sys_>< bcclist sys_>< '\n', len fi_+ 3);
			endunless;
*/
			sysclose(dout);
			/* wait for the child */
			sys_wait(child) -> (,);
			sysclose(nulldev);
		else
			/* child - the mailer */
			sysclose(dout);
			din -> popdevin;
			;;; prevent attempts to read from or write to terminal
			nulldev ->> poprawdevin -> popdevout;
			;;; Should never return from this:
			sysexecute(mailer, args, false);
		endif;
	enddefine;

	if vedindent_From then
		;;; Insert ">" at beginning of lines starting 'From '
		;;; May be suppressed in vedsend
		veddo('gsr/@aFrom />From /');
	endif;

	/* construct the argument to the mailer which gives recipient list */
	[^(sys_fname_nam(ved_send_mailer)) '-t'] -> mailer_arglist;

	/* is user willing to wait? */
	if ved_send_wait then
		vedputmessage('Sending mail: please wait...');
		/* open a pipe to send mail to mailer from the top level process */
		do_mail(ved_send_mailer, mailer_arglist);
		writelog(tolist, subject, cclist, bcclist);
	else
		/* busy user can't wait, so detach a process */
		vedputmessage('Sending mail in background...');
		/* these values are restored by dlocal */
		identfn -> popexit;
		[] -> vedbufferlist;
		false -> vedediting;
		if sys_vfork(true) ->> child then
			/* top level parent - a quick wait then we're off */
			sys_wait(child) -> (,)
		else
			/* vforked 1st child (to prevent zombie) */
			if sys_fork(false) then
				/* needed a real fork because processes will be running along
				 * side one another.  This is still the 1st child.
				*/
				fast_sysexit();
			endif;
			/* we're in the fully detached process */
			lblock
				compile_mode :vm -prmprt;
				;;; this is required to make things work ....
            	false -> vedinvedprocess;
			endlblock;
			do_mail(ved_send_mailer, mailer_arglist);
			writelog(tolist, subject, cclist, bcclist);
			/* exit from the detached parent process */
			fast_sysexit()
		endif
	endif
enddefine;

define lconstant fixline(string);
	;;; make string current line and re-display
	lvars string;
	string -> vedthisline();
	vedrefreshrange(vedline,vedline,undef);
enddefine;

/*
;;;

mail_names() =>
** Aaron Sloman axs@cs.bham.ac.uk Aaron Sloman <axs@cs.bham.ac.uk>

*/

define lconstant mail_names() -> (fullname, emailname, fromname);
	;;; Using popusername (the login name) try to get the user's full name,
	;;; the email address (login name plus site name) and a full name	
	;;; to use in From: line in form "Aaaa Bbbbb <xxx@yyy.zzz.ac.uk>"

	sysgetusername(popusername) -> fullname;

	if isstring(popsitename) then
		popusername sys_>< popsitename
	else
		popusername
	endif -> emailname;

	if fullname then
		fullname sys_>< ' <' sys_>< emailname sys_>< '>'
	else emailname
	endif -> fromname;
	
enddefine;


define lconstant check_next_lines(namestring) -> namestring;
	;;; Could be tolist, cclist or bcclist. See if following
	;;; lines start with either tab or four spaces, and
	;;; if so append to list, after translating using aliases

	lvars string ;

	repeat
		vednextline();
		vedthisline() -> string;
			/*transform tabs to spaces*/
		mapdata(string,
				procedure char; lvars char;
					if char == `\t` then `\s` else char endif
				endprocedure) -> string;
		;;; See if string starts with 4 spaces or tab
		if isstartstring('\s\s\s\s',string)
		or fast_subscrs(1,string) ==`\t`
		then
			/* expand aliases, if necessary */
			check_aliases(string) -> string;
			fixline('\s\s\s\s' sys_>< string);
			;;; insert comma at end of previousl line.
			vedcharup(); vedtextright(); vedcharinsert(`,`);
			vedchardown();
			namestring sys_>< ',' sys_>< string -> namestring;
		else
			vedcharup();
			quitloop
		endif
	endrepeat
enddefine;

define lconstant has_record(list);
	;;; Used to examine line from .mailrc file for 'record=<filename>'
	;;; if necessary unset $record
	lvars item;
	fast_for item in list do
	returnif(isstartstring('record=',item))(true)
	endfor;
	false
enddefine;

define lconstant vedsend(whole_file);
	;;; This procedure does the sending. It may send either the whole file, or only
	;;; the marked range.
	lvars
		message, line, i, prefix, rest, tolist, subject,
		emptyline = 0,
		cclist, bcclist,
		changed = vedchanged,
		sender_arg = vedargument /= nullstring,
        ;;; Information for email header
		(fullname, emailname, fromname) = mail_names(),
		inserted_from = false,	;;; make true if From: line to be deleted at end.
	;

	dlocal
		;;; temporary changes to environment
		vedbreak = false,
		vedargument, vedpositionstack,
		vedautowrite = false,
		vedautosave_min_write = 100000000, ;;; prevent autosaving
		pop_file_versions = 1,
		popenvlist,
		vedindent_From, vedinsert_From,

		;;; next variable preserves vedsearch context
		ved_search_state
	;



	if not(ved_send_record) and has_record(popenvlist) then
		;;; get rid of "record" setting, used by mailx. See MAN mailx
		maplist(popenvlist,
			procedure(string);
				unless isstartstring('record=',string) then string endunless
			endprocedure) -> popenvlist
	endif;

	/*	Decide whether to put 'From' line at top and change lines in
		message starting with 'From ' to start with '>From' */

	if whole_file or sender_arg then
		/* Probably not kept in mail_file format, so don't change file */
		false ->> vedinsert_From -> vedindent_From
	endif;

	/* Prevent display of intermediate changed marked ranges */
	vedmarkpush();
	false -> vvedmarkprops;
	dlocal 0 %, vedrefreshrange(vedmarkpop(), vvedmarklo, vvedmarkhi, undef) %;

	/* position the cursor and so on depending on whole or marked range */
	vedpositionpush();
	if whole_file then
		1 -> vvedmarklo;
		vvedbuffersize -> vvedmarkhi;
		vedtopfile();
		'Sending mail - whole file'
	else
		if vvedmarkhi < vvedmarklo then
			vederror('ILLEGAL MARKED RANGE: vvedmarkhi < vvedmarklo')
		endif;
		vedmarkfind();
		'Sending mail - marked range'
	endif -> message;

	/* Find the first non-empty line in marked range */
	unless ved_try_search('@?', [range]) do
		vederror('No message in marked range')
	endunless;
	vedputmessage(message);

	/* include the From line in the file, if required and appropriate */
	if vedinsert_From then
		/* add Berkeley-like From line unless one already there */
		'From ' sys_>< (fullname or popusername) -> line;
		/* look for an old From - delete if found */
		if isstartstring(line, vedthisline()) then
			/* From is on current line */
		elseif vedline /== 1 and
				isstartstring(line, vedbuffer(vedline-1)) then
			/* From is on previous line */
			vedcharup();
		else
			/* no existing From - make space for one */
			vedlineabove();
		endif;
		fixline(line);
		vedcheck();
		vedtextright(); vedcharright(); vedinsertstring(sysdaytime());
		/* don't send the From line as part of the message */
		vedline fi_+ 1 -> vvedmarklo;
		vednextline();
	endif;
	vedputmessage(message);

	/* collect argument names, either from command line or "To: " line */
	nullstring ->> tolist ->> subject ->> cclist -> bcclist;

	if sender_arg then
		space sys_>< check_aliases(vedargument) -> tolist;
		vedlineabove();
		vedmarklo();
		vedinsertstring('To: ');
		vedinsertstring(tolist);
		vednextline();
	endif;

	/* collect names etc from file and clean up file */
	lvars fromlinefound = false;
	repeat
		vedthisline() -> line;
		/* is this the last line of the mail header? */
		unless ((locchar(`:`, 1, line) ->> i) and i <= vvedlinesize) then
			false -> line;
			quitloop();
		endunless;
		/* no - get the mail header part prefix */
		substring(1, i fi_- 1, line) -> prefix;
		/* now get the rest of the line */
		/* bug fix from jamesg */
		if skipchar(`\s`, i fi_+ 1, line) ->> i then
			substring(i, vvedlinesize fi_+ 1 fi_- i, line)
		else
			/* colon must have been spurious */
			space
		endif -> rest;
		/* store the rest according to the prefix, and note if From: exists */
		if member(prefix, to_prefixes) then
			unless tolist = nullstring then
				if vedargument = nullstring then
					/* conflict from multiple To: lines */
					vederror('Can\'t send - more than one recipient line');
				else
					vederror('Use "send person" OR give "to:" line in file');
				endif;
			endunless;
			/* expand aliases, if necessary */
			check_aliases(rest) -> tolist;
			fixline('To: ' sys_>< tolist);
			check_next_lines(tolist) -> tolist;
		elseif member(prefix, re_prefixes) then
			unless subject = nullstring then
				 vederror('Can\'t send - too many subject lines');
			endunless;
			rest -> subject;
			fixline('Subject: ' sys_>< subject);
		elseif member(prefix, cc_prefixes) then
			unless cclist = nullstring then
				vederror('Can\'t send - too many cc lines');
			endunless;
			check_aliases(rest) -> cclist;
			fixline('Cc: ' sys_>< cclist);
			check_next_lines(cclist) -> cclist;
		elseif member(prefix, bcc_prefixes) then
			unless bcclist = nullstring then
				vederror('Can\'t send - too many bcc lines');
			endunless;
			check_aliases(rest) -> bcclist;
			fixline('Bcc: ' sys_>< bcclist);
			check_next_lines(bcclist) -> bcclist;
		elseif prefix = 'From' then
			true -> fromlinefound;
		else
			/* not a known header line */
			;;; quitloop;
		endif;
		vednextline();
	endrepeat;

	;;; Veddebug(line);
	;;;	Veddebug(tolist);
	if line and line /== nullstring then
		;;; sysprmishap -> prmishap;
		vederror('Too few spaces in header line, or no blank line after header');

	endif;

/*
;;; No longer needed in Birmingham
	unless fromlinefound then
		;;; insert From: line
		vedlineabove();
		fixline('From: ' sys_>< fromname);
		true -> inserted_from;
		vednextline();
	endunless;
*/

	if sender_arg then
		;;; Make sure there's an empty line, in case next line is
		;;; indented.
		vedlineabove();
		vedline -> emptyline;
	endif;

	/* mark the body of the message - that which is to be sent */
	;;;; not needed with sendmail
	;;;;	vedmarkpush();
	;;;;	vedline -> vvedmarklo;
/*
	;;; uncomment these two lines if you want to be prevented from
	;;; sending empty messages!
	if vvedmarklo > vvedmarkhi then
		vederror('Can\'t send - null message body');
	endif;
*/
	/* check that we have someone to send to */
	if tolist = nullstring and bcclist = nullstring then
		vederror('Can\'t send - send mail to whom?');
	endif;

	/* call the mail processing function */
	runmailer(tolist, subject, cclist, bcclist);

	;;; remove inserted To: line if obtained from vedargument
	dlocal vvedlinedump; 	;;; don't remember lines deleted here.
	if sender_arg then
		vedmarkfind();

		if isstartstring('To: ', vedthisline()) then
			vedlinedelete();
			emptyline - 1 -> emptyline;
		endif;

		if inserted_from and isstartstring('From: ', vedthisline()) then
			vedlinedelete();
			emptyline - 1 -> emptyline;
		endif;

		if vedline == emptyline then
			;;; now delete the blank line previously inserted
			vedlinedelete();
		endif;
	endif;

	;;; Return to top of message
	vedpositionpop();
	vedputmessage('Done');
	if vedinsert_From then
		if changed then changed + 1 else 1 endif
	else
		changed
	endif -> vedchanged;
enddefine;

define global vars procedure ved_send =
	vedsend(%true%)
enddefine;

define global vars procedure ved_sendmr =
	vedsend(%false%)
enddefine;

endsection;

nil -> proglist;	;;; suppress reading of comments

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec  8 2001
	Introduced vedinsert_commas to stop complex entries in .mailrc
		being split up.
--- Aaron Sloman, Apr  6 2000
	Changed to allow empty To: list, if Bcc: is used.
--- Aaron Sloman, Jul 11 1999
	Changed parse_string:
		Removed empty strings produced by sys_parse_string (Since Poplog V15.53)
	Added missing argument to call of mishap in full_email_name
--- Aaron Sloman, Jun  8 1999
	Checked for alias line containing only tab.
--- Aaron Sloman, Mar 14 1999
	Commented out bit which inserts From: line.
--- Aaron Sloman, Dec 19 1998
	Further fix when sending ENTER sendmr <name> and text is
	indented.
--- Aaron Sloman, Nov 21 1998
	Fixed bug due to mixture of tabs and spaces at beginning of line
--- Aaron Sloman, Nov 15 1998
	Prevented insertions when giving addressee from argument line.
--- Aaron Sloman, Oct 28 1998
	Removed unnecessarily alias translation while reading .mailrc
--- Aaron Sloman, Oct 17 1998
	fixed to remove leading spaces in address lines, and to make
	vedbreak false while editing header lines
--- Aaron Sloman, Oct  3 1998
	Change to use new format, comma-separated, address lists
	and to expand local user names to full addresses showing real names.
--- Aaron Sloman, Sep 30 1998
	Updated version of ved_send using sendmail rather than mailx.
	Fixed to insert proper From: line if there isn't one already.
--- Aaron Sloman, Aug 25 1998
	changed to ensure that full range is refreshed after vedmarkpop.
--- Aaron Sloman,  17 May 1996
	On recommendation from John Gibson made sure poprawdevin and poprawdevout
	are devices before calling do_mail, to prevent mishap on exit from do_mail
--- Aaron Sloman, April 1 1994
	Allowed To: line, Cc: line or Bcc: line to have multi-line continuations.
	Added check_next_lines to do this
--- John Gibson, Apr 21 1994
		Changed to use new sys_vfork etc.
--- John Williams, Jan  4 1994
		ved_sendmr now makes sure the marked range isn't empty.
--- Jonathan Meyer, Sep 29 1993
		Change vvedsr*ch vars to ved_search_state.
		vedtest*search -> ved_try_search.
--- Aaron Sloman, Aug 19 1993
	Suppressed sending of whole file when ved_sendmr used with empty
	message at end of file!
--- Aaron Sloman, May  8 1993
	Put in compile_mode fix and assignment to vedinvedprocess
	Also changed vfork to fork as advised by John Gibson
--- John Gibson, May  8 1993
		Fixes to runmailer
--- James Goodlet, Oct 22 1992
		Tried to make multiple addressee lines error more meaningful,
		especially when conflict is between addressee on command lines and
		one or more to: lines in file.
--- John Gibson, Mar 23 1992
		Changed to use vedfile_line_consumer to write out the marked range.
		Also added -ved_send_plain_text- for controlling 2nd arg to that.
--- Aaron Sloman, Apr  3 1990
		ved_sendmr was not updating -vedchanged-. Fixed so that it increments
		it by 1 if vedinsert_From is true. Otherwise the whole point of
		inserting the From line is lost if it is not recorded.
--- James Goodlet, Feb 16 1990 - Fixed last change so that one line messages
		are not sent as empty ones.
--- Aaron Sloman, Jan  4 1990
	Fixed so that it allows transmission of empty messages. (Should this
	be controlled by a variable?)
--- Aaron Sloman, Aug 13 1989
	Replaced issubstring_lim with isstartstring
--- Aaron Sloman, Aug 13 1989
	Tidied up. Fixed vedindent_From bug. Replaced pdr_valof with define =
	Changed -ucbmail- to -runmailer-. Made vedindent_From and vedinsert_From
	automatically false when sending whole file or sending with names in
	vedargument
--- Aaron Sloman, Aug  9 1989
	Now changes 'From ' at start of line to '>From ' unless vedindent_From
	is false.
--- Aaron Sloman, Apr  5 1989
	CHANGED BOBCAT to SYSTEM_V
--- Rob Duncan, Apr  4 1989
	Changed to use -sys*vfork- unconditionally, as this is always available
	(although it may be the same as -sys*fork-);
	added "uses sysdefs" to provide definition of BOBCAT flag;
	added -str- to lvars list in parse_string
--- Aaron Sloman, Mar 21 1989
	Introduced ved_send_mailer, and made mailer_arglist sensitive
	to it.
--- Aaron Sloman, Mar 21 1989
	Line ending with colon at end of headers caused problems. Bug fix
	by James Goodlet installed.
--- Aaron Sloman, Mar 17 1989
	dlocalised vedsearch state variables in vedsend.
--- Aaron Sloman, Mar 13 1989
	Fixed lines starting with "~"
--- Aaron Sloman, Mar 12 1989
	Simplified last bit using define :pdr_vlaof.
	Added ved_send_record
	Merged James' changes below with some previous changes avoiding
	consword.
--- James Goodlet, Mar 1989 - Major rewrite.  Changed to allow use of
		/usr/ucb/Mail, using idea of Jason Handby to use "~" prefixes.
		Added ved_send_aliases.  Various rationalisations and fewer forks.
--- Aaron Sloman, Jan  2 1989
	Changed -aliases- to use newanyproperty, removing need for consword.
	Made alias expander (checkentry) insert commas instead of spaces
--- Aaron Sloman, Feb  6 1988
	Fixed format for output to $MAILREC in <ENTER> sendmr <name>
	Made it suppress From line if sending whole file or argument given.
	Made it insert blank line if message does not start at beginning of
	line. (See -withblank-)
	Made -vedmailrc- user defineable and exported it. If undefined use
	$MAILRC, or $HOME/.mailrc
	Added -
vedinsert_From- to control insertion of "From" line.
	Removed redundant local "hasfromline" and did some general tidying.
--- John Gibson, Nov 11 1987
	Replaced -popdevraw- with -poprawdevin- and -poprawdevout-
--- Aaron Sloman, Aug 17 1987
	Fixed to remove redundant space produced by check_aliases
--- Aaron Sloman, Nov 18 1986
	added ved_send_wait. If false doesn't wait at all.
--- Aaron Sloman, Nov  4 1986
	Removed used of lib pipeout in mail send. Used in-line version
--- Aaron Sloman, Oct 29 1986
	Replaced simple ved_send, now available in LIB * OLDSEND
	Made sensitive to "set metoo" or "unset metoo" in .mailrc
	Sends mail via pipe, following Mark Rubinstein's version
--- A. Sloman 25 April 1986
	inserted procedure 'parse_string' to cope with commas as well as spaces
	separating names, etc. Replace spaces with commas in name list.
--- A. Sloman 20th Oct 1985
	Modified (including ideas from Mark Rubinstein's lib ved_send)
	- Uses sendmail direct, in place of mail, allowing 'Cc:' and 'Bcc' lines
		etc in mail to be effective.
	- Read .mailrc file to get aliases, using readmailrc
	- 'set record ...' doesn't work for sendmail, so user must keep
		explicit records (easy in VED)
	- Aliases are updated in the file itself, before sending.
	- Lines starting 'From ' in message have '>' inserted.
	- Inserts 'From <name> <date>' in file above message. To conform
		to Unix mail format, in case message saved in a mail file
--- A. Sloman 24 March 1985
	If $MAILREC is an environment variable then a record of date,
	recipients and subject is stored in the file of that name.
	Example records:
		Sun Mar 24 23:43:46 GMT 1985
		To: alanf
		Re: sending mail from ved
		Sun Mar 24 23:54:35 GMT 1985
		To: fred@uk.ac.ed.aiva joe@uk.ac.fgh.cs
		Re: arpa mail
		Cc: aarons
--- A. Sloman 13 March 1985
	 used vedtest*search to find non-empty line.
	 added ability to specify names with TO: or To:
	 Suppressed deleting and adding lines. Just shift vvedmarklo

 CONTENTS - (Use <ENTER> g define to access required sections)

 define lconstant parse_string(str) -> stringlist;
 define lconstant tabs_to_spaces(str) -> str;
 define lconstant count_ok(bool, line);
 define lconstant full_email_name(alias) -> alias;
 define lconstant expand_local_address(name, alias);
 define lconstant checkentry(name, alias);
 define lconstant tryreadmailrc;
 define lconstant onlywhitespace(string) -> boolean;
 define lconstant check_aliases(line) -> line;
 define lconstant writelog(tolist, subject, cclist, bcclist);
 define lconstant runmailer(tolist, subject, cclist, bcclist);
 define lconstant fixline(string);
 define lconstant mail_names() -> (fullname, emailname, fromname);
 define lconstant check_next_lines(namestring) -> namestring;
 define lconstant has_record(list);
 define lconstant vedsend(whole_file);
 define global vars procedure ved_send =
 define global vars procedure ved_sendmr =

*/
