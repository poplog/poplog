/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 >  File:           $poplocal/local/auto/ved_gn.p
 >  Purpose:        examining net news, and posting news (since 6 Jan 2001)
 >  Author:         Aaron Sloman, June 1994 (see revisions)
 >  Documentation:  local HELP * VED_NN HELP * VED_POSTNEWS
 >  Related Files:  /usr/spool/news/...  LIB * VED_POSTNEWS *VED_FOLLOWUP
 */

compile_mode:pop11 +varsch +defpdr -lprops +constr
				:vm +prmfix  :popc -wrdflt -wrclos;
section;

uses unix_sockets;
uses newmapping;

;;; The next variables may have to be altered on a site-wide or per user
global vars
	vednewsrc,				;;; user's file specifying news groups
	vednewssig				;;; user's file containing signature
		= '~/.signature',
	vedmaxsig = 5, 			;;; maximum number of lines allowed in signature
	newsgroupdone = '.',	;;; used to indicate that group is to be updated
	gn_hide_header,			;;; if true then scrolls past header of news file
	gn_divider = ' ][ ',	;;; between subject and author fields
	gn_info_starts = 7, 	;;; column in which information starts in index files
	gn_next,				;;; make it 'gns' or 'gna' if you want one of
							;;; those to be the next command by default
							;;; after an article has been read
	gn_read_active_interval = 15*60, ;;; 15 minutes
	;;;; NBNB you may have to change the default server
	gn_nntp_server, 		;;; Default news server, if $NNTPSERVER not set

	gn_unread_file			;;; file name for information about unread news
		= '~/.news_unread',

	gn_index_limit = 100,	;;; maximum number of news articles to list
							;;; if "ENTER gn -" command is used
	gn_timeout_secs , 	;;; 10 second timeout limit

	gn_idle_interval = 10 * 60, ;;; 10 minutes after which close connection.

	gn_last_active = 0,

	gn_short_author = true,	;;; show only author's name in index, not address

	gn_max_articles, ;;; show no more than that number of articles
;


;;;; NB NB NB change default server as needed
;;;; This works for Birmingham and Sussex. Overridden by $NNTPSERVER
if sys_file_stat('/bham',{}) then
	;;; at birmingham
	'news.cs.bham.ac.uk', ;;; default server
else
	'news.sussex.ac.uk'
endif -> gn_nntp_server;

unless isinteger(gn_timeout_secs) then
	10 -> gn_timeout_secs;
endunless;

unless isnumber(gn_max_articles) then
	1000 -> gn_max_articles;
endunless;

;;; these are defined below
global
	vars procedure
		(gn_consumer, gn_repeater, gn_kill_connection, gn_setup_nntp_env);

global vars
	;;; list of messages from server
	gn_messages = [],
	;;; checked when connection made
	gn_posting_allowed = undef;


;;; some global file_local lexicals used by ved_gn etc.
lvars
	gn_last_news_file=false,
	ved_gn_down_line = false,
	newsrc_file = false,
	newsrc_group_list = false,
	nntpsetupdone = false, 			;;; Made true when connection set up

	gn_last_group = false,			;;; Used if link restarted
	gn_last_sent_command = false,	;;; ditto
	gn_time_active_read = false,	;;; Time active list last examined
	gn_group_info = false,			;;; a property mapping groups to numbers
	gn_error_depth = 0,				;;; Prevent recursive errors
	gn_timeout_ok = false,				;;; set true inside ved_gn
	gn_timed_out = false,
	gn_outdev,			;;; current socket out device (to server)
	gn_indev,			;;; current socket in device (from server)
	;

lconstant
	;;; Approximate expected number of active groups, for property size
	active_size = 4001,
	;;; string used to set up next command on command line
	gn_string = 'gn',
	;;; initial number range for a new news group
	gn_newgroup_string = ' 0-0',

	;;; empty message back from server, or end of message
	gn_dotstring = '.',

;


unless isboolean(gn_hide_header) then
	true -> gn_hide_header
endunless;

unless isstring(gn_next) then
	gn_string -> gn_next
endunless;

;;; Start of first lines of index files. Can be used to recognize them
lconstant
	index_header = '       OUTPUT FROM: nntplist ',
	index_length = datalength(index_header),
	active_list_header =
		'UNREAD MESSAGES (NOTE THAT NUMBERS ARE APPROXIMATE ONLY). Press REDO to read',
;

;;; this is to test whehter Popversion > 14.5, when sys_fork becomes
;;; available.
lvars must_wait = (identprops("sys_fork") = "undef");

;;; Some facilities for manipulating news file

define lconstant get_newsrc_file();
	lvars file = vedpresent(newsrc_file);
	if file and vedediting then
		file -> ved_current_file
	else
		vededitor(vedveddefaults, newsrc_file);
	endif;
	if vedonstatus then vedstatusswitch() endif;
	vedscreengraphoff();
enddefine;


define lconstant get_last_col_start(string) -> loc;
	;;; get location of start of number at end of string, or false
	lvars string, loc = datalength(string);
	if isnumbercode(subscrs(loc, string)) then
		repeat
			quitif((loc fi_- 1 ->> loc) == 0);
			quitunless(isnumbercode(fast_subscrs(loc, string)))
		endrepeat;
	else
		false -> loc
	endif
enddefine;

define lconstant first_number() -> num;
	lvars num;
	;;; get number at beginning of line
	dlocal vedcolumn = 1;
	vedmoveitem() -> num;
	unless num == termin or isinteger(num) then
		vederror('Line does not start with article number')
	endunless;
enddefine;

define lconstant getlastnum(string) /* -> num */;
	;;; get number at end of string, or false
	lvars string, loc = get_last_col_start(string), /* num */;
	if loc then
			strnumber(allbutfirst(loc, string))
	else false
	endif /* -> num */;
enddefine;


define lconstant last_number() -> (num, col);
	;;; Assume line ends with a number.
	;;; return the number i.e. number of last file accessed in this group
	;;; and the column where it starts.
	lvars col, string, loc, num;
	vedtrimline();
	vedsetlinesize();
	vedthisline() -> string;
	get_last_col_start(string) -> col;
	if col then
      	strnumber(allbutfirst(col, string)) -> num;
		col + 1 -> col;
	else
		vederror('No number at end of current line').
	endif
enddefine;

define lconstant gn_update_newsrc(group_string, last_num);
	lvars group_string, last_num, string, num, file;
	
	dlocal ved_current_file, vedediting;
	get_newsrc_file();
	vedscreengraphoff();
	false -> vedbreak;
	vedpositionpush();
	vedtrimline();
	for vedline to vvedbuffersize do
		;;; search for required group
		subscrv(vedline,vedbuffer) -> string;
		if isstartstring(group_string,string) then
			;;; update last number accessed
			last_number() -> (num, vedcolumn);
			if last_num > num then
				false -> vedediting;
				vedcleartail();
				vedinsertstring(last_num sys_>< nullstring);
			endif;
			quitloop();
		endif
	endfor;

	if vedusewindows == "x" or vedcurrentfile == vedupperfile
		or vedcurrentfile == vedlowerfile
	then
		;;; refresh only the changed line
		true -> vedediting;
		vedrefreshrange(vedline - 1, vedline, undef);
	endif;
	vedpositionpop();
enddefine;

;;; FACILITIES FOR LINKING TO NNTP SERVER

define gn_reset_connection();
	;;; close current connection, and try to reconnent
	vedputmessage('Retrying connection. Please wait');
	gn_kill_connection();
	gn_setup_nntp_env();
	vedputmessage(nullstring);
enddefine;

define lconstant gn_set_group(group) -> answer;
	lvars group, answer;
	group -> gn_last_group;

	gn_consumer('group ' sys_>< group);
	gn_repeater() -> (answer, /*len*/);

;;;; veddebug('set group ' >< answer);

	if answer == termin then
		false -> answer
	elseif answer = gn_dotstring then
		false -> answer;
		vederror('Server sends back empty group index');
	elseif isstartstring('411', answer) then
		false -> answer;
		vederror('Select group failed: ' >< group)
	elseif isstartstring('480', answer) then
		false -> answer;
		vederror('Authentication required')
	elseif gn_timed_out then
		gn_reset_connection();
		chain(group, gn_set_group)
	elseunless isstartstring('211', answer) then
		false -> answer
	endif;
enddefine;

define lconstant gn_try_close(dev);
	;;; used with gn_indev or gn_outdev, to close (and flush if necessary)
	lvars dev;
	if isdevice(dev) and not(isclosed(dev, false)) then
		
		define dlocal prmishap();
			;;; ignore mishaps here
			erasenum(2);
			exitfrom(gn_try_close)
		enddefine;

		sysclose(dev);
	endif;
enddefine;

define global procedure gn_kill_connection();
	gn_try_close(gn_outdev);
;;;	gn_try_close(gn_indev);
	false ->> gn_outdev ->> gn_indev -> gn_time_active_read;
	false -> nntpsetupdone;
enddefine;

lvars gn_retries = 0;

define lconstant gn_retry_communicate(ExitFrom, ThenRead);
	;;; ExitFrom is one of gn_consumer, gn_repeater
	;;; ThenRead is a boolean
	;;; This is a hacky attempt to try reading or writing again, after
	;;; restoring the NNTP context if for any
	;;; reason the socket connection has died, etc.
	;;; May have extra argument on stack, gn_consumer or gn_repeater.
	lvars ExitFrom, ThenRead;

	;;; increment retry counter
	gn_retries + 1 -> gn_retries;
	gn_reset_connection();

	if isstring(gn_last_group) then gn_set_group(gn_last_group) ->; endif;
	if ThenRead and isstring(gn_last_sent_command) then
		;;; Try to restore environment before reading
		;;; risky !!??
		gn_consumer(gn_last_sent_command)
	endif;
	;;; try again in new environment
	chainfrom(ExitFrom,
		if ThenRead then gn_repeater else gn_consumer endif);
enddefine;


define lconstant gn_timeout();
	;;; This procedure is called to reset the link if necessary
	;;; Veddebug('timeout');
	if gn_timeout_ok then
		;;; still inside ved_gn
		true -> gn_timed_out;
		if iscaller(gn_repeater) and isstartstring('000', sysstring) then
			;;; Waiting for last string of response. Simulate it
			exitfrom(gn_dotstring, 1, gn_repeater);
		elseif iscaller(sys_clear_input) then
			;;; timed out trying to clear input
			gn_reset_connection();
			exitfrom(sys_clear_input);
		else
			vedputmessage('Timeout exceeded. Breaking connection. Try again');
			gn_reset_connection();
			interrupt();
		endif
	endif
enddefine;


define global procedure gn_repeater() -> (string, len);
	;;; String repeater that uses gn_indev as global variable
	;;; "gn_indev" is pipe output device from nntp process
	;;; string will be a string or termin
	;;; len the length of the string.
	lvars len, string, oldprmishap = prmishap;

	define dlocal prmishap(errstring, list);
		;;; catch errors due to socket link being closed;
		lvars errstring, list;

		dlocal gn_error_depth = 1 + gn_error_depth;
		if gn_error_depth > 3 then
			oldprmishap(errstring, list)
		endif;

		if gn_retries < 3 and issubstring('ERROR WRITING DEVICE', errstring)
		then
			vedputmessage('RETRYING');
			gn_retry_communicate(gn_repeater, true);
		else
			chain(errstring, list, oldprmishap);
		endif;
	enddefine;

	;;; clear start code in sysstring
	'000' -> substring(1, 3, sysstring);

	if iscaller(gn_retry_communicate) then
	;;;;veddebug('waiting to read, in retry');
	endif;
	
	;;; set timeout for reading
	false -> gn_timed_out;
	gn_timeout_secs * 1e6 -> sys_timer(gn_timeout);
	fast_sysread(gn_indev, 1, sysstring, sysstringlen) -> len;
	false  -> sys_timer(gn_timeout);

;;;;veddebug('read ' sys_>< len ' characters');

	if len == 0 then
		;;; nntp server killed link
		gn_kill_connection();
		termin
	else
		sys_real_time() -> gn_last_active;
		;;; Prepare a line of text, possibly to go in a VED buffer.
		;;; so expand the tabs
		lvars start = subscrs(1, sysstring) /== `\n`;
		if start then
			vedencodetabs(substring(1, max(1,len fi_- 2), sysstring))
		else
			vedencodetabs(substring(min(len,2), max(1,len fi_- 2), sysstring))
		endif
	endif -> string;
;;;veddebug('READ ' >< string);
enddefine;


define global procedure gn_consumer(string);
	;;; Send the string

	lvars pid, string,
		oldprmishap = prmishap;

	lconstant quitstring = 'quit';

	define dlocal prmishap(errstring, list);
		;;; catch errors due to socket link being closed;
		lvars errstring, list;

		dlocal gn_error_depth = 1 + gn_error_depth;
		if gn_error_depth > 3 then
			oldprmishap(errstring, list)
		endif;

		if gn_retries < 3 and issubstring('DEVICE', errstring) then
			gn_retry_communicate(string, gn_consumer, false);
		else
			chain(errstring,list,oldprmishap);
		endif;
	enddefine;

	if string == termin or string = quitstring then
		gn_kill_connection();
		return();
	endif;

	if (not(gn_outdev) or isclosed(gn_outdev)) and gn_retries < 3 then
		;;; reopen link (restores environment, then chains out).
		gn_retry_communicate(gn_consumer, false);
	endif;

	;;; Set timer, in case clear_input or write hangs
	gn_timeout_secs * 1e6 -> sys_timer(gn_timeout);
	sys_clear_input(gn_indev);
	syswrite(gn_outdev, string, datalength(string));

	;;; make sure string ends with newline
	unless datalength(string) > 0 and last(string) == `\n` then
		syswrite(gn_outdev,'\n', 1)
	endunless;
	sysflush(gn_outdev);

	false -> sys_timer(gn_timeout);
	sys_real_time() -> gn_last_active;
enddefine;


define gn_close_idle();
	;;; close the connection if unused for gn_idle_interval minutes
	lvars time = sys_real_time() - gn_last_active;
	if time > gn_idle_interval
	and isdevice(gn_outdev) and not(isclosed(gn_outdev)) then
		;;;vedputmessage('Closing connection to news');
		;;; vedscreenbell();
		gn_kill_connection()
	else
		;;; restart the timer
		gn_idle_interval * 1e6 -> sys_timer(gn_close_idle)
	endif
enddefine;


define lconstant nntp_readanswer(okcode) -> string;
	;;; read in stuff up to end of file or '.'
	;;; leave all strings except the last on the stack.
	;;; return last item (could be termin)
	;;; But first line read in must start with okcode
	lvars len, last, count = 0;

	gn_repeater() -> (string, len);
	;;; Veddebug([ANSWER ^string ^len]);
	unless isstring(string) and string /= gn_dotstring then
		vederror('News Connection closed')
	endunless;

	if isstartstring(okcode, string) then
	elseif isstartstring('440', string) then
		;;; XXX fix this. Should be somewhere else?
		vederror('HOST WILL NOT ALLOW YOU TO POST');
	else vederror(string)
	endif;

	repeat
		count fi_+ 1 -> count;
		;;; abort if user types anything (check every 5 reads)
		if count mod 5 == 0 and vedscr_input_waiting() then
			vedscr_clear_input();
			quitloop()	;;; risky
		endif;
		gn_repeater() -> (string, len);
		if string = '\r' or string = '\n' then nullstring -> string endif;
		quitif(string == termin or string = gn_dotstring);
		;;; split string at CR characters.
		lblock 	lvars n;
			if isstartstring('..', string) then
				allbutfirst(1, string) -> string;
			endif;
			while locchar(`\n`, 1, string) ->> n do
				substring(1, n-1, string); 	;;; left on stack
				allbutfirst(n, string) -> string;
				if isstartstring('..', string) then
					allbutfirst(1, string) -> string;
				endif;
			endwhile;
		endlblock;
		string

	endrepeat
enddefine;


define vars procedure gn_nntp_request(string, okcode) -> vector;
	;;; return last string read (or termin) and the vector
	lvars string, answer, vector, okcode;
	gn_consumer(string);
	{% nntp_readanswer(okcode) -> answer %} -> vector;
	if datalength(vector) == 0 then
		false -> vector
	else
;;;;veddebug('returning from nntp_request with ' <> vector(1))
	endif;
enddefine;


lvars last_missing = 0;
define lconstant gn_article_info(num) -> (subject, author);
	lvars num, string, len,
		subject = 'NOSUBJECT',
		author = 'NOAUTHOR';

	dlvars oldinterrupt = interrupt;

	define dlocal interrupt();
		dlocal interrupt = oldinterrupt;
		;;; get rid of spurious arguments
		until stacklength() ==0
		or isstring(dup())
		do erase();
		enduntil;
		gn_kill_connection();
		termin, termin;
		exitfrom(gn_article_info)
	enddefine;

	gn_consumer('head ' sys_>< num );
	gn_repeater() -> (string, len);

	if string == termin then
		string ->> subject -> author;
		return();
	endif;

	unless isstring(string) and isstartstring('221 ', string) then
		false -> subject; false -> author;
		dlocal vedediting = true;
		unless num == last_missing + 1 then
			if last_missing = 0 then
				vedputmessage('Searching for earliest article number(any key to interrupt)')
			else
				vedputmessage('Missing article: ' sys_>< num);
			endif
		endunless;
		num -> last_missing;
		return();
	endunless;

	repeat;
		;;; Read in header and save Subject and Author lines
		gn_repeater() -> (string, len);
		quitif(string == termin or string = gn_dotstring);
;;;veddebug(string);
		if isstartstring('Subject: ', string) then
			;;; Get subject information
			allbutfirst(9, string) -> subject;
		elseif isstartstring('From: ', string) then
			;;; get author information
			lblock
			lvars col0 = datalength('From: ') fi_+ 1, col1, col2, d1, d2;
			;;; first see if name is present in parentheses
			if (locchar(`(`, col0, string) ->> col1)
			and ( col1 fi_+ 1 -> col1; locchar(`)`, col1, string) ->> col2)
			and (col2 /== col1 )	;;; empty name
			then
				;;; get suff between parentheses
				substring(col1, col2 fi_- col1, string)

			elseif (locchar(`<`, col0, string) ->> col1)
			and ( col1 fi_+ 1 -> col1; locchar(`>`, col1, string) ->> col2)
			and (col2 /== col1 )	;;; empty name
			then
				;;; email name is between angle brackets. Decide which
				;;; side the real name, outside the brackets, is, or
				;;; whether to use the name in the brackets
				col1 fi_- col0 -> d1;
				datalength(string) fi_- col2 -> d2;
				if d2 == 0 and d1 <= 2 then
					;;; the ONLY name info is between angle brackets
					locchar(`@`, col1, string) or col2 -> col2;
					substring(col1, col2 fi_- col1, string)
				elseif d1 fi_> d2 then
					;;; real name is before the angle brackets
				 	substring(col0, d1 fi_- 1, string)
				else
					;;; it is after the angle brackets
				 	substring(col2 fi_+ 1 , d2, string)
				endif;
			else
				if gn_short_author and (locchar(`@`, col0, string) ->> col2) then
					if fast_subscrs(col0, string) == `<` then
						;;; format is '<name@site>'. Skip '<'
						col0 fi_+ 1 -> col0
					endif;
					substring(col0, col2 fi_- col0, string)
				else
					allbutfirst(col0 fi_- 1, string)
				endif
			endif -> author;
			endlblock
		endif;
	endrepeat;
enddefine;


define lconstant gn_group_subject_strings(group, start, maxarticles)
		-> vector;
	;;; Create a vector of strings to go in group subject index file.
	lvars group, start, subject, author,
		vector = false, string, len total, first, fin, name;

	;;; doing this seems to prevent things slowing down.
	gn_reset_connection();
	gn_set_group(group) -> string;

	if isstring(string) and isstartstring('211', string) then
		explode(sysparse_string(string)) -> (, total, first, fin, name);
		dlvars count = 0;


		;;; Create a vector of strings for the subject/author index
		{%
		procedure() with_props nntplist;
			lvars i, numstring;

			dlvars oldediting = vedediting, oldinterrupt = interrupt;
			dlocal vedediting = false;		;;; Suppress screen activity.
			dlocal last_missing = 0;

			define dlocal interrupt();
				dlocal interrupt = oldinterrupt;
				;;; If interrupted, exit this subprocedure and
				;;; clean up
				;;; gn_reset_connection(); ***
				exitto(gn_group_subject_strings);
			enddefine;

		;;; Get information for each current article in the group in strings:
		;;; <number> <spaces> <subject> ][ <author>
		;;; leave all the strings on the stack

		;;; find start number
		lvars newstart = max(max(start, first), fin-maxarticles+1);

		;;; update total number unread
		fin - newstart + 1 -> total;

		vedputmessage(total sys_><' articles to be read in group ' sys_>< group);

		fast_for i from newstart by 1 to fin do
			if i mod 100 == 0 then
				;;; restart after 100 connections, otherwise slooooows down
				gn_reset_connection();
				gn_set_group(group) -> string;
				;;; Veddebug(string);
			endif;
			gn_article_info(i) -> (subject, author);
			quitif(subject == termin);
			if subject or author then
				i sys_>< nullstring -> numstring;
				consstring(#|
					explode(numstring),
					fast_repeat gn_info_starts fi_- datalength(numstring) fi_+ 1 times
						`\s`
					endfast_repeat;
					if author then explode(author) endif;
					explode(gn_divider),
					if subject then explode(subject) endif,
				  |#);
					count fi_+ 1 -> count;
					if count fi_mod 10 == 0 then
						procedure();
							dlocal vedediting = oldediting; ;;; restore screen activity
							vedputmessage(count sys_>< ' out of ' sys_>< total);
						endprocedure();
				endif;
			endif;
			if i fi_mod 5 == 0 and vedscr_input_waiting() then
				;;; Use has pressed a key, so abort gracefully
				gn_update_newsrc(group, last_missing);
				vedscr_clear_input();
				exitto(gn_group_subject_strings);
			endif;
		endfor
		endprocedure(),
		;;; pad out buffer as needed.
		if count fi_> 0 then
			fast_repeat vedscreenlength times nullstring endrepeat
		endif
		%} -> vector;
		if count == 0 then false -> vector endif;
	else
		false -> vector;
		vederror('Could not select group: '>< group >< string)
	endif;
enddefine;



define lconstant nntp_initialise() -> status;
	lvars string, len, codenum, status = true;

	lconstant codebuff = '000';

	repeat 100 times;
		false -> codenum;
		gn_repeater() -> (string, len);

		;;; get error code if present
		if datalength(string) fi_>= 3 then
				move_bytes(1, string, 1, codebuff, 3);
			strnumber(codebuff) -> codenum;
		endif;

		if member(codenum, [400 502 503]) then
			false -> status;
			gn_consumer(termin);
			return();
		elseif codenum == 200 or codenum == 201 then
			return();
		endif;
	endrepeat;
	vederror('Spurious output from server: ' <> string);
enddefine;

define lconstant gn_initialise(server);
	lvars server;

	lconstant
		;;; nnpt_port_num = 119,

		;;; nntp_host_spec = writeable [0 'nntp']
		;;; The above does not seem to work on linux becaus this
		;;;     exacc U_getservbyname(port, proto) -> servent;
		;;; in the socket library does not work.

		;;; so use the following, which seems to work on all systems
		nntp_host_spec = writeable [0 {119 'tcp'}]
	;

	vedputmessage('(Re-)starting connection to news server');

	;;; close previously opened devices, if necessary.
	gn_kill_connection();

	server -> nntp_host_spec(1);

	lvars sock = sys_socket_to_service(nntp_host_spec, "line");

	;;; assign devices to file local lexical variables
	sock ->> (gn_outdev, gn_indev);

	;;; ensure connection closed if unused
	gn_idle_interval * 1e6 -> sys_timer(gn_close_idle);
	sys_real_time() -> gn_last_active;

    lvars status = nntp_initialise();
	unless status then vederror('NNTP server not available') endunless;

	vedputmessage('Connection complete');

enddefine;

;;; VED NEWSREADING FACILITIES.

define lconstant gn_create_buffer(suffix, break, indent, vector, mess1, mess2);
	lvars suffix, break, indent, vector,mess1, mess2;
	if mess1 then vedputmessage(mess1) endif;
	vededitor(vedhelpdefaults, systmpfile(false, gn_string, suffix));
	dlocal vedediting = false;
	break -> vedbreak;
	indent -> vedindentstep;
	vector -> vedbuffer;
	vedusedsize(vedbuffer) -> vvedbuffersize;
	vedbufferextend();	;;; may not be necessary
	vedtopfile();
	
	if mess2 then
		vedtopfile();
		vedlineabove();
		vedinsertstring(mess2);
		vednextline();
	endif;
enddefine;

define lconstant procedure gn_in_indexfile() -> group;
	;;; Procedure to recognize index file for a news group.
	;;; Returns the group or false
	lvars group = false, string;
	if vedediting and vvedbuffersize >= 2 then
		vedbuffer(1) -> string;
		if isstartstring(index_header, string) then
			allbutfirst(index_length, string) -> group
		endif;
	endif;
enddefine;

define lconstant procedure gn_in_active_list_file() /* -> boole */;
	;;; Recognize file showing unread articles
	vvedbuffersize > 0 and vedbuffer(1) = active_list_header
		/* -> boole */
enddefine;



define gn_setup_nntp_env();
	;;; Set up path names etc. for nntptools

	unless nntpsetupdone then
		unless newsrc_file then
			;;; set up file name with list of newsgroups if necessary
			unless isstring(vednewsrc) then
				'$HOME/.newsrc' -> vednewsrc
			endunless;
			sysfileok(vednewsrc) -> newsrc_file
		endunless;

		lvars server;
		unless systranslate('NNTPSERVER') ->> server then
			gn_nntp_server -> server;
		endunless;

		gn_initialise(server);
		true -> nntpsetupdone;
	endunless;
enddefine;

define lconstant gn_getauthor(string, full) -> author;
	;;; Get name of author from string, in news group index file
	;;; author precedes '][' (gn_divider)
	;;; If name is between parentheses return it.

	lvars string, col1 = gn_info_starts fi_+ 1, col2, author, full;

	issubstring(gn_divider, col1, string) -> col2;
	if col2 then
		substring(col1, col2 fi_- col1, string) -> author;
	else
		vederror('NO AUTHOR')
	endif;
	if (strmember(`(`, author) ->> col1)
		and (locchar(`)`, col1, author) ->> col2)
	then
		;;; authorname between parentheses
		substring(col1, col2 fi_- col1 fi_+ 1, author) -> author;
	endif
enddefine;

define lconstant gn_getsubject(string) -> subject;
	;;; Get subject from string, in news group index file
	;;; subject after gn_divider

	lvars string, col1, col2 = datalength(string), newcol, subject;

	issubstring(gn_divider, gn_info_starts fi_+ 1, string) -> col1;
	if col1 then
		datalength(gn_divider) fi_+ col1  -> col1;
		while issubstring('Re:', col1, string) ->> newcol  do
			newcol fi_+ 3 -> col1;
		endwhile;
		substring(col1, col2 fi_- col1 fi_+ 1, string) -> subject;
	else
		vederror('NO SUBJECT')
	endif;

enddefine;

define lconstant procedure end_of_first_space(line) -> n with_props 0;
	lvars line, n = 1, c, lim;
	subscrv(line, vedbuffer) -> line;	;;; now a string
	datalength(line) -> lim;
	repeat
		if n fi_> lim then vederror('NO SPACE OR TAB IN LINE') endif;
		fast_subscrs(n, line) -> c;
		quitif(c == `\t` or c == `\s`);
		n fi_+ 1 -> n;
	endrepeat;
enddefine;


define lconstant procedure markseenfile ();
	;;; To indicate file has been read mark current line of
	;;; index file
	lvars loc;
	dlocal vedstatic = true;
	end_of_first_space(vedline) -> vedcolumn;
	if vedcolumn < gn_info_starts then
		gn_info_starts  -> vedcolumn
	endif;
	locchar(`*`, 1, vedthisline()) -> loc;
	unless loc and loc <= vedcolumn then
		vedcharinsert(`*`)
	endunless;
enddefine;



define lconstant getgroup(string) -> group;
	lvars string, col, group;
	if (locchar(`:`,1,string) ->> col)
	or (locchar(`!`,1,string) ->>col)
	or (locchar(`\s`,1,string) ->>col)
	then
		substring(1, col - 1, string)
	else
		string
	endif -> group;
enddefine;

define lconstant gn_setup();
	;;; prepare next command for REDO button
	unless vedcommand = gn_string then
		vedputcommand(gn_string);
		unless vedonstatus then
			vedswitchstatus();
				datalength(gn_string) + 1 -> vedcolumn;
			vedswitchstatus()
		endunless;
	endunless
enddefine;



define lconstant get_latest_num(group) -> num;
	lvars group,num;
	dlocal ved_current_file;
	dlocal ved_search_state;
	get_newsrc_file();
	vedpositionpush();
	vedlocate('@a'<> group <> ':');
	getlastnum(vedthisline()) -> num;
	vedpositionpop();
enddefine;

define lconstant get_active_list();
	lvars vector;
	lconstant waitstring = 'GETTING ACTIVE LIST, PLEASE WAIT';

    vedputmessage(waitstring);
	gn_nntp_request('list', '215') -> vector;
	if vector then
		;;; get temporary file
		gn_create_buffer(
			'.active', false, vedindentstep,
			vector, waitstring,
			'Newsgroups in form "group high low flags".');
		vedtopfile();
		vedrefresh();
	else
		vederror('Could not get active list');
	endif;
enddefine;

define lconstant gn_index_list(group, maxarticles);
	;;; Make in index file for the group
	lvars
		group, num = get_latest_num(group) + 1, vector,
		;

	lconstant waitstring = 'GETTING ARTICLE LIST, PLEASE WAIT (press "." to interrupt)';

    vedputmessage(waitstring);
	gn_group_subject_strings(group, num, maxarticles) -> vector;

	unless vector then
		vedputmessage('NO NEW ARTICLES FOR ' sys_>< group);
		return()
	endunless;

unless isvector(vector) then
	mishap('VECTOR NEEDED', [^vector])
endunless;

	;;; get temporary file
	gn_create_buffer(
		'.ind', false, vedindentstep,
		vector, waitstring,
		index_header <> group);

	false ->vednotabs;
	vedjumpto(2,1);
	;;; move past number
	vedwordright();
	gn_info_starts - 1 ->> vedcolumnoffset -> vedleftmargin;
	0 -> vedlineoffset;

	;;; Finished reading in articles. Now reorganise file
	lvars message =
		'Found ' sys_>< (vvedbuffersize - 1) sys_>< ' articles.';
		vedputmessage(message sys_>< ' Reformatting now');
		vedscr_flush_output();

	vedtrimline();

	;;; redisplay screen
	if vvedbuffersize > 6 then
		;;; show how many messages there are.
		vedputmessage(message);
	endif;
	vedrefresh();
enddefine;


vars	show_output_on_status;	;;; used below

define lconstant gn_make_group_index(maxarticles);
	;;; Read news subjects corresponding to news group on
	;;; current line in .newsrc file.
	;;; maxarticles is maximum number of entries to read
	;;; Make sure .newsrc file is up to date
	lvars group, c, line;

	repeat
		;;; find valid news group line
		repeat
			vedthisline() -> line;
		quitunless(strmember(`!`,line) or isstartstring('#', line));
			vedchardown();
		endrepeat;
		if vedatend() then
			vedputmessage('NO MORE ENTRIES'); return()
		else
			if vvedlinesize == 0 or subscrs(1,line) == `#` then
				vedchardown();
				nextloop()
			endif;
			strmember(`:`, line) -> c;
			if c == vvedlinesize then
				;;; No number. Insert 0-0 at end
				vedtextright();
				vedinsertstring(gn_newgroup_string);
			endif;
			dlocal show_output_on_status = false;
			vedchardown();
			;;; get group
			getgroup(line) -> group;
			gn_index_list(group, maxarticles);
			return();
		endif
	endrepeat
enddefine;



define lconstant gn_arrange_header();
	;;; find end of header, picking up date, author,
	;;; organisation and subject lines, to be made visible

	lconstant linevector = {0 0 0 0};
	fill(nullstring, nullstring, nullstring, nullstring,
		linevector) ->;
	until vvedlinesize == 0 or vedline > vvedbuffersize do
		lvars string = vedthisline();
		if isstartstring('Date: ', string) then
			vedlinedelete();
			vvedlinedump -> linevector(1);
		elseif isstartstring('Organization: ', string) then
			vedlinedelete();
			vvedlinedump -> linevector(2);
		elseif isstartstring('Subject: ', string) then
			vedlinedelete();
			vvedlinedump -> linevector(3);
		elseif isstartstring('From: ', string) then
			vedlinedelete();
			vvedlinedump -> linevector(4);
		else
			vedchardown();
		endif;
	enduntil;
	vedline - 1 -> vedlineoffset;
	1 -> vedcolumn;
	appdata(linevector, vedinsertstring<>vedlinebelow);
enddefine;


define lconstant gn_goto_newsrc();
	;;; Go back to newsrc file
	gn_setup();
	get_newsrc_file();
	vedselect(newsrc_file, true);
	vedputmessage('To get group for current line <ENTER> gn')
enddefine;


lconstant procedure (gn_nextsame);	;;; defined below.

define lconstant gn_get_article(group, article) -> answer;
	;;; get the article from that group
	lvars group, article, string, vector,
		answer = true;

	gn_set_group(group) -> string;

	if isstring(string) and isstartstring('211', string) then
		procedure;
			;;; Use indentstep 8 when reading articles, in case they
			;;; contain tabs
			dlocal vedindentstep = 8;

	  		gn_nntp_request('ARTICLE ' sys_>< article, '220') -> vector;
		endprocedure();

		if vector then
			lvars oldediting = vedediting;
			dlocal vedediting = false;
			gn_create_buffer( '.art', false, 8, vector,
				'Getting news file, please wait',
				'article: ' sys_>< article sys_><' in ' sys_>< group);
			if vvedbuffersize = 1 then
				nullstring -> vedmessage;
			else
				vedchardown();
				if gn_hide_header and vvedbuffersize > vedwindowlength then
					gn_arrange_header();
				endif;
			endif;
			oldediting -> vedediting;
			vedrefresh();
			vedpathname -> gn_last_news_file;
		endif
	else
		vedputmessage('Get article failed: Could not set group: ' <> group);
		false -> answer;
	endif;
enddefine;

define lconstant get_article_from_index(group, group_string, article_num);

	lvars last_num, subject, author, group, group_string, article_num,
		indexfile = ved_current_file,
		indexline = vedthisline() ;

	gn_getsubject(indexline) -> subject;
	gn_getauthor(indexline, false) sys_>< ":" -> author;
	false -> ved_gn_down_line;
	;;; go to next line
	unless iscaller(gn_nextsame) then
		vedchardown();
		true -> ved_gn_down_line;
	endunless;
	;;; update .newsrc file
	if vedargument = newsgroupdone then
		;;; don't do any more processing
		ved_q();
		;;; set up argument string
		if vedpresent(newsrc_file) then
			gn_update_newsrc(group_string, article_num);
		endif;
		gn_setup();
	else
		article_num sys_>< nullstring -> last_num;
		vedputmessage('Getting news file, please wait');
		lvars answer;
		gn_get_article(group, article_num) -> answer;
		if answer then
			lvars articlefile = ved_current_file;
			if vedpresent(newsrc_file) then
			  procedure();
				dlocal ved_current_file;
				;;; Ensure updating is done behind the scenes
				dlocal vedediting, vedwarpcontext;
				if vedusewindows == "x" then
					false -> vedwarpcontext
				else
					;;; false -> vedediting
				endif;
				gn_update_newsrc(group_string, article_num);
				;;; vedselect(articlefile, false);
				vedselect(indexfile, false);
				;;; indexfile -> ved_current_file;
			 endprocedure();
				vedselect(articlefile, true);
				;;; articlefile -> ved_current_file;
			endif;
			vedputmessage(author sys_>< subject);
			if gn_next /= gn_string and vedcommand /= gn_next then
					vedputcommand(gn_next)
			endif
		endif;
	endif
enddefine;

define lconstant gn_do_index_file(group);
	;;; invoked by ved_gn when in an index file.

	lvars group, group_string, article_num;

	;;; Get file number at beginning of line or, from vedargument
	group sys_>< ":" -> group_string;

	if strnumber(vedargument) then
		;;; User has given a message number.
		;;; Search for line with the number

		;;; localise search state variables
		dlocal
			vvedanywhere, vvedoldsrchdisplay, vvedsrchstring, vvedsrchsize;

		unless vedtestsearch('@a' sys_>< vedargument,false) then
			vederror('NO NEWS ITEM: ' sys_>< vedargument)
		endunless

	elseif vedargument = newsgroupdone then
		vedendfile(); vedcharup();
	endif;
	;;; get number at beginning of line
	first_number() -> article_num;
	if article_num == termin then ;;; at end of file
		ved_q();
		chain(gn_goto_newsrc)
	else
		markseenfile();
		get_article_from_index(group, group_string, article_num);
	endif;
enddefine;



define lconstant gn_setup_group_info(new);
	;;; set up the property gn_group_info, storing information about
	;;; groups mentioned in the active file
	lvars new,
		time = sys_real_time();
returnif(
		not(new)
		and isnumber(gn_time_active_read)
		and time - gn_time_active_read < gn_read_active_interval);

	;;; initialise the table
	newmapping([], active_size, false,true) -> gn_group_info;
	;;; now get information about active list.
	vedputmessage('Please wait. Processing "active" file');
	lblock;

	lvars high, low, string, group, pid,  vector,
		;
	;;; Get the "active" list.
	gn_nntp_request('list', '215') -> vector;

	if vector then
		lvars index;
		;;; store information about high and low values for each group
		;;; in gn_group_info
		for index from 1 to datalength(vector) do
			subscrv(index, vector) -> string;
		quitif (string == termin);
    		getgroup(string) -> group;
			sysparse_string(string, true) -> string;
			;;; find number of latest item in group
			string(2), string(3) -> (high,low);
			conspair(high, low) -> gn_group_info(group)
		endfor;
		time -> gn_time_active_read ;
	else
		vederror('Could not get active list')
	endif;
	endlblock;
enddefine;


define lconstant gn_show_unread_numbers(new);
	;;; If argument is true, then get active list again, otherwise
	;;; let gn_setup_group_info decide
	;;; create file showing number of unread articles in each group
	lvars, high, low, num, nums, group, new, oldediting = vedediting;

	gn_setup_group_info(new);

	vededitor(vedhelpdefaults, gn_unread_file);
	vedscreengraphoff();

	if vedonstatus then vedstatusswitch() endif;

	vedputmessage('PLEASE WAIT, COMPUTING NEW ITEMS');
	dlocal vedediting = false, vedbreak = false;
	if vvedbuffersize > 1 then ved_clear(); endif;
	vedinsertstring(active_list_header);
	for group in newsrc_group_list do
		gn_group_info(front(group)) -> nums;
		vedlinebelow();
		;;;		vedinsertstring(front(group)); vedcharright();
		(front(group)
			sys_>< vedspacestring
			sys_><
			if nums then
				if ispair(nums) then
					destpair(nums) -> (high, low);
					high - max(low, back(group)) -> num;
					;;; if negative then group is empty
					max(0,num) -> num;
					;;; vedinsertstring( nullstring sys_>< num )
					num
				else
					' @@@ IS NOT A VALID NEWS GROUP @@@'
				endif
			endif) -> vedthisline();
	endfor;
	vedtopfile();
	oldediting -> vedediting;
	vedrefresh();
	vedputmessage('');
	vednextline();
enddefine;

define lconstant gn_set_new_num(limit, group);
	;;; Assume current line is a news group entry in .newsrc. Change
	;;; the limit to be limit, if it is lower than limit.
	lvars oldnum, nums, high, low, group, limit, char, col;
	gn_setup_group_info(false);
	gn_group_info(group) -> nums;
	unless ispair(nums) then vederror('Not a valid news group: ' <> group)
	endunless;

	destpair(nums) -> (high, low);
	if low > high then high -> low endif;	;;; group empty ?

	max(low, max(0, high - limit)) -> limit;

	last_number() -> (oldnum, col);
	if limit > oldnum then
		;;; change the number
		col -> vedcolumn;
		vedcleartail();
		vedinsertstring(limit sys_>< nullstring);
		ved_w1();
		vedputmessage('Please wait');
	endif;
enddefine;


define lconstant gn_show_group_info(group, lastnum);
	;;; triggered by ENTER gn ?
	;;; show how many unread articles in the group
	lvars group, lastnum, nums, low, high;
	gn_setup_group_info(false);
	gn_group_info(group) -> nums;
;;;veddebug(group >< space>< nums);
	if nums then
		if ispair(nums) then
			destpair(nums) -> (high, low);
			high - max(low, lastnum) + 1 -> lastnum;
			max(0, lastnum) -> lastnum;
			vedputmessage(
				if lastnum == 0 then 'No new messages in '
				else
					'Up to ' sys_>< lastnum sys_>< ' new messages in '
				endif
				sys_>< group)
		else
			vederror(group <> ' is not a valid news group');
		endif
	else
		vederror('No information on this group')
	endif;
enddefine;


;;; procedures for posting news

define gn_post_request(string, okcode) -> string;
	lvars len;
	gn_consumer(string);
	gn_repeater() -> (string, len);
	;;; Veddebug([ANSWER ^string ^len]);
	[^string ^^gn_messages] -> gn_messages;
	unless isstring(string) and string /= gn_dotstring then
		vederror('News Connection closed')
	endunless;

	unless isstartstring(okcode, string) then
		if isstartstring('440', string) then
			vederror('HOST WILL NOT ALLOW YOU TO POST');
		endif;
		vederror(string)
	endunless;

enddefine;


/*
   The text forming the header and body of the message to be posted
   should be sent by the client using the conventions for text received
   from the news server:  A single period (".") on a line indicates the
   end of the text, with lines starting with a period in the original
   text having that period doubled during transmission.
   240 article posted ok
   340 send article to be posted. End with <CR-LF>.<CR-LF>
   440 posting not allowed
   441 posting failed
*/

define gn_sendnews();
	;;; clear messages
	[] -> gn_messages;

	lvars num = 1, limit, line;
	gn_setup_nntp_env();

	max(num,vvedbuffersize) -> limit;
	until vedusedsize(vedbuffer(num)) /== 0 do
		num fi_+ 1 -> num;
		if num fi_> limit then vederror('NO MESSAGE') endif
	enduntil;

	lvars string;
	lconstant waitstring = 'POSTING ARTICLE, PLEASE WAIT';

    vedputmessage(waitstring);

	gn_post_request('post', '340') -> string;

	;;; Veddebug(string);

	if isstring(string) then
		if sys_file_exists(vednewssig) then
			vedpositionpush();
			vedputmessage('Reading in signature file');
			lvars
				sigcount = 0,
				sigstring,
				procedure(sigrep = line_repeater(vednewssig, sysstring));
			vedendfile();
			vedinsertstring('====\n');
			dlocal vedbreak = false;
			repeat
				sigrep() -> sigstring;
				quitif(sigstring == termin);
				if sigcount > vedmaxsig then
					vedputmessage('ONLY ' >< vedmaxsig >< ' lines allowed in signature');
					syssleep(60*3);		;;; 3 seconds
					quitloop();
				endif;
				vedinsertstring(sigstring);
				vedlinebelow();
				sigcount + 1 -> sigcount;
			endrepeat;
			vedpositionpop();
		endif;
		vedputmessage('Transmitting text');
		vvedbuffersize -> limit;
		1 -> num;
		repeat
			veddecodetabs(subscrv(num,vedbuffer)) -> line;
			if datalength(line) > 0 and subscrs(1, line) == `.` then
				;;; line starting with "." must be given two of them.
				'.' <> line -> line;
			endif;
			gn_consumer(line);
			;;; Veddebug('sending ' >< line);
		quitif(num == limit);
			num fi_+ 1 -> num
		endrepeat;
    	vedputmessage('ALL POSTED - PLEASE WAIT');
		gn_post_request('\r\n.\r\n', '240') -> string;
		;;; Veddebug([Reply  ^string]);
		vedputmessage('Done');
		unless string then
			vederror('POSTING NOT SUCCESSFUL: CHECK NEWS GROUP AND TRY AGAIN');
		endunless;
	else
		vederror('COULD NOT GET PERMISSION TO POST');
	endif;

	;;; Now show messages received
	vededit('gn_send_messages_received', vedhelpdefaults);
	vedendfile();
	vedinsertstring('\nMESSAGES FROM NEWS SERVER\n');
		
	lvars string;
	for string in rev(gn_messages) do
		vedlinebelow();
		vedinsertstring(string);
	endfor;
	[] -> gn_messages;
enddefine;


define global procedure ved_gn;
	;;; Get News item, from index
	;;; If used in a news file, go back to index file.
	;;; If used with an argument (unless a number), chain to VED_NET
	;;; If used in newsrc file call gn_make_group_index for current line
	;;; If not in a group index file, then get .newsrc
	;;; If used in a news group index file without an argument go to the news
	;;;		item on current line. If used with an argument which is a
	;;; 	number, go to the news item with that number.
	;;; 	assume first line of file group name
	;;; 	assume first item on current line is the file number

	lvars
		limit = false,
		oldinterrupt = interrupt,
		oldline = vedline,
		oldcol = vedcolumn,
		oldfile = ved_current_file;

	dlocal ved_search_state;

	if vedargument = 'close' or vedargument = 'quit' then
		vedputmessage('Closing nntpconnection');
		if nntpsetupdone then
			gn_kill_connection();
		endif;
		return();
	endif;

	gn_setup_nntp_env();

	unless vedediting then
		;;; if not in editor just start editing newsrc file
		chain(get_newsrc_file);
	endunless;

	dlocal
		gn_retries,				;;; counter incremented in gn_retry_communicate
		gn_timeout_ok = true;	;;; used to test context
	
	define dlocal interrupt();
		;;; after interrupts socket connection has to be reset
		dlocal interrupt = oldinterrupt;	;;; allow only one interrupt
		gn_reset_connection();
		oldinterrupt();
	enddefine;

	lvars invednewsrc = (vedpathname = newsrc_file);

	if invednewsrc then
		lvars c = strmember(`:`, vedthisline());
		if c == vvedlinesize then
			;;; No number. Insert 0-0 at end
			vedtextright();
			vedinsertstring(gn_newgroup_string);
		endif;
	endif;

	if vedargument = '-' then
		gn_index_limit -> limit;
		nullstring -> vedargument;
	elseif (strnumber(vedargument) ->> limit) then
		nullstring -> vedargument;
	else
		false -> limit
	endif;


	if strmember(`\s`, vedargument) then
		;;; Assume it is newsgroup followed by number. Get article
		lvars group, num;
		explode(sysparse_string(vedargument)) -> (group, num);
		vedputmessage('Please wait. Reading article');
		gn_get_article(group, num) -> ; /*answer*/
	elseif vedargument = 'active' or vedargument = 'a' then
		get_active_list();
	elseif vedargument = 'post' or vedargument = 'p' then
		gn_sendnews();
	elseif vedargument = 'new' then
		gn_show_unread_numbers(false);
	elseif vedargument = 'renew' then
		gn_show_unread_numbers(true);
	elseif vedargument = '?' then
		;;; find information about current group
		lvars group num;
		if invednewsrc then
			getgroup(vedthisline()) -> group;
			last_number() -> (num, /*col*/);
		;;; Check if in index file for a group.
		elseif gn_in_indexfile() ->> group then
			;;; find how many articles left in group after this one.
			first_number() -> num;
		else
			;;; Not an index file
			;;; Start to read news - get .newsrc.
			chain(gn_goto_newsrc);
		endif;
		gn_show_group_info(group, num);
		return();
	elseif datalength(vedargument) > 1 and not(strnumber(vedargument))
	then
		;;; Assume the argument is a news group name
		gn_index_list(vedargument, gn_max_articles);
	elseif vedpathname = gn_last_news_file then
		;;; If in a news article file, quit
		ved_q();
		if vedargument = newsgroupdone then
			chain(ved_gn)
		endif;
	elseif invednewsrc then
		;;; In newsrc file. Get group
		lvars string = vedthisline(), group = getgroup(string);
		;;; Make index for group on current line or next line with a ":".

		if limit then
		;;; If there's an integer argument, get no more than that number
		;;; of articles.
			;;; gn_set_new_num(limit, group);
			gn_make_group_index(limit)
		else
			gn_make_group_index(gn_max_articles)
		endif;
	elseif gn_in_active_list_file() then
		;;; in list of groups with numbers of new articles
		;;; user has selected current group
		vedtrimline();
		getgroup(vedthisline()) -> group;
		get_newsrc_file();
		vedlocate('@a'<> group <> ':');
		if limit then gn_set_new_num(limit, group) endif;
		ved_w1();
		chain(ved_gn);
	else
		lvars group;
		;;; Check if in index file for a group.
		if gn_in_indexfile() ->> group then
			gn_do_index_file(group);
		else
			;;; Not an index file
			;;; Start to read news - get .newsrc.
			chain(gn_goto_newsrc);
		endif
	endif;
	gn_setup();
enddefine;

define lconstant gn_setup_for_search(string) -> string;
	;;; replace occurrences of "@" with "@@"
	lvars string, char;
	if strmember(`@`, string) then
		consstring(
			#| appdata(string,
					procedure(char); lvars char;
						if char.dup == `@` then char endif
					endprocedure)
			|#) -> string
	endif;
enddefine;

define lconstant procedure gn_nextsame(procname, getproc);
	;;; Find next article with same subject or author
	lvars procname, string, procedure getproc,
		oldediting = vedediting,
		oldline = vedline,
		oldcol = vedcolumn;
	dlocal ved_search_state;

	if vedpathname = gn_last_news_file then
		;;; go back to index file and gn_goto_newsrc
		ved_q();
		if gn_in_indexfile() and ved_gn_down_line then vedcharup() endif;
		chain(procname, getproc, gn_nextsame)
	elseif gn_in_indexfile() then
		;;; get next file with same author or subject
		getproc(gn_setup_for_search(vedthisline())) -> string;
		vedtextright();
		dlocal vedediting = false;
		vedlocate(string);
		if vedline <= oldline then
			oldediting -> vedediting;
			vedjumpto(oldline + 1, oldcol);
			vedputcommand(gn_string);
			vederror('NO MORE FOR ' sys_>< procname);
		endif;
		max(vedcolumn, vedleftmargin + 1) -> vedcolumn;
		vedleftmargin -> vedcolumnoffset;
			oldediting -> vedediting;
		if vedline - vedlineoffset >= vedwindowlength then
			vedline - 1 -> vedlineoffset;
			vedrefresh();
		endif;
	endif;
	ved_gn();
	vedputcommand(procname)
enddefine;

define ved_gns;
	;;; find next article with same subject
	gn_nextsame('gns', gn_getsubject)
enddefine;

define ved_gna;
	;;; find next article with same author
	gn_nextsame('gna', gn_getauthor(%true%))
enddefine;

define ved_gnn;
	;;; just get next article from current group
	if gn_in_indexfile() then ved_gn()
	elseif vedpathname = gn_last_news_file then
		ved_gn();
		ved_gn();
	else ved_gn();
	endif;
	vedputcommand('gn');
enddefine;

define ved_save;
	;;; save current news file in specified file, appending if necessary
	veddo('wapp ' sys_>< vedargument)
enddefine;


;;; "gn" syntax word for use outside ved
define global vars syntax gn = popvedcommand(%"ved_gn"%) enddefine;

endsection;

nil -> proglist;
/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan  6 2001
	Made gn_sendnews duplicate periods at beginning of line when sent.
	Made reader remove duplicated periods.

--- Aaron Sloman, Jan  6 2001

	Added facility for posting news ENTER gn post, or ENTER gn p
		calls gn_sendnews
		So news can now be posted without depending on inews

	Removed/replaced comments and identifier names referring to telnet. E.g.
		gn_kill_telnet becomes gn_kill_connection

--- Aaron Sloman, Jan  2 2001
	Changed
		nntp_host_spec = writeable [0 'nntp']
	to
		nntp_host_spec = writeable [0 {119 'tcp'}]
	as the former doesn't seem to work with linux.
--- Aaron Sloman, Jan  1 1998
	When reading from large groups, fixed to restart connection after
	reading 100th header.
--- Aaron Sloman, May 28 1997
	Introduced gn_max_articles, and improved handling of gn -
--- Aaron Sloman, May 26 1997
	checked that output of repeater is a string before calling isstartstring
--- Aaron Sloman,  22 Jun 1996
	Altered to use sockets instead of pipes. (Originally done Dec 1995)
	Make sure that all local defininitions of interrupt reset to oldinterrupt
	locally.
--- Aaron Sloman, Oct 22 1995
	Changed gn_setup_group_info to store all information from active
	file, not only what's in user's list. This could provide a basis for
	telling user about new groups not included. A different procedure
	could then prune gn_group_info
--- Aaron Sloman, Oct 21 1995
		Added start_line()
		Fixed behaviour of ENTER gn ?
			(give information on number of unread articles)
		Fixed minor bug caused by spurious vedpositionpush
--- Aaron Sloman, Oct 8 1995
	multiplied gn_idle_interval by 1e6 (previously forgotten)

--- Aaron Sloman, May 27 1995
		Prevented multiple calls of vedputmessage when articles are
		missing in a consecutive range of numbers. Will speed things up
		for people logging in over slow lines.

		Changed to update newsrc file if program interrupted while searching
		for unread articles in a group and so far none have been found.
--- Aaron Sloman, Jan 16 1995
		Changed gn_update_newsrc to refresh the altered line in more cases.
--- Aaron Sloman, Jan 3 1995
		Updated gn_article_info to handle cases where the From: line
		merely includes <author@site>

		Make ved_gn insert numbers if line ends with ":".

		Fixed gn_setup_group_info so as not to leave misleading items
		for groups not in the active list. This enables gn_set_new_num
		to behave more sensibly.

		Altered gn_kill_connection to reset gn_time_active_read as false.


--- Aaron Sloman, Dec  3 1994
		dlocalised ved_search_state in various places where vedlocate
		was used.
--- Aaron Sloman, Nov 26 1994
	Changed format of article index to have author first, preferably
	only the real name name (detected by parentheses), e.g.
	19495   Giovanni Aliberti ][ Can't boot a SUN4/280 from SCSI disk ???
	19496   Albert J. Corda ][ Unknown Monitor (Help!)

	If real name not available, use everthing in From: line. But if
	gn_short_author is true (the default) then ignore everything after @

--- Aaron Sloman, Oct 14 1994
	Made it try close connection if idle for gn_idle_interval
--- Aaron Sloman, Aug 6 1994
	renamed gn_try_*clear as gn_try_close and made it simply use the
	device, gn_indev or gn_outdev.
--- Aaron Sloman, Aug 6 1994
	Made gn_initialise use gn_kill_connection, and generally tried to
	reduce the occurrence of error messages due to broken pipes
--- Aaron Sloman, Jul 25 1994
	Made it more interruptable when reading in articles from groups
	with lots of missing article.
--- Aaron Sloman, Jul 21 1994
	Break strings where there are "CR" characters.
--- Aaron Sloman, June 22 June 1994
	Allowed any input to interrupt building of index for group.
	Other minor fixes
--- Aaron Sloman, June 18 1994
	Added gn_setup_for_search (for gna).
	Made gn_consumer, gn_repeater, gn_kill_connection procedures not
		closures. This simplified many things. Got rid of gn_read, gn_write.
		Had to use file-local global lvars for devices and pid
--- Aaron Sloman, June 18 1994
	Prevented gn_try_*clear causing a mishap
--- Aaron Sloman, June 18 1994
	Extended timeout mechanism to handle "broken" connections following
		interrupts (e.g. if user types CTRL-C).
	Resetting connection to news server is now more automatic.
	Added
		gn_timed_out, gn_try_*clear, gn_reset_connection, gn_retries,
		gn_retry_communicate, gn_error_depth
--- Aaron Sloman, June 14 1994
	Implemented a timeout mechanism for communicating with the remote
	server, and used it to cope with servers that sometimes don't complete
	the last line of a news article.
--- Aaron Sloman, June 10 1994
	Completely rewritten to work with NNTP server via telnet.

 */
/*
         CONTENTS

 define lconstant get_newsrc_file();
 define lconstant get_last_col_start(string) -> loc;
 define lconstant first_number() -> num;
 define lconstant getlastnum(string) /* -> num */;
 define lconstant last_number() -> (num, col);
 define lconstant gn_update_newsrc(group_string, last_num);
 define gn_reset_connection();
 define lconstant gn_set_group(group) -> answer;
 define lconstant gn_try_close(dev);
 define global procedure gn_kill_connection();
 define lconstant gn_retry_communicate(ExitFrom, ThenRead);
 define lconstant gn_timeout();
 define global procedure gn_repeater() -> (string, len);
 define global procedure gn_consumer(string);
 define gn_close_idle();
 define lconstant nntp_readanswer(okcode) -> string;
 define vars procedure gn_nntp_request(string, okcode) -> vector;
 define lconstant gn_article_info(num) -> (subject, author);
 define lconstant gn_group_subject_strings(group, start, maxarticles)
 define lconstant nntp_initialise() -> status;
 define lconstant gn_initialise(server);
 define lconstant gn_create_buffer(suffix, break, indent, vector, mess1, mess2);
 define lconstant procedure gn_in_indexfile() -> group;
 define lconstant procedure gn_in_active_list_file() /* -> boole */;
 define gn_setup_nntp_env();
 define lconstant gn_getauthor(string, full) -> author;
 define lconstant gn_getsubject(string) -> subject;
 define lconstant procedure end_of_first_space(line) -> n with_props 0;
 define lconstant procedure markseenfile ();
 define lconstant getgroup(string) -> group;
 define lconstant gn_setup();
 define lconstant get_latest_num(group) -> num;
 define lconstant get_active_list();
 define lconstant gn_index_list(group, maxarticles);
 define lconstant gn_make_group_index(maxarticles);
 define lconstant gn_arrange_header();
 define lconstant gn_goto_newsrc();
 define lconstant gn_get_article(group, article) -> answer;
 define lconstant get_article_from_index(group, group_string, article_num);
 define lconstant gn_do_index_file(group);
 define lconstant gn_setup_group_info(new);
 define lconstant gn_show_unread_numbers(new);
 define lconstant gn_set_new_num(limit, group);
 define lconstant gn_show_group_info(group, lastnum);
 define gn_post_request(string, okcode) -> string;
 define gn_sendnews();
 define global procedure ved_gn;
 define lconstant gn_setup_for_search(string) -> string;
 define lconstant procedure gn_nextsame(procname, getproc);
 define ved_gns;
 define ved_gna;
 define ved_gnn;
 define ved_save;
 define global vars syntax gn = popvedcommand(%"ved_gn"%) enddefine;

*/
