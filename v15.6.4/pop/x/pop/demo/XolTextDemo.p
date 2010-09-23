/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XolTextDemo.p
 > Purpose:         Demonstrates text widgets for Xol
 > Author:          Jonathan Meyer, Dec  5 1990 (see revisions)
 > Documentation:   HELP *OPENLOOK TEACH *OPENLOOK
 > Related Files:   XolSamplerDemo.p XolTutorial.p
 */

uses XolDemoUtils.p;

section ; ;;; $-xol_demo;


/*************************************************************************
 * Text Palette
 *************************************************************************/

vars
	text_palette = false,
	tcontrols, tcommands, list_item1, list_item2;

define new_text_palette();

	XtVaCreatePopupShell('Open Look Text Palette', PopupWindowShellWidget, demomenu,
		XptVaArgList([])) -> text_palette;

	XptValue(text_palette, XtN upperControlArea, TYPESPEC(:XptWidget)) -> tcontrols;
	XptValue(text_palette, XtN lowerControlArea, TYPESPEC(:XptWidget)) -> tcommands;

	OL_FIXEDCOLS -> XptValue(tcontrols, XtN layoutType, "short");
	true -> XptValue(tcontrols, XtN traversalManager, TYPESPEC(:XptBoolean));

	[{traversalOn ^true}] -> caption_args;

	CaptionedWidget('Static Text: ', StaticTextWidget, tcontrols, [%consXptArgPtr(XtN string,'"statictext"')%]);
	CaptionedWidget('Text Editor: ', TextEditWidget, tcontrols, [{height 25} %consXptArgPtr(XtN string,'"text"')%]);
	CaptionedWidget('TextField 1: ', TextFieldWidget, tcontrols, []);
	CaptionedWidget('TextField 2: ', TextFieldWidget, tcontrols, []);
	CaptionedWidget('ScrollingList: ', ScrollingListWidget, tcontrols, [{viewHeight 1}]);

	;;; add an item to the scrolling list:
	['list item 1' 'list item 2'] -> XpolListItems(generic_widget);

	;;; Popuplate lower text area
	XtCreateManagedWidget('Dismiss',OblongButtonWidget, tcommands,
		XptArgList([])) -> generic_widget;
	XtRealizeWidget(text_palette);
	XtPopup(text_palette, 0);
enddefine;


lvars text_palette_init_done = false;
define init_text_palette();
	returnif(text_palette_init_done);
	new_demomenu_entry('Text Controls', #_< identof("text_palette") >_#,
			new_text_palette);
	true -> text_palette_init_done;
enddefine;

if toplevel then
	init_text_palette()
else
	XolDemo <> init_text_palette -> XolDemo;
endif;

endsection;

/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Aug  7 1992
		Uses TextEditWidget rather than the obsolete TextWidget
--- Adrian Howard, Oct 31 1991 : Changed to use -XptArgPtr-.
--- Jonathan Meyer, Jun 28 1991
		Changed to use XpolListItems
--- Jonathan Meyer, Jun  5 1991 Added extra field to XpolListItem
--- Jonathan Meyer, Feb  6 1991 changed XptOl to Xpol
--- Roger Evans, Feb  5 1991 changed XptValue coercion specifications
 */
