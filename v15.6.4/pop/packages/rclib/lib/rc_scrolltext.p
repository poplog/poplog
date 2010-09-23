/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File: 			$poplocal/local/rclib/lib/rc_scrolltext.p
 > Purpose:			Add scrolling text widgets to rclib
 > Author:          Aaron Sloman, Apr 27 1999 (see revisions)
 > Documentation:	HELP rc_scrolltext, HELP rc_control_panel
					See example in TEACH POPCONTROL
					And examples below.
 > Related Files:
 */

/*
The format for create_scroll_text

create_scroll_text(
	;;; parameters for the text panel
	name, stringvec, container, xpos, ypos, rows, cols, fg, bg, font,
	;;; parameters controlling the associated sliders (see LIB RC_SLIDER)
	swidth, scol, sblob, fcol, fwidth) -> scroll_text_object;

;;; Testing the facilities defined below

;;; A vector of strings to be displayed by the scrolltext widget
vars stringvec =
    {'1.  now is the time for all good men 1234567890 1234567890'
    '2.  Now Is the time for all bad men 1234567890 1234567890'
    '3.  now was The time for all good men 1234567890 1234567890'
    '4.  now is the day for all good men 1234567890 1234567890'
    '5.  Now is the week for all bad men 1234567890 1234567890'
    '6.  when was the time for all good men 1234567890 1234567890'
    '7.  now is the month for all good men 1234567890 1234567890'
    '8.  now is the time for all red men 1234567890 1234567890'
    '9.  now is the time for all good men 1234567890 1234567890'
    '10. Now Is the time for all bad men 1234567890 1234567890'
    '11. now was The time for all good men 1234567890 1234567890'
    '12. now is the day for all good men 1234567890 1234567890'
    '13. Now is the week for all bad men 1234567890 1234567890'
    '14. when was the time for all good men 1234567890 1234567890'
    '15. now is the month for all good men 1234567890 1234567890'
    '16. now is the time for all red men 1234567890 1234567890'
    '17. now was the day for all good men 1234567890 1234567890'
    '18. now is the month for all good men 1234567890 1234567890'
    '19. Now is the week for all bad men 1234567890 1234567890'
    '20.  when was the time for all good men 1234567890 1234567890'
	};

;;; Create a window object
rc_kill_window_object(win1);

vars win1 = rc_new_window_object("right",10,500,400,true,'win1');

vars win1 = rc_new_window_object(600,10,500,400,{250 20 1 1},'win1');
vars win1 = rc_new_window_object("right","top",500,400,{50 20 2 2},'win1');

;;; A variable whose value will always be the currently selected string.

vars wstring;

;;; Create a scroll text panel in the window_object win1.

vars ww =
	create_scroll_text(
		;;; 'ww', stringvec, win1, -200, 155, 8, 40, 'yellow', 'blue', '6x13',
		'ww', stringvec, win1, -20, 15, 8, 40, 'yellow', 'blue', '6x13',
		;;; 'ww', stringvec, win1, -100, 155, 10, 50, false, false, '6x13',
		6, 'grey75', 'blue', 'red', 0, ident wstring);


vars vec = rc_scroll_text_strings(ww);
1 -> rc_informant_value(ww);
20 -> rc_informant_value(ww);
ww.rc_informant_value =>
4 -> rc_informant_value(ww);
9 -> rc_informant_value(ww);
vec(2) -> rc_informant_value(ww);
vec(18) -> rc_informant_value(ww);
ww.rc_informant_value =>
;;;or

vars ww =
	create_scroll_text(
		;;;'ww', stringvec, win1, -200, 155, 10, 40, 'yellow', 'blue', '9x15',
		'ww', stringvec, win1, -20, 15, 10, 40, 'yellow', 'blue', '9x15',
		;;; 'ww', stringvec, win1, -100, 155, 10, 50, false, false, '6x13',
		8, 'grey75', 'blue', 'red', 0, ident wstring);

;;; Check this value after altering the current selection, by scrolling, using
;;; handles on left or right, or clicking on a visible string.

wstring =>
rc_scroll_text_rowoffset(ww)=>
rc_slider_value(rc_scroll_select_slider(ww))=>
1 ->rc_slider_value(rc_scroll_select_slider(ww))
5 ->rc_slider_value(rc_scroll_select_slider(ww))
8 ->rc_slider_value(rc_scroll_select_slider(ww))

;;; this mishaps
10 ->rc_slider_value(rc_scroll_select_slider(ww))
rc_slider_value(rc_scroll_row_slider(ww))=>
18 ->rc_slider_value(rc_scroll_row_slider(ww))
88 ->rc_informant_value(rc_scroll_row_slider(ww))

;;; examine the effects of these procedures
rc_scrollup(ww);
rc_informant_value(ww) =>
rc_slider_value(rc_scroll_select_slider(ww)) =>
3 ->rc_slider_value(rc_scroll_select_slider(ww))
rc_scrolldown(ww);
rc_scrollleft(ww);
rc_scrollright(ww);
rc_scroll_to_row(ww, 7);
rc_scroll_to_row(ww, 1);
rc_scroll_to_row(ww, 14);
rc_scroll_to_row(ww, 96);
rc_scroll_to_column(ww, 1);
rc_scroll_to_column(ww, 15);
rc_scroll_to_column(ww, 50);


find_loc('the cat', {'the cat' 'my dog' 'a b c d'}) =>
find_loc('the cat', {'the catch' 'my dog' 'a b c d'}) =>
find_loc('a b c d', {'the cat' 'my dog' 'a b c d'}) =>




;;; extract the widget from the objectclass instance
vars www = rc_scroll_text_widget(ww);

XptWidgetCoords(rc_scroll_text_widget(ww)) =>

uses rc_buttons

vars button1 =
        create_rc_button(-200, -100, 45,20,
            {action 'up' [POP11 rc_scrollup(ww)]}, false, false);

vars button2 =
        create_rc_button(-200, -150, 45, 20,
            {action 'down' [POP11 rc_scrolldown(ww)]}, false, false);


*/


section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses objectclass;

exload_batch;
uses rclib
uses rc_window_object
uses rc_mousepic
uses rc_slider
uses rc_opaque_slider
uses XpwScrollText
uses interpret_specs

global vars
	rc_scroll_text_fg_def = 'black',
	rc_scroll_text_bg_def = 'grey90',
	rc_scroll_text_font_def = '8x13',

	rc_scroll_rows_max = 30,
	rc_scroll_columns_max = 100,
	rc_scroll_slider_default_type = false;
;


define vars rc_scrolltext_field_abbreviations =
	newproperty(
		[
			[font rc_scroll_text_font]
			[fg  rc_scroll_text_fg]
			[bg  rc_scroll_text_bg]
			[rows rc_scroll_text_numrows]
			[cols rc_scroll_text_numcols]
			[ident rc_informant_ident]
			[label rc_informant_label]
			], 4, false, "perm")
enddefine;

define :class vars rc_scroll_text; is rc_informant rc_linepic rc_selectable rc_keysensitive;
	slot rc_informant_window = false;
	slot rc_scroll_text_widget;
	slot rc_scroll_text_container;
	slot rc_scroll_text_strings;
	slot rc_scroll_text_rowoffset;
	slot rc_scroll_text_coloffset;
	slot rc_scroll_text_font;
	slot rc_scroll_text_fg;
	slot rc_scroll_text_bg;
	slot rc_scroll_text_numrows;
	slot rc_scroll_text_numcols;
	slot rc_scroll_text_maxcols;
	slot rc_scroll_row_slider;
	slot rc_scroll_select_slider;
	slot rc_scroll_column_slider;
	slot rc_scroll_slider_type == false;

	;;; information for drawing the background for the scrolltext panel
	slot rc_scrolltext_surround_x1 == false;	;;; a number once panel drawn
	slot rc_scrolltext_surround_x2;
	slot rc_scrolltext_surround_y;
	slot rc_scrolltext_surround_height;
	slot rc_scrolltext_surround_col;

	;;; used to control dragging
	slot rc_scroll_prev_column == 0;
	;;; Button event handlers. Keypress handlers can be added
	;;; via mixin rc rc_keysensitive;
	slot rc_button_up_handlers =
		{ ^false ^false ^false};
	slot rc_button_down_handlers =
		{rc_button_1_down ^false ^false };
	slot rc_drag_handlers =
		{rc_button_1_drag ^false ^false };
	slot rc_keypress_handler = "rc_handle_keypress";
	;;; action when RETURN or ENTER is pressed
	slot rc_accept_action = "rc_handle_accept";
enddefine;

define :method print_instance(pic: rc_scroll_text);
	printf('<SCROLLTEXT(%P,%P): %P>',
			[%rc_coords(pic), rc_informant_value(pic)%])
enddefine;

define trywriteline(widget, col, row, col_offset, vec, stringnum);
	lvars
		string = vec(stringnum),
		c_offset = min(datalength(string), col_offset);
    if c_offset > 0 then
		allbutfirst(c_offset, string) -> string
	endif;
	XpwTextWriteLine(widget, col, row, string, true);
enddefine;

define :method rc_scrolltext_refresh(obj:rc_scroll_text, start, fin);
	
	lvars
		widget = rc_scroll_text_widget(obj),
		vec = rc_scroll_text_strings(obj),
		veclen = datalength(vec),
		row_offset = rc_scroll_text_rowoffset(obj),
		col_offset = rc_scroll_text_coloffset(obj),
		rows = rc_scroll_text_numrows(obj),
		lastrow = min(fin, row_offset+rows);

	checkinteger(start, 1, veclen);
	checkinteger(fin, 1, veclen);

	lvars index;

	for index from max(row_offset + 1, start) to lastrow do
		trywriteline(widget, 0, index-(row_offset+1), col_offset, vec, index);
	endfor;
enddefine;

;;; made true in updater of rc_informant_value
lvars updating_informant = false;

define :method rc_scrollup(obj:rc_scroll_text);
	;;; text moves up window
	lvars
		widget = rc_scroll_text_widget(obj),
		vec = rc_scroll_text_strings(obj),
		veclen = datalength(vec),
		row_offset = rc_scroll_text_rowoffset(obj),
		col_offset = rc_scroll_text_coloffset(obj),
		rows = rc_scroll_text_numrows(obj),
		lastrow = min(rows fi_+ 1, veclen fi_- row_offset),
		nextstring =
			if lastrow <= rows then false else vec(row_offset fi_+ rows fi_+ 1) endif,
		selected = rc_slider_value(rc_scroll_select_slider(obj)),
		oldval = row_offset + selected,
		;

	returnif(row_offset == veclen - rows + 1);

    XpwTextScroll(widget, 0, 1, 0 ,0, 0,-1);
	;;; why was this ever here???
	;;;trywriteline(widget, 0, 0, col_offset, vec, row_offset fi_+ 2);

	if nextstring then
		;;; show new string at bottom of panel
		trywriteline(widget, 0, rows fi_- 1, col_offset, vec, row_offset fi_+ rows fi_+ 1);
	endif;
	row_offset fi_+ 1  ->> row_offset -> rc_scroll_text_rowoffset(obj);
	unless updating_informant then
		;;; update select slider on left
		min(veclen - row_offset, max(1, selected - 1))
			->> selected -> rc_slider_value(rc_scroll_select_slider(obj));
		if oldval /== row_offset + selected then
			;;; value has changed
			row_offset + selected -> rc_informant_value(obj)
		endif;
	endunless;
enddefine;

define :method rc_scrolldown(obj:rc_scroll_text);
	;;; text moves down window
	lvars
		widget = rc_scroll_text_widget(obj),
		vec = rc_scroll_text_strings(obj),
		veclen = datalength(vec),
		row_offset = rc_scroll_text_rowoffset(obj),
		col_offset = rc_scroll_text_coloffset(obj),
		rows = rc_scroll_text_numrows(obj),
		nextstring =
			if row_offset <= 0 then false else vec(row_offset) endif,
		selected = rc_slider_value(rc_scroll_select_slider(obj)),
		oldval = row_offset + selected,
		;

	unless nextstring then return endunless;

	if rows > 1 then
	    XpwTextScroll(widget, 0,0, 0,0, 0,1);
	endif;
	;;; show new string at top of panel
	trywriteline(widget, 0, 0, col_offset, vec, row_offset );

	row_offset - 1 ->> row_offset -> rc_scroll_text_rowoffset(obj);
	;;; update select slider on left

	unless updating_informant then
		min(rows, min(veclen - row_offset, selected + 1)) ->>
		selected -> rc_slider_value(rc_scroll_select_slider(obj));

		if oldval /== row_offset + selected then
			;;; value has changed
			row_offset + selected -> rc_informant_value(obj)
		endif;
	endunless;
enddefine;

define :method rc_scrollleft(obj:rc_scroll_text);
	lvars
		widget = rc_scroll_text_widget(obj),
		vec = rc_scroll_text_strings(obj),
		veclen = datalength(vec),
		row_offset = rc_scroll_text_rowoffset(obj),
		col_offset = rc_scroll_text_coloffset(obj),
		rows = rc_scroll_text_numrows(obj),
		cols = rc_scroll_text_numcols(obj),
		;

	XpwTextScrollScreenLeft(widget);
	col_offset + 1 -> rc_scroll_text_coloffset(obj);

	lconstant string = '0';

	lvars row, index = cols+col_offset+1;

	for row from 0 to min(rows - 1, veclen - row_offset - 1) do
		lvars line = vec(row + row_offset + 1);
		if datalength(line) >= index then
			subscrs(index, line) else `\s`
		endif -> subscrs(1, string);
		XpwTextInsert(widget, cols - 1, row, string)
	endfor;


enddefine;

define :method rc_scrollright(obj:rc_scroll_text);
	lvars
		widget = rc_scroll_text_widget(obj),
		vec = rc_scroll_text_strings(obj),
		veclen = datalength(vec),
		row_offset = rc_scroll_text_rowoffset(obj),
		col_offset = rc_scroll_text_coloffset(obj),
		rows = rc_scroll_text_numrows(obj),
		;

	unless col_offset > 0 then  return endunless;

	lconstant string = '0';
	lvars row;
	for row from 0 to min(rows - 1, veclen - row_offset - 1) do
		lvars line = vec(row + row_offset + 1);
		if datalength(line) >= col_offset then
			subscrs(col_offset, line) else `\s`
		endif -> subscrs(1, string);
		XpwTextInsert(widget, 0, row, string)
	endfor;

	col_offset - 1 -> rc_scroll_text_coloffset(obj);

enddefine;

define :method rc_update_selected(obj:rc_scroll_text, val);
	;;; Note new selected string. If it is different from previous one
	;;; run the reactor method
	lvars oldval = rc_informant_value(obj);
	if val /= oldval then
		val -> rc_informant_value(obj);
		dlocal rc_reactor_depth = 0;
		rc_information_changed(obj);
	endif;
enddefine;

define :method rc_scroll_to_row(obj:rc_scroll_text, row);
	returnif(self_caller());
	;;; Scroll till row is the first one visible
	lvars
		rows = rc_scroll_text_numrows(obj),
		vec = rc_scroll_text_strings(obj),
		veclen = datalength(vec),
		row_offset = rc_scroll_text_rowoffset(obj),
		row_slider = rc_scroll_row_slider(obj);

	if row > row_offset then
		repeat row - row_offset - 1 times
			rc_scrollup(obj);
		endrepeat;
	else
		repeat row_offset - row  + 1 times
			rc_scrolldown(obj)
		endrepeat
	endif;

	if row_slider then
		min(rc_scroll_text_rowoffset(obj), veclen - rows + 1)
				-> rc_informant_value(row_slider);
	endif;
	;;; Run reactors if necessary
	rc_update_selected(obj, rc_informant_value(obj));
enddefine;

define :method rc_scroll_to_column(obj:rc_scroll_text, col);
	;;; Scroll till col is the first one visible
	lvars
		col_offset = rc_scroll_text_coloffset(obj),
		cols = rc_scroll_text_maxcols(obj),
		col_slider = rc_scroll_column_slider(obj);
		;
	col - 1 -> col;
	if col > col_offset then
		repeat col - col_offset times
			rc_scrollleft(obj);
		endrepeat;
	else
		repeat col_offset - col times
			rc_scrollright(obj)
		endrepeat
	endif;
	if col_slider then
		col -> rc_informant_value(col_slider);
	endif;
enddefine;


define :method updaterof rc_informant_value(item, obj:rc_scroll_text);

	define lconstant find_loc(string, vec) -> num;
		;;; find location at which string exists in vec, or false
		lvars num;
		fast_for num from 1 to datalength(vec) do
		returnif(string = fast_subscrv(num, vec))
		endfor;
		false -> num;
	enddefine;

	dlocal updating_informant;
	true -> updating_informant;

	lvars
		vec = rc_scroll_text_strings(obj);
	if isinteger(item) then
		lvars
			len = datalength(vec),
			rows = rc_scroll_text_numrows(obj);
		if item > len or item < 1 then
			mishap('INAPPROPRIATE STRING NUMBER IN SCROLL TEXT PANEL',
				[^item ^obj])
		else
			;;; scroll up or down to get required string into visible window
			until item  >= rc_scroll_text_rowoffset(obj) + 1 do
				;;; Veddebug('down');
				rc_scrolldown(obj);
			enduntil;
			until item <= rc_scroll_text_rowoffset(obj) + rows do
				;;; Veddebug('up');
				rc_scrollup(obj);
			enduntil;
			;;; Veddebug(vec(item));
			call_next_method(vec(item), obj);
			item - rc_scroll_text_rowoffset(obj)
				-> rc_slider_value(rc_scroll_select_slider(obj));
		endif;
	elseif isstring(item) then
		lvars num;
		if (find_loc(item, vec) ->> num) then
			num -> rc_informant_value(obj)
		else
			mishap('UNRECOGNIZED STRING IN SCROLL TEXT PANEL', [^item ^obj])
		endif;
	else
		mishap('STRING OR NUMBER NEEDED FOR SCROLL TEXT VALUE', [^item ^obj])
	endif
enddefine;



define lconstant select_row_string(obj, row) -> num;
	;;; given a row in the text panel, find the corresponding string
	;;; in the panel's vector, and also return the actual row number
	;;; of the selected string (which may be the last in the vector.
	lvars
		offset = rc_scroll_text_rowoffset(obj),
		vec = rc_scroll_text_strings(obj),
		len = datalength(vec);
		min(len, (offset + row)) -> num;
		;;; having found the string, update the informant_contents of
		;;; the scroll text object.
		rc_update_selected(obj, vec(num));
		num - offset -> num;
enddefine;

define :method rc_button_1_down(obj:rc_scroll_text, col, row, modifiers);
	;;; Click on an object to make it the selected one,
	lvars
		veclen = datalength(rc_scroll_text_strings(obj)),
		rowoffset = rc_scroll_text_rowoffset(obj);
	max(0,row) -> row;
	min(rc_scroll_text_numrows(obj) + 1, row)
			-> rc_slider_value(rc_scroll_select_slider(obj));
	rc_update_selected(obj, rc_informant_value(obj));
	max(0,col + 1) -> rc_scroll_prev_column(obj);
enddefine;

define :method rc_button_1_up(obj:rc_scroll_text, col, row, modifiers);
	;;; Click on an object to make it the selected one, unless the
	;;; shift key is already down and an object has been selected
	[up ^obj ^col ^row ^modifiers] =>
enddefine;

define :method rc_button_1_drag(obj:rc_scroll_text, col, row, modifiers);
	lvars
		veclen = datalength(rc_scroll_text_strings(obj)),
		rowoffset = rc_scroll_text_rowoffset(obj),
		rows = rc_scroll_text_numrows(obj);

	max(0,row) -> row;

	if (row <= rows and rowoffset + row <= veclen)
	or	(veclen - rowoffset) >= rows
	then
		min(rows + 1, row) -> rc_slider_value(rc_scroll_select_slider(obj));
		rc_update_selected(obj, rc_informant_value(obj));
	endif;

	lvars
		slider = rc_scroll_column_slider(obj);

	returnunless(slider);

	lvars
		coloffset = rc_scroll_text_coloffset(obj),
		lastcol = rc_scroll_prev_column(obj),
		maxcol = back(rc_slider_range(slider));

	max(0, col) -> col;

	if col == 0 or col < lastcol -1  then
		rc_scrollright(obj);
	elseif col > lastcol + 1 or col >= rc_scroll_text_numcols(obj)
	and coloffset <= maxcol then
		rc_scrollleft(obj)
	endif;

	min(maxcol, rc_scroll_text_coloffset(obj)) -> rc_slider_value(slider);
	
	;;; save the value of col
	if abs(col - lastcol) > 1 then
		col -> rc_scroll_prev_column(obj);
	endif;
enddefine;


define :method rc_handle_keypress(obj:rc_scroll_text, col, row, modifiers, key);
	;;; Work out what to do when a key is pressed. Can be changed by users.
	;;; Should use a more easily changed table.

	;;;[A key ^key] =>
	;;; For some reason key presses are all recorded with code 0
	;;; only key releases are recognized in the scrolltext window
	;;; React only to key release and ignore value 0?
	returnif(key >= 0);
	abs(key) -> key;

	rc_interpret_key(key) -> key;
	;;;Veddebug([key ^key]);
	;;; [B key ^key] =>
	;;;; [keypress ^obj ^col ^row ^modifiers key ^key ] =>

	lvars
		veclen = datalength(rc_scroll_text_strings(obj)),
		rowoffset = rc_scroll_text_rowoffset(obj),
		rows = rc_scroll_text_numrows(obj),
		cols = rc_scroll_text_numcols(obj),
		max_cols = rc_scroll_text_maxcols(obj),
		select_slider = rc_scroll_select_slider(obj),
		selected = rc_slider_value(select_slider),
		col_slider = rc_scroll_column_slider(obj),
		current_col =
			if col_slider then rc_slider_value(col_slider) else false endif;

	if key == "END" then
		rc_scroll_to_row(obj, veclen - rows + 1);
		rows -> rc_slider_value(select_slider),
	elseif key == "HOME" then
		rc_scroll_to_row(obj, 1);
		1 -> rc_slider_value(select_slider),
		return();
	elseif modifiers = 'c' then
		;;; Control key held down
		if key == `a` then
			;;; beginning of line
			if col_slider then
				0 -> rc_slider_value(col_slider);
			endif;
		elseif key == `e` then
			;;; end of line
			if col_slider then
				max_cols - cols  -> rc_slider_value(col_slider);
			endif;
		elseif key == `c` then
			;;; Control C
			external_defer_apply(interrupt)
		elseif key == `p` then
			;;; go uP
			selected - 1 -> rc_slider_value(select_slider),
		elseif key == `n` then
			;;; go dowN
			selected + 1 -> rc_slider_value(select_slider),
		elseif key == `=` then
			[row ^row col ^col stringnumber ^(row + rowoffset)]=>
		endif;
	;;; elseif modifiers /= nullstring and modifiers /= 's' then
	elseif key == "BACKSPACE" or key == "DELETE" then
	elseif fast_lmember(key, #_< [SHIFT CAPSLOCK CONTROL ESC] >_# ) then
		;;; Ignore for now. These may be used later
	elseif key == "RETURN" or key == "ENTER" then
		recursive_valof(rc_accept_action(obj))
			(obj, rc_informant_value(obj), key)
	elseif isnumber(key) and key >= 32 and key < 127 then
	elseif key == "LEFT" or key == "KP_4" then
		if col_slider then
			max(current_col - 1, 0)  -> rc_slider_value(col_slider);
			;;; rc_scrollright(obj)
		endif;
	elseif key == "RIGHT" or key == "KP_6" then
		if col_slider then
			min(current_col + 1, max_cols - cols)  -> rc_slider_value(col_slider);
			;;; rc_scrollleft(obj)
		endif;
	elseif key == "UP" or key == "KP_8" then
		selected - 1 -> rc_slider_value(select_slider),
	elseif key == "DOWN" or key == "KP_2" then
		selected + 1 -> rc_slider_value(select_slider),
	else
		'UNRECOGNIZED KEY FOR Scroll Text: ' sys_>< key =>
	endif;

enddefine;

define :method rc_handle_accept(obj:rc_scroll_text, val, button);
	;;; [Accept ^obj ^val ^button]=>
enddefine;

define lconstant do_select_row(slider, val, obj);
	;;; partially apply to widget to create reactor for vertical left_slider
	;;; for selecting string
	lvars
		vec = rc_scroll_text_strings(obj),
		len = datalength(vec),
		offset = rc_scroll_text_rowoffset(obj),
		numrows = rc_scroll_text_numrows(obj),
		num = min(numrows + 1, len - offset),
		row_slider = rc_scroll_row_slider(obj);

	if val == 0 then
		if row_slider then rc_scrolldown(obj) endif;
		1 -> val;
	elseif val > numrows then
        if len - offset > numrows - 1  then
		    if row_slider then rc_scrollup(obj) endif;
		    val - 1 -> val
        endif;
	endif;

	;;; in case the vector of strings does not reach the full
	;;; range of the slider, find the row of the selected string.
	select_row_string(obj, val) -> rc_slider_value(slider);

	if row_slider then
		;;; work out new offset
		rc_scroll_text_rowoffset(obj) -> rc_slider_value(row_slider);
	endif;
	rc_update_selected(obj, rc_informant_value(obj));
enddefine;

define lconstant do_scroll_row(slider, val, obj);
	;;; Invoked when slider on the right is changed.
	;;; update everything else

	lvars
		vec = rc_scroll_text_strings(obj),
		veclen = datalength(vec),
		rows = rc_scroll_text_numrows(obj),
		selector = rc_scroll_select_slider(obj),
		offset = rc_scroll_text_rowoffset(obj),
		selected = rc_slider_value(selector) + offset,
		newselected = selected - val,
		newrow
	;

	rc_scroll_to_row(obj, val+1);

	;;; Now update selector
	if newselected >= rows then
		rows
	elseif newselected < 1 then
		1
	else
		newselected
	endif ->> newrow -> rc_slider_value(selector);

	rc_update_selected(obj, vec(min(veclen, val + newrow)));
enddefine;


define lconstant do_scroll_col(slider, val, obj);
	;;; for column slider at bottom
	rc_scroll_to_column(obj, val+1)
enddefine;



define lconstant set_current_active_object(scr_obj);
	lvars win_obj = rc_informant_window(scr_obj);
	;;; based on code in rc_mousepic
	unless win_obj == rc_active_window_object then
		rc_active_window_object -> rc_prev_active_window_object;
		win_obj -> rc_active_window_object;
	endunless;
	unless win_obj == rc_current_window_object then
		win_obj -> rc_current_window_object;
	endunless;
enddefine;

define lconstant restore_current_window(win_obj);
	unless win_obj == rc_current_window_object then
		if not(win_obj) or rc_islive_window_object(win_obj) then
			win_obj
		else false
		endif -> rc_current_window_object;
	endunless;
enddefine;

define lconstant do_button_actions(widget, item, data);
	;;; Invoke the handler for mouse button up or down events
	;;; partly based on lib mousepic

	lvars (col, row, modifiers) =
		XptVal widget(XtN mouseColumn, XtN mouseRow, XtN modifiers);

	;;; convert modifier to string
	rc_modifier_codes(modifiers) -> modifiers;

	exacc ^int data -> data; ;;; button number. <4 if pressed

	lvars mode, clicks, button;

	data && 2:111 -> button;
	data >> 8 -> data;
	data && 2:11 -> mode;
	((data >> 2) div 64) -> clicks;

	;;; [clicks ^clicks mode ^mode data ^data]=>
	;;; [button ^button mode ^ mode clicks ^clicks loc ^col ^row mod ^modifiers ^item data ^data] =>

	lvars
		old_win = rc_current_window_object,
		;;; get the scroll text object
		scr_obj = rc_window_object_of(widget);

	dlocal 0% , if dlocal_context < 3 then restore_current_window(old_win) endif%;

	set_current_active_object(scr_obj);

	;;; convert to normal row count
	row + 1 -> row;
	if mode == 0 then
		if clicks == 1 then
			rc_system_button_up_callback(scr_obj, col, row, modifiers, item, button);
		elseif clicks > 1 then
			;;; double or treble clicks: invoke acceptor
			recursive_valof(rc_accept_action(scr_obj))
				(scr_obj, rc_informant_value(scr_obj), button);
		endif;
	elseif mode == 1 then
		rc_system_button_down_callback(scr_obj, col, row, modifiers, item, button);
	endif;
enddefine;

define lconstant do_move_actions(widget, item, data);
	;;; Invoke the handler for mouse move
	;;; partly based on lib mousepic

	lvars (col, row, modifiers) =
		XptVal widget(XtN mouseColumn, XtN mouseRow, XtN modifiers);

	exacc ^int data -> data;

	;;; convert modifier to string
	rc_modifier_codes(modifiers) -> modifiers;

	lvars button;
	if data < 256 then 0	;;; pure motion event
	elseif data == 256 then 1 elseif data == 512 then 2 else 3 endif -> button;

	;;; [data ^data button ^button loc ^col ^row mod ^modifiers ^item] =>

	lvars
		old_win = rc_current_window_object,
		;;; get the scroll text object
		scr_obj = rc_window_object_of(widget);

	dlocal 0% , if dlocal_context < 3 then restore_current_window(old_win) endif%;

	set_current_active_object(scr_obj);

	;;; get the callback handler, and apply it to the object and coords
	if button > 0 then
		rc_system_drag_callback(scr_obj, col+1, row+1, modifiers, item, button);
	endif;

enddefine;

define lconstant do_keyboard_actions(widget, item, data);
	;;; Invoke the handler for keyboard events
	;;; partly based on lib mousepic

	lvars (col, row, modifiers) =
		XptVal widget(XtN mouseColumn, XtN mouseRow, XtN modifiers);

	exacc ^int data -> data;
	
	;;; convert modifier to string
	rc_modifier_codes(modifiers) -> modifiers;

	lvars
		old_win = rc_current_window_object,
		;;; get the scroll text object
		scr_obj = rc_window_object_of(widget);

	dlocal 0% , if dlocal_context < 3 then restore_current_window(old_win) endif%;
	
	set_current_active_object(scr_obj);

	;;; get the callback handler, and apply it to the object and coords
	rc_system_keypress_callback(scr_obj, col+1, row+1, modifiers, data, data);

enddefine;

/*
;;; test next procedure
rc_start();
rc_point_right(0,-150, 10, 'blue');
rc_point_right(30,-150, 5, 'blue');
rc_point_right(30,150, 25, 'red');
*/

define rc_point_right(x, y, size, col);
	;;; draw a triangle pointing right, for use at left of panel.

	rc_draw_filled_triangle(
		x - size, y - size, x - size, y + size, x + size, y,
		col)
	
enddefine;

define :method rc_draw_slider_right(s:rc_slider);
	;;; draw a slider blob as right-pointing triangle
	lvars
		scale = max(abs(rc_xscale), abs(rc_yscale))+0.0,
		rad = rc_slider_blobradius(s),
		col = rc_slider_blobcol(s),
		;
	rc_point_right(0, 0, rad, col);
enddefine;


define :method rc_undraw_linepic(obj:rc_scroll_text);

	lvars
		slider1 = rc_scroll_select_slider(obj),
		slider2 = rc_scroll_row_slider(obj),
		slider3 = rc_scroll_column_slider(obj);
	;;; Veddebug('undrawing');
	if isrc_slider(slider1) then rc_undraw_linepic(slider1) endif;
	if isrc_slider(slider2) then rc_undraw_linepic(slider2) endif;
	if isrc_slider(slider3) then rc_undraw_linepic(slider3) endif;

enddefine;

define :method rc_draw_linepic(obj:rc_scroll_text);

	lvars
		slider1 = rc_scroll_select_slider(obj),
		slider2 = rc_scroll_row_slider(obj),
		slider3 = rc_scroll_column_slider(obj);

	lvars surround_x1 = rc_scrolltext_surround_x1(obj);
	if surround_x1 then
		;;; draw the background panel 	
	  	lvars
			surround_x2 = rc_scrolltext_surround_x2(obj),
			surround_y = rc_scrolltext_surround_y(obj),
	    	surround_height = rc_scrolltext_surround_height(obj),
	  		surround_col = rc_scrolltext_surround_col(obj);

    	rc_drawline_relative(
        	surround_x1, surround_y, surround_x2, surround_y,
			surround_col, surround_height);

	endif;

	;;; Veddebug('drawing');
	if isrc_slider(slider1) then rc_draw_slider(slider1) endif;
	if isrc_slider(slider2) then rc_draw_slider(slider2) endif;
	if isrc_slider(slider3) then rc_draw_slider(slider3) endif;


enddefine;

define create_scroll_text(name, vec, container, xpos, ypos, rows, cols, fg, bg, font,
		swidth, scol, sblob, fcol, fwidth) -> obj;
	;;; Using vector of strings vec, create scrolling text widget in the containr
	;;; at location xpos, ypos (in rc_graphic coordinates) with the specified
	;;; number of rows and columns of text, with fg, foreground and bg background
	;;; colors, usint text font font, with associated scroll bar (on right) of
	;;; width swidth, slider bar colour scol, blob colour sblob, frame colour
	;;; fcol, and slider framewidth fwidth;

	;;; NB vec can now be a list starting with a vector of
	;;; strings and continuing with property vectors

	dlocal
		;;; used in interpret_specs
		featurespec_abbreviation = rc_scrolltext_field_abbreviations;

	lvars spec = false, wid = false;

	;;; see if optional word or identifier given
	if isword_or_ident(fwidth) then
		(name, vec, container, xpos, ypos, rows, cols, fg, bg, font,
			swidth, scol, sblob, fcol, fwidth) ->
		(name, vec, container, xpos, ypos, rows, cols, fg, bg, font,
			swidth, scol, sblob, fcol, fwidth, wid)
	endif;

	;;; see if spec arg given.
	if isvector(fwidth) then
		(name, vec, container, xpos, ypos, rows, cols, fg, bg, font,
			swidth, scol, sblob, fcol, fwidth) ->
		(name, vec, container, xpos, ypos, rows, cols, fg, bg, font,
			swidth, scol, sblob, fcol, fwidth, spec)
	endif;

	;;; if container not supplied use the current panel.
	unless container then rc_current_window_object -> container endunless;

	lvars file, extras = false;

	if isvector(vec) then vec
	elseif islist(vec) then
		if vec == [] then
				mishap('VECTOR OF STRINGS NEEDED FOR SCROLLTEXT', [^vec])
		elseif isvector(front(vec)) then
			;;; leave the vector of strings, and process the rest
			destpair(vec) -> extras;
		elseif isstring(front(vec)) then
			{%	
				;;; this for programs that use this to display directory contents
				;;; perhaps no longer needed.
				for file in vec do
					if sysisdirectory(file) then file dir_>< '/' else file endif
				endfor
			%}
		else
			mishap('VECTOR OF STRINGS NEEDED FOR SCROLLTEXT', [^vec])			
		endif;
	else
		mishap('Vector or list of strings needed', [^vec])
	endif -> vec;

	lvars
		max_len = max_string_length(vec),
		len = datalength(vec),
		win_obj =
			if isrc_window_object(container) then container else false endif,
		composite =
			if isrc_window_object(container) then rc_window_composite(container)
				else container
			endif;


	;;; Make space for slider on left of panel
	xpos + 2*(swidth + fwidth)/rc_xscale -> xpos;
	;;; Get absolute coordinates of scrolltext top left corner
	lvars (x, y) = rc_transxyout(xpos, ypos);

	;;; create scrolltext instance with default values
	;;; create objectclass instance
	instance rc_scroll_text;
	  rc_informant_window = rc_current_window_object;
	  rc_scroll_text_container = container;
	  rc_scroll_text_strings = vec;
	  rc_picx = xpos;
	  rc_picy = ypos;
	  rc_scroll_text_rowoffset = 0;
	  rc_scroll_text_coloffset = 0;
	  rc_scroll_text_font = font;
	  rc_scroll_text_fg = fg;
	  rc_scroll_text_bg = bg;
	  rc_scroll_text_numrows = rows;
	  rc_scroll_text_numcols = cols;
	  rc_scroll_text_maxcols = max_string_length(vec);
	  rc_scroll_slider_type = rc_scroll_slider_default_type;
	  rc_informant_ident = wid;
	endinstance -> obj;

	;;; now update defaults
	interpret_specs(obj, spec);
	if extras then
		lvars item, ok = false;;
		;;; interpret the rest of the spec.
		for item in extras do
			;;; Veddebug([item ^item]);
			if isvector(item) then
				lvars vlen = datalength(item);
				if vlen == 2 then
					true -> ok;
					lvars (key, val)= explode(item);
					if key == "specs" then
						interpret_specs(obj, val)
					else interpret_specs(obj, item)
					endif;
				elseif vlen mod 2 == 0 then
					true -> ok;
					;;; a vector of even length
					interpret_specs(obj, item)
				else ;;; not OK
				endif;
			endif;
			unless ok then
				mishap('UNRECOGNISED SPEC FOR INPUT FIELD', [^item ^extras])
			endunless;
		endfor;
	endif;

	;;; check whether interpret_specs has changed the rows or cols values
	;;; or some other values
	rc_scroll_text_numrows(obj) -> rows;
	rc_scroll_text_numcols(obj) -> cols;
	rc_scroll_text_font(obj) -> font;
	rc_scroll_text_fg(obj) -> fg;
	rc_scroll_text_bg(obj) -> bg;
	rc_informant_ident(obj) -> wid;
	;;; others might beswidth, scol, sblob, fcol, fwidth

	;;; work out required numbers of rows and columns if necessary
	if rows == 0 then min(len, rc_scroll_rows_max) -> rows endif;
	if cols == 0 then min(max_len, rc_scroll_columns_max) -> cols endif;

	;;; Unmap composite while constructing scrolltext in it ???
	;;;    XtUnmapWidget(composite);
	lvars
		widget =
			XtCreateManagedWidget(name,
				xpwScrollTextWidget, composite,
				XptArgList([
						{x ^x} {y ^y}
						;;; start small then expand after setting font
						{numRows 1} {numColumns 1}
						;;; These don't work at creation time (strings)
						;;;{XtNfont ^font}
						;;;{XtNBackground ^bg}
						;;;{XtNforeground ^fg}
						;;;{XtNstatusBackground ^bg}
						;;;{XtNstatusForeground ^bg}
					]) );

    ;;; XtUnmapWidget(widget);
    ;;; remove cursor, by making it a space
    XpwSetTextCursor(widget, ` `);

	font or rc_scroll_text_font_def -> widget(XtN font);

	bg or rc_scroll_text_bg_def
		->> widget(XtN background)
		-> widget(XtN statusBackground);

	fg or rc_scroll_text_fg_def
		->> widget(XtN foreground)
		-> widget(XtN statusForeground);

	rows -> widget(XtN numRows);
	cols -> widget(XtN numColumns);

	;;; Put the text in
	XpwTextWrite(widget, 0, 0, 0, min(rows, len), 0, cols, vec, true);

	;;; Now show the original and the new widget ???
    ;;; XtMapWidget(composite);
    ;;; XtMapWidget(widget);

	;;; add the mouse callback handler	
	XptAddCallback(widget, XtN buttonEvent, do_button_actions, "button", identfn);
	;;; add the drag/motion callback handler	

	XptAddCallback(widget, XtN motionEvent, do_move_actions, "move", identfn);

	XptAddCallback(widget, XtN keyboardEvent, do_keyboard_actions, "key", identfn);

	;;; Create the two sliders, row_slider and col_slider
	;;; make blob and bar the same width
	dlocal rc_slider_blob_bar_ratio = 1;

	lvars
		font_height = XpwFontHeight(widget),
		font_ascent = XpwFontAscent(widget),

	;;; find actual width and height of scroll text widget
		(,,width, height) = XptWidgetCoords(widget),
	;;; find location of vertical slider, on right
		xright = xpos+(width+swidth+fwidth + 2)/rc_xscale,
		xleft = xpos-(swidth+fwidth)/rc_xscale,
		ytop = ypos+(swidth+fwidth)/rc_yscale,
		ybot = ypos+(rows*font_height+font_ascent + 2)/rc_yscale,
	;;; get the absolute slider bar width and frame width for the slider.
		abs_swidth = swidth/abs(rc_xscale),
		abs_fwidth = fwidth/abs(rc_xscale),
	;;; Information about locations of sliders
		ylefttop = ypos -(font_height-font_ascent)/rc_yscale,
	;;; information for drawing background panel
		surround_y = (ypos - (swidth+fwidth)/rc_yscale + ybot)*0.5,
		surround_x1 = xleft - (swidth + 3)/rc_xscale,
		surround_x2 = xright + (swidth + 2)/rc_xscale,
		surround_height = abs(ylefttop - ybot) + 3 + 3*abs_swidth,
		;

	;;; The (up to) three sliders, created for the panel. Only the first
	;;; one is always created. The row and col sliders are needed only as
	;;; scrollbars if there is too much text for the window.
	lvars
		left_slider,
		row_slider,
		col_slider;
	
	;;; Prepare rectangular background for the panel
    rc_drawline_relative(
        surround_x1, surround_y, surround_x2, surround_y, scol, surround_height);

	;;; slider on left with invisible bar, showing selected line.
	rc_opaque_slider(
		xleft, ylefttop,
		xleft, ybot,
		{0 ^(rows + 1) 1 1},
		abs_swidth, scol, sblob, [],
		{rc_slider_value_panel ^false
			rc_draw_slider_blob ^rc_draw_slider_right
			rc_slider_barframe ^(conspair(false, 0))
			})
		-> left_slider;


	;;; Slider on right showing how far text has scrolled. Limiting position
	;;; has one visible blank line
	
	if rows < len then
		if rc_scroll_slider_default_type == "panel" then
			rc_panel_slider
		else
			rc_opaque_slider
		endif(xright, ytop, xright, ypos+(height-swidth)/rc_yscale,
			{0 ^(max(1, len-rows + 1)) 0 1},
			abs_swidth, scol, sblob, [],
			{rc_slider_value_panel ^false
			 rc_draw_slider_blob ^rc_draw_vert_slider_blob
				rc_slider_barframe ^(conspair(fcol, abs_fwidth))})
	else
		false
	endif -> row_slider;

	;;; Now work out location for horizontal column_slider
	lvars
	;;; find location of horizontal column_slider
		xloc_left = xpos+(swidth)/rc_xscale,
		xloc_right = xpos+(width-(swidth+fwidth))/rc_xscale,
		yloc = ypos+(height+(swidth+fwidth))/rc_yscale;

	if cols < max_len then

		if cols == 1 then
			xloc_left-5-> xloc_left;
			xloc_right+5-> xloc_right
		endif;

		if rc_scroll_slider_default_type == "panel" then
			rc_panel_slider
		else
			rc_opaque_slider
		endif(xloc_left, yloc, xloc_right, yloc,
			{0 ^(max(1, max_len + 2 - cols)) 0 1},
			abs_swidth, scol, sblob, [],
			{rc_slider_value_panel ^false
			 rc_draw_slider_blob ^rc_draw_hor_slider_blob
				rc_slider_barframe ^(conspair(fcol, abs_fwidth))})
	else
		false
	endif -> col_slider;

	;;; Update objectclass instance

	  {0 0 ^width ^height} -> rc_mouse_limit(obj);
	  widget -> rc_scroll_text_widget(obj);
	  surround_x1 -> rc_scrolltext_surround_x1(obj);
	  surround_x2 -> rc_scrolltext_surround_x2(obj);
	  surround_y -> rc_scrolltext_surround_y(obj);
	  surround_height -> rc_scrolltext_surround_height(obj);
	  scol -> rc_scrolltext_surround_col(obj);
	  row_slider -> rc_scroll_row_slider(obj);
	  left_slider -> rc_scroll_select_slider(obj);
	  col_slider -> rc_scroll_column_slider(obj);

	obj -> rc_window_object_of(widget);

	do_select_row(%obj%) -> rc_informant_reactor(left_slider);

	if row_slider then
		do_scroll_row(%obj%) -> rc_informant_reactor(row_slider);
	endif;

	;;; create reactor for horizontal slider

	if col_slider then
		do_scroll_col(%obj%) -> rc_informant_reactor(col_slider);
	endif;

	vec(1) -> rc_informant_value(obj);

enddefine;


;;; for "uses"
global vars rc_scrolltext = true;

endexload_batch;

endsection;
[] -> proglist

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 30 2002
		added uses interpret_specs
--- Aaron Sloman, Aug 26 2002
		
	added rc_scrolltext_refresh(obj:rc_scroll_text, start, fin);

	made rc_scrollup stop if last line has moved above bottom of
	window.

	made rc_scrollup and rc_scrolldown move pointer on left if possible.
	made them update rc_informant_value properly

--- Aaron Sloman, Aug 25 2002
	replaced rc_informant*_contents with rc_informant_value
--- Aaron Sloman, Aug 25 2002
	Made updater of rc_informant_value acept a string or a number, and
	work as expected.
--- Aaron Sloman, Aug 25 2002
		Fixed keystrokes to work with linux.
--- Aaron Sloman, Aug 24 2002
	Altered create_scroll_text to allow the second argument(vec) to be either
	a vector of strings, as before, or a list starting with a vector of strings,
	and followed by attribute value specs.

--- Aaron Sloman, Aug 23 2002
		Altered compile mode, and added "vars" to the class definition
--- Aaron Sloman, Aug 20 2000
	Changed to use rc_draw_filled_triangle for pointer on left
--- Aaron Sloman, Jul 23 2000
	Changed to draw square blobs for right and bottom sliders
--- Aaron Sloman, Jul  4 2000
	Introduced four new slots to support redrawing, and updated rc_control_panel
	rc_scrolltext_surround_x1
	rc_scrolltext_surround_x2
	rc_scrolltext_surround_y
	rc_scrolltext_surround_height
	rc_scrolltext_surround_col

--- Aaron Sloman, Jul  3 2000
	Changed default slider type so that it is no longer "panel".
	Changed to use opaque sliders by default.
	Left slider still messy. Got rid of Do_*scroll_action
--- Aaron Sloman, Jun 30 2000
	Changed to use rc_opaque_slider
--- Aaron Sloman, Jun  9 2000
	Fixed rc_undraw_linepic, and rc_draw_linepic
--- Aaron Sloman, Mar  8 2000
	The call of rc_modifier_codes was in the wrong place. Moved it to earlier
	occurrence, before the handlers are called.
--- Aaron Sloman, Oct 11 1999
	Changed to use
	  rc_informant_window instead of rc_scroll_*text_window_object
	Made to restore current_window_object
--- Aaron Sloman, 9 Aug 1999
	Fixed bug involving vertical slider when window size = 1.
--- Aaron Sloman, Jun  1 1999
	Introduced rc_scroll_slider_type, rc_scroll_slider_default_type, and made
	the default type "panel"
--- Aaron Sloman, May 14 1999
	Introduced set_current_active_object
--- Aaron Sloman, May 13 1999
	Introduced rc_scroll_rows_max, rc_scroll_columns_max
--- Aaron Sloman, May 11 1999
	Added keyboard handler, with appropriate slot and method.
	Also acceptor slot
--- Aaron Sloman, May  9 1999
	Made dragging a bit easier by reducing sensitivity to column change
--- Aaron Sloman, May  8 1999
	removed calls of vedscreenbell
	Made the text panel scrollable left and right as well as up and down
	by dragging the mouse.
*/

/*

         CONTENTS - (Use <ENTER> g to access required sections)

 define vars rc_scrolltext_field_abbreviations =
 define :class vars rc_scroll_text; is rc_informant rc_linepic rc_selectable rc_keysensitive;
 define :method print_instance(pic: rc_scroll_text);
 define trywriteline(widget, col, row, col_offset, vec, stringnum);
 define :method rc_scrolltext_refresh(obj:rc_scroll_text, start, fin);
 define :method rc_scrollup(obj:rc_scroll_text);
 define :method rc_scrolldown(obj:rc_scroll_text);
 define :method rc_scrollleft(obj:rc_scroll_text);
 define :method rc_scrollright(obj:rc_scroll_text);
 define :method rc_update_selected(obj:rc_scroll_text, val);
 define :method rc_scroll_to_row(obj:rc_scroll_text, row);
 define :method rc_scroll_to_column(obj:rc_scroll_text, col);
 define :method updaterof rc_informant_value(item, obj:rc_scroll_text);
 define lconstant select_row_string(obj, row) -> num;
 define :method rc_button_1_down(obj:rc_scroll_text, col, row, modifiers);
 define :method rc_button_1_up(obj:rc_scroll_text, col, row, modifiers);
 define :method rc_button_1_drag(obj:rc_scroll_text, col, row, modifiers);
 define :method rc_handle_keypress(obj:rc_scroll_text, col, row, modifiers, key);
 define :method rc_handle_accept(obj:rc_scroll_text, val, button);
 define lconstant do_select_row(slider, val, obj);
 define lconstant do_scroll_row(slider, val, obj);
 define lconstant do_scroll_col(slider, val, obj);
 define lconstant set_current_active_object(scr_obj);
 define lconstant restore_current_window(win_obj);
 define lconstant do_button_actions(widget, item, data);
 define lconstant do_move_actions(widget, item, data);
 define lconstant do_keyboard_actions(widget, item, data);
 define rc_point_right(x, y, size, col);
 define :method rc_draw_slider_right(s:rc_slider);
 define :method rc_undraw_linepic(obj:rc_scroll_text);
 define :method rc_draw_linepic(obj:rc_scroll_text);
 define create_scroll_text(name, vec, container, xpos, ypos, rows, cols, fg, bg, font,

*/
;
