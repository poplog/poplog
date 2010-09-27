/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_gn_setup.p
 > Purpose:			Get an up to date list of current news groups
 > Author:          Aaron Sloman, Oct 23 1994 (see revisions)
 > Documentation:	Below
 > Related Files:	LIB * VED_GN, HELP * VED_GN
 */

/*
HELP VED_GN_SETUP

The command

	ENTER gn_setup

can be used only if ved_gn is available. It uses the 'gn active' command
to read in a copy of the current 'active news' file and then reorganises
the file to fit the format required for your .newsrc file, used by
the

	ENTER gn

command (and other newsreaders) for accessing news. It stores
instructions at the top of the file.

If you wish to indicate which groups you'd like to have at the top
of your file try something like this:

	ENTER gn_setup news.announce cs comp.ai sci.cog bham. comp.lang comp

Then follow instructions.

*/

uses ved_gn

define ved_gn_setup();
	;;; get new active group
	lvars line, item, col,oldfile = ved_current_file,
			 groups = sysparse_string(vedargument),
	;
	dlocal vveddump, vedediting;
	veddo('gn active');
	returnif(ved_current_file == oldfile);		;;; could not get active file
	unless isstring(vednewsrc) then
		'$HOME/.newsrc' -> vednewsrc
	endunless;
	vedputmessage('Please wait, converting to .newsrc format');
	false -> vedediting;
	vedjumpto(1,1);
	vedlinedelete();
	until vedatend()  do
		vedthisline() -> line;
		locchar(`\s`, 1, line) -> col;
		unless col then
			vederror('NO SPACE IN ACTIVE FILE ON LINE: ' >< vedline)
		endunless;
		col -> vedcolumn;
		vedinsertstring(': 1-');
		;;; get rid of number of latest article.
		vedwordrightdelete();
		vedwordrightdelete();
		;;; get number of lowest article.
		vednextitem() -> item;
		unless isinteger(item) then
			vederror('Expected integer, found: ' >< item);
		endunless;
		;;; now insert numbers
		vedcleartail();
		vedinsertstring((item -1) >< nullstring);
		vedchardown();
	enduntil;
	if vedonstatus then vedswitchstatus() endif;
	vedtopfile();
	true -> vedediting;
	;;;vedrefresh();
	vedputmessage('PLEASE WAIT: SORTING');
	false -> vedediting;
	;;; sort into alphabetical order
	ved_mbe();	ved_smr(); vedtopfile();
	unless groups == [] then
		nullstring -> vedargument;
		lvars group, line, DEFAULT = 'DEFAULT',
			group_entries = newmapping([], length(groups), [], false),
			string ;
		ved_mbe(); ved_copy();
			;;; now get the groups sorted according to vedargument
			for line from 1 to vvedbuffersize do
				fast_subscrv(line, vedbuffer) -> string;
				nextunless(isstring(string));
				for group in groups do
					if isstartstring(group, string) then
						conspair(string, group_entries(group))
							-> group_entries(group);
						nextloop(2)
					endif;
				endfor;
				conspair(string, group_entries(DEFAULT))
							-> group_entries(DEFAULT);
			endfor;
			;;; now reinsert in order
			true -> vedediting;
			vedputmessage('RE-INSERTING NEWS GROUP NAMES');
			false -> vedediting;
			ved_clear();
			vedtopfile();
			for group in groups do
				fast_ncrev(group_entries(group)) -> vveddump;
				[] -> group_entries(group);
				vedjumpto(max(1, vvedbuffersize), 1);
				ved_y();
				sys_grbg_list(vveddump);
			endfor;
			vedjumpto(max(1,vvedbuffersize), 1);
			fast_ncrev(group_entries(DEFAULT)) -> vveddump;
			ved_y();
			[] -> group_entries;
			sys_grbg_list(vveddump);
	endunless;
	vedtopfile();
	vedlineabove();
	vedinsertstring(
'!YOU SHOULD DELETE FROM THIS FILE ANY NEWS GROUPS THAT DO NOT\
!INTEREST YOU AND WHICH YOU DO NOT WISH TO READ. MOST OF THE\
!ACADEMICALLY RELEVANT INTERESTING GROUPS HAVE NAMES STARTING\
!   "comp" or "sci", e.g. "comp.ai" "comp.lang.c++" "sci.cognitive"\
!You should include the group "news.announce.newusers" and read its\
!introductory articles for new users.\
!If there is a group you don\'t wish to read now, but you may wish to\
!read later, insert "!" at the beginning of the line. You can re-order\
!the groups so that the ones that interest you most are at the top of\
!the file.\
!To delete all the groups after the current line do "ENTER deof"\
!	(undo with "ENTER y" \
!When the file is ready, do\
!	ENTER name ' <> vednewsrc <> '\n');
	vedinsertstring(
'!Then write and quit the file. If you then later do\
!	ENTER gn\
!the file will be retrieved, you can select a news group, and then\
!use the "ENTER gn" command to get a list of articles in the group\
!then REDO to select one of the articles -- after putting the VED cursor\
!on the appropriate line. (See also HELP * VED_GN, HELP * VED_POSTNEWS)');
	vedtopfile();
	true -> vedediting;
	vedputmessage('DONE');
	chain(vedrefresh)
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct 20 1996
	declared missing lvar "string"
 */
