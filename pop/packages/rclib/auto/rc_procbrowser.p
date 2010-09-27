/* --- Copyright University of Birmingham 2005. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_procbrowser.p
 > Purpose:			Browsing, marking, compiling procedures in current VED file
 > Author:          Aaron Sloman, Aug 28 1999 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RC_CONTROL_PANEL, VED_HEADERS, MENU COMPILING
 > 					LIB RC_LISPBROWSER
 */


section;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib

uses rc_defaults

uses rc_display_strings



define :rc_defaults ;

	;;; Some users may prefer a bigger or smaller default font
	rc_procbrowser_button_font = '*lucida*-r-*sans-10*';
	rc_procbrowser_button_width = 105;
	rc_procbrowser_scroll_columns = 55;
	rc_procbrowser_scroll_rows = 15;
	rc_procbrowser_scroll_font = '7x13';
	rc_procbrowser_text_font = '*lucida*-r-*sans-12*';

enddefine;


lconstant
	;;; used for line numbers in pad_print
	padstring1 = '00 ',
	padstring2 = '000 ',
	padstring3 = '0000 ',
	padstring4 = '00000 ';

lvars padstring, padlen = 0;

define lconstant pad_print(num, string) -> string;

	lvars index = 1;

	define dlocal cucharout(char);
		char -> subscrs(index, string);
		index fi_+ 1 -> index;
	enddefine;

	syspr(num);

	;;; fill the rest of the string with spaces
	lvars len = datalength(string);

	until index > len do
		`\s` -> subscrs(index, string);
		index fi_+ 1 -> index;
	enduntil;

enddefine;

;;; Stuff from Birmingham LIB VED_HEADERS
define lconstant getheaders() -> vec;
	lvars
		index,
		string,
		lim = vvedbuffersize;

	if lim <= 99 then padstring1
	elseif lim <= 999 then padstring2
	elseif lim <= 9999 then padstring3
	elseif lim <= 99999 then padstring4
	else
		;;; Very unlikely. Make a new string
		inits(intof(log10(lim)+2))
	endif -> padstring;

	datalength(padstring) -> padlen;


	{%
		for index from 1 to lim do
			fast_subscrv(index, vedbuffer) -> string;
				lvars col = issubstring('define ', string);

			if col == 1 then
				pad_print(index, padstring) <> veddecodetabs(string)
			elseif col then
				;;; check if there's only white space before 'define'
				lvars num;
				fast_for num from 1 to col fi_- 1 do
					lvars char = fast_subscrs(num, string);
					unless char == `\s` or char == `\t` then
						nextloop(2);
					endunless;
				endfor;
				(pad_print(index, padstring) <>
					consstring(#| repeat col - 1 times `\s` endrepeat |#)) <>
						veddecodetabs(allbutfirst(col-1, string))
			endif;
		endfor
	%} -> vec

enddefine;

define rc_procbrowser();

	lvars
		file = vedcurrentfile,
		filename = sys_fname_name(vedpathname),
		;;; create index to enable going to procedure
		vec = getheaders(),
		line;


	define do_refresh();
		vedcheck();
		if vedusewindows == "x" and not(vedinvedprocess) then
			vedinput(vedrefresh);
		else
			vedrefresh();
		endif;
	enddefine;

	define do_go_procedure(refresh);
		edit(file);
		lvars num = strnumber(substring(1, padlen, the_selected_string));
		vedjumpto(num, 1);
		if refresh then do_refresh() endif;
	enddefine;

	define do_compile_procedure();
		do_go_procedure(false);
		menu_vedinput(ved_lcp);
	enddefine;

	define do_find_expression_start();
		repeat
			if vedcolumn > vvedlinesize then vednextline()
			elseif strmember(vedcurrentchar(), '\s\t)]}') then
				vedcharright()
			else
				quitloop()
			endif;
		endrepeat;
	enddefine;

	define do_skip_expression();
		do_find_expression_start();
		;;; Go through the motions of compiling an expression
		;;; Used to find the end of an expression.

		lvars item = vednextitem();

		lconstant declarers =
			[dlocal lvars dlvars lconstant];

		if member(item, declarers) then
            if ved_try_search(';', []) then
				vedcharright();
				do_refresh();
				return();
			endif;
		elseif item == "global" or item == "section" then
			vedmoveitem()->;
			do_refresh();
			return();
		endif;

		dlocal
			pop_syntax_only = true,
			proglist = pdtolist(incharitem(vedrepeater)),
			;;; suppress autoloading
			pop_autoload = false,
			;;; suppress errors due to re-declaration
			pop_debugging = true,
			;;; collect a list of declared variables
			popwarnings = [];

		;;; record automatically declared variables
		define dlocal prwarning(word);
			conspair(word, popwarnings) -> popwarnings;
		enddefine;

		define dlocal prmishap(string, list);
			false -> vedprintingdone;
			lvars err_string = 'POSSIBLE ERROR: ' <> string;
			if vedusewindows == "x" and not(vedinvedprocess) then
				vedinput(vederror(%err_string%));
				;;;interrupt();
			else
				vederror(err_string)
			endif;
		enddefine;


		pop11_comp_expr();

		;;; cancel automatically declared variables
		applist(popwarnings, syscancel);
		do_refresh();
	enddefine;

	define do_mark_expression();
		do_find_expression_start();
		if isstartstring('define', vedthisline()) then
			ved_mcp();
		else
			vedpositionpush();
			vedmarklo();
			do_skip_expression();
			vedmarkhi();
			vedpositionpop();
		endif;
		do_refresh();
	enddefine;

	define do_tidy_expression();
		do_mark_expression();
		ved_tidy();
		do_refresh();
	enddefine;


	define do_mark_procedure();
		do_go_procedure(false);
		;;; Could be a nested procedure definition
		do_mark_expression();
		do_refresh();
	enddefine;

	define do_tidy_procedure();
		do_go_procedure(false);
		if isstartstring('define', vedthisline()) then
			ved_jcp();
		else
			do_mark_expression();
			ved_tidy()
		endif;
		do_refresh();
	enddefine;


	define default_acceptor(obj, val, item);
		;;; The procedure invoked by the "acceptor" mechanism, e.g.
		;;; double click, or RETURN in scrolling window.
		val -> the_selected_string;
		do_go_procedure(true);
	enddefine;

	lvars panel_fields =
		[
			[ACTIONS {cols 4} {width ^rc_procbrowser_button_width}
			{font ^rc_procbrowser_button_font}:
				['UpHalfWin' [POP11 menu_do_scroll(-1, "vert")]]
				['DownHalfWin' [POP11 menu_do_scroll(1, "vert")]]
				['PrevScreen' vedprevscreen]
				['NextScreen' vednextscreen]
				['Prev "define"' ^(veddo(%'`define'%)) ]
				['Next "define"' ^(veddo(%'"define'%)) ]
				['Next Expression' ^do_skip_expression]
				['Mark Expression' ^do_mark_expression ]
				['Tidy Expression' ^do_tidy_expression]
				['DEL Expression' ^(do_mark_expression<>ved_d)]
				['DEL Marked' ^(do_mark_expression<>ved_d)]
				['Yank' ved_y]
				['Mark Current' ved_mcp]
				['Compile Current' ved_lcp]
				['SaveFile' ved_w1]
				['RE-INDEX' [POP11 rc_kill_panel();chain(rc_procbrowser)]]
				['Go to It' ^(do_go_procedure(%true%))]
				['Compile It' ^do_compile_procedure]
				['Mark It' ^do_mark_procedure]
				['Tidy It' ^do_tidy_procedure]
			]

			[TEXT {font ^rc_procbrowser_text_font }:
				'Edit required program file then click on RE-INDEX.'
				'Select item on scrolling list below.'
				'Then click on button(s) above. "It" = selected item.'
				'"Current" = procedure where cursor is.'
			]
		],

	scroll_specs =
		[{font ^rc_procbrowser_scroll_font }
			{cols ^rc_procbrowser_scroll_columns }
			{rows ^rc_procbrowser_scroll_rows }
			{acceptor ^default_acceptor}] ;

	rc_display_strings(
		"right", "top", vec, panel_fields,
			false, false,
			rc_procbrowser_scroll_rows, rc_procbrowser_scroll_columns,
			scroll_specs, filename) ->;


enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 15 2005
		Added new global variable
			rc_procbrowser_scroll_rows = 15;
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Sep  6 2002
		Minor change in use of vedinput
--- Aaron Sloman, Sep 14 1999
	Some extra buttons. Slightly improved error handling in expression
	reader.
--- Aaron Sloman, Sep 13 1999
	Introduced use of rc_defaults, and user-assignable variables
	rc_procbrowser_button_font
	rc_procbrowser_button_width
	rc_procbrowser_scroll_columns
	rc_procbrowser_scroll_font
	rc_procbrowser_text_font
--- Aaron Sloman, Sep  3 1999
	Improved text and button labels. Still more to be done.
 */
