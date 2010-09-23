/* --- Copyright University of Birmingham 2005. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_cleanmail.p
 > Purpose:			Tidy certain sorts of encoded email messages
 > Author:          Aaron Sloman, Dec 15 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
HELP ved_cleanmail

ENTER cleanmail
(inside an email message.)

ENTER cleanmail all
(whole file)

ENTER cleanmail mr
(marked range)

A first attempt to get rid of funny "=" joining broken
lines and other symbols starting with "=". Must find the relevant
documentation some day and do this properly.

*/
/*
between(0,0,5)=>
between(5,0,10)=>
between(0,10,5)=>
between(20,10,5)=>

ishexcode(`0`)=>
ishexcode(`1`)=>
ishexcode(`9`)=>
ishexcode(`c`)=>
ishexcode(`A`)=>
ishexcode(`F`)=>
ishexcode(`G`)=>
*/

define lconstant between(x, y, z);
	y <= x and x <= z
enddefine;

define ishexcode(x);
	if between(x, `0`, `9`) then
		x - `0`
	elseif between(x, `A`, `F`) then
		10 + x - `A`
	else
		false
	endif;
enddefine;

define ved_cleanmail();
	dlocal ved_search_state, vedbreak = false, vvedworddump, vvedlinedump ;
	vedpositionpush();
	if vedargument = 'all' then
		;;; mark whole file
		ved_mbe()
	elseif vedargument = 'mr' then
		;;; use current marked range
	else
		;;; mark mail message
		ved_mcm();
	endif;

	;;; do the replacements

	;;; strange stuff in headers, from yahoo
	veddo('gsr/"=?iso-8859-1?q?/"/');
	veddo('gsr/?="/"/');

	;;; special cases
	;;; this (bullet?)
	veddo('gsr/=85/o/');
	veddo('gsr/=96/--/');
	veddo('gsr/=97/--/');
	;;; veddo('gsr/=20/ /');

	;;; Go through replacing =XY with hexadecimal character
	;;; 16:XY
	vedjumpto(vvedmarklo, 1);
		;;;Veddebug('Starting');
	repeat
		;;; Veddebug(vedthisline());
		until vedcurrentchar() == `=` do
			vedcharright();
			if vedcolumn > vvedlinesize then vednextline() endif;
			quitif(vedline > vvedmarkhi)(2);
		enduntil;
			;;; check that hex code follows `=`.
			vedcharright();

			lvars char1, char2;
			if (ishexcode(vedcurrentchar()) ->>char1) and
				(vedcharright(), ishexcode(vedcurrentchar()) ->>char2)
			then
				;;; found =XY so delete last three chars and insert
				;;; appropriate character
				veddotdelete();vedchardelete();vedchardelete();
				;;; Veddebug(vedthisline());
				vedcharinsert(16*char1 + char2);
				;;; Veddebug(vedthisline());
				nextloop();
			else
				vedcharright();
				nextloop();
			endif;

	
		;;;Veddebug('AAAAA');
		if vedcolumn > 50 then
			vedcharleft();vedcharleft();
			lvars last_char = vedcurrentchar();
			if last_char /== `=` then
				vedcharright();
				if vedcurrentchar() == `=` then
					;;; it is a line ending with `=`
					;;; so join next line to it
					veddotdelete();		;;; delete `=`
					;;; go to next line
					vednextline();
					;;; save the text and delete it
					lvars text = vedthisline();
					vedlinedelete();
					;;; add at end of previous line
					vedcharup();
					vedtextright();
					if last_char == `\s` then vedcharright() endif;
					vedinsertstring(text);
				endif;
			endif;
		endif;
		quitif(vedline == vvedmarklo);
	endrepeat;

/*
	;;; CR/LF
	veddo('gsr/=0D=0A/\\n/');
	;;; LF at beginning of line, ignore
	veddo('gsr/@a=0A//');
	veddo('gsr/=09/-/');
	;;; LF
	veddo('gsr/=0A/\\n/');
	;;; CR
	veddo('gsr/=0D/\\n');
	;;; Left string quote I think:
	veddo('gsr/=E2=80=98/\'/');
	;;; Right string quote I think:
	veddo('gsr/=E2=80=99/\'/');
	veddo('gsr/=20/ /');
	veddo('gsr/=27/\'/');
	veddo('gsr/=2C/,/');
	veddo('gsr/=2E/./');
	veddo('gsr.=2F./.');
	veddo('gsr/=3A/:/');
	veddo('gsr/=3D/=/');
	veddo('gsr/=3F/?/');
	veddo('gsr/=46/F/');
	veddo('gsr/=46/F/');
	veddo('gsr/=5F/_/');
	veddo('gsr/=91/`/');
	veddo('gsr/=92/\'/');
	veddo('gsr/=93/`/');
	veddo('gsr/=94/\'/');
	;;; veddo('gsr" =@z@a" "');
	veddo('gsr/=A0/ /');
	veddo('gsr/=A3/£/');
	veddo('gsr/=AB/`/');
	veddo('gsr/=AD/--/');
	veddo('gsr/=B4/\'/');
	veddo('gsr/=B7/o/');
	veddo('gsr/=B9/\'/');
	veddo('gsr/=BB/\'/');
	veddo('gsr/=D5/\'/');
	veddo('gsr/=DF/ss/');
	veddo('gsr/=D2/`/');
	veddo('gsr/=D3/\'/');
	veddo('gsr/=E7/ç/');	;;; ???
	veddo('gsr/=E9/é/');	;;; ???
	veddo('gsr/=EB/ë/');	;;; ???
	veddo('gsr/=FC/ü/');   ;;; ue
	veddo('gsr/=F3/ó/');
	veddo('gsr/=F6/ö/');
	veddo('gsr/=A1=AF/\'/');
	veddo('gsr/=A7/§/'); 	;;; not $
	veddo('gsr/=40/@@/');
	veddo('gsr/=3D/=/');
*/

	;;; get rid of graphic characters that screw up xterm windows.
	veddo('gsr.\(10:146).\'.');		;;; replace character ascii 146 with '
	veddo('gsr.\(10:147).`.');		;;; replace character ascii 147 with `
	veddo('gsr.\(10:148).\'.');		;;; replace character ascii 148 with '
	veddo('gsr.\(10:150).\'.');		
			;;; replace (invisible) character ascii 150 with space

	;;; redo in case:
	;;;veddo('gsr/ =@z@a/ /');

	;;; join up lines ending with "="
	vedjumpto(vvedmarkhi, 1);
	repeat
		vedcharup(); vedtextright();
		if vedcolumn > 50 then
			vedcharleft();vedcharleft();
			lvars last_char = vedcurrentchar();
			if last_char /== `=` then
				vedcharright();
				if vedcurrentchar() == `=` then
					;;; it is a line ending with `=`
					;;; so join next line to it
					veddotdelete();		;;; delete `=`
					;;; go to next line
					vednextline();
					;;; save the text and delete it
					lvars text = vedthisline();
					vedlinedelete();
					;;; add at end of previous line
					vedcharup();
					vedtextright();
					if last_char == `\s` then vedcharright() endif;
					vedinsertstring(text);
				endif;
			endif;
		endif;
		quitif(vedline == vvedmarklo);
	endrepeat;
	vedpositionpop();
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 31 2005
		More systematic treatment of hexadecimal characters.
		Get rid of characters that screw up xterm windows.
--- Aaron Sloman, Aug 10 2004
		Added stuff to deal with quotes in mail headers
--- Aaron Sloman, Oct  5 2002
		Added more line breaks.
--- Aaron Sloman, Aug 22 2002
		added 5F for _
			  3F for ?
--- Aaron Sloman, Feb  1 2001
	Fixed cases where end of line is  space then "=".
--- Aaron Sloman, May 20 2000
	added =D2 =D3
	Made it deal better with =@z@a

--- Aaron Sloman, Apr 11 2000
	Added "mr" option
	Added more cases =FC =DF
--- Aaron Sloman, Mar 15 2000
	added "all" option etc.
--- Aaron Sloman, Jan  9 2000
	dlocalised ved_search_state
 */
