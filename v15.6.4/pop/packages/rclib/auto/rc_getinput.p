/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_getinput.p
 > Purpose:			Get a line of input
 > Author:          Aaron Sloman, May  8 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
vars panel =
	rc_control_panel(400, 10,
		[{width 500}{height 400}
			[ACTIONS {gap 200}:
				[KILL rc_kill_menu]]], 'TEST');


vars instruct =
	['Type your name in'
	'Press return or click'
	'Then press "OK"'];

rc_getinput(600, 300, instruct, 'asdasdfasdfasddf', [], 'Name?')=>
rc_getinput(600, 300, instruct, '', [{font 'r24'}], 'Name?')=>
rc_getinput(600, 300, instruct, '', [{font 'r24'}{width 500}], 'Name?')=>
rc_getinput(600, 300, instruct, '', [{font 'r24'}{width 900}], 'Name?')=>
rc_getinput(600, 300, ['type a number'], 0, [{font '10x20'}], 'A number')=>
rc_getinput(10, 30, instruct, 'hello', [{font '6x13'}], 'Name?', panel)=>

rc_getinput("middle", "bottom", instruct, 'hello', [{font '6x13'}], 'Name?', panel)=>

*/

section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_text_input
uses rc_scrolltext
uses rc_control_panel
uses rc_popup_panel

global vars
	rc_default_textin_width = 300,
	rc_default_numberin_width = 100;
	

define rc_getinput(x, y, strings, prompt, specs, title) -> result;

	lvars container = false, len = stacklength();

	ARGS x, y, strings, prompt, specs, title, &OPTIONAL container:isrc_window_object;
	
	lvars type = if isstring(prompt) then "TEXTIN" else "NUMBERIN" endif;

	lvars width = if type == "TEXTIN" then rc_default_textin_width
					else rc_default_numberin_width endif;

	;;; default value
	prompt -> result;

	dlocal rc_text_length_def = 200;

	;;; Control variable. Exit when it is made non-false.
	lvars done = false;

	define lconstant selection_done;
		lvars text_panel =
			rc_fieldcontents_of(rc_current_query, "textin");

		if rc_text_input_active(text_panel) then
			consolidate_or_activate(text_panel)
		endif;

		true -> done;
	enddefine;

	define lconstant reactor(panel, content);
		selection_done();
	enddefine;

	define lconstant do_cancel();
		false -> result;
		rc_kill_window_object(rc_current_query);
		false -> rc_current_query;
		rc_flush_everything();
		lvars newonstack = stacklength() - len;
		if newonstack > 0 then
			erasenum(newonstack);
		endif;
		exitto(rc_getinput)
	enddefine;

	lvars fields =
		[
		[TEXT : ^^strings ]
		[^type {ident ^(ident result)} {margin 4}
			{label textin}
			{reactor ^reactor}
			;;; {height 30}
			{height ^(rc_text_height_def +8)}
			{width ^width}	;;; may be overridden
			{align centre}
		     ^specs :
			[^prompt]
		]
		[ACTIONS {width 70}:
			['OK' ^selection_done]
			['Cancel' ^do_cancel]]
	];
	rc_popup_panel(x, y, fields, title, ident done, if container then container endif);

	unless done then false -> result endunless;

enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Feb 19 2000
	Fixed stacklength bug, which manifested itself if invoked in a containing
	panel.
--- Aaron Sloman, Aug 10 1999
		Added rc_default_textin_width, rc_default_numberin_width
--- Aaron Sloman, May 23 1999
	Used expanded default height.
--- Aaron Sloman, May 19 1999
	 Allowed optional container argument for parent rc_window_object
 */
