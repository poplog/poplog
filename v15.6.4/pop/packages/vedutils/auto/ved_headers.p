/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_headers.p
 > Linked to;		$poplocal/local/auto/ved_gp.p
 > Purpose:         Make a list of procedure header lines
 > Author:          Aaron Sloman, Dec 28 1997 (see revisions)
 > Documentation:	HELP * VED_HEADERS
 > Related Files:
 */

section;

define vedheaders() -> list;
	lvars
		index,
		string,
		lim = vvedbuffersize;

	[%
		for index from 1 to lim do
			fast_subscrv(index, vedbuffer) -> string;
				lvars col = issubstring('define ', string);

			if col == 1 then
				[^index ^string]
			elseif col and col /== 2 then
				;;; check if there's only white space before 'define'
				lvars num;
				fast_for num from 1 to col fi_- 1 do
					lvars char = fast_subscrs(num, string);
					unless char == `\s` or char == `\t` then
						nextloop(2);
					endunless;
				endfor;
				[^index ^(veddecodetabs(string))]
			endif;
		endfor
	%] -> list

enddefine;

define ved_headers();
	lvars
		list = vedheaders(),
		file = systmpfile('/tmp','headers', nullstring),
		path = vedpathname,
		line;


	define dlocal cucharout(char);
		vedcharinsert(char);
	enddefine;

	vededit(file, vedhelpdefaults);
	false -> vedbreak;  ;;; don't break long lines

	vedinsertstring(path);
	vedlinebelow();
	vedputmessage('please wait');

	dlocal vedediting = false;

	for line in list do
		syspr(line(1));
		6 -> vedcolumn;
		vedinsertstring(line(2));
		vedlinebelow();
	endfor;
	vedtopfile();
	vedputcommand('gp');
	vedputmessage('Select line then press REDO (or "ENTER gp")');
	chain(vedrefresh);
enddefine;

define ved_gp();
	;;; go to procedure
	lvars
		path = vedbuffer(1),
		line;
	1 -> vedcolumn;
	vednextitem() ->> line -> vvedgotoplace;
	vededit(path);
	vedjumpto(line, 1)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 13 1998
	Created HELP VED_HEADERS
 */
