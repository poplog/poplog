/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XmTextDemo.p
 > Purpose:			Demonstrates Motif Text widgets
 > Author:          Jonathan Meyer, Feb 16 1991
 > Documentation:	TEACH *XmDemos
 > Related Files:	LIB *XmDemos, LIB *XmDemoUtils
 */


section;

uses popxdemo;
uses XmDemoUtils;

vars text_palette = false;

define new_text_palette();
	NewShell('Text Controls') -> text_palette;
	XtCreateManagedWidget('rowcol', RowColumnWidget, text_palette,
		XptArgList([])) -> rowcol;

	CaptionedWidget('TextField:', TextFieldWidget, rowcol, [{labelString 'label'}]);

	CaptionedWidget('TextEditor:', ScrolledWindowWidget, rowcol, [
				{height 1}]);
	XtCreateManagedWidget('Text Editor:', TextWidget, captioned_widget,
		XptArgList([
			{editMode ^XmMULTI_LINE_EDIT}
			{wordWrap ^true}
			{scrollVertical ^true}
			{rows 2}]))->;

	vars list_items = consXpmStringTable( #|
		XmStringCreateLtoR('item 1\(0)', XmSTRING_DEFAULT_CHARSET),
		XmStringCreateLtoR('item 2\(0)', XmSTRING_DEFAULT_CHARSET),
		XmStringCreateLtoR('item 3\(0)', XmSTRING_DEFAULT_CHARSET),
		XmStringCreateLtoR('item 4\(0)', XmSTRING_DEFAULT_CHARSET),
		|#);

	CaptionedWidget('List:', ListWidget, rowcol,[
		{items ^list_items}{itemCount 2}{visibleItemCount 2}]);

	CaptionedWidget('Scrolling List:', ScrolledWindowWidget, rowcol, [
				{height 1}]);
	XtCreateManagedWidget('list', ListWidget, captioned_widget,
			XptArgList([
				{items ^list_items}{itemCount 4}{visibleItemCount 3}]))->;

	XtRealizeWidget(text_palette);
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
	XmDemo <> init_text_palette -> XmDemo;
endif;

endsection;
