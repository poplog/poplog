/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/ved_menu_hkey.p
 > Purpose:			Version of ved_key that works when invoked asynchronously
 > Author:          Aaron Sloman, Sep 18 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*  --- Copyright University of Sussex 1996.  All rights reserved. ---------
 >  File:           C.all/lib/ved/ved_hkey.p
 >  Purpose:        Describe a key (or key sequence)
 >  Author:         Aled Morris, Aug  7 1986 (see revisions)
 >  Documentation:  HELP *VED_HKEY
 >  Related Files:  LIB *VED_HK
 */

section;

define lconstant Vedkeytrans(list);
	lvars item, list;
	consstring(#|
		`\'`,
		fast_for item in list do
			if item fi_> 127 then
				`\\`, `(`, dest_characters(item), `)`
			elseif item fi_< 32 then
				if item == `\e` then
					`\\`, `e`
				else
					`\\`, `\^`, item fi_+ `@`
				endif
			elseif item == `\^?` then
				`\\`, `\^`, `?`
			elseif item == `'` then
				`\\`, `\'`
			else
				item
			endif
		endfast_for;
		`\'`
	|#)
enddefine;


define global ved_menu_hkey();
	lvars
		;;; added newchars (A.S. 18 Sep 1999)
		chars, newchars,
		insert, item, oldvedscr_read_input, props,
		Vedescapestring = consstring(vedescape, 1);

	unless (vedargument = '-i' ->> insert) then
		unless vedargument = nullstring do
			vederror('Unknown argument')
		endunless
	endunless;

	[] -> chars;
	vedscr_read_input -> oldvedscr_read_input;
	define dlocal vedscr_read_input() -> c;
		(oldvedscr_read_input() ->> c) :: chars -> chars
	enddefine;

	vedputmessage('Please press the key. If no response, press more keys');
	vedgetproctable(vedscr_read_input) -> item;
	if item = Vedescapestring then
		;;; Hack for LIB VEDVT220 where Select is mapped to Escape
		vedgetproctable(vedescape) -> item
	endif;

	Vedkeytrans(fast_ncrev(chars)) -> newchars;
	;;; reset chars for ved_scr_read_input (AS. 18 Sep 1999)
	[] -> chars;

	if insert then
		vedinsertstring(newchars)
	endif;

	if isprocedure(item) then
		if (recursive_front(pdprops(item)) ->> props) then
			ved_try_do_??(props sys_>< nullstring, false) ->
		endif;
		vedputmessage('Sequence ' <> newchars <> ' maps onto: ' sys_>< item)
	elseif isstring(item) then
		vedputmessage('Sequence ' <> newchars <> ' maps onto: ' <> item)
	else
		vedputmessage('Sequence ' <> newchars <> ' is undefined')
	endif;

	lvars mess = vedmessage, line = vedline, col = vedcolumn;

	define show_message();
		vedendfile();
		vedinsertstring(mess);
		vedcheck();
		;;; vedrefresh();
		vedjumpto(line,col)
	enddefine;

	if vedinvedprocess then
		show_message()
	else
		vedinput(show_message)
	endif;
enddefine;


endsection;


/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 18 1999
	Copied then edited ved_hkey, which doesn't work if invoked from
	a panel
*/
