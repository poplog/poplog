/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XolControlsDemo.p
 > Purpose:			Demonstrates basic controls for OpenLook
 > Author:          Jonathan Meyer, Dec  5 1990 (see revisions)
 > Documentation:	HELP *OPENLOOK TEACH *OPENLOOK
 > Related Files:	XolSamplerDemo.p XolTutorial.p
 */

uses popxdemo;
uses XolDemoUtils.p;

section ; ;;; $-xol_demo;

/*************************************************************************
 * Basic Control Palette
 *************************************************************************/

vars
	control_palette = false,
;
;;; procedure to make the control palette
define new_control_palette();
	lvars
		pcontrols	;;; controls in popup window
		pcommands	;;; buttons along bottom of window
	;

	XtVaCreatePopupShell('Open Look Controls Palette', PopupWindowShellWidget, demomenu,
		XptVaArgList([])) -> control_palette;

	XptValue(control_palette, XtN upperControlArea, TYPESPEC(:XptWidget))
			-> pcontrols;
	XptValue(control_palette, XtN lowerControlArea, TYPESPEC(:XptWidget))
			-> pcommands;

	OL_FIXEDCOLS -> XptValue(pcontrols, XtN layoutType, "short");
	[] -> caption_args;

	CaptionedWidget('Button: ', ButtonWidget, pcontrols, []);
	CaptionedWidget('OblongButton: ', OblongButtonWidget, pcontrols, []);
	CaptionedWidget('RectButton: ', RectButtonWidget, pcontrols, []);
	CaptionedWidget('CheckBox: ', CheckBoxWidget, pcontrols, [{foreground 'black'}]);
	CaptionedWidget('Arrow: ', ArrowWidget, pcontrols, []);
	CaptionedWidget('AbbrevMenuButton: ', AbbrevMenuButtonWidget, pcontrols, []);
	CaptionedWidget('MenuButton: ', MenuButtonWidget, pcontrols, []);
	CaptionedWidget('Scrollbar: ', ScrollbarWidget, pcontrols,[
				{orientation ^OL_HORIZONTAL}{width 200} {proportionLength 1}]);
	CaptionedWidget('Slider: ', SliderWidget, pcontrols,[
				{orientation ^OL_HORIZONTAL}{width 200}]);

	;;; Popuplate lower control area
	XtCreateManagedWidget('Dismiss',OblongButtonWidget, pcommands,
		XptArgList([])) -> generic_widget;

	XtRealizeWidget(control_palette);
	XtPopup(control_palette, 0);
enddefine;

;;; procedure to add option to demo menu
lvars control_palette_init_done = false;
define init_control_palette();

	returnif(control_palette_init_done);
	new_demomenu_entry('Basic Controls',
		#_< identof("control_palette") >_#, new_control_palette);
	true -> control_palette_init_done;
enddefine;


if toplevel then
	;;; already running demos - start up now
	init_control_palette()
else
	;;; start up when XolDemo is called
	XolDemo <> init_control_palette  -> XolDemo;
endif;

endsection;

/* --- Revision History ---------------------------------------------------
--- Roger Evans, Feb  5 1991 changed XptValue coercion specifications
--- Jonathan Meyer, Jan 29 1991
		Removed redundant scrollbar callback code, added comments
 */
