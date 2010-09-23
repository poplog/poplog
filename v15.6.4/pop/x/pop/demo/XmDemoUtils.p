/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XmDemoUtils.p
 > Purpose:         Sets up Poplog to work with Motif demos
 > Author:          Jonathan Meyer, Dec  6 1990 (see revisions)
 > Documentation:	TEACH *XmDemos
 > Related Files:	LIB *XmDemos, XmControlsDemo, XmDialogsDemo, XmTextDemo
 */

uses popxdemo;

section ; ;;; $-xol_demo => XolDemo;

max(popmemlim, 400000) -> popmemlim;

exload_batch;

include xdefs;

;;; load Motif widgetset
XptLoadWidgetSet("Motif");
vars ws = XptWidgetSet("Motif");
XptLoadWidgetSet("Toolkit");
vars ws1 = XptWidgetSet("Toolkit");

;;; load support libraries
uses xt_widget;
uses xt_widgetinfo;
uses xt_widgetclass;
uses xt_popup;
uses xt_callback;
uses xt_resource;
uses xt_event;
uses xt_composite;

endexload_batch;

;;; Declare every widget in the widget set as a global constant
;;; of the same name.

lvars i;
for i in ws("WidgetSetMembers") do
	pop11_define_declare(i, sysGLOBAL, sysCONSTANT, 0);
	sysPASSIGN(ws(i), i);
endfor;

for i in ws1("WidgetSetMembers") do
	pop11_define_declare(i, sysGLOBAL, sysCONSTANT, 0);
	sysPASSIGN(ws1(i), i);
endfor;

loadinclude xt_constants.ph;

vars toplevel = false, active demomenu;

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
		unless tmpfile then systmpfile(false, 'XmDemo', '') -> tmpfile; endunless;
		vededitor(vedveddefaults, tmpfile);
		false -> vedwriteable;
		vedendfile();
		vedcharinsert -> cucharout;
	endif;
	printf(fstring,'%s\n');

enddefine;

;;; active variable: iscolour
;;;		Returns true if the top level shell is connected to a color display

vars screen_depth = false;
define active iscolour;
	unless screen_depth then
		fast_XptValue(toplevel, XtN depth) -> screen_depth;
	endunless;
	screen_depth fi_> 1;
enddefine;

;;; procedure CaptionedWidget:
;;; 	make a widget with a caption on its left

vars captioned_widget;
define CaptionedWidget(title, class, parent, args);
	lvars title class parent args;
	vars rowcol label w;

	XtVaCreateManagedWidget('rowcol', RowColumnWidget, parent,
		XptVaArgList([
				{isAligned ^true}
				{entryAlignment ^XmALIGNMENT_END}
				{resizeWidth ^true}
				{orientation ^XmHORIZONTAL}])) -> rowcol;
	XtVaCreateManagedWidget('label', LabelGadget, rowcol,
			XptVaArgList([
				{recomputeSize ^false}
				{width 100}
				{traversalOn ^false}
				{labelString ^title}])) -> label;
	XtVaCreateManagedWidget('widget', class, rowcol, XptVaArgList(args)) ->
		captioned_widget;
enddefine;

;;; NewShell - create a new top level shell
define NewShell(name);
	lvars name class;
	unless name.isstring then
		(,name) -> (name, class);
	else
		XptWidgetSet("Toolkit")("ApplicationShellWidget") -> class;
	endunless;
	XtAppCreateShell(name, 'Demo', class, XptDefaultDisplay, XptArgList([]))
enddefine;


;;; active variable: demomenu
;;; creates a new top level shell the first time it is accessed.
;;; the demomenu lists currently loaded demos

lvars menu menutitle;
define active demomenu;
	unless toplevel then
		;;; start up the demo menu
		XptDefaultSetup();
		NewShell('Poplog Motif') -> toplevel;
		XtCreateManagedWidget('menu', RowColumnWidget, toplevel,
			XptArgList([
				{isAligned ^true}
				{entryAlignment ^XmALIGNMENT_CENTER}
				{orientation ^XmVERTICAL}])) -> menu;
		XtVaCreateManagedWidget('label', LabelGadget, menu,
			XptVaArgList([
				{recomputeSize ^false}
				{alignment ^XmALIGNMENT_CENTER}
				{traversalOn ^false}
				{labelString 'Motif Widgets'}])) -> ;
		XtCreateManagedWidget('separator', SeparatorWidget, menu,
			XptArgList([ {width 200}])) ->;

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
		XtMapWidget(client);
	endunless;
enddefine;

define new_demomenu_entry(name, id, init_proc);
	lvars name, id, init_proc;
	XtCreateManagedWidget(name, PushButtonWidget, demomenu,
		XptArgList([])) -> generic_widget;
	XtAddCallback(generic_widget, XtN activateCallback, demomenu_item_callback,
		{%id, init_proc%});
enddefine;

global constant XmDemoUtils = true;
global vars XmDemo = identfn;


endsection;

/* --- Revision History ---------------------------------------------------
--- Jonathan Meyer, Feb 16 1991 Fixed toplevel declaration
 */
