/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_new_graphic_widget.p
 > Purpose:         Create a new graphic widget without necessarily
					displaying it.
 > Author:          Aaron Sloman, Jan 14 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

uses-now popxlib;

section;
exload_batch;

include xpt_constants.ph;
include xpt_coretypes.ph;
uses xt_widget;
uses XpwGraphic;
uses rc_graphic


define lconstant XptNewWin(name, size, args, class, shellargs) -> widget;
	;;; Based on XptNewWindow, but simplified, and does not show
	;;; the widget
	lvars	argstring, shell, l, shellname;

	name sys_>< '_shell' -> shellname;

	unless XptDefaultDisplay then XptDefaultSetup(); endunless;

	[%  {geometry ^(XptGeometrySpec(size))},
		{title ^name},
		{iconName ^name},
		{allowShellResize ^true}
	%] nc_<> shellargs -> shellargs;

	XtAppCreateShell(shellname, XT_POPLOG_CLASSNAME,
		xtApplicationShellWidget,XptDefaultDisplay,
		XptArgList(shellargs)
	) -> shell;

	XtCreateManagedWidget(name, class, shell,
		XptArgList([% if size then
						{height ^(size(1))}, {width ^(size(2))}
					  endif
					%] nc_<> args)
	) -> widget;
;;; 	XtRealizeWidget(shell);
;;; 	syssleep(5);
;;; 	XptSyncDisplay(XtDisplay(shell));
;;; 	syssleep(5);
;;; 	XptSyncDisplay(XtDisplay(shell));
;;; 	XtUnrealizeWidget(shell);

enddefine;


global vars rc_wm_input = false;

define rc_new_graphic_widget(title, width, height, xloc, yloc, setframe);

	lconstant sizevec = initv(4); ;;; re-usable input vector
	lconstant input_arg_vector = {input ^(not(not(rc_wm_input)))};  ;;;thanks to jonm

	lvars old = false;
	if XptIsLiveType(rc_window, "Widget") then
		rc_window -> old;
	endif;

	width -> rc_window_xsize;
	height ->rc_window_ysize;
	xloc -> rc_window_x;
	yloc -> rc_window_y;

	if setframe then
		;;; set clipping boundary to frame
		0 ->> rc_xmin -> rc_ymin;
		width -> rc_xmax; height -> rc_ymax;

		;;; set origin in middle of window, y increasing upwards
		rc_set_coordinates(
			rc_window_xsize >> 1, rc_window_ysize >> 1, 1, -1);

		0 ->> rc_xposition ->> rc_yposition -> rc_heading;
	endif;

	XptNewWin(
		title,
		fill(width, height, xloc, yloc, sizevec),
		[],
		xpwGraphicWidget,
		[^input_arg_vector]
		) -> rc_window;

enddefine;

endexload_batch;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 30 1997
	Made it not show the widget
 */
