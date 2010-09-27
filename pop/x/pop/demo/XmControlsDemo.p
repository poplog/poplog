/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XmControlsDemo.p
 > Purpose:			Display Motif controls
 > Author:          Jonathan Meyer, Feb 16 1991
 > Documentation:	TEACH *XmDemos
 > Related Files:	LIB *XmDemoUtils
 */

section;

uses popxdemo;
uses XmDemoUtils;

vars control_palette = false;

define new_control_palette;
	lvars rowcol mp;
	NewShell('Motif Controls') -> control_palette;
	XtCreateManagedWidget('rowcol', RowColumnWidget, control_palette,
				XptArgList([])) -> rowcol;

	CaptionedWidget('Label:', LabelWidget, rowcol,
				[{labelString 'label'}]);
	CaptionedWidget('PushButton:', PushButtonWidget, rowcol,
				[{labelString 'label'}]);
	CaptionedWidget('DrawnButton:', DrawnButtonWidget, rowcol,
				[{width 20}]);
	CaptionedWidget('ToggleButton:', ToggleButtonWidget, rowcol,
				[{labelString 'label'}]);
	CaptionedWidget('Radio Button:', ToggleButtonWidget, rowcol,
				[{indicatorType ^XmONE_OF_MANY}{labelString 'label'}]);

	;;; Option menu
	XmCreatePulldownMenu(rowcol, 'menu_pane', XptArgList([])) -> mp;
	XtManageChild(XmCreatePushButton(mp, 'one', XptArgList([])));
	XtManageChild(XmCreatePushButton(mp, 'two', XptArgList([])));
	CaptionedWidget('Option Menu:', RowColumnWidget, rowcol,[
			{labelString 'label'}{rowColumnType ^XmMENU_OPTION}{subMenuId ^mp}]);

	CaptionedWidget('ArrowButton:', ArrowButtonWidget, rowcol, []);
	CaptionedWidget('Separator:', SeparatorWidget, rowcol,
				[{width 90}]);
	CaptionedWidget('ScrollBar:', ScrollBarWidget, rowcol,
				[{orientation ^XmHORIZONTAL}]);
	CaptionedWidget('Scale:', ScaleWidget, rowcol,
				[{orientation ^XmHORIZONTAL}]);
	XtRealizeWidget(control_palette);
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
	XmDemo <> init_control_palette  -> XmDemo;
endif;

endsection;
