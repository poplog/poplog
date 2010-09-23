/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/rc_insert_strings_scrolltext.p
 > Purpose:			Replace some strings in scrolling text widget
 > Author:			Aaron Sloman, Aug 26 2002 (see revisions)
 > Documentation:	HELP RCLIB, HELP rc_scrolltext
 > Related Files:	LIB rc_scrolltext
 */

/*
TESTS

rc_kill_window_object(win1);

vars win1 = rc_new_window_object("right",10,300,300,true,'win1');

vars
	wstring,
	vec1 =
      {
	    '1. AAAAAAAAAAAAAAAAA'
        '2. BBBBBBBBBBBBBBBBB'
        '3. CCCCCCCCCCCCCCCCC'
        '4. DDDDDDDDDDDDDDDDD'
        '5. EEEEEEEEEEEEEEEEE'
        '6. FFFFFFFFFFFFFFFFF'
        '7. GGGGGGGGGGGGGGGGG'
        '8. HHHHHHHHHHHHHHHHH'
        '9. IIIIIIIIIIIIIIIII'
        '10 JJJJJJJJJJJJJJJJJ'
	  },
	vec2 =
      {
	    '1. aaaaaaaaaaaaaa'
        '2. bbbbbbbbbbbbbb'
        '3. cccccccccccccc'
	  },
	vec3 =
      {
	    '1. 11111111111111'
	    '2. 22222222222222'
	    '3. 33333333333333'
	    '4. 44444444444444'
	 },
	;

vars ww =
	create_scroll_text(
		'ww', copy(vec1), win1, -130, 130, 6, 12, 'yellow', 'blue', '10x20',
		6, 'grey75', 'blue', 'red', 0, ident wstring);

wstring =>
rc_scrollup(ww);
rc_informant_value(ww) =>
wstring =>
rc_scrolldown(ww);
rc_informant_value(ww) =>
wstring =>

rc_scroll_text_strings(ww).dup.datalength =>
rc_insert_strings_scrolltext(ww, vec2, 1, "over");
rc_insert_strings_scrolltext(ww, vec1, 1, "over");
rc_insert_strings_scrolltext(ww, vec2, 8, "over");
rc_insert_strings_scrolltext(ww, vec2, 6, "pushdown");
rc_insert_strings_scrolltext(ww, vec3, 6, "pushdown");
rc_insert_strings_scrolltext(ww, vec2, 9, "over");
rc_insert_strings_scrolltext(ww, vec3, 9, "over");
rc_insert_strings_scrolltext(ww, vec3, 1, "pushdown");
rc_insert_strings_scrolltext(ww, vec3, 9, "pushdown");
rc_insert_strings_scrolltext(ww, vec2, 9, "pushdown");
rc_insert_strings_scrolltext(ww, vec2, 14, "pushdown");
rc_insert_strings_scrolltext(ww, vec2, 1, "pushdown");
rc_insert_strings_scrolltext(ww, vec2, 13, "over");
rc_insert_strings_scrolltext(ww, vec2, 1, "pushup");
rc_insert_strings_scrolltext(ww, {'neww4'}, 10, "pushup");
rc_insert_strings_scrolltext(ww, {'newA' 'newB'}, 10, "pushup");
rc_insert_strings_scrolltext(ww, {'newA' 'newB'}, 8, "pushup");
rc_insert_strings_scrolltext(ww, {'neww5'}, 11, "pushup");
rc_insert_strings_scrolltext(ww, {'neww4' 'new5' 'new6'}, 2, "pushup");
rc_insert_strings_scrolltext(ww, vec2, 7, "pushup");
rc_insert_strings_scrolltext(ww, vec3, 10, "pushup");
rc_insert_strings_scrolltext(ww, vec3, "end", "pushup");
rc_insert_strings_scrolltext(ww, vec2, "end", "pushup");
rc_insert_strings_scrolltext(ww, vec1, "start", "pushup");
*/

section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses objectclass;
uses rclib
uses rc_scrolltext


define :method vars rc_insert_strings_scrolltext(obj:rc_scroll_text, strings, loc, mode);

	lvars
		oldval = rc_informant_value(obj),
		vec = rc_scroll_text_strings(obj),
		len = datalength(vec),
		num = length(strings),
		rows = rc_scroll_text_numrows(obj),
		start =
			;;; where to insert strings
			if loc == "start" then 1 ->> loc
			elseif loc == "end" then len - num + 1 ->> loc
			elseif isinteger(loc) then loc
			else
				mishap('NEED "start" OR "end" OR INTEGER', [%loc, strings, obj%])
			endif;

	checkinteger(start, 1, len+1);

	;;; see if new strings will fit, or if vector needs to be extended
	if mode == "over" or mode == "pushup" then
		if loc + num > len then
			consvector(
				explode(vec),
					repeat (loc+num-1)-len times nullstring endrepeat,
						loc+num-1) -> vec;
			loc+num-1 -> len;
			vec -> rc_scroll_text_strings(obj);
		endif;
	else
		;;; must extend vector
		consvector(explode(vec), repeat num times nullstring endrepeat, len+num) -> vec;
		len + num -> len;
		vec -> rc_scroll_text_strings(obj);
	endif;

	if mode == "over" then
		move_subvector(1, strings, start, vec, num);
	elseif mode == "pushup" then
		if start == 1 then
			;;; just overwrite num
		elseif start <= num then
			;;; push up num - start items			
			move_subvector(num+1, vec, 1, vec, start);
		else
			;;; start > num
			move_subvector(num+1, vec, 1, vec, start-1);
		endif;
	elseif mode == "pushdown" then
		move_subvector(start, vec, start+num, vec, len - start - num + 1);
	else
		mishap('UNKNOWN MODE ARG', [^mode])
	endif;
	move_subvector(1, strings, start, vec, num);
	lvars
		row_slider = rc_scroll_row_slider(obj),
		range = rc_slider_range(row_slider);

	max(1, len-rows + 1) -> back(range);
	;;; make sure informant contents up to date
	lvars
		new_index = rc_scroll_text_rowoffset(obj) + rc_slider_value(rc_scroll_select_slider(obj)),
		new_val = vec(new_index);
	
	unless new_val == oldval then
		new_index -> rc_informant_value(obj);
	endunless;
	rc_scrolltext_refresh(obj, 1, len);

	;;; [NEWVEC ^vec ^len] =>
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 27 2002
		fixed symbolic values for loc: "tart" and "end"
 */
