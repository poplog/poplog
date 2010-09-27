/* --- Copyright University of Sussex 1991. All rights reserved. ----------
 > File:            C.all/x/pop/auto/XptResizeResponse.p
 > Purpose:         Sets callback for widget resize events
 > Author:          Jonathan Meyer, Nov 27 1991
 > Documentation:   REF *XptResizeResponse
 > Related Files:
 */

compile_mode :pop11 +strict;

exload_batch;

uses xt_event;
uses fast_xt_display;
uses fast_xt_widgetinfo;

include xpt_xevent.ph;
include xpt_constants.ph;
include xt_constants.ph;

endexload_batch;


lconstant actionsTable = newproperty([], 10, false, "tmparg");

define global XptResizeResponse(widget);
    lvars widget, action;
    actionsTable(XptDescriptor(widget, XDT_WIDGET))
enddefine;

define updaterof XptResizeResponse(response, widget);
    lvars response, widget, widget;
    l_typespec
    XConfigureEvent {
        type: int,
        serial: ulong,
        send_event: XBool,
        display: XptDisplayPtr,
        event: XptWindow,
        window: XptWindow,
        x: int,
        y: int,
        width: int,
        height: int,
        border_width: int,
        above: XptWindow,
        override_redirect: XBool,
    },
    ;


    define lconstant Resize_cb(w, client, event);
        lvars w, client, event, width, height, action;

        l_typespec event :XConfigureEvent;
        if exacc event.type == ConfigureNotify then
            XptWidgetCoords(w) -> (,, width, height);
            if width /== exacc event.width or height /== exacc event.height
            then
                XptDeferApply(XptCallbackHandler(%w, actionsTable(XptDescriptor(w, XDT_WIDGET)), "resize_window"%));
                XptSetXtWakeup();
            endif;
        endif;
    enddefine;

    XptDescriptor(widget, XDT_WIDGET) -> widget;

    unless response.isprocedure or response.isword or
        response.isident or not(response) then
        mishap(response,1,'WIDENTPROC or -false- NEEDED');
    endunless;

    unless fast_XtIsRealized(widget) then
        mishap(widget,1, 'REALIZED WIDGET NEEDED');
    endunless;

    if response and not(actionsTable(widget)) then
        ;;; register event handler
        XtInsertEventHandler(widget, StructureNotifyMask, false,
            Resize_cb, false, XtListHead);
    else
        ;;; unregister event handler
        XtRemoveEventHandler(widget, StructureNotifyMask, false,
            Resize_cb, false);
    endif;

    response -> actionsTable(widget);
enddefine;

