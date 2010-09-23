/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XolDemoUtils.p
 > Purpose:         Sets up Poplog to work with Xol demos
 > Author:          Jonathan Meyer, Dec  6 1990 (see revisions)
 > Documentation:
 > Related Files:
 */

uses popxdemo;

section ; ;;; $-xol_demo => XolDemo;

max(popmemlim, 400000) -> popmemlim;

exload_batch;

;;; load OpenLook widgetset
XptLoadWidgetSet("OpenLook");

;;; load support libraries
uses xt_widget;
uses xt_widgetinfo;
uses xt_widgetclass;
uses xt_popup;
uses xt_callback;
uses xt_resource;
uses xt_event;

endexload_batch;

#_IF not(DEF AbbrevMenuButtonWidget)

;;; Declare every widget in the OpenLook widget set as a global constant
;;; of the same name.

lvars i, ws = XptWidgetSet("OpenLook");

for i in ws("WidgetSetMembers") do
	pop11_define_declare(i, sysGLOBAL, sysCONSTANT, 0);
	sysPASSIGN(ws(i), i);
endfor;

#_ENDIF

loadinclude xt_constants.ph;

vars active demomenu;

/*************************************************************************
 * Some Utility Procedures
 *************************************************************************/

;;; active variable: generic_widget
;;; useful for repeatedly creating a widget & making a few references to it.
;;;	Widgets are remembered in a list.

vars last_generic_widget, generic_widgets = [];

define active generic_widget;
	last_generic_widget;
enddefine;

define updaterof active generic_widget(widget);
	widget ->> last_generic_widget, :: generic_widgets -> generic_widgets;
enddefine;


;;; procedure: output(string)
;;; 	output from all callbacks is sent to a ved buffer using this proc

lvars tmpfile = false;
define output(fstring);
	lvars fstring;
	dlocal cucharout;
	if vedediting then
		unless tmpfile then systmpfile(false, 'XolSampler', '') -> tmpfile; endunless;
		vededitor(vedveddefaults, tmpfile);
		false -> vedwriteable;
		vedendfile();
		vedcharinsert -> cucharout;
	endif;
	printf(fstring,'%s\n');
enddefine;

;;; active variable: iscolour
;;;		Returns true if the top level shell is connected to a color display

vars toplevel = false;

vars screen_depth = false;
define active iscolour;
	unless screen_depth then
		fast_XptValue(toplevel, XtN depth) -> screen_depth;
	endunless;
	screen_depth fi_> 1;
enddefine;


vars
	caption_args = [],
;

;;; procedure CaptionedWidget:
;;; 	make a widget with a caption on its left

define CaptionedWidget(title, class, parent, args);
	lvars title class parent args;
	lconstant wargs = [1 2];
	XtCreateManagedWidget(title, CaptionWidget, parent,
		XptArgList([])) -> generic_widget;
	args -> wargs(1); caption_args -> wargs(2);
	XtVaCreateManagedWidget('"label"', class, generic_widget,
		XptVaArgList(wargs)) -> generic_widget;
enddefine;


;;; active variable: demomenu
;;; creates a new top level shell the first time it is accessed.
;;; the demomenu lists currently loaded demos

lvars menu menutitle;
define active demomenu;
	unless toplevel then
		;;; start up the demo menu
		XpolDefaultSetup();
		XtAppCreateShell('OpenLook Demo Menu', 'Demo', BaseWindowShellWidget,
			XptDefaultDisplay, XptArgList([{labelJustify ^OL_CENTER }])) -> toplevel;
		XtCreateManagedWidget('demos', ControlAreaWidget, toplevel,
			XptArgList([{layoutType ^OL_FIXEDCOLS}])) -> menu;
		XtCreateManagedWidget(' --- Demos --- ', ButtonWidget, menu,
			XptArgList([])) -> menutitle;
		XtRealizeWidget(toplevel);
	endunless;
	menu;
enddefine;

define demomenu_item_callback(w, client, call);
	lvars w, client, call, val;
	unless isXptDescriptor(idval(client(1)) ->>val) and
			is_valid_external_ptr(val) then
		;;; no widget created yet - set a timer to create one shortly
		client(2)();
	else
		;;; widget is created - so we need to map it
		idval(client(1)) -> client;
		if XtIsSubclass(client, PopupWindowShellWidget) then
			XtPopup(client, XtGrabNone);
		else
			XtMapWidget(client);
		endif;
	endunless;
enddefine;

define new_demomenu_entry(name, id, init_proc);
	lvars name, id, init_proc;
	XtCreateManagedWidget(name, OblongButtonWidget, demomenu,
		XptArgList([])) -> generic_widget;
	XtAddCallback(generic_widget, XtN select, demomenu_item_callback,
		{%id, init_proc%});
enddefine;

global constant XolDemoUtils = true;
global vars XolDemo = identfn;

endsection;

/* --- Revision History ---------------------------------------------------
--- Integral Solutions Ltd (Julian Clinton), Jan 10 1994
		Fixed bug in iscolour.
--- Jonathan Meyer, Feb  7 1991 Added better check on menu callback
		so that if a widget dies a new one will be created
--- Jonathan Meyer, Feb  6 1991 Renamed XptOl Xpol
--- Roger Evans, Feb  6 1991 changed output procedure to use a ved buffer
		only if already in ved
--- Jonathan Meyer, Jan 29 1991
		Removed definition of XptCallbackList (moved into library)
 */
