/* --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved --------
 > File:            $popneural/src/pop/nui_xpanels.p
 > Purpose:         X UI panel creators
 > Author:          Julian Clinton, July 1992
 > Documentation:
 > Related Files:
 */

section $-popneural;

/* ----------------------------------------------------------------- *
     Load Widget Classes And Xt Libraries
 * ----------------------------------------------------------------- */

pr(';;; Loading X panels\n');

uses nui_utils;
uses popxlib;
include xdefs.ph;
include xpt_coretypes;
include xpt_xgcvalues;
uses pop_ui;

exload_batch

include xt_constants;
uses xt_init;
uses xt_widget;
uses xt_widgetclass;
uses xt_widgetinfo;
uses xt_callback;
uses xt_event;
uses xt_popup;
uses xt_action;
uses xt_composite;
uses xt_popup;
uses xt_resource;
uses $-poplog_ui$-guiShells;
uses $-poplog_ui$-guiMouseEvents;
uses XptGarbageCursorFeedback;
uses XptBusyCursorFeedback;

uses
    xtApplicationShellWidget,
    xtTransientShellWidget,
    xtTopLevelShellWidget,
    XpwGraphic,
    xpwGraphicWidget,
    xpwCompositeWidget,
;

#_IF DEF XOPENLOOK

include XolConstants;

uses
    xolOblongButtonWidget,
    xolMenuButtonWidget,
    xolControlAreaWidget,
    xolCaptionWidget,
    xolStaticTextWidget,
    xolTextFieldWidget,
    xolScrollingListWidget,
    xolMenuShellWidget,
    xolPopupWindowShellWidget,
;

uses xpol_listutils;

#_ELSEIF DEF XMOTIF

include XmConstants;

uses
    xmBulletinBoardWidget,
    xmFormWidget,
    xmRowColumnWidget,
    xmPushButtonWidget,
    xmTextWidget,
    xmCascadeButtonWidget,
    xmMenuShellWidget,
    xmListWidget,
    xmLabelWidget,
    ;;; force DialogShell to be loaded to get at the mapping libraries
    xmDialogShellWidget
;

uses xpm_listutils;

#_ENDIF

uses pop_ui_logo;
uses pop_ui_information;
uses pop_ui_message;
uses pop_ui_confirm;
uses pop_ui_filetool;
uses pop_ui_compiletool;
uses pop_ui_edittool;
uses propsheet;

endexload_batch;



/* ----------------------------------------------------------------- *
     X Dialog Functions
 * ----------------------------------------------------------------- */

;;; y_or_n_x is simply modelled on the PWM and text versions.
define constant y_or_n_x(query) -> saidyes;
lvars query saidyes;
    (pop_ui_confirm(query, ['Yes' 'No'], 1, true, false) == 1) -> saidyes;
enddefine;


;;; nui_message_x puts the string up ina dialog box
;;;
define constant nui_message_x(prompt);
lvars prompt;
    pop_ui_message(prompt, true, nn_trans_shell);
enddefine;


define constant nui_confirm_x(prompt, options, default) -> val;
lvars prompt options default val;
    pop_ui_confirm(prompt, options, default, true, nn_trans_shell) -> val;
enddefine;


/* ----------------------------------------------------------------- *
     Routines For Creating Windows, Buttons, Menus etc.
 * ----------------------------------------------------------------- */

;;; Called when the 'Dismiss' button is pressed
define nui_generic_dismiss(w,client,call);
    lvars w, client, call;

    XtPopdown(client);
enddefine;


define BUSY_DOING(proc);
    dlocal XptBusyCursorOn = true;
    proc();
enddefine;


;;; nui_generic_callback is used to create closures on the basic UI
;;; procedures. It removes the callback args and then XptDeferApply's
;;; the procedure it was closed on.
;;;
define nui_generic_callback(proc);
lvars proc;
    erasenum(3);
    XptDeferApply(BUSY_DOING(%proc%));
    XptSetXtWakeup();
enddefine;


;;; textfield_string_x and its updater extract the string in an
;;; editable text field.
;;;
define textfield_string_x(textfield) -> string;
lvars textfield string;

#_IF DEF XOPENLOOK
    XptValue(textfield, XtN string, TYPESPEC(:XptString)) -> string;
#_ELSEIF DEF XMOTIF
    XmTextGetString(textfield) -> string;
#_ENDIF
enddefine;

define updaterof textfield_string_x(string, textfield);
lvars textfield string;

#_IF DEF XOPENLOOK
    string -> XptValue(textfield, XtN string, TYPESPEC(:XptString));
#_ELSEIF DEF XMOTIF
     XmTextSetString(textfield, string);
#_ENDIF
enddefine;


;;; gen_x_textfield takes a parent widget, a label for the textfield,
;;; a verify callback procedure and the clientdata to be passed to that
;;; procedure.
;;;
define gen_x_textfield(parent, label, verifyproc, clientdata) -> textfield;
lvars parent label verifyproc textfield textfield_label;

#_IF DEF XOPENLOOK
    XtVaCreateManagedWidget(label, xolCaptionWidget, parent,
        XptVaArgList([{font 'variable'}])) -> textfield_label;

    XtVaCreateManagedWidget('', xolTextFieldWidget,
        textfield_label,
        XptVaArgList([{width 300}])) -> textfield;

    if isprocedure(verifyproc) then
        XtAddCallback(textfield, XtN verification, verifyproc, clientdata);
    endif;

#_ELSEIF DEF XMOTIF
    ;;; assumes the parent widget is a Form

    XmCreateText(parent, 'text',
        XptArgList([{topAttachment ^XmATTACH_FORM}
                    {rightAttachment ^XmATTACH_FORM}
                    {leftAttachment ^XmATTACH_POSITION}
                    {leftPosition 17}])) -> textfield;

    XtManageChild(textfield);

    XtVaCreateManagedWidget(label, xmLabelWidget, parent,
        XptVaArgList([{alignment ^XmALIGNMENT_END}
                    {leftAttachment ^XmATTACH_FORM}
                    {rightAttachment ^XmATTACH_POSITION}
                    {rightPosition 16}
                    {topAttachment ^XmATTACH_OPPOSITE_WIDGET}
                    {topWidget ^textfield}
                    {bottomAttachment ^XmATTACH_OPPOSITE_WIDGET}
                    {bottomWidget ^textfield}])) -> textfield_label;

    if isprocedure(verifyproc) then
        XtAddCallback(textfield, XmN activateCallback, verifyproc, clientdata);
    endif;
#_ENDIF
    nullstring -> textfield_string_x(textfield);
enddefine;


;;; gen_x_menubutton takes the parent widget, the button label (a string),
;;; a list of option strings and a list of procedures which are called
;;; within an XptDeferApply if that menu option is selected. The return
;;; value is a menu button widget.
;;;
define gen_x_menubutton(parent, label, options, procs) -> mbutton;
lvars parent index option proc options procs mbutton flag = true;

#_IF DEF XOPENLOOK
    lvars newmenu_pane newmenu_widget newmenu_button;

    XtVaCreateManagedWidget(label, xolMenuButtonWidget,
        parent, XptVaArgList([])) -> mbutton;

    XptValue(mbutton, XtN menuPane, TYPESPEC(:XptWidget))
            -> newmenu_pane;

    XtVaCreateManagedWidget('', xolControlAreaWidget, newmenu_pane,
        XptVaArgList([{layoutType ^OL_FIXEDCOLS} {center ^false}
                        ])) -> newmenu_widget;

    fast_for index from 1 to length(options) do
        options(index) -> option;
        procs(index) -> proc;
        XtVaCreateManagedWidget(option, xolOblongButtonWidget,
            newmenu_widget,
            XptVaArgList([{default ^flag}])) -> newmenu_button;

        if flag then false -> flag; endif;   ;;; first item is default

        XtAddCallback(newmenu_button, XtN select,
            nui_generic_callback(%proc%), true);
    endfast_for;

#_ELSEIF DEF XMOTIF
    lvars newmenu_widget newmenu_button;

    XmCreatePulldownMenu(parent, label, XptArgList([])) -> newmenu_widget;

    fast_for index from 1 to length(options) do
        options(index) -> option;
        procs(index) -> proc;
        XtVaCreateManagedWidget(option, xmPushButtonWidget,
            newmenu_widget,
            XptVaArgList([{default ^flag}])) -> newmenu_button;

        if flag then false -> flag; endif;   ;;; first item is default
        XtAddCallback(newmenu_button, XmN activateCallback,
            nui_generic_callback(%proc%), true);
    endfast_for;

    XtVaCreateManagedWidget(label, xmCascadeButtonWidget,
        parent, XptVaArgList([{subMenuId ^newmenu_widget}])) -> mbutton;
#_ENDIF
enddefine;


;;; gen_x_execbutton takes the parent widget, the button label (a string),
;;; and the procedure (which will be XptDeferApply'd and must therefore
;;; take no arguments). The return value is a button widget.
;;;
define gen_x_execbutton(parent, label, proc) -> ebutton;
lvars parent label proc ebutton;

#_IF DEF XOPENLOOK
    XtVaCreateManagedWidget(label, xolOblongButtonWidget,
        parent, XptVaArgList([{default ^false}])) -> ebutton;

    XtAddCallback(ebutton, XtN select, nui_generic_callback(%proc%), true);
#_ELSEIF DEF XMOTIF
    XtVaCreateManagedWidget(label, xmPushButtonWidget,
        parent, XptVaArgList([{default ^false}])) -> ebutton;

    XtAddCallback(ebutton, XmN activateCallback, nui_generic_callback(%proc%), true);
#_ENDIF
enddefine;


;;; gen_x_graphics_panel takes the parent widget and the width and height
;;; of the panel. The return value is a graphics widget.
;;;
define gen_x_graphics_panel(parent, arglist) -> panel;
lvars parent arglist panel;

    XtVaCreateManagedWidget('popneural', xpwGraphicWidget,
        parent, XptVaArgList(arglist)) -> panel;
enddefine;


;;; used if the panel has been destroyed or popped down.
define lconstant panel_quit_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    false -> ui_options_table(clientdata);
enddefine;


;;; create_x_control_win is used to create the main X control panel. Under
;;; Motif, all the options have to menus so exec buttons will have to be
;;; menus (of one item).
;;; It returns the window frame widget id, the menu bar widget
;;; and the button widget id.
;;;
define create_x_control_win(title, x, y, panel_name) -> win_id -> menuarea_id -> buttonarea_id;
#_IF (DEF XOPENLOOK and DEFV XLINK_VERSION > 2005) or DEF XMOTIF
dlocal XptWMProtocols = false;
#_ENDIF
lvars title x y panel_name control_widget win_id menuarea_id buttonarea_id;

#_IF DEF XOPENLOOK

    XtVaAppCreateShell('popneural', 'PoplogNeural',
        xtApplicationShellWidget, XptDefaultDisplay,
        XptVaArgList([ % consXptArgPtr(XtN title, title) %
            ;;; {iconWindow ^icon_window}
            {allowShellResize ^false} {x ^x} {y ^y}])) -> win_id;

    XtVaCreateManagedWidget('controlarea', xolControlAreaWidget,
        win_id, XptVaArgList([{layoutType ^OL_FIXEDCOLS}
                            {centre ^false} {hPad 10}])) -> control_widget;

    XtVaCreateManagedWidget('upper_controlarea', xolControlAreaWidget,
        control_widget,
        XptVaArgList([{layoutType ^OL_FIXEDROWS}
                        {centre ^false}])) -> menuarea_id;

    XtVaCreateManagedWidget('lower_controlarea', xolControlAreaWidget,
        control_widget,
        XptVaArgList([{layoutType ^OL_FIXEDROWS}
                        {centre ^false}])) -> buttonarea_id;

    XtAddCallback(win_id, XtN destroyCallback, panel_quit_cb, panel_name);

#_ELSEIF DEF XMOTIF

    lvars bulletin_widget uppercontrol_widget;

    XtVaAppCreateShell('popneural', 'PoplogNeural',
        xtApplicationShellWidget, XptDefaultDisplay,
        XptVaArgList([;;; {iconWindow ^icon_window}
            {allowShellResize ^false} {x ^x} {y ^y}
            {deleteResponse ^XmDO_NOTHING}])) -> win_id;

    title -> XptValue(win_id, XtN title, TYPESPEC(:XptString));

    XtVaCreateManagedWidget('', xmBulletinBoardWidget, win_id,
        XptVaArgList([{noResize ^true}])) -> bulletin_widget;

    XtVaCreateManagedWidget('popneural', xmRowColumnWidget, bulletin_widget,
        XptVaArgList([{orientation ^XmVERTICAL}])) -> control_widget;

    XtVaCreateManagedWidget('popneural', xmRowColumnWidget, control_widget,
        XptVaArgList([{orientation ^XmHORIZONTAL}
                    {allowShellResize ^true}])) -> uppercontrol_widget;

    XmCreateMenuBar(uppercontrol_widget, 'popneural',
        XptArgList([{orientation ^XmHORIZONTAL}])) -> menuarea_id;

    XtManageChild(menuarea_id);

    XtVaCreateManagedWidget('popneural', xmRowColumnWidget, control_widget,
        XptVaArgList([{orientation ^XmHORIZONTAL}
                    {allowShellResize ^true}])) -> buttonarea_id;
#_ENDIF
enddefine;


;;; create_x_panel is used to create an X control panel.
;;; It returns the window frame widget id and the container widget id.
;;;
define create_x_panel_win(title, rows, cols) -> win_id -> buttonarea_id;
#_IF (DEF XOPENLOOK and DEFV XLINK_VERSION > 2005) or DEF XMOTIF
dlocal XptWMProtocols = false;
#_ENDIF
lvars win_id rows cols buttonarea_id dismiss_widget;

#_IF DEF XOPENLOOK
    lvars lowercontrol_widget;

    XtVaCreatePopupShell('popneural', xolPopupWindowShellWidget,
        nn_app_shell, XptVaArgList([{allowShellResize ^false}
                                    {pushpin ^OL_IN}])) -> win_id;

    title -> XptValue(win_id, XtN title, TYPESPEC(:XptString));

    XptValue(win_id, XtN upperControlArea,
                TYPESPEC(:XptWidget)) -> buttonarea_id;

    XptValue(win_id, XtN lowerControlArea,
                TYPESPEC(:XptWidget)) -> lowercontrol_widget;

    XtVaSetValues(buttonarea_id, #|
        XtN hPad, 10,
        XtN vPad, 10,
        XtN sameSize, OL_ALL,
        XtN layoutType, OL_FIXEDCOLS,
        XtN measure, cols,
        XtN borderWidth, 2,
        |#);

    XtVaCreateManagedWidget('Dismiss', xolOblongButtonWidget,
        lowercontrol_widget, XptVaArgList([])) -> dismiss_widget;

    XtAddCallback(dismiss_widget, XtN select, nui_generic_dismiss, win_id);
    XtAddCallback(win_id, XtN popdownCallback, nui_generic_dismiss, win_id);

#_ELSEIF DEF XMOTIF
    lvars bulletin_widget uppercontrol_widget lowercontrol_widget;

    XtVaCreatePopupShell('popneural', xtApplicationShellWidget,
        nn_app_shell,
        XptVaArgList([{allowShellResize ^false}
                    {deleteResponse ^XmUNMAP}])) -> win_id;

    title -> XptValue(win_id, XtN title, TYPESPEC(:XptString));

    XtVaCreateManagedWidget('popneural', xmBulletinBoardWidget, win_id,
        XptVaArgList([{noResize ^true}])) -> bulletin_widget;

    XtVaCreateManagedWidget('popneural', xmRowColumnWidget,
        bulletin_widget,
        XptVaArgList([{orientation ^XmVERTICAL} {isAligned ^true}
                    {entryAlignment ^XmALIGNMENT_CENTER}
                    ])) -> uppercontrol_widget;

    XtVaCreateManagedWidget('', xmRowColumnWidget,
        uppercontrol_widget,
        XptVaArgList([{orientation ^XmHORIZONTAL} {borderWidth 2}
                      {numColumns ^rows} {packing ^XmPACK_COLUMN}
                    {allowShellResize ^true}])) -> buttonarea_id;

    XtVaCreateManagedWidget('', xmRowColumnWidget,
        uppercontrol_widget,
        XptVaArgList([{orientation ^XmHORIZONTAL}
                      {entryAlignment ^XmALIGNMENT_CENTER}
                    {allowShellResize ^true}])) -> lowercontrol_widget;

    XtVaCreateManagedWidget('Dismiss', xmPushButtonWidget,
        lowercontrol_widget, XptVaArgList([])) -> dismiss_widget;

    XtAddCallback(dismiss_widget, XtN activateCallback,
                                nui_generic_dismiss, win_id);
    XtAddCallback(win_id, XtN popdownCallback, nui_generic_dismiss, win_id);
#_ENDIF
enddefine;


/* ----------------------------------------------------------------- *
     File IO Dialog Functions
 * ----------------------------------------------------------------- */

constant macro (
    FILE_SAVE_XWIN          = 1012,
    FILE_LOAD_XWIN          = 1022,
);

;;; file_search_proc can contain a procedure which is used to update the
;;; scrolling list if teh directory is changed.
;;;
lvars file_search_proc = false;

;;; update_dir_items is used to update the names of objects in the
;;; selection scrolling list. file_search_proc should have been
;;; dlocal'd by the top-level calling procedure to an appropriate value.
;;;
define update_dir_items(newdir, list_id);
lvars newdir list_id newlist;

    ;;; get the names of the objects we're interested in
    file_search_proc(newdir) -> newlist;

    if islist(newlist) then
        update_list_widget(list_id, newlist);
    endif;
enddefine;

define directory_changed_cb(widget, clientdata, calldata);
lvars widget clientdata calldata action newdir newlist;

    if isprocedure(file_search_proc) then
        textfield_string_x(widget) -> newdir;
        update_dir_items(newdir, clientdata);
    endif;
enddefine;

lvars file_selection_made = false;

define fileselect_select_cb(widget, clientdata, calldata);
lvars widget clientdata calldata textwidget dir;

    true -> file_selection_made;
enddefine;

define fileselect_dismiss_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    unless file_selection_made then
        undef -> file_selection_made;
    endunless;
enddefine;

define fileselect_popdown_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    unless file_selection_made then
        undef -> file_selection_made;
    endunless;
enddefine;


define get_fileselect_win(panel_index, directory, prompt, list_label, button_label)
                -> win_id -> list_id -> textfield_id;
lvars panel_index directory prompt list_label button_label
    win_desc win_id control_id label_id list_id select_id textfield_id;

    unless (ui_options_table(panel_index) ->> win_desc) and
      XptIsLiveType(subscrv(1, win_desc), "Widget") then

        create_x_selection_win(prompt, true,
            fileselect_select_cb, fileselect_dismiss_cb, fileselect_popdown_cb)
                -> win_id -> control_id -> label_id -> list_id -> select_id;

        gen_x_textfield(control_id, 'Directory',
            directory_changed_cb, list_id) -> textfield_id;

        consvector(win_id, textfield_id, label_id, list_id, select_id, 5) ->> win_desc
            -> ui_options_table(panel_index);

        XtRealizeWidget(win_id);
        XptAppTryEvents(XptDefaultAppContext);
        XptCenterWidgetOn(win_id, "screen");
    endunless;

    fast_subscrv(1, win_desc) -> win_id;
    fast_subscrv(2, win_desc) -> textfield_id;
    fast_subscrv(3, win_desc) -> label_id;
    fast_subscrv(4, win_desc) -> list_id;
    fast_subscrv(5, win_desc) -> select_id;

    prompt -> XptValue(win_id, XtN title, TYPESPEC(:XptString));
    directory -> textfield_string_x(textfield_id);

#_IF DEF XOPENLOOK
    list_label -> XptValue(label_id, XtN string, TYPESPEC(:XptString));
    button_label -> XptValue(select_id, XtN label, TYPESPEC(:XptString));
#_ELSEIF DEF XMOTIF
    list_label -> XptValue(label_id, XmN labelString, TYPESPEC(:XmString));
    button_label -> XptValue(select_id, XmN labelString, TYPESPEC(:XmString));
#_ENDIF
enddefine;


define get_fileselect_result(choice_list, win_id, list_id, textfield_id) -> dir;
lvars choice_list win_id list_id textfield_id dir old_busy = XptBusyCursorOn;

    procedure;
        EXIT_ACTION((XtPopdown(win_id), XtUnmanageChild(win_id),
                                    old_busy -> XptBusyCursorOn));
        true -> XptBusyCursorOn;
        XptAppTryEvents(XptDefaultAppContext);
        XtManageChild(win_id);
        update_list_widget(list_id, choice_list);
        XtPopup(win_id, XtGrabNone);
        false -> file_selection_made;

        until file_selection_made do
            until file_selection_made do
                XtAppProcessEvent(XptDefaultAppContext, XtIMAll);
            enduntil;

            ;;; if the user is asking to use a particular directory
            ;;; then verify that it exists
            ;;;
            if file_selection_made == true then
                if isdirectory(textfield_string_x(textfield_id) ->> dir) then
                    dir -> file_selection_made;
                else
                    false -> file_selection_made;

                    ;;; if the directory doesn't exist then prevent
                    ;;; the window popping down
                    ;;;
                    pop_ui_message(sprintf(dir, 'Invalid directory: %p'),
                                    true, false);
                endif;
            endif;
        enduntil;

        unless isstring(file_selection_made) then
            false
        else
            file_selection_made
        endunless -> dir;
    endprocedure();
enddefine;


;;; nui_select_saveitems_x is used to save datatypes, example sets and networks to
;;; disk. It takes an initial directory, a list of initial possibilities
;;; (which may be empty), a prompt (which will become the title of the
;;; window) and the label for the scrolling list (a string).
;;; The results returned are the directory selected and a list of items
;;; within that are to be saved to that directory.
;;;
define /* constant */ nui_select_saveitems_x(directory, choice_list,
                        prompt, list_label) -> savedir -> saveitems;
dlocal file_search_proc = false;
lvars directory choice_list prompt list_label
        savedir saveitems win_id list_id textfield_id;

    unless isstring(directory) then
        current_directory -> directory;
    endunless;

    get_fileselect_win(FILE_SAVE_XWIN, directory, prompt, list_label, 'Save')
            -> win_id -> list_id -> textfield_id;

    get_fileselect_result(choice_list, win_id, list_id, textfield_id) -> savedir;

    unless isstring(savedir) then
        false ->> savedir -> saveitems;
        return();
    endunless;

    flatten(selected_list_items(list_id)) -> saveitems;
enddefine;


;;; nui_select_loaditems_x is used to load datatypes, example sets and networks from
;;; disk. It takes an initial directory, an update procedure which
;;; is called to update the scrolling list if the user changes
;;; directory, a list of initial possibilities (which may be empty),
;;; a prompt (which will become the title of the window and the label
;;; for the scrolling list (a string).
;;; The results returned are the directory selected and a list of items
;;; within that directory which are to be loaded.
;;;
define /* constant */ nui_select_loaditems_x(directory, update_proc, choice_list,
                            prompt, list_label) -> loaddir -> loaditems;
lvars directory choice_list update_proc prompt list_label
        loaddir loaditems win_id list_id textfield_id;
dlocal file_search_proc = update_proc;

    unless isstring(directory) then
        current_directory -> directory;
    endunless;

    get_fileselect_win(FILE_LOAD_XWIN, directory, prompt, list_label, 'Load')
            -> win_id -> list_id -> textfield_id;

    get_fileselect_result(choice_list, win_id, list_id, textfield_id) -> loaddir;

    unless isstring(loaddir) then
        false ->> loaddir -> loaditems;
        return();
    endunless;

    flatten(selected_list_items(list_id)) -> loaditems;
enddefine;


/* ----------------------------------------------------------------- *
     Display Functions
 * ----------------------------------------------------------------- */

#_IF DEFV pop_internal_version < 142000

;;; for 14.1 Poplog's, the presence of a refresh button is not
;;; detected so need to define one here
;;;
define lconstant options_sheet_cb(box, button) -> ok;
lvars box button ok = true;

    if button == "Apply" then
        propsheet_apply(box);
    elseif button == "Refresh" then
        propsheet_refresh(box);
    else
        propsheet_hide(box);
    endif;
enddefine;
#_ENDIF

;;; these two converters are required to handle the case where
;;; a variable can hold a value or false and convert the false
;;; to a form suitable for propsheet. Note that strings are always
;;; returned from the propsheet unchanged.
;;;
define sheet_string_convert(sval) -> pval;
lvars sval pval;
    sval -> pval;
enddefine;

define updaterof sheet_string_convert(pval) -> sval;
lvars sval pval;

    if isstring(pval) then
        pval
    else
        nullstring
    endif -> sval;
enddefine;


define sheet_word_convert(sval) -> pval;
lvars sval pval;

    if length(sval) == 0 then
        false
    else
        consword(sval)
    endif -> pval;
enddefine;

define updaterof sheet_word_convert(pval) -> sval;
lconstant null_word = consword(0);
lvars sval pval;

    if isword(pval) then
        word_string(pval)
    else
        nullstring
    endif -> sval;
enddefine;


;;; Note that the maxwidth argument is ignored under X.
;;;
define show_options_x(panel_name);
dlocal nn_exitfromproc = show_options_x;
lvars menu panel_name panel labels index = 1, num title maxwidth
      values wid_var win_id menu_name menuval mval child_id sheets;

    window_var(panel_name) -> wid_var;

    ;;; only create it if not already created
    if (ui_options_table(wid_var) ->> sheets) and islist(sheets) then

        ;;; win_id should be a list of the new box + its container
        propsheet_show(sheets);
    else
        ui_options_table(panel_name) -> panel;
        destpanel_txt(panel) -> title -> maxwidth -> labels -> values;
        length(labels) -> num;


#_IF DEFV pop_internal_version < 142000
        propsheet_new_box(title, false, options_sheet_cb,
                        [Apply Refresh Dismiss]) -> win_id;
#_ELSE
        propsheet_new_box(title, false, false, [Apply Refresh Dismiss]) -> win_id;
#_ENDIF

        propsheet_new(nullstring, win_id, false) -> child_id;

        if win_id then
            for index from 1 to num do
                if (back(menu_valof(values(index)) ->> menuval)) == "boolean"
                    then
                    propsheet_field(child_id,
                        [^(labels(index)) ^(idval(front(menuval)))
                         (nodefault, ident = ^(front(menuval)))]);
                elseif back(menuval) == "string" then
                    unless (idval(front(menuval)) ->> mval) then
                        nullstring -> mval;
                    endunless;
                    propsheet_field(child_id,
                        [^(labels(index)) ^mval
                         (nodefault, converter = ^sheet_string_convert,
                            ident = ^(front(menuval)))]);

                elseif back(menuval) == "word" then
                    unless (idval(front(menuval)) ->> mval) then
                        nullstring -> mval;
                    else
                        word_string(mval) -> mval;
                    endunless;
                    propsheet_field(child_id,
                        [^(labels(index)) ^mval
                         (nodefault, converter = ^sheet_word_convert,
                            ident = ^(front(menuval)))]);

                else
                    propsheet_field(child_id,
                        [^(labels(index)) ^(idval(front(menuval)))
                         (nodefault, ident = ^(front(menuval)))]);
                endif;
            conspair(child_id, labels(index)) -> ui_options_table(front(menuval));
            endfor;
            [^child_id ^win_id] ->> sheets -> ui_options_table(wid_var);
            propsheet_show(sheets);
            true ->> XptGarbageCursorFeedback(win_id)
                -> XptBusyCursorFeedback(win_id);

        else
            warning(0, err(FAIL_WINMAKE));
        endif;
    endif;
enddefine;


;;; show_panel_x takes the panel name and builds a panel.
;;;
define show_panel_x(panel_name);
dlocal nn_exitfromproc = show_panel_x;
lvars panel_name panel title maxwidth menu labels label index values value
    wid_var win_id buttonarea_id options procs menu_name itemtype;

    window_var(panel_name) -> wid_var;

    if (ui_options_table(wid_var) ->> win_id) and
      isXptDescriptor(win_id) and
      XptIsLiveType(win_id, "Widget") then
        XtPopup(win_id, XtGrabNone);
        return();
    endif;

    ui_options_table(panel_name) -> panel;
    destpanel_txt(panel) -> title -> maxwidth -> labels -> values;

    create_x_panel_win(title, (length(labels) div 2) + (length(labels) mod 2),
            2) -> win_id -> buttonarea_id;

    fast_for index from 1 to length(labels) do
        labels(index) -> label;
        menu_valof(values(index)) -> value;

        if isprocedure(value) then
            ;;; for a control panel, create a menu item of 1 item
            gen_x_execbutton(buttonarea_id, label, value) ->;
        elseif islist(value) then
            if is_menu_ref(value) then
                ui_options_table(subscrl(2, value)) -> menu;
                ;;; X menus are lists of title + menu strings + menu values
                destmenu_txt(menu) -> label -> options -> procs;
                gen_x_menubutton(buttonarea_id, label, options, procs) ->;

            elseif is_panel_ref(value) then
                lvars panel_show_proc;

                show_panel_x(%subscrl(2, value)%) -> panel_show_proc;
                gen_x_execbutton(buttonarea_id, label, panel_show_proc) ->;

            elseif is_options_ref(value) then
                lvars panel_show_proc;

                show_options_x(%subscrl(2, value)%) -> panel_show_proc;
                gen_x_execbutton(buttonarea_id, label, panel_show_proc) ->;
            else
                mishap(value, 1, 'NUI: invalid button result');
            endif;
        endif;
    endfast_for;
    XtRealizeWidget(win_id);
    true ->> XptGarbageCursorFeedback(win_id) -> XptBusyCursorFeedback(win_id);
    win_id -> ui_options_table(wid_var);
    XtPopup(win_id, XtGrabNone);
enddefine;


;;;
define show_mainpanel_x(panel_name);
lvars panel_name panel menu title maxwidth labels values wid_var win_id
    menuarea_id buttonarea_id label options procs proc value graphic_id;

    window_var(panel_name) -> wid_var;

    if (ui_options_table(wid_var) ->> win_id) and isXptDescriptor(win_id) and
      XptIsLiveType(win_id, "Widget") then
        XtPopup(win_id, XtGrabNone);
        return();
    endif;

    create_x_control_win(sprintf(nn_version,
        'Poplog-Neural %p: Main Panel'), 0, 0, wid_var)
        -> win_id -> menuarea_id -> buttonarea_id;

    ui_options_table(panel_name) -> panel;
    destpanel_txt(panel) -> title -> maxwidth -> labels -> values;

    ;;; add the menus
    lvars index;
    fast_for index from 1 to length(labels) do
        labels(index) -> label;
        menu_valof(values(index)) -> value;

        if isprocedure(value) then
            ;;; for a control panel, create a menu item of 1 item
            gen_x_menubutton(menuarea_id, label, [^label], [^value]) ->;
        elseif islist(value) then
            if is_menu_ref(value) then
                ui_options_table(subscrl(2, value)) -> menu;
                ;;; X menus are lists of title + menu strings + menu values
                destmenu_txt(menu) -> label -> options -> procs;
                gen_x_menubutton(menuarea_id, label, options, procs) ->;

            elseif is_panel_ref(value) then
                lvars panel_show_proc;

                show_panel_x(%subscrl(2, value)%) -> panel_show_proc;
                gen_x_menubutton(menuarea_id, label, [^label], [^panel_show_proc]) ->;

            elseif is_options_ref(value) then
                lvars panel_show_proc;

                show_options_x(%subscrl(2, value)%) -> panel_show_proc;
                gen_x_menubutton(menuarea_id, label, [^label], [^panel_show_proc]) ->;
            else
                mishap(value, 1, 'NUI: invalid button result');
            endif;
        endif;
    endfast_for;

    ;;; add the title banner
    gen_x_graphics_panel(buttonarea_id, [{width 379} {height 49}]) -> graphic_id;

    XpwGetPixmap(graphic_id, '$popneural/bitmaps/popneural.xbm',
            XptValue(graphic_id, XtN foreground),
            XptValue(graphic_id, XtN background),
            XptValue(graphic_id, XtN depth)) -> XptValue(graphic_id, XtN pixmap);

    XtRealizeWidget(win_id);
    true ->> XptGarbageCursorFeedback(win_id) -> XptBusyCursorFeedback(win_id);
    erase -> XptDeleteResponse(win_id);

    XtPopup(win_id, XtGrabNone);
    win_id -> ui_options_table(wid_var);
enddefine;

global vars nui_xpanels = true;       ;;; for "uses"

endsection;

/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 26/8/95
    Added missing lvars in show_main_panel_x.
-- Julian Clinton, 1/9/93
    Added DEFV for included guiShells and guiMouseEvents with section
    prefixes for Poplog versions greater than 14.2.
    Added includes for xpt_coretypes and xpt_xgcvalues.
-- Julian Clinton, 17/8/93
    Changed #_IF X* to #_IF DEF X*.
-- Julian Clinton, 23/11/92
    Added popdown callback for fileselect windows.
-- Julian Clinton, 17/11/92
    Removed window centering code from get_fileselect_result.
-- Julian Clinton, 10/11/92
    Modified last change so that XptWMProtocols is true for OPEN LOOK 1.3.
-- Julian Clinton, 14/9/92
    dlocal'd XptWMProtocols false for both Motif and OPEN LOOK.
-- Julian Clinton, 27/7/92
    Modified calls to show_panel_x and show_options_x to take
    the panel name only.
*/
