/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_add_kill_button.p
 > Purpose:			Add a "KILL" button to a window object
 > Author:          Aaron Sloman, Sep  2 2000
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RC_WINDOW_OBJECT
 */
/*

;;; tests
vars w0 = rc_new_window_object(800,20,300,250,{100 100 0.75 -0.25},'w0');
vars w0 = rc_new_window_object(800,20,300,250,{100 500 0.75 -0.25},'w0');
vars w0 = rc_new_window_object(800,20,300,250,true,'w0');

rc_add_kill_button(w0, false, false, 32, 20)
rc_add_kill_button(w0, 40, 1220, 40, 20);
rc_add_kill_button(w0, 40, 20, 40, 20 );
rc_add_kill_button(w0, 0, 0, 40, 20 );

'12x24' -> rc_kill_button_font;
rc_add_kill_button(w0, 0, false, 60, 40 );

*/

section;

compile_mode :pop11 +strict;

uses rclib
uses rc_window_object
uses rc_buttons
uses rc_defaults

define :rc_defaults;
	;;; default colours and font for the Kill button
	rc_kill_button_text_col = 'black';
	rc_kill_button_bg_col = 'white';
	rc_kill_button_font = '6x13';

enddefine;

define rc_add_kill_button(win, x, y, buttonwidth, buttonheight);
	;;; assume window produced by rc_new_window_object
	;;; if x is false use right edge of window
	;;; if y is false us bottom edge of window

	lconstant buttonspec = {textbg 'white' textfg 'black' font '6x13'};
	rc_kill_button_bg_col -> buttonspec(2);
	rc_kill_button_text_col -> buttonspec(4);
	rc_kill_button_font -> buttonspec(6);

	lvars
		(_,_,xmax,ymax) = explode(rc_screen_frame(win)),

		(xorigin,yorigin,xscale,yscale) = explode(rc_window_origin(win));


		unless x then
			(xmax-xorigin-buttonwidth)/xscale -> x;
		endunless;

		unless y then
			(ymax-yorigin-buttonheight)/yscale -> y
		endunless;

        create_rc_button(
			x, y, buttonwidth, buttonheight,
          	['KILL' rc_kill_panel], "action", buttonspec) ->;

enddefine;	

endsection;
