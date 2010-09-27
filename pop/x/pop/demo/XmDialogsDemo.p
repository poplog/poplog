/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            C.x/x/pop/demo/XmDialogsDemo.p
 > Purpose:			Demonstrate Motif dialog boxes
 > Author:          Jonathan Meyer, Feb 13 1991 (see revisions)
 > Documentation:	TEACH *XmDemos
 > Related Files:	LIB *XmDemos, LIB *XmDemoUtils
 */

/*
This file is based very closely on the C motif demo program, xmdialogs.c.

Changes:

	fixed bug in callback for help item
	Changed long arglists to use XptArgList
	Made procedures all share a single arglist

*/

section;

uses popxdemo;
uses XmDemoUtils;


/* DECLARATIONS */

vars procedure (
	CreateMenuBar,
	CreateSelectionBox,
	CreateWorkArea,
	CreateDialogBox,
	SetItem,
	CreateItem,
	GetItemArgList
);

constant macro (
		 MENU_HELP		         =200,
		 MENU_EXIT		         =201,
		 MENU_RESET		         =202,

		 DIALOG_ALLOW_OVERLAP	 =300,
		 DIALOG_AUTO_UNMANAGE	 =301,
		 DIALOG_DEFAULT_POSITION =302,
		 DIALOG_CREATE		     =303,
		 DIALOG_DESTROY		     =304,
		 DIALOG_MANAGE		     =305,
		 DIALOG_UNMANAGE	     =306,

		 BULLETIN_BOARD		     =1,
		 COMMAND			     =3,
		 FILE_SELECTION_BOX	     =5,
		 FORM			         =7,
		 MESSAGE_BOX	         =10,
		 SELECTION_BOX		     =14,

		 NUM_ITEMS		         =17,
);

vars

	;;; top level widgets
	shell_parent,
	dialog_shell = false,

	;;; work area widgets
	work_area_toggle,
	modeless_toggle,
	application_modal_toggle,
	system_modal_toggle,
	auto_unmanage_toggle,
	default_position_toggle,
	create_button,
	destroy_button,
	manage_button,
	unmanage_button,

	;;; current item
	selected_item_index,
	selected_item_is_dialog = true,

	;;; procs to create new dialogs
	create_procs,

	;;; resize policy for dialogs
	resize_policy = XmRESIZE_ANY,
;

constant
	;;; currently built dialog widgets
	dialog = initvectorclass(NUM_ITEMS, false, vector_key),

	;;; titles of items in work area list
	item = {
			'bulletin board'
			'bulletin board dialog'
			'command'
			'error dialog'
			'file selection box'
			'file selection dialog'
			'form'
			'form dialog'
			'information dialog'
			'message box'
			'message dialog'
			'prompt dialog'
			'question dialog'
			'selection box'
			'selection dialog'
			'warning dialog'
			'working dialog'
		},

		;;; pre-built arglist
		arglist = initXptArgList(12),
;

/* CALLBACK HANDLERS */

define MenuCB(w, client_data, call_data);
	lvars w, client_data, call_data;

	switchon client_data

	case == MENU_EXIT then
		output('exiting');
		XtDestroyWidget(dialog_shell);
		;;; exit
	case == MENU_HELP then
		output('help requested');
	case == MENU_RESET then
		output('reset');
	else
		output('unexpected tag in MenuCB');
	endswitchon
enddefine;

define ResizeCB(w, client_data, call_data);
	lvars w, client_data, call_data;
	client_data -> resize_policy;
enddefine;

define ListCB(w, client_data, call_data);
	lvars w, client_data, call_data;
	SetItem(exacc :XmListCallbackStruct call_data.item_position);
enddefine;

define DestroyCB(w, client_data, call_data);
	XtDestroyWidget(XtParent(w));
enddefine;

define WorkAreaCB(w, client_data, call_data);
	lvars w, client_data, call_data, index = selected_item_index,
		dialog_widget = dialog(index);
	switchon client_data ==
	case DIALOG_CREATE then
		if dialog_widget then XtDestroyWidget(dialog_widget) endif;
		CreateItem(index);
	case DIALOG_DESTROY then
		if dialog_widget and is_valid_external_ptr(dialog_widget) then
			XtUnmanageChild(dialog_widget);
			XtDestroyWidget(dialog_widget);
			false -> dialog(index);
		endif;
	case DIALOG_MANAGE then
		unless dialog_widget and is_valid_external_ptr(dialog_widget) then
			CreateItem(index);
		endunless;
		XtManageChild(dialog(index));
	case DIALOG_UNMANAGE then
		if dialog_widget and is_valid_external_ptr(dialog_widget) then
			XtUnmanageChild(dialog_widget);
		endif;
	else
		mishap(0,'unexpected tag in WorkAreaCB');
	endswitchon;
enddefine;


/* MISC PROCS */

;;; SetItem - make a new item in the scrolling list current

define SetItem(index);
	lvars index, new_item_is_dialog = false,
	;
	lconstant non_dialog_items = [
				^BULLETIN_BOARD
				^COMMAND
				^FILE_SELECTION_BOX
				^FORM
				^MESSAGE_BOX
				^SELECTION_BOX
	];
	index -> selected_item_index;
	(fast_lmember(selected_item_index , non_dialog_items) == false)
			-> new_item_is_dialog;
	if new_item_is_dialog /== selected_item_is_dialog then
		XmToggleButtonGadgetSetState (work_area_toggle,
						not(new_item_is_dialog), true);
		XtSetSensitive (work_area_toggle, not(new_item_is_dialog));

		XmToggleButtonGadgetSetState (modeless_toggle,
						new_item_is_dialog, true);
		XtSetSensitive (modeless_toggle, new_item_is_dialog);
		XmToggleButtonGadgetSetState (application_modal_toggle,
						false, true);
		XtSetSensitive (application_modal_toggle, new_item_is_dialog);
		XmToggleButtonGadgetSetState (system_modal_toggle,
						false, true);
		XtSetSensitive (system_modal_toggle, new_item_is_dialog);


		XmToggleButtonGadgetSetState (auto_unmanage_toggle,
						new_item_is_dialog, true);
		XtSetSensitive (auto_unmanage_toggle, new_item_is_dialog);

		XmToggleButtonGadgetSetState (default_position_toggle,
						new_item_is_dialog, true);
		XtSetSensitive (default_position_toggle, new_item_is_dialog);

		XtSetSensitive (manage_button, new_item_is_dialog);
		XtSetSensitive (unmanage_button, new_item_is_dialog);
	endif;
	new_item_is_dialog -> selected_item_is_dialog;
enddefine;

define CreateItem(index);
	lvars index, ac;
	;;; build a new dialog
	lconstant al = arglist;
	GetItemArgList(al) -> ac;
	create_procs(index)(shell_parent, item(index), al, ac) ->>
		->dialog(index);
enddefine;

;;; GetItemArgList - use current settings on form to build an arglist

define GetItemArgList(al) -> ac;
	lvars al ac,
		auto_unmanage = XmToggleButtonGadgetGetState (auto_unmanage_toggle),
		default_position = XmToggleButtonGadgetGetState (default_position_toggle),
		dialog_style, title_string;

	if (XmToggleButtonGadgetGetState(application_modal_toggle)) then
		XmDIALOG_APPLICATION_MODAL -> dialog_style;
	elseif (XmToggleButtonGadgetGetState (system_modal_toggle)) then
		XmDIALOG_SYSTEM_MODAL -> dialog_style;
	elseif (XmToggleButtonGadgetGetState (modeless_toggle)) then
		XmDIALOG_MODELESS -> dialog_style;
	else
		XmDIALOG_WORK_AREA -> dialog_style;
	endif;

	1 	->ac;	dialog_style -> XptSetArg(XmN dialogStyle, al,ac);
	ac+1->ac; 	auto_unmanage -> XptSetArg(XmN autoUnmanage, al,ac);
	ac+1->ac; 	default_position -> XptSetArg(XmN defaultPosition, al,ac);

	XmStringCreateLtoR(item(selected_item_index), XmSTRING_DEFAULT_CHARSET)
		-> title_string;

	ac+1->ac; 	title_string -> XptSetArg(XmN dialogTitle, al,ac);
	ac+1->ac;	resize_policy -> XptSetArg(XmN resizePolicy,  al,ac);
enddefine;


/* WIDGET CREATION PROCEDURES */

;;; Generic procedure for building a dialog box

define CreateDialogBox(parent, name, al, ac);
	lvars parent, name, al, ac, shell, d;
	lconstant args=nc_consXptArgList(#|
			XmN allowShellResize,false,
		|# div 2);

	XtCreatePopupShell('dialog', TopLevelShellWidget, parent,
			args, shadow_length(args)) -> shell;

	;;; copy the al al, adding 1 item
	nc_consXptArgList(
				nc_destXptArgList(al) -> ac,	;;; old al
				nullstring, 0,	;;; additional item
				nullstring, 0,	;;; additional item
				ac+2) -> al;

	switchon selected_item_index ==

	case BULLETIN_BOARD then
			 XmCreateBulletinBoard (shell, name, al, ac);
	case COMMAND then
			ac+1->ac; XmDIALOG_COMMAND -> XptSetArg(XmN dialogType, al, ac);
			XmCreateCommand(shell, name, al, ac);
	case FILE_SELECTION_BOX then
			ac+1->ac; XmDIALOG_FILE_SELECTION -> XptSetArg(XmN dialogType, al, ac);
			XmCreateFileSelectionBox (shell, name, al, ac)
	case FORM then
			ac+1->ac; 50 -> XptSetArg(XmN width, al, ac);
			ac+1->ac; 50 -> XptSetArg(XmN height, al, ac);
			XmCreateForm(shell, name, al, ac);
	case MESSAGE_BOX then
			ac+1->ac; XmDIALOG_MESSAGE -> XptSetArg(XmN dialogType, al, ac);
			XmCreateMessageBox (shell, name, al, ac);
	case SELECTION_BOX then
			ac+1->ac; XmDIALOG_SELECTION -> XptSetArg(XmN dialogType, al, ac);
			XmCreateSelectionBox (shell, name, al, ac);
	else
		mishap(0,'unexpected tag in CreateDialogBox');
	endif -> d;
	XtAddCallback(d, XmN destroyCallback, DestroyCB, false);

	XtManageChild(d);
	XtRealizeWidget(shell);
	XtPopup(shell,XtGrabNone);
	return(d);
enddefine;

;;; Build menu bar with 'Actions' and 'Help' options

define CreateMenuBar(parent);
	lvars parent, menu_bar, cascade, menu_pane, button,
			al = arglist, ac =0;

	XmCreateMenuBar(parent, 'menu_bar', al, ac) -> menu_bar;
	XtManageChild(menu_bar);

	XmCreatePulldownMenu(menu_bar, 'menu_pane', al, ac) -> menu_pane;

	XmCreatePushButton(menu_pane, 'Reset', al, ac) -> button;
	XtAddCallback (button, XmN activateCallback, MenuCB, MENU_RESET);
	XtManageChild (button);

	XmCreatePushButton (menu_pane, 'Exit', al, ac) -> button;
	XtAddCallback (button, XmN activateCallback, MenuCB, MENU_EXIT);
	XtManageChild (button);

	1 ->ac; 	menu_pane -> XptSetArg(XmN subMenuId, al, ac);
	XmCreateCascadeButton(menu_bar, 'Actions', al, ac) -> cascade;
	XtManageChild (cascade);

	0 -> ac;
	XmCreateCascadeButton(menu_bar, 'Help', al, ac) -> cascade;
	XtAddCallback (cascade, XmN activateCallback, MenuCB, MENU_HELP);
	XtManageChild (cascade);

	cascade -> XptValue(menu_bar, XmN menuHelpWidget, TYPESPEC(:XptWidget));

	menu_bar;
enddefine;

;;; Build scrolling list with selection options in it

define CreateSelectionBox(parent);
	lvars parent selection_box list text work_area button frame,
			i, text_value, list_item = initXpmStringTable(NUM_ITEMS),
			charset = XmSTRING_DEFAULT_CHARSET, hsbar, vsbar, pixel_data;

	for i from 1 to NUM_ITEMS do
		XmStringCreateLtoR(item(i), charset) -> list_item(i);
	endfor;

	XmCreateSelectionBox(parent, 'selection_box',
			XptArgList([
					{^XmN shadowThickness 1}
					{^XmN shadowType ^XmSHADOW_OUT}
					{^XmN textString ^(list_item(1))}
					{^XmN listItems ^list_item}
					{^XmN listItemCount ^NUM_ITEMS}
					{^XmN listLabelString
						%XmStringCreateLtoR('Motif Dialog Widgets', charset)%}
					{^XmN selectionLabelString
						%XmStringCreateLtoR('Active Dialog', charset)%}
					])) -> selection_box;

	XmSelectionBoxGetChild(selection_box, XmDIALOG_LIST) -> list;
	XtAddCallback(list, XmN browseSelectionCallback, ListCB, false);
	XtAddCallback (list, XmN defaultActionCallback, ListCB, false);
	list -> shell_parent;

	XmSelectionBoxGetChild (selection_box, XmDIALOG_TEXT) -> text;
	XptValue(XtParent(list), XmN horizontalScrollBar, TYPESPEC(:XptWidget))
			-> hsbar;
	XptValue(XtParent(list), XmN verticalScrollBar, TYPESPEC(:XptWidget))
			-> vsbar;

/* this code was in the C version, but is undocumented
	_XmSelectColorDefault (selection_box, NULL, &pixel_data);
	XtSetArg (al[0], XmNbackground, *((Pixel *) pixel_data.addr));
	XtSetValues (list, al, 1);
	XtSetValues (text, al, 1);
	XtSetValues (hsbar, al, 1);
	XtSetValues (vsbar, al, 1);
*/

	consXptWidgetList( #|
		applist([
			^XmDIALOG_SEPARATOR
			^XmDIALOG_OK_BUTTON
			^XmDIALOG_CANCEL_BUTTON
			^XmDIALOG_APPLY_BUTTON
			^XmDIALOG_HELP_BUTTON
		], procedure(i);
				XmSelectionBoxGetChild(selection_box, i);
			endprocedure)|#)->list;

	XtUnmanageChildren(list, shadow_length(list));
	selection_box;
enddefine;

;;; Build other parts of work area

define CreateWorkArea(parent);
	lvars parent, row_column, menu_pane, box, button, default_button,
		al = arglist, ac,
		list, frame0, frame1, frame2, frame3, w1,w2,w3, h1,h2,h3,label_string;

	0 -> ac;
	XmCreateForm(parent, 'work_area', al, ac) -> box;
	XtManageChild (box);

	XmCreateFrame(box, 'frame', XptArgList([
			{^XmN shadowType ^XmSHADOW_ETCHED_IN}
			{^XmN leftAttachment ^XmATTACH_FORM}
			{^XmN rightAttachment ^XmATTACH_FORM}
			{^XmN topAttachment ^XmATTACH_FORM}
		])) -> frame0;
	XtManageChild(frame0);

	XmCreatePulldownMenu(frame0, 'menu_pane', al, ac) -> menu_pane;

	XmCreatePushButton(menu_pane, 'any', al, ac) -> default_button;
	XtAddCallback (default_button, XmN activateCallback, ResizeCB, XmRESIZE_ANY);
	XtManageChild (default_button);

	XmCreatePushButton(menu_pane, 'grow', al, ac) -> button;
	XtAddCallback (button, XmN activateCallback, ResizeCB, XmRESIZE_GROW);
	XtManageChild (button);

	XmCreatePushButton(menu_pane, 'none', al, ac) -> button;
	XtAddCallback (button, XmN activateCallback, ResizeCB, XmRESIZE_NONE);
	XtManageChild (button);

	XmStringCreateLtoR ('resize policy', XmSTRING_DEFAULT_CHARSET)
		-> label_string;

	XmCreateOptionMenu(frame0, 'row_column1',
		XptArgList([
			{^XmN labelString ^label_string}
			{^XmN menuHistory ^default_button}
			{^XmN subMenuId ^menu_pane}])) -> row_column;
	XtManageChild (row_column);
	XmAddTabGroup (row_column);


	;;; Create RadioBox and dialog style toggles.

	XmCreateFrame (box, 'frame',
			XptArgList([
				{^XmN shadowType ^XmSHADOW_ETCHED_IN}
				{^XmN leftAttachment ^XmATTACH_FORM}
				{^XmN rightAttachment ^XmATTACH_FORM}
				{^XmN topAttachment ^XmATTACH_WIDGET}
				{^XmN topWidget ^frame0}
				{^XmN topOffset 10}
			])) -> frame1;
	XtManageChild (frame1);

	1 ->ac; 		ToggleButtonGadget -> XptSetArg (XmN entryClass, al, ac);
	XmCreateRadioBox(frame1, 'row_column1', al, ac) -> row_column;
	XtManageChild (row_column);
	XmAddTabGroup (row_column);

	1   ->ac; 		true -> XptSetArg (XmN set, al, ac);
	ac+1->ac; 		0 -> XptSetArg(XmN shadowThickness, al, ac);
	XmCreateToggleButtonGadget (row_column, 'work area', al, ac)
		-> work_area_toggle;
	XtManageChild (work_area_toggle);

	1  ->ac; 		0 -> XptSetArg(XmN shadowThickness, al, ac);

	XmCreateToggleButtonGadget(row_column, 'modeless', al, ac)
		-> modeless_toggle;
	XtManageChild (modeless_toggle);

	XmCreateToggleButtonGadget(row_column, 'application modal', al, ac)
		-> application_modal_toggle;
	XtManageChild (application_modal_toggle);

	XmCreateToggleButtonGadget(row_column, 'system modal', al, ac)
		-> system_modal_toggle;
	XtManageChild (system_modal_toggle);

	;;; Create RowColumn and dialog attribute toggles.

	XmCreateFrame(box, 'frame', XptArgList([
			{^XmN shadowType ^XmSHADOW_ETCHED_IN}
			{^XmN topAttachment ^XmATTACH_WIDGET}
			{^XmN topWidget ^frame1}
			{^XmN topOffset 10}
			{^XmN rightAttachment ^XmATTACH_FORM}
			{^XmN leftAttachment ^XmATTACH_FORM}
		])) -> frame2;
	XtManageChild (frame2);

	0 -> ac;
	XmCreateRowColumn(frame2, 'row_column2', al, ac) -> row_column;
	XtManageChild (row_column);
	XmAddTabGroup (row_column);

	1   ->ac; 		true -> XptSetArg (XmN set, al, ac);
	ac+1->ac; 		0 -> XptSetArg(XmN shadowThickness, al, ac);

	XmCreateToggleButtonGadget(row_column, 'auto unmanage', al, ac)
		-> auto_unmanage_toggle;
	XtManageChild (auto_unmanage_toggle);

	XmCreateToggleButtonGadget (row_column, 'default position', al, ac)
		->default_position_toggle;
	XtManageChild (default_position_toggle);


	;;; Create RowColumn with action buttons.

	XmCreateFrame (box, 'work_area', XptArgList([
			{^XmN shadowType ^XmSHADOW_ETCHED_IN}
			{^XmN topAttachment ^XmATTACH_WIDGET}
			{^XmN topWidget ^frame2}
			{^XmN topOffset 10}
			{^XmN rightAttachment ^XmATTACH_FORM}
			{^XmN leftAttachment ^XmATTACH_FORM}
			{^XmN bottomAttachment ^XmATTACH_FORM}
		])) -> frame3;

	XtManageChild (frame3);

	1   ->ac; 	XmPACK_COLUMN -> XptSetArg(XmN packing, al, ac);
	ac+1->ac; 	2 -> XptSetArg(XmN numColumns, al,ac);

	XmCreateRowColumn(frame3, 'row_column3', al, ac) -> row_column;
	XtManageChild (row_column);
	XmAddTabGroup (row_column);

	0 -> ac;
	XmCreatePushButtonGadget(row_column, 'create', al, ac) -> create_button;
	XtAddCallback (create_button, XmN activateCallback, WorkAreaCB,
			DIALOG_CREATE);
	XtManageChild (create_button);

	XmCreatePushButtonGadget(row_column, 'destroy', al, ac) -> destroy_button;
	XtAddCallback (destroy_button, XmN activateCallback, WorkAreaCB,
			DIALOG_DESTROY);
	XtManageChild (destroy_button);

	XmCreatePushButtonGadget(row_column, 'manage', al, ac) -> manage_button;
	XtAddCallback (manage_button, XmN activateCallback, WorkAreaCB,
			DIALOG_MANAGE);
	XtManageChild (manage_button);

	XmCreatePushButtonGadget(row_column, 'unmanage', al, ac)
		-> unmanage_button;
	XtAddCallback (unmanage_button, XmN activateCallback, WorkAreaCB,
			DIALOG_UNMANAGE);
	XtManageChild (unmanage_button);

	box;
enddefine;

/* TOP LEVEL CODE */

define new_dialog;
	lvars
		main,		/*  MainWindow	 	*/
		menu_bar,	/*  Frame	 	*/
		work_area,	/*  SelectionBox	*/
		form,		/*  Form		*/
		frame,		/*  Frame		*/
		al = arglist, ac,
	;

	;;; XmListCallbackStruct	cb;

	XptDefaultSetup();

	NewShell('Dialog Widgets') -> dialog_shell;

	;;; Create MainWindow.

	1 ->ac; XmAPPLICATION_DEFINED -> XptSetArg (XmN scrollingPolicy,al,ac);
	XmCreateMainWindow (dialog_shell, 'main', al, ac) -> main;
	XtManageChild (main);


	;;; Create MenuBar in MainWindow.

	CreateMenuBar (main) -> menu_bar;
	XtManageChild (menu_bar);


	;;; Create toplevel SelectionBox.

	CreateSelectionBox(main) -> work_area;
	XtManageChild (work_area);


	;;; Create work area in SelectionBox.

	CreateWorkArea(work_area) -> form;
	XtManageChild (form);


	;;; Set areas of MainWindow.
	XmMainWindowSetAreas (main, menu_bar, 0,0,0, work_area);


	;;; Realize toplevel widgets.
	XtRealizeWidget (dialog_shell);

	;;;	initialize selected item data.

	SetItem(1);
enddefine;


{%
			CreateDialogBox,
			XmCreateBulletinBoardDialog,
			CreateDialogBox,
			XmCreateErrorDialog,
			CreateDialogBox,
			XmCreateFileSelectionDialog,
			CreateDialogBox,
			XmCreateFormDialog,
			XmCreateInformationDialog,
			CreateDialogBox,
			XmCreateMessageDialog,
			XmCreatePromptDialog,
			XmCreateQuestionDialog,
			CreateDialogBox,
			XmCreateSelectionDialog,
			XmCreateWarningDialog,
			XmCreateWorkingDialog,
%} -> create_procs ;


lvars dialog_init_done = false;
define init_dialog();
	returnif(dialog_init_done);
	new_demomenu_entry('Dialog Windows', #_< identof("dialog_shell") >_#,
			new_dialog);
	true -> dialog_init_done;
enddefine;

if toplevel then
	init_dialog()
else
	XmDemo <> init_dialog -> XmDemo;
endif;

endsection;

/* --- Revision History ---------------------------------------------------
 */
