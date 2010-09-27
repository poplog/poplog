/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved ---------
 > File:           $popneural/src/pop/nui_txtbrowser.p
 > Purpose:        generic list/structure browsers
 > Author:         Julian Clinton, Sept 1989
 > Documentation:
 > Related Files:
 */

section $-popneural => 	nn_browse_list
                        nn_browse_struct
                        nn_edit_list
                        nn_edit_struct
                        nn_select_list
;

pr(';;; Loading browser\n');

uses fmatches;
uses nui_utils;

/* ----------------------------------------------------------------- *
    Structure Printers
 * ----------------------------------------------------------------- */


define pr_listparts(lists, titles, start_at, items, len);
dlocal pop_pr_quotes = false;
	lvars lists titles start_at items item index len tlen title;

    if len fi_> 0 then
		;;; length(lists) -> tlen;
		length(titles) -> tlen;
		titles(1) -> title;
        for index from start_at to min(start_at fi_+ items fi_- 1, len) do
			if tlen > 1 then
			    for item from 1 to tlen do
				    if item == 1 then
					    pr_field(index, 4, ` `, false);
					    syspr(' - ');
					    pr_field(title, 6, ` `, false);
				    else
					    pr_field(titles(item), 13, ` `, false);
				    endif;
				    syspr(': ');
					true -> pop_pr_quotes;
				    ppr(lists(item)(index));
					false -> pop_pr_quotes;
				    nl(1);
                endfor;
			    nl(1);
			else
			    pr_field(title, 10, ` `, false);
			    syspr(space);
			    pr_field(index, 4, ` `, false);
			    syspr(': ');
				true -> pop_pr_quotes;
			    ppr(lists(1)(index));
				false -> pop_pr_quotes;
			    nl(1);
			endif;
        endfor;
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    Generic Browse Functions
 * ----------------------------------------------------------------- */


define generic_browser_txt(structs, titles, level,
                           selectable, editable, descendable, prompt);
lvars titles, incr = 1, items = length(titles),
      index = 1, level, i, n, n2, com structs structlen newlist
      editable, descendable, selectable, prompt;
dlocal pop_readline_prompt =
        if descendable then
            prompt sys_>< ' (' sys_>< (level sys_>< ') > ');
        else
            prompt sys_>< ' > ';
        endif;


	;;; fix for PNF0026
	if not(structs) or not(structs(1)) then
		nui_message_txt('No items to browse');
		if selectable then false endif;
		return();
	endif;

    length(structs(1)) -> structlen;
    use_basewindow(false);
    npr(prompt <> ' - ' >< (structlen >< ' items supplied'));
    nl(1);
    pr_listparts(structs, titles,  index, 1, structlen);
    while (readline() ->> com) /= [q] and com /=[quit] and com /= [u] then
        if com == [] then
            min(structlen, index fi_+ 1) -> index;
            1 -> incr;

		elseif length(com) == 1 then

			;;; check for single item commands
			;;;
			hd(com) -> com;
            if descendable and com == "d" then
                generic_browser_txt({%structs(1)(index)%},
                                    {%titles(1)%}, level + 1,
                                   selectable, editable, descendable, prompt);
                1 -> incr;

            elseif com == "l" then
                structlen -> index;
                1 -> incr;

            elseif descendable and com == "qq" then
                interrupt();

            elseif isinteger(com) then
                if (com ->> n) fi_< 0 then
                    max(index fi_+ n, 1) -> index;
                else
                    min(structlen, n) -> index;
                endif;
                1 -> incr;
            elseif editable and com == "r" then
                get_item_default([string word], 'New value', structs(1)(index))
                    -> structs(1)(index);
                1 -> incr;
			elseif selectable and com == "s" then
    	        structs(1)(index);
        	    quitloop();
            elseif editable and com == "a" then
                get_lists(false, 'New entry', false, false) -> newlist;
                unless newlist == [] then
          		    if (islist(structs(1)) and structs(1) /== []) or isvector(structs(1)) then
                	    structs(1) nc_<> newlist -> structs(1);
                	    length(structs(1)) -> structlen;
				    else
					    newlist -> structs(1);
					    length(newlist) -> structlen;
				    endif;
                endunless;
                structlen -> index;
                1 -> incr;
            elseif com == "h" or com == "?" then
                npr('Commands :');
                npr('       <RETURN> : next item');
                npr('            <n> : show item <n>');
                npr('           +<n> : forward <n> items');
                npr('           -<n> : backward <n> items');
                npr('              l : show last item');
                npr('     <n1>, <n2> : show items from <n1> to <n2>');
                if editable then
                    npr('              r : replace current item');
                    npr('              a : append new items');
                    npr('            del : delete current item');
                    npr('        del <n> : delete item <n>');
                    npr(' del <n1>, <n2> : delete items <n1> to <n2>');
                endif;
                if selectable then
                    npr('              s : select current item');
                endif;
                if descendable then
                    npr('              d : recurse down current item');
                    npr('              u : return up from current item');
                    npr('             qq : quit from all browse levels');
                endif;
                pr('        quit, q : quit current ');
                if editable then
                    pr('edit ');
                else
                    pr('browse ');
                endif;
                if descendable then
                    npr('level');
                else
                    nl(1);
                endif;
                npr('         h or ? : this help');
                nextloop();
		    else
			    nextloop();
		    endif;

        elseif com fmatches [+ ?n] then
            min(structlen, index fi_+ n) -> index;
            1 -> incr;

        elseif editable and (com fmatches [r ?n:isinteger]) and
	      n <= length(structs) then
            get_item_default([string word], 'New value', structs(n)(index))
                -> structs(n)(index);
            1 -> incr;

        elseif editable and (com fmatches [del ??n]) and islist(structs(1)) then
            if n == [] then
                fast_ncdelete(structs(1)(index), structs(1), nonop ==)->;
            elseif length(n) == 1 then
                fast_ncdelete(structs(1)(subscrl(1,n)), structs(1), nonop ==)->;
            elseif n fmatches [= , =] then
                subscrl(1,n) -> incr;
                fast_for i from incr to min(subscrl(3,n), structlen) do
                    fast_ncdelete(structs(1)(incr), structs(1), nonop ==)->;
                endfast_for;
            endif;
            length(structs(1)) -> structlen;
            min(index, structlen) -> index;
            1 -> incr;

        elseif selectable and (com fmatches [s ??n]) then
            if (listlength(n) > 0) and isinteger(hd(n))
              and hd(n) <= structlen then
                structs(1)(hd(n));
                quitloop();
            endif;
        elseif com fmatches [?n:isinteger , ?n2:isinteger] then
            min(structlen, n) -> index;
            min(n2, structlen) fi_+ 1 fi_- index -> incr;
        elseif com fmatches [?n:isinteger , l] then
            min(structlen, n) -> index;
            structlen fi_+ 1 fi_- index -> incr;
        else
            1 -> incr;
        endif;
        pr_listparts(structs, titles, index, incr, structlen);
        min(index fi_+ incr fi_- 1, structlen) -> index;
    endwhile;

    if selectable and (com = [q] or com = [quit]) then
        false;
    endif;
enddefine;


define generic_browser_gfx(structs, titles, level,
                           selectable, editable, descendable, prompt);
lvars titles level editable descendable selectable prompt structs;

	use_basewindow(false);
    generic_browser_txt(structs, titles, level,
                            selectable, editable, descendable, prompt);
enddefine;


define generic_browser(structs, titles, level,
                       selectable, editable, descendable, prompt);
lvars titles incr = 1, index = 1, level editable descendable selectable
	prompt com structs;

    if GUI then
        generic_browser_gfx(structs, titles, level,
                            selectable, editable, descendable, prompt);
    else
        generic_browser_txt(structs, titles, level,
                            selectable, editable, descendable, prompt);
    endif;
enddefine;


/* ----------------------------------------------------------------- *
    Visible Functions
 * ----------------------------------------------------------------- */

global constant procedure
  nn_browse_list = generic_browser(%0, false, false, false, 'Browse List'%),
  nn_browse_struct = generic_browser(%0, false,false,true,'Browse Structure'%),
  nn_edit_list = generic_browser(%0, false, true, false, 'Edit List'%),
  nn_edit_struct = generic_browser(%0, false, true, true, 'Edit Structure'%),
  nn_select_list = generic_browser(%0, true, false, false, 'Selector'%);

endsection; 	/* $-popneural */

global vars nui_txtbrowser = true;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 17/7/92
	Renamed from browser.p to nui_txtbrowser.p.
-- Julian Clinton, 30/6/92
	Allowed strings to be returned.
-- Julian Clinton, 22/6/92
	Added fix for PNF0026 (browser mishap on <false>).
	Fixed a bug with the "r <integer>" command.
-- Julian Clinton, 4/6/92
	pr_listparts now labels items differently depending on what is being
	displayed. For single items (e.g. set items), then format is:
		Item   1: <item>
	For multiple items (e.g. actual and target results), the format is:
	  2 - Actual  : <item1>
	      Target  : <item2>
-- Julian Clinton, 1/6/92
	Modified format_print strings in pr_listparts.
-- Julian Clinton, 29/5/92
	Now uses fmatches instead of matches.
-- Julian Clinton, 8/5/92
    Sectioned.
-- Julian Clinton, 14th Sept 1990:
    PNE0054 - changed text browser to take structures
*/
