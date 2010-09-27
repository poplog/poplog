/*  --- Copyright Integral Solutions Ltd. 1992. All Rights Reserved ---------
 > File:            $popneural/src/pop/nn_gfxdialogs.p
 > Purpose:         graphics dialog boxes
 > Author:          Julian Clinton, Aug 1992
 > Documentation:
 > Related Files:   nn_gfxutils.p nn_gfxdefs.p nn_gfxdraw.p nn_gfxevents.p
 */

section $-popneural;

#_IF DEF XNEURAL

uses popxlib;
include xdefs;

exload_batch


include xt_constants;
uses xt_init;
uses xt_grab;
uses xt_trans;
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
uses XptGarbageCursorFeedback;
uses XptBusyCursorFeedback;

include xpt_coretypes;
include xpt_xgcvalues;

uses
    xtApplicationShellWidget,
    xtTransientShellWidget,
    xtTopLevelShellWidget,
;

#_IF DEF XOPENLOOK

include XolConstants;

uses
    xolOblongButtonWidget,
    xolMenuButtonWidget,
    xolControlAreaWidget,
    xolStaticTextWidget,
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
    xmCascadeButtonWidget,
    xmMenuShellWidget,
    xmListWidget,
    xmLabelWidget,
    ;;; force DialogShell to be loaded to get at the mapping libraries
    xmDialogShellWidget,
;

uses xpm_listutils;


#_ENDIF         /* OPEN LOOK or Motif */

compile('$popneural/src/utils/XptResizeResponse.p');
compile('$popneural/src/utils/XptDeleteResponse.p');
endexload_batch;

#_ENDIF         /* XNEURAL */

#_IF (DEF XNEURAL) or (DEF PWMNEURAL)

uses nn_gfxutils;

#_ENDIF


/* ----------------------------------------------------------------- *
     PWM Selection Utility Functions
 * ----------------------------------------------------------------- */

#_IF DEF PWMNEURAL

;;; the next two routines are used to implement a popup dialog in the PWM
lvars select_pwm_button = false;

define lconstant generic_pwm_select(val);
lvars val;
    val -> select_pwm_button;
enddefine;

define nn_singlechoice_pwm(choice_list, prompt, list_label, action_label) -> val;
dlocal nn_exitfromproc = nn_singlechoice_pwm;
dlocal pwmgfxsurface, pwmgfxrasterop = PWM_SRC,
    pwmgfxfont = pwmstdfont;
lconstant dlg_height = 19;
lvars choice_list prompt list_label action_label win_width total_width
        prompt_width win_id x_offset y_offset scroll_list;

    max((length(prompt) + 2 ->> prompt_width), 24) -> total_width;

    intof(total_width * nn_stdfont_width) -> win_width;

    create_pwm_gfxwin(prompt, win_width,
                    dlg_height * nn_stdfont_height) -> win_id;

    win_id -> pwmgfxsurface;

    nn_stdfont_width -> x_offset;
    nn_stdfont_height -> y_offset;

    pwm_make_listitem(win_id, x_offset, y_offset, choice_list,
                             list_label, max(length(list_label), 20), 10,
                             false) -> scroll_list;

    (dlg_height - 2) * nn_stdfont_height -> y_offset;

    pwm_make_execitem(win_id, x_offset, y_offset, sprintf(action_label, ' %p '),
                      generic_pwm_select(%1%)) ->;

    win_width - (9 * nn_stdfont_width) -> x_offset;

    pwm_make_execitem(win_id, x_offset, y_offset, ' Cancel ',
                      generic_pwm_select(%2%)) ->;

    false -> select_pwm_button;

    until isinteger(select_pwm_button) do
        pwm_wait_inevent(win_id, true);
    enduntil;

    select_pwm_button -> val;
    false -> select_pwm_button;

    if val == 1 then
        pwm_itemvalue(scroll_list) -> val;
        if isundef(val) or val == "undef" then
            false -> val;
        endif;
    else
        false -> val;
    endif;

    pwm_reset_input();
    pwm_kill_window(win_id);
enddefine;


define nn_multichoice_pwm(choice_list, prompt, list_label, action_label) -> vals;
dlocal nn_exitfromproc = nn_multichoice_pwm;
dlocal pwmgfxsurface, pwmgfxrasterop = PWM_SRC, pwmgfxfont = pwmstdfont;
lconstant dlg_height = 19;
lvars choice_list prompt list_label action_label win_width total_width
        prompt_width win_id x_offset y_offset scroll_list;

    max((length(prompt) + 2 ->> prompt_width), 24) -> total_width;

    intof(total_width * nn_stdfont_width) -> win_width;

    create_pwm_gfxwin(prompt, win_width,
                    dlg_height * nn_stdfont_height) -> win_id;

    win_id -> pwmgfxsurface;

    nn_stdfont_width -> x_offset;
    nn_stdfont_height -> y_offset;

    pwm_make_setitem(win_id, x_offset, y_offset, false, choice_list,
                             list_label, max(length(list_label), 20), 10,
                             false) -> scroll_list;

    (dlg_height - 2) * nn_stdfont_height -> y_offset;

    pwm_make_execitem(win_id, x_offset, y_offset, sprintf(action_label, ' %p '),
                      generic_pwm_select(%1%)) ->;

    win_width - (9 * nn_stdfont_width) -> x_offset;

    pwm_make_execitem(win_id, x_offset, y_offset, ' Cancel ',
                      generic_pwm_select(%2%)) ->;

    false -> select_pwm_button;

    until isinteger(select_pwm_button) do
        pwm_wait_inevent(win_id, true);
    enduntil;

    select_pwm_button -> vals;
    false -> select_pwm_button;

    if vals == 1 then
        pwm_itemvalue(scroll_list) -> vals;
        if isundef(vals) or vals == "undef" then
            false -> vals;
        endif;
    else
        false -> vals;
    endif;

    pwm_reset_input();
    pwm_kill_window(win_id);
enddefine;
#_ENDIF


/* ----------------------------------------------------------------- *
     X Selection Utility Functions
 * ----------------------------------------------------------------- */

#_IF DEF XNEURAL

constant macro (
    SINGLE_SELECT_XWIN      = 1001,
    MULTI_SELECT_XWIN       = 1002,
);


define update_list_widget(list_widget, list);
lvars list_widget list;

#_IF DEF XOPENLOOK
    list -> XpolListItems(list_widget);
#_ELSEIF DEF XMOTIF
    list -> XpmListItems(list_widget);
    ;;; move scrolling list to top item
    1 -> XptValue(list_widget, XmN topItemPosition);
#_ENDIF
enddefine;


;;; selected_list_item is used to find out which item has been
;;; selected from a single-choice selection dialog
;;;
define selected_list_item(list_widget) -> value;
lvars list_widget value;
#_IF DEF XOPENLOOK
    XpolCurrentListItem(list_widget) -> value;
#_ELSEIF DEF XMOTIF
    XpmCurrentListItem(list_widget) -> value;
#_ENDIF
enddefine;


;;; selected_list_items is used to find out which items have been
;;; selected from a multichoice selection dialog
;;;
define selected_list_items(list_widget) -> values;
lvars list_widget values;

#_IF DEF XOPENLOOK
    XpolSelectedListItems(list_widget) -> values;
#_ELSEIF DEF XMOTIF
    XpmSelectedListItems(list_widget) -> values;
#_ENDIF
enddefine;


lvars
    multi_selection_made = false,
    multi_selection_dismissed = false,
    single_selection_made = false,
    single_selection_dismissed = false,
;

define singlechoice_select_cb(w, client, call);
lvars w, client, call;
    true -> single_selection_made;
    ;;; XtPopdown(client);
enddefine;

define singlechoice_dismiss_cb(w, client, call);
lvars w, client, call;
    undef -> single_selection_made;
    ;;; XtPopdown(client);
enddefine;

define singlechoice_popdown_cb(w, client, call);
lvars w, client, call;
    true -> single_selection_dismissed;
enddefine;


define multichoice_select_cb(w, client, call);
lvars w, client, call;
    true -> multi_selection_made;
    ;;; XtPopdown(client);
enddefine;

define multichoice_dismiss_cb(w, client, call);
lvars w, client, call;
    undef -> multi_selection_made;
    ;;; XtPopdown(client);
enddefine;

define multichoice_popdown_cb(w, client, call);
lvars w, client, call;
    true -> multi_selection_dismissed;
enddefine;


define global is_doubleclick(display, last_time) -> this_time -> boole;
lvars display, last_time, boole, this_time, timeout;
    exacc ^int (XtLastTimestampProcessed(display)) -> this_time;
    XtGetMultiClickTime(display) -> timeout;
    if this_time - last_time < timeout then
        true
    else
        false
    endif -> boole;
enddefine;


lvars last_single_select_time = 0,
    current_singleselect_item = false,
;

;;; callback when list item is selected
define list_select_cb(widget, clientdata, calldata);
    lvars widget clientdata calldata selected_item;

#_IF DEF XMOTIF
    l_typespec calldata :XmListCallbackStruct;

    exacc calldata.item -> selected_item;
    XpmCoerceString(selected_item) -> selected_item;

#_ELSEIF DEF XOPENLOOK
    calldata -> XpolCurrentListItem(widget);
    XpolListTokenToItem(calldata) -> selected_item;

#_ENDIF

    ;;; always update the last_single_select_time
    if (is_doubleclick(XptDefaultDisplay, last_single_select_time)
        -> last_single_select_time)
      and selected_item = current_singleselect_item then
        singlechoice_select_cb(false, clientdata, false);
    else
        selected_item -> current_singleselect_item;
    endif;
enddefine;


define create_x_selection_win(title, multichoice_p, select_cb, dismiss_cb, popdown_cb)
        -> win_id -> controlarea_id -> label_id -> list_id -> select_id;
#_IF (DEF XOPENLOOK and DEFV XLINK_VERSION > 2005) or XMOTIF
dlocal XptWMProtocols = false;
#_ENDIF
lvars title multichoice_p select_cb dismiss_cb popdown_cb selection_policy
    win_id controlarea_id label_id list_id select_id cancel_id
    win_name;

    if multichoice_p then
        'multichoice'
    else
        'singlechoice'
    endif -> win_name;

#_IF DEF XOPENLOOK
    lvars uppercontrol_widget lowercontrol_widget;

    XtVaCreatePopupShell(win_name, xtTransientShellWidget,
        nn_app_shell, XptVaArgList([])) -> win_id;

    title -> XptValue(win_id, XtN title, TYPESPEC(:XptString));

    XtVaCreateManagedWidget('', xolControlAreaWidget, win_id,
        XptVaArgList([{layoutType ^OL_FIXEDCOLS} {borderWidth 2}
                    {center ^true} {alignCaptions ^true}
                    {hPad 10} {vPad 10}
                    {sameSize ^OL_ALL}])) -> uppercontrol_widget;

    XtVaCreateManagedWidget('popneural', xolControlAreaWidget,
        uppercontrol_widget,
        XptVaArgList([{layoutType ^OL_FIXEDCOLS}])) -> controlarea_id;

    XtVaCreateManagedWidget('popneural', xolStaticTextWidget,
        uppercontrol_widget, XptVaArgList([])) -> label_id;

    if multichoice_p then
        true
    else
        false
    endif -> selection_policy;

    XtVaCreateManagedWidget('popneural', xolScrollingListWidget,
        uppercontrol_widget,
        XptVaArgList([{viewHeight 10} {recomputeWidth ^true}
                    {selectable ^selection_policy}])) -> list_id;

    unless multichoice_p then
        ;;; this allows the user to double click on a single choice dialog
        XtAddCallback(list_id, XtN userMakeCurrent, list_select_cb, win_id);
    endunless;

    [% consstring(repeat 20 times `_` endrepeat, 20) %]
        -> XpolListItems(list_id);

    false -> XptValue(list_id, XtN recomputeWidth,
                        TYPESPEC(:XptBoolean));

    XtCreateManagedWidget('', xolControlAreaWidget,
        uppercontrol_widget,
        XptArgList([{layoutType ^OL_FIXEDCOLS} {measure 3}
                    {center ^true} {hPad 25} {hSpace 25}]))
        -> lowercontrol_widget;

    XtVaCreateManagedWidget('________', xolOblongButtonWidget,
        lowercontrol_widget, XptVaArgList([])) -> select_id;

    XtVaCreateManagedWidget('Cancel', xolOblongButtonWidget,
        lowercontrol_widget, XptVaArgList([])) -> cancel_id;

    XtAddCallback(select_id, XtN select, select_cb, win_id);
    XtAddCallback(cancel_id, XtN select, dismiss_cb, win_id);
    XtAddCallback(win_id, XtN popdownCallback, popdown_cb, win_id);

#_ELSEIF DEF XMOTIF
    lvars mainform_widget uppercontrol_widget lowercontrol_widget
        listarea_widget;

    XtVaCreatePopupShell(win_name, xtApplicationShellWidget,
        nn_app_shell,
        XptVaArgList([{allowShellResize ^true}
                      {deleteResponse ^XmDO_NOTHING}])) -> win_id;

    title -> XptValue(win_id, XtN title, TYPESPEC(:XptString));

    ;;; create the main Form widget
    ;;;
    XmCreateForm(win_id, 'popneural',
        XptArgList([{allowOverlap ^false}
                    {rubberPositioning ^true}
                    {marginHeight 10} {marginWidth 10}])) -> mainform_widget;

    XtManageChild(mainform_widget);

    ;;; create the control area Form widget
    ;;;
    XmCreateForm(mainform_widget, 'popneural',
        XptArgList([{allowOverlap ^false}
                    {rubberPositioning ^true}
                    {topAttachment ^XmATTACH_FORM}
                    {leftAttachment ^XmATTACH_FORM}
                    {rightAttachment ^XmATTACH_FORM}
                    {marginHeight 10} {marginWidth 10}])) -> controlarea_id;

    XtManageChild(controlarea_id);

    XtVaCreateManagedWidget(nullstring, xmLabelWidget,
        mainform_widget, XptVaArgList([
                    {topAttachment ^XmATTACH_WIDGET}
                    {topWidget ^controlarea_id}
                    {leftAttachment ^XmATTACH_FORM}
                    {rightAttachment ^XmATTACH_FORM}])) -> label_id;

    ;;; now create the lower Form widget which contains the action buttons
    ;;;
    XmCreateForm(mainform_widget, 'popneural',
        XptArgList([{allowOverlap ^false}
                    {rubberPositioning ^true}
                    {bottomAttachment ^XmATTACH_FORM}
                    {leftAttachment ^XmATTACH_FORM}
                    {rightAttachment ^XmATTACH_FORM}
                    {marginHeight 10} {margin_width 10}])) -> lowercontrol_widget;

    XtManageChild(lowercontrol_widget);

    XtVaCreateManagedWidget('________', xmPushButtonWidget,
        lowercontrol_widget,
            XptVaArgList([{leftAttachment ^XmATTACH_POSITION}
                        {leftPosition 5}
                        {rightAttachment ^XmATTACH_POSITION}
                        {rightPosition 40}
                        {topAttachment ^XmATTACH_FORM}
                        {bottomAttachment ^XmATTACH_FORM}])) -> select_id;

    XtVaCreateManagedWidget('Cancel', xmPushButtonWidget,
        lowercontrol_widget,
        XptVaArgList([{leftAttachment ^XmATTACH_POSITION}
                        {leftPosition 60}
                        {rightAttachment ^XmATTACH_POSITION}
                        {rightPosition 95}
                        {topAttachment ^XmATTACH_FORM}
                        {bottomAttachment ^XmATTACH_FORM}])) -> cancel_id;

    XtAddCallback(select_id, XmN activateCallback, select_cb, win_id);
    XtAddCallback(cancel_id, XmN activateCallback, dismiss_cb, win_id);
    XtAddCallback(win_id, XtN popdownCallback, popdown_cb, win_id);

    ;;; create the Form widget which contains the label and scrolling list
    ;;;
    XmCreateForm(mainform_widget, 'popneural',
        XptArgList([{allowOverlap ^false}
                    {rubberPositioning ^true}
                    {leftAttachment ^XmATTACH_FORM}
                    {rightAttachment ^XmATTACH_FORM}
                    {topAttachment ^XmATTACH_WIDGET}
                    {topWidget ^label_id}
                    {bottomAttachment ^XmATTACH_WIDGET}
                    {bottomWidget ^lowercontrol_widget}
                    {marginHeight 5}])) -> listarea_widget;

    XtManageChild(listarea_widget);

    if multichoice_p then
        XmMULTIPLE_SELECT
    else
        XmSINGLE_SELECT
    endif -> selection_policy;

    XmCreateScrolledList(listarea_widget, 'List',
        XptArgList([{visibleItemCount 10}
                    {selectionPolicy ^selection_policy}
                    {listSizePolicy ^XmCONSTANT}
                    {scrollBarDisplayPolicy ^XmSTATIC}
                    {leftAttachment ^XmATTACH_FORM}
                    {rightAttachment ^XmATTACH_FORM}
                    {topAttachment ^XmATTACH_FORM}
                    {bottomAttachment ^XmATTACH_FORM}])) -> list_id;

    XtManageChild(list_id);

    unless multichoice_p then
        ;;; this allows the user to double click on a single choice dialog
        XtAddCallback(list_id, XmN singleSelectionCallback,
                            list_select_cb, win_id);
    endunless;

#_ENDIF
enddefine;


define get_singlechoice_win(prompt, list_label, button_label) -> win_id -> list_id;
lvars prompt list_label button_label win_desc
    win_id control_id label_id list_id select_id;

    unless (ui_options_table(SINGLE_SELECT_XWIN) ->> win_desc) and
      XptIsLiveType(subscrv(1, win_desc), "Widget") then

        create_x_selection_win(prompt, false, singlechoice_select_cb,
            singlechoice_dismiss_cb, singlechoice_popdown_cb)
                -> win_id -> control_id -> label_id -> list_id -> select_id;

        ;;; don't need to keep a reference of the control_id
        consvector(win_id, label_id, list_id, select_id, 4) ->> win_desc
            -> ui_options_table(SINGLE_SELECT_XWIN);

        XtRealizeWidget(win_id);
        XptCenterWidgetOn(win_id, "screen");
    endunless;

    fast_subscrv(1, win_desc) -> win_id;
    fast_subscrv(2, win_desc) -> label_id;
    fast_subscrv(3, win_desc) -> list_id;
    fast_subscrv(4, win_desc) -> select_id;

    prompt -> XptValue(win_id, XtN title, TYPESPEC(:XptString));
#_IF DEF XOPENLOOK
    list_label -> XptValue(label_id, XtN string, TYPESPEC(:XptString));
    button_label -> XptValue(select_id, XtN label, TYPESPEC(:XptString));
#_ELSEIF DEF XMOTIF
    list_label -> XptValue(label_id, XmN labelString, TYPESPEC(:XmString));
    button_label -> XptValue(select_id, XmN labelString, TYPESPEC(:XmString));
#_ENDIF
enddefine;


define get_multichoice_win(prompt, list_label, button_label) -> win_id -> list_id;
lvars prompt list_label button_label win_desc
    win_id control_id label_id list_id select_id;

    unless (ui_options_table(MULTI_SELECT_XWIN) ->> win_desc) and
      XptIsLiveType(subscrv(1, win_desc), "Widget") then

        create_x_selection_win(prompt, true, multichoice_select_cb,
            multichoice_dismiss_cb, multichoice_popdown_cb)
                -> win_id -> control_id -> label_id -> list_id -> select_id;

        consvector(win_id, label_id, list_id, select_id, 4) ->> win_desc
            -> ui_options_table(MULTI_SELECT_XWIN);

        XtRealizeWidget(win_id);
        XptCenterWidgetOn(win_id, "screen");
    endunless;

    fast_subscrv(1, win_desc) -> win_id;
    fast_subscrv(2, win_desc) -> label_id;
    fast_subscrv(3, win_desc) -> list_id;
    fast_subscrv(4, win_desc) -> select_id;

    prompt -> XptValue(win_id, XtN title, TYPESPEC(:XptString));
#_IF DEF XOPENLOOK
    list_label -> XptValue(label_id, XtN string, TYPESPEC(:XptString));
    button_label -> XptValue(select_id, XtN label, TYPESPEC(:XptString));
#_ELSEIF DEF XMOTIF
    list_label -> XptValue(label_id, XmN labelString, TYPESPEC(:XmString));
    button_label -> XptValue(select_id, XmN labelString, TYPESPEC(:XmString));
#_ENDIF
enddefine;


define :inline constant EXIT_ACTION(action);
    dlocal 0 %, if dlocal_context fi_< 3 then
                    action
                endif%;
enddefine;


#_IF (DEF XOPENLOOK and not(DEFV XLINK_VERSION > 2005))
;;; These two routines solve a problem which causes early OLIT versions
;;; to lock if the same popup dialog is used in quick succession. These
;;; routines are called from a timer which causes the window to be mapped
;;; unless the window has already been dismissed. Timer is currently set
;;; to go off 1 second after the window has supposedly been popped up.
;;;
define lconstant map_singlechoice_win(win_id);
lvars win_id;

    unless single_selection_made or single_selection_dismissed then
        XtMapWidget(win_id);
    endunless;
enddefine;


define lconstant map_multichoice_win(win_id);
lvars win_id;

    unless multi_selection_made or multi_selection_dismissed then
        XtMapWidget(win_id);
    endunless;
enddefine;
#_ENDIF


define get_singlechoice_result(win_id, list_id) -> val;
lvars win_id list_id val old_busy = XptBusyCursorOn;

    procedure;
        EXIT_ACTION((
                     XtPopdown(win_id),
                     old_busy -> XptBusyCursorOn,
#_IF DEF XMOTIF
                     XtUnmanageChild(win_id),
#_ENDIF
                    ));

        true -> XptBusyCursorOn;
        XtPopup(win_id, XtGrabExclusive);
#_IF DEF XMOTIF
        XtManageChild(win_id);
#_ENDIF
        false ->> single_selection_made ->> single_selection_dismissed
            -> current_singleselect_item;

#_IF (DEF XOPENLOOK and not(DEFV XLINK_VERSION > 2005))
        1e6 -> sys_timer(map_singlechoice_win(%win_id%));
#_ENDIF

        until single_selection_made or single_selection_dismissed do
            syshibernate();
        enduntil;
        (single_selection_made == true) -> val;
    endprocedure();
enddefine;


define get_multichoice_result(win_id, list_id) -> val;
lvars win_id list_id val old_busy = XptBusyCursorOn;

    procedure;
        EXIT_ACTION((
                     XtPopdown(win_id),
                     old_busy -> XptBusyCursorOn,
#_IF DEF XMOTIF
                     XtUnmanageChild(win_id),
#_ENDIF
                    ));

        true -> XptBusyCursorOn;
        XtPopup(win_id, XtGrabExclusive);
#_IF DEF XMOTIF
        XtManageChild(win_id);
#_ENDIF
        false ->> multi_selection_made -> multi_selection_dismissed;

#_IF (DEF XOPENLOOK and not(DEFV XLINK_VERSION > 2005))
        1e6 -> sys_timer(map_multichoice_win(%win_id%));
#_ENDIF

        until multi_selection_made or multi_selection_dismissed do
            ;;; XtAppProcessEvent(XptDefaultAppContext, XtIMAll);
            syshibernate();
        enduntil;
        (multi_selection_made == true) -> val;
    endprocedure();
enddefine;


define /* constant */ nn_singlechoice_x(choice_list, prompt, list_label, action_label) -> val;
lvars choice_list prompt list_label action_label val
    win_id list_id;

    get_singlechoice_win(prompt, list_label, action_label) -> win_id -> list_id;
    update_list_widget(list_id, choice_list);
    XptAppTryEvents(XptDefaultAppContext);
    get_singlechoice_result(win_id, list_id) -> val;

    if val then
        selected_list_item(list_id) -> val;
    else
        false -> val;
    endif;
enddefine;


define /* constant */ nn_multichoice_x(choice_list, prompt, list_label, action_label) -> vals;
    lvars choice_list prompt list_label action_label vals win_id list_id;

    get_multichoice_win(prompt, list_label, action_label) -> win_id -> list_id;
    update_list_widget(list_id, choice_list);
    get_multichoice_result(win_id, list_id) -> vals;

    if vals then
        flatten(selected_list_items(list_id)) -> vals;
    else
        false -> vals;
    endif;
enddefine;

#_ENDIF


/* ----------------------------------------------------------------- *
     Generic Graphics Dialog Functions
 * ----------------------------------------------------------------- */

;;; Generic graphics panel and options display functions. Arguments
;;; are left on the stack.

global vars procedure nn_singlechoice_gfx =
    CHECK_GFXSWITCH nn_singlechoice_x nn_singlechoice_pwm
                    nn_singlechoice_gfx;

global vars procedure nn_multichoice_gfx =
    CHECK_GFXSWITCH nn_multichoice_x nn_multichoice_pwm nn_multichoice_gfx;


/* ----------------------------------------------------------------- *
    Graphics Menu Create And Display Functions
 * ----------------------------------------------------------------- */

#_IF DEF PWMNEURAL
;;; popup_menu_pwm is used to popup a menu and then apply its
;;; result. Note that the win_id and x and y location of the mouse
;;; event which caused the popup is ignored by PWM.
;;;
define /* constant */ popup_menu_pwm(n_args, win_id, mouse_x, mouse_y, menu_name);
lvars n_args win_id mouse_x mouse_y menu_name
    menu options values val = false, int = false;

    gfxmenu_table(menu_name) -> menu;
    dest(menu) -> values -> options;

    pwm_displaymenu(options) -> int;
    if int and int > 0 then
        menu_valof(values(int))
    else
        false
    endif -> val;

    if val then
        ;;; any arguments needed should be on the stack
        apply(val);
    else
        ;;; erase the arguments on the stack
        erasenum(n_args);
    endif;
enddefine;
#_ENDIF


#_IF DEF XNEURAL
lvars menu_value_x = false;

;;; used to notify if an option has been selected
;;;
define xmenu_select_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    clientdata -> menu_value_x;
enddefine;

;;; used to notify if the menu has been popped down without an option
;;; being selected
;;;
define xmenu_dismiss_cb(widget, clientdata, calldata);
lvars widget clientdata calldata;

    ;;; make sure dismiss doesn't overwrite any existing value
    unless menu_value_x then
        undef -> menu_value_x;
    endunless;
enddefine;

;;; gen_x_popup_menu returns a popup menu widget with the required
;;; title and options
define gen_x_popup_menu(title, options, procs) -> popup_menu;
lvars parent index option proc options procs popup_menu flag = true;

#_IF DEF XOPENLOOK
    lvars newmenu_pane newmenu_widget newmenu_button;

    XtVaCreatePopupShell(title, xolMenuShellWidget,
        nn_app_shell, XptVaArgList([{pushpin ^OL_NONE}])) -> popup_menu;

    XptValue(popup_menu, XtN menuPane, TYPESPEC(:XptWidget))
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

        XtAddCallback(newmenu_button, XtN select, xmenu_select_cb, proc);
    endfast_for;

    XtAddCallback(popup_menu, XtN popdownCallback, xmenu_dismiss_cb, false);

#_ELSEIF DEF XMOTIF
    lvars newmenu_widget newmenu_button;

    XmCreatePopupMenu(nn_app_shell, title,
            XptArgList([{width 1} {height 1}
                    {deleteResponse ^XmUNMAP}])) -> popup_menu;

    fast_for index from 1 to length(options) do
        options(index) -> option;
        procs(index) -> proc;
        XtVaCreateManagedWidget(option, xmPushButtonWidget, popup_menu,
            XptVaArgList([{default ^flag}])) -> newmenu_button;

        if flag then false -> flag; endif;   ;;; first item is default
        XtAddCallback(newmenu_button, XmN activateCallback,
            xmenu_select_cb, proc);
    endfast_for;

    XtAddCallback(XtParent(popup_menu), XtN popdownCallback, xmenu_dismiss_cb, false);
#_ENDIF
enddefine;


;;; get_x_popup_selection pops up the menu once it has been created
;;; in the required window and position. Note that under OPEN LOOK,
;;; the win_id and x and y co-ords are ignored as OlMenuPost takes
;;; care of positioning the menu appropriately.
;;;
define get_x_popup_selection(win_id, mouse_x, mouse_y, menu_struct) -> val;
lvars menu_struct val old_busy = XptBusyCursorOn;

    procedure;
        EXIT_ACTION((
#_IF DEF XMOTIF
                    XtUnmanageChild(menu_struct),
#_ENDIF
                    old_busy -> XptBusyCursorOn));
        true -> XptBusyCursorOn;
        false -> menu_value_x;
#_IF DEF XOPENLOOK
        OlMenuPost(menu_struct);
#_ELSEIF DEF XMOTIF
        lvars menu_x menu_y;
        fast_XptValue(XtParent(win_id), XtN x, "short") + mouse_x -> menu_x;
        fast_XptValue(XtParent(win_id), XtN y, "short") + mouse_y -> menu_y;
        XtVaSetValues(menu_struct, XptVaArgList([{x ^menu_x} {y ^menu_y}]));
        XtManageChild(menu_struct);
#_ENDIF
        until menu_value_x do
            XtAppProcessEvent(XptDefaultAppContext, XtIMAll);
        enduntil;
        menu_value_x -> val;
    endprocedure();

    unless isprocedure(val) then
        false -> val;
    endunless;
enddefine;

;;; popup_menu_x is used to popup an menu and then apply its
;;; result
define /* constant */ popup_menu_x(n_args, win_id, mouse_x, mouse_y, menu_name);
lvars n_args win_id mouse_x mouse_y menu_name menu_struct
    menu_struct_name menu options values val = false, int = false;

    gfxmenustruct_id(menu_name) -> menu_struct_name;
    unless (gfxmenu_table(menu_struct_name) ->> menu_struct) and
      XptIsLiveType(menu_struct, "Widget") then
        gfxmenu_table(menu_name) -> menu;
        dest(menu) -> values -> options;
        gen_x_popup_menu(hd(options), tl(options), values) ->>
            gfxmenu_table(menu_struct_name) -> menu_struct;
        XtRealizeWidget(menu_struct);
    endunless;

    get_x_popup_selection(win_id, mouse_x, mouse_y, menu_struct) -> val;

    if val then
        ;;; any arguments needed should be on the stack
        apply(val);
    else
        ;;; erase the arguments on the stack
        erasenum(n_args);
    endif;
enddefine;
#_ENDIF

global vars procedure popup_menu_gfx =
    CHECK_GFXSWITCH popup_menu_x popup_menu_pwm popup_menu_gfx;


;;; select_window_dimensions takes a list of 2-element vectors,
;;; converts them to a list of strings which the user is then asked
;;; to select from to get their desired dimensions for the weights/activs
;;; /bias window etc. Note that the user will be given the choice even
;;; if there is only one possible selection since this gives the opportunity
;;; to cancel the operation.
;;;
define select_window_dimensions(dimensions) -> dimension;
lvars dimensions dimension choice_list choice;

    define lconstant vec_to_string(vec) -> str;
    lvars vec str;
        sprintf(subscrv(2, vec), subscrv(1, vec), '%p x %p') -> str;
    enddefine;

    define lconstant string_to_vec(str) -> vec;
    lconstant vec = writeable initv(2);
    lvars str num1 num2 num1_index len = length(str);

        strnumber(substring(1, (locchar(` `, 1, str) ->> num1_index) - 1,
                    str)) -> num1;
        strnumber(substring(num1_index + 3, len - num1_index - 2,
                    str)) -> num2;
        num1 -> fast_subscrv(1, vec);
        num2 -> fast_subscrv(2, vec);
    enddefine;

    maplist(dimensions, vec_to_string) -> choice_list;
    nn_singlechoice_gfx(choice_list, 'Possible Window Dimensions',
                        'Dimensions', 'Select') -> choice;

    if choice then
        string_to_vec(choice)
    else
        false
    endif -> dimension;
    sys_grbg_list(choice_list);
enddefine;

endsection;     /* $-popneural */


/*  --- Revision History --------------------------------------------------
-- Julian Clinton, 1/9/93
    Added include of xpt_coretypes;
-- Julian Clinton, 17/8/93
    Changed #_IF X* to #_IF DEF X*.
-- Julian Clinton, 23/11/92
    Added code to force choice windows to be mapped under early OLIT
    versions.
-- Julian Clinton, 17/11/92
    Deleted centering dialog on screen code from get_*_result.
    Removed some references to identifiers in section $-poplog_ui.
-- Julian Clinton, 10/11/92
    Modified last change so that XptWMProtocols is true for OPEN LOOK 1.3.
-- Julian Clinton, 14/9/92
    dlocal'd XptWMProtocols false for both Motif and OPEN LOOK.
    Added XptDeleteResponse.
*/
