/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/history.p
 > Purpose:         Summarises the newmaster LOG
 > Author:          Robert John Duncan, Mar  9 1992 (see revisions)
 > Documentation:   HELP * NEWMASTER
 > Related Files:   LIB * NEWMASTER
 */


section $-newmaster;

lconstant
	days		= {mon tue wed thu fri sat sun},
	months		= {jan feb mar apr may jun jul aug sep oct nov dec},
	month_ndays	= {31 28 31 30 31 30 31 31 30 31 30 31},
		;;; leap years ignored
;

define lconstant day_number(day);
	lvars i, day;
	fast_for i to 7 do
		returnif(day == fast_subscrv(i, days))(i);
	endfor;
	false;
enddefine;

define lconstant month_number(month);
	lvars i, month;
	fast_for i to 12 do
		returnif(month == fast_subscrv(i, months))(i);
	endfor;
	false;
enddefine;

define lconstant encode(nth, month, year);
	lvars nth, month, year;
	if nth fi_< 1 then
		month fi_- 1 -> month;
	endif;
	if month fi_< 1 then
		year fi_- 1 -> year;
		month fi_+ 12 -> month;
	endif;
	if nth fi_< 1 then
		nth fi_+ fast_subscrv(month, month_ndays) -> nth;
	else
		fi_min(nth, fast_subscrv(month, month_ndays)) -> nth;
	endif;
	year fi_* 10000 fi_+ month fi_* 100 fi_+ nth;
enddefine;

define lconstant parse_date(date) -> (day, nth, month, year);
	lvars i = 1, j, date, day, nth, month, year;
	if isinteger(date) then
		;;; starting index into the date string
		((), date) -> (date, i);
	endif;
	;;; day of the week
	locspace(i, date) -> j;
	day_number(consword(uppertolower(substring(i, j-i, date)))) -> day;
	;;; month
	locspace(skipspace(j, date) ->> i, date) -> j;
	month_number(consword(uppertolower(substring(i, j-i, date)))) -> month;
	;;; date
	locspace(skipspace(j, date) ->> i, date) -> j;
	strnumber(substring(i, j-i, date)) -> nth;
	;;; year
	strnumber(substring(datalength(date)-3, 4, date)) -> year;
enddefine;

define lconstant encode_date(date) -> code;
	lvars day, nth, month, year, date, code = -1;
	parse_date(date) -> (day, nth, month, year);
	if day and nth and month and year then
		encode(nth, month, year) -> code;
	endif;
enddefine;

define lconstant decode_date(code) -> date;
	lvars	nth, month, year, code, date;
	dlocal	pop_pr_quotes = false;
	code // 100 -> (nth, code);
	code // 100 -> (month, year);
	word_string(months(month)) -> month;
	lowertoupper(month(1)) -> month(1);
	sprintf('%P %P%P %P', [
		^month
		^(if nth < 10 then space else nullstring endif)
		^nth
		^year
	]) -> date;
enddefine;

define lconstant next_line(dev) -> line;
	lconstant BUFF_SIZE = 256, buff = writeable inits(BUFF_SIZE);
	lvars n, dev, line;
	fast_sysread(dev, 1, buff, BUFF_SIZE) -> n;
	if n == 0 then
		termin -> line;
	else
		substring(1, n fi_- 1, buff) -> line;
		while n == BUFF_SIZE and buff(n) /== `\n` do
			;;; discard the rest of the line
			fast_sysread(dev, 1, buff, BUFF_SIZE) -> n;
		endwhile;
	endif;
enddefine;

define lconstant history(dev, mark, date, user)
-> (marks, news, dels, mods, trans, odds);
	lvars	i, j, line, file, action, dev, mark, date, user,
			(marks, news, dels, mods, trans, odds) = ([], [], [], [], [], []);

	define lvars file_action =
		newmapping([], 32, "NONE", true);
	enddefine;

	define lconstant record_action(file, action);
		lvars previous, file, action;
		file_action(file) -> previous;
		if action == "NEW" then
			if previous == "NONE"	;;; first time
			or previous == "NEW"	;;; second time -- first failed?
			or previous == "TRANS"	;;; installed, deleted, re-installed
			then
				"NEW"
			elseif previous == "DEL" then
				;;; re-installed -- count as modified
				"MOD"
			else
				;;; inconsistent
				"ODD"
			endif;
		elseif action == "DEL" then
			if previous == "NONE"
			or previous == "MOD"
			or previous == "DEL"
			or previous == "TRANS"
			then
				"DEL"
			elseif previous == "NEW" then
				;;; transitory -- installed and deleted
				"TRANS"
			else
				"ODD"
			endif;
		elseif action == "MOD" then
			if previous == "NEW" then
				;;; this takes precedence
				"NEW"
			elseif previous == "NONE"
			or previous == "MOD"
			then
				"MOD"
			else
				"ODD"
			endif;
		else
			mishap(file, action, 2, 'IMPOSSIBLE CASE IN record_action');
		endif -> action;
		unless action == previous then action -> file_action(file) endunless;
	enddefine;

	define lconstant summarise(file, action);
		lvars file, action;
		if action == "NEW" then
			file :: news -> news;
		elseif action == "DEL" then
			file :: dels -> dels;
		elseif action == "MOD" then
			file :: mods -> mods;
		elseif action == "TRANS" then
			file :: trans -> trans;
		elseif action == "ODD" then
			file :: odds -> odds;
		else
			mishap(file, action, 2, 'IMPOSSIBLE CASE IN summarise');
		endif;
	enddefine;

	until (next_line(dev) ->> line) == termin do
		nextunless(isstartstring(NEWMASTER, line));
		locspace(skipspace(datalength(NEWMASTER)+1, line) ->> i, line) -> j;
		consword(substring(i, j-i, line)) -> action;
		if not(mark)
		and (action == "MOD" or action == "NEW" or action == "DEL")
		then
			unless action == "DEL" then
				;;; skip SRC/DOC field
				locspace(skipspace(j, line), line) -> j;
			endunless;
			;;; extract file name
			locspace(skipspace(j, line) ->> i, line) -> j;
			substring(i, j-i, line) -> file;
			;;; user name
			locspace(skipspace(j, line) ->> i, line) -> j;
			nextif(user and user /= substring(i, j-i, line));
			;;; date
			nextif(date and date > encode_date(line, skipspace(j, line)));
			false -> date;
			record_action(file, action);
		elseif action == "MARK" then
			nextunless(locchar(`'`, j, line) ->> i);
			nextunless(locchar(`'`, i+1, line) ->> j);
			substring(i+1, j-i-1, line) -> file;
			nextif(mark and mark /= file);
			false -> mark;
			;;; skip user name
			locspace(skipspace(j+1, line), line) -> j;
			nextif(date and date > encode_date(line, skipspace(j, line)));
			false -> date;
			file :: marks -> marks;
		endif;
	enduntil;
	;;; summarise
	appproperty(file_action, summarise);
	syssort(news, false, alphabefore) -> news;
	syssort(dels, false, alphabefore) -> dels;
	syssort(mods, false, alphabefore) -> mods;
	syssort(trans, false, alphabefore) -> trans;
	syssort(odds, false, alphabefore) -> odds;
	rev(marks) -> marks;
enddefine;

define lconstant display_history(logfile, mark, date, user);
	lvars	dev, logfile, mark, date, user, marks, news, dels, mods, trans,
			odds, changes;
	dlocal	cucharout;

	define lconstant display_files(title, files);
		lvars file, title, files;
		returnif(files == [])(false);
		printf('\n%s:\n', [^title]);
        for file in files do
			printf(file, '\t%p\n');
        endfor;
		true;
	enddefine;

	sysopen(logfile, 0, "line") -> dev;
	history(dev, mark, date, user) -> (marks, news, dels, mods, trans, odds);
	sysclose(dev);
	vededitor(vedhelpdefaults, systmpfile(false, 'history', nullstring));
	false ->> vednotabs -> vedbreak;
	vedcharinsert -> cucharout;
	false -> changes;
	display_files('Marks', marks) or changes -> changes;
	display_files('New files', news) or changes -> changes;
	display_files('Deleted files', dels) or changes -> changes;
	display_files('Changed files', mods) or changes -> changes;
	display_files('Transitory files', trans) or changes -> changes;
	display_files('Inconsistent files', odds) or changes -> changes;
	vedtopfile();
	vedlineabove();
	printf('%s made to the%s master system%s since %s', [%
		if changes then
			'Changes'
		else
			'No changes'
		endif,
		if option("version") then
			' %p', option("version")
		else
			nullstring
		endif,
		if user then
			' by %p', user
		else
			nullstring
		endif,
		if mark then
			mark
		elseif date == 0 then
			'start of LOG'
		else
			decode_date(date)
		endif,
	%]);
	vedtextleft();
	vedcheck();
enddefine;

define lconstant translate_argument(arg) -> (mark, date);
	lvars i, day, nth, month, year, arg, since, (mark, date) = (false, false);
	returnif(arg = nullstring);
	uppertolower(arg) -> since;
	parse_date(sysdaytime()) -> (day, nth, month, year);
	if isstartstring(since, 'today') then
		encode(nth, month, year) -> date;
	elseif isstartstring(since, 'yesterday') then
		encode(nth - 1, month, year) -> date;
	elseif isnumbercode(since(1)) and (strnumber(since) ->> i) then
		if i > 0 and i <= 31 then
			encode(i, if i <= nth then month else month-1 endif, year)
				-> date;
		elseif i > 1970 and i <= 2070 then
			encode(1, 1, i) -> date;
		endif;
	elseif day_number(consword(since)) ->> i then
		day - i -> i;
		if i < 0 then 7 + i -> i endif;
		encode(nth - i, month, year) -> date;
	elseif month_number(consword(since)) ->> i then
		encode(1, i, if i <= month then year else year-1 endif) -> date;
	elseif since = '.' then
		;;; the year dot!
		0 -> date;
	else
		;;; assume it's a mark
		arg -> mark;
	endif;
enddefine;

define lconstant do_history();
	lvars mark, date, user, version, logfile;
	translate_argument(option("history")) -> (mark, date);
	option("user") -> user;
	vername_search(option("version") or 'default', newmaster_versions)
		-> version;
	check_version_log("history", version) -> logfile;
	display_history(logfile, mark, date, user);
enddefine;
;;;
do_history -> command("history");

endsection;		/* $-newmaster */

/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Sep  1 1992
		Added dlocal of pop_pr_quotes inside decode_date.
 */
