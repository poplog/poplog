/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            C.all/x/pop/auto/XptDeleteResponse.p
 > Purpose:         Changes handling of WM_DELETE_WINDOW messages
 > Author:          Jonathan Meyer, Nov 27 1991
 > Documentation:   REF *XptDeleteResponse
 > Related Files:
 */
compile_mode :pop11 +strict;
section;

exload_batch;

uses xpt_atomcache;
uses xt_event;
uses fast_xt_display;
uses fast_xt_widgetinfo;

include xpt_xevent.ph;
include xpt_constants.ph;
include xt_constants.ph;

endexload_batch;

lconstant actionsTable = newproperty([], 10, false, "tmparg");

define global XptDeleteResponse(widget);
    lvars widget, action;
    actionsTable(XptDescriptor(XptShellOfObject(widget), XDT_WIDGET))-> action;
    action and fast_back(action);
enddefine;

define updaterof XptDeleteResponse(response, widget);
    lvars response, widget, shell_widget;

    ;;; Client_message_cb:
    ;;;     event handler for ClientMessage events.
    ;;;     may  be  called  quite  frequently,  so  efficiency  counts
    define lconstant Client_message_cb(shell, client, event) -> carry_on;
        lvars shell, client, widget, event, action, carry_on = true, disp;
        l_typespec event :XClientMessageEvent;

        define :inline lconstant ATOM(name);
            XptInternAtom(disp, name, false)
        enddefine;

        if exacc [fast] event.type == ClientMessage and
          (fast_XtDisplay(shell)->disp,
          exacc [fast] event.message_type == ATOM("WM_PROTOCOLS")) and
          exacc :uint (exacc [@] event.data) == ATOM("WM_DELETE_WINDOW") then
            if actionsTable(XptDescriptor(shell, XDT_WIDGET)) ->> action then
                fast_destpair(action) -> (widget, action);
                if widget == undef then shell -> widget endif;
                if XptIsLiveType(widget, XDT_WIDGET) then
                    XptCallbackHandler(widget, action, "delete_window")
                endif;
                unless XptIsLiveType(widget, XDT_WIDGET) then
                    ;;; the delete_window action did me in
                    false -> actionsTable(shell);
                endunless;
                false -> carry_on;
            endif;
        endif;
    enddefine;

    XptDescriptor(XptShellOfObject(widget), XDT_WIDGET) -> shell_widget;

    unless response.isprocedure or response.isword or
            response.isident or not(response) then
        mishap(response,1,'WIDENTPROC or -false- NEEDED');
    endunless;

    unless fast_XtIsRealized(widget) then
        mishap(widget,1, 'REALIZED WIDGET NEEDED');
    endunless;

    if response and not(actionsTable(shell_widget)) then
        ;;; register event handler
        XtInsertEventHandler(shell_widget, NoEventMask, true,
                Client_message_cb, false, XtListHead);
    else
        ;;; unregister event handler
        XtRemoveEventHandler(shell_widget, NoEventMask, true,
                Client_message_cb, false);
    endif;
    ;;; we do this so we don't keep a handle on the shell widget.
    if widget == shell_widget then undef -> widget endif;
    response and conspair(widget, response) -> actionsTable(shell_widget);
enddefine;

endsection;

/*
XptDeleteResponse(WIDGET) -> WIDENTPROC                      [procedure]
WIDENTPROC -> XptDeleteResponse(WIDGET)                      [procedure]
        A high level autoloadable procedure for setting the response  of
        a Shell widget to the 'WM_DELETE_WINDOW' window manager protocol
        message, which is sent by a window manager to a client when  the
        shell widget should be removed from the workspace.

        WIDGET must  be  realized  before  setting  a  delete  response.
        Setting a delete response overrides any previous widget handling
        for the WM_DELETE_WINDOW for WIDGET.

        WIDENTPROC  should  be  a  procedure,  or  a  word/ident   which
        evaluates to a procedure. The procedure is passed WIDGET as  its
        only argument. ie. the form for WINDENTPROC is:

                delete_response(WIDGET)

        The delete response  procedure should decide  whether to  accept
        the request to delete the window, and call for example XtPopdown
        or XtDestroyWidget to close the window. Useful procedures to use
        as a simple delete response procedures are:

            -erase-
                Assigning -erase- as  the delete response  for a  window
                causes WM_DELETE_WINDOW messages to be ignored.

            XtPopdown
                Causes   the   window   to   be   popped   down   when a
                WM_DELETE_WINDOW  message   arrives  (useful  for  popup
                shells).

            XtDestroyWidget
                The widget  will be destroyed  when  a   WM_DELETE_WINDOW
                message is received.

            XtUnmapWidget
                The  widget will be unmapped when  a WM_DELETE_WINDOW  is
                received.

            XtUnmanageChild
                This delete response is useful as a way to pop down Motif
                dialog boxes.

        Note that, if WIDGET is  not a shell widget,  -XptShellOfObject-
        is used to find  the nearest ancester shell  of WIDGET, and  the
        delete response  for that  widget is  returned/updated  instead.
        However, when the delete response  is invoked, WIDENT is  always
        called   with    the    WIDGET    that    you    specified    to
        -XptDeleteResponse-.  This  allows  you  to  direct  the  delete
        response handling for a shell widget to one of its children.

        Note that WIDENTPROC will be -false- for widgets which have  not
        had  a  delete  response  specified.  You  can  also   specify a
        WIDENTPROC of  -false- as  the  delete action  for a  widget  to
        cancel handling of WM_DELETE_WINDOW messages for that widget. If
        there is no specified delete  response for WIDGET, the  reaction
        of the widget to WM_DELETE_WINDOW is unspecified.

        The delete response procedure is called via -XptCallbackHandler-
        with a TYPE argument of "delete_window". You can therefore trace
        delete response actions by doing:

            [delete_window] -> XptTraceCallback;

        The following example will make the delete response for an  XVed
        window be to print something. NB. After doing this, you will not
        be able to  use the  window manager  to close  the current  XVed
        window (use <ENTER> q instead):

            npr -> XptDeleteResponse(wvedwindow);
*/
