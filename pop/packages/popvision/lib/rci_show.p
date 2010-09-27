/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/rci_show.p
 > Purpose:         Straightforward image display under X
 > Author:          David S Young, Nov 26 1992 (see revisions)
 > Documentation:   HELP *RCI_SHOW
 > Related Files:   LIB *RC_GRAPHIC, LIB *RC_IMAGE, LIB*RC_ARRAY
 */

compile_mode:pop11 +strict;

section;

uses xlib
uses XlibMacros
uses popvision
uses rc_image;

vars
    rci_show_black = false,
    rci_show_white = false,
    rci_show_xshift = false,
    rci_show_yshift = false,

    rci_show_cursorcoords = true;

#_IF not(DEF rc_mousing)
;;; Need to test rc_mousing
vars rc_mousing = false;
#_ENDIF

lvars
    scale = 1,
    windows = [],   ;;; For garbage collection protection
    show_x = rc_window_x,
    show_y = rc_window_y,
    max_y = 0;

define active rci_show_scale; scale; enddefine;
define updaterof active rci_show_scale(s);
    checkinteger(s, 1, false);
    s -> scale
enddefine;

;;; Position has to be active as need to reset max_y.
define active rci_show_x; show_x; enddefine;
define updaterof active rci_show_x(x);
    x -> show_x;
    0 -> max_y
enddefine;

define active rci_show_y; show_y; enddefine;
define updaterof active rci_show_y(y);
    y -> show_y;
    0 -> max_y
enddefine;

define rci_show_setcoords(b);
    ;;; Set the user coordinates non-locally so as to map user coordinates
    ;;; onto array coordinates.
    if b.isarray then boundslist(b) -> b endif;
    scale ->> rc_xscale -> rc_yscale;
    lvars
        (x0, x1, y0, y1) = explode(b);
    -0.5 - (x0-0.5) * scale -> rc_xorigin;
    -0.5 - (y0-0.5) * scale -> rc_yorigin;
    (x1 - x0 + 1) * scale -> rc_window_xsize;
    (y1 - y0 + 1) * scale -> rc_window_ysize;
    0 ->> rc_xmin -> rc_ymin;
    rc_window_xsize - 1 -> rc_xmax;
    rc_window_ysize - 1 -> rc_ymax;
enddefine;


define lconstant screensize /* -> (width, height) */;
    ;;; Returns the size of the screen.
    ;;; Thanks to Aaron Sloman for how to do this.
    unless XptDefaultDisplay then XptDefaultSetup() endunless;
    XDisplayWidth(XptDefaultDisplay,0) /* -> width */;
    XDisplayHeight(XptDefaultDisplay,0) /* -> height */;
enddefine;

/* This is the old version of screensize, retained in case there's
some unexpected problem with the new one above.

uses xpt_screeninfo

    ;;; Get a widget - any widget. rc_graphic uses this type already.
    lconstant AppShell = XptWidgetSet("Toolkit")("ApplicationShellWidget");
    lvars widget
        = XtAppCreateShell('temp', 'temp', AppShell, XptDefaultDisplay, []);
    ;;; Get the screen
    lvars screen = XtScreen(widget);
    ;;; No need for the widget any more
    XtDestroyWidget(widget);
    ;;; Get the width and height of the screen
    XWidthOfScreen(screen) /* -> width */;
    XHeightOfScreen(screen) /* -> height */;
*/

;;; Hold screen size here - but defer setting these variables until first
;;; use in case building a saved image.
lvars screenx = false, screeny = false;

define vars procedure rci_show_pause; enddefine;

define lconstant shiftpos_pre;
    ;;; If the display would go off the screen, and shifting is in effect,
    ;;; jump back to the left or the top. The rc size parameters should have
    ;;; already been set for the window to be displayed.
    unless screenx and screeny then
        screensize() -> (screenx, screeny)
    endunless;
    if rci_show_xshift and show_x + rc_window_xsize > screenx then
        0 -> show_x;
        if rci_show_yshift then
            max_y + rci_show_yshift -> show_y
        endif;
        0 -> max_y;
    endif;
    if rci_show_yshift and show_y + rc_window_ysize > screeny then
        0 -> show_y;
        if rci_show_xshift then
            0 -> show_x
        endif;
        0 -> max_y;
    endif
enddefine;

define lconstant shiftpos_post;
    ;;; Shifts the rc_window origin parameters ready for the next window.
    if rci_show_xshift then
        show_x + rc_window_xsize + rci_show_xshift -> show_x;
        max(show_y + rc_window_ysize, max_y) -> max_y
    endif
enddefine;


/*
Main procedure.

A simple procedure for creating a new window with a single image in it.
Clicking on the window gets rid of it (unless rc_mousing is true).

Optional second argument permits existing window to be used - but
image will be shown in top-left corner regardless of rc_xscale etc.

Optional third argument, if true, causes global rc coordinates to be
set up to correspond to image coordinates. (Done in wrapper procedure
to be outside dlocalisation. */

define lconstant rci_show_local(image, window) -> rc_window;
    dlocal
        rc_window = window,
        rc_window_x, rc_window_y,
        rc_window_xsize, rc_window_ysize,
        rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
        rc_xmin, rc_xmax, rc_ymin, rc_ymax;

    lvars newwindow = not(rc_window.xt_islivewindow);

    rci_show_setcoords(image);
    rci_show_pause();
    if newwindow then
        shiftpos_pre();
        show_x -> rc_window_x;
        show_y -> rc_window_y;
    endif;

    if image.isarray then
        rc_image(image, false, false, rci_show_black, rci_show_white)
    elseif newwindow then   ;;; just create the right sized window
        rc_new_window(      ;;; not rc_start, which reset coords
            rc_window_xsize, rc_window_ysize, rc_window_x, rc_window_y, false)
    else
        rc_clear_window()   ;;; maybe should just clear a region
    endif;

    if newwindow then shiftpos_post() endif;

    ;;; Callback procedures

    define lconstant showpos(w, client_data, call_data);
        ;;; Expect call data to hold the transform for this image
        dlocal pop_pr_ratios = false;
        lvars (xorigin, yorigin, xscale, yscale) = explode(client_data);
        lvars (x, y) = XptVal[fast] w(XtN mouseX, XtN mouseY);
        round((x - xorigin)/xscale) -> x;
        round((y - yorigin)/yscale) -> y;
        x >< ', ' >< y
            -> XptValue(XtParent(w), XtN title, TYPESPEC(:XptString))
    enddefine;

    define lconstant destroy(w, x, call_data);
        ;;; Button releases only
    returnif (rc_mousing or exacc ^int call_data > 0);
        XptDestroyWindow(w);
        ncdelete(w, windows, nonop ==) -> windows;
    enddefine;

    ;;; Need to store the transform params for the window
    ;;; only in order to remove the callback procedure in case the
    ;;; window is reused with a different origin or scale
    lconstant transprop = newproperty([], 50, false, "tmparg");

    ;;; If this is a locally created window then hang on to it to
    ;;; avoid garbage collections and set up button callback to destroy it
    if newwindow then
        conspair(rc_window, windows) -> windows;
        XtAddCallback(rc_window, XtN buttonEvent, destroy, 0);
    else  ;;; remove any old motion callback
        lvars otrans = transprop(rc_window);
        if otrans then
            XtRemoveCallback(rc_window, XtN motionEvent, showpos, otrans)
        endif
    endif;

    ;;; Add a motion callback
    if rci_show_cursorcoords then
        ;;; Pack up current transform and save it
        lvars ctrans = {% rc_xorigin, rc_yorigin, rc_xscale, rc_yscale %};
        ctrans -> transprop(rc_window);
        ;;; Add motion callback for current transform
        XtAddCallback(rc_window, XtN motionEvent, showpos, ctrans)
    endif

enddefine;

define rci_show(image) -> window;
    lvars setcoords = false;
    false -> window;
    ;;; Get optional arguments
    unless image.isarray or image.islist then
        image -> (image, window)
    endunless;
    unless image.isarray or image.islist then
        (image, window) -> (image, window, setcoords)
    endunless;
    rci_show_local(image, window) -> window;
    if setcoords then rci_show_setcoords(image) endif
enddefine;

/*
Extra procedures
*/

define rci_show_destroy(n);
    ;;; If n is a window that rci_show created, destroy it. Otherwise,
    ;;; if n is an integer destroy the last n windows; otherwise destroy them all.
    ;;; Need check in next procedure because windows may have been destroyed
    ;;; from other procedures.
    define lconstant destroy(w);
        if w.xt_islivewindow then
            XptDestroyWindow(w)
        endif
    enddefine;
    if lmember(n, windows) then
        destroy(n);
        ncdelete(n, windows, nonop ==) -> windows;
    elseif n.isinteger then
        repeat n times
        quitif(windows == []);
            destroy(destpair(windows) -> windows);
        endrepeat
    else
        applist(windows, destroy);
        [] -> windows
    endif
enddefine;

define rci_show_setframe(b, display_region);
    ;;; Set the coordinates non-locally to make the display_region
    ;;; correspond to the outer edge of the
    ;;; image given by b, assuming that b is displayed on the window
    ;;; in the way rci_show does it.
    lvars xsize, ysize;
    if b.isarray then boundslist(b) -> b endif;
    lvars
        (ax0, ax1, ay0, ay1) = explode(b),
        (px0, px1, py0, py1) = explode(display_region);

    (ax1 - ax0 + 1) * scale / (px1 - px0) -> rc_xscale;
    -0.5 - rc_xscale * px0 -> rc_xorigin;
    (ay1 - ay0 + 1) * scale / (py1 - py0) -> rc_yscale;
    -0.5 - rc_yscale * py0 -> rc_yorigin;
enddefine;

define rci_drawpoint(/*x, y*/);
    lvars x, y, xe, xf, yf;
    rc_transxyout(rc_getxy()) -> (x, y);
    x - rc_xscale div 2 -> x;
    y - rc_yscale div 2 -> y;
    x + rc_xscale - 1 -> xe;
    fast_for yf from y to y + rc_yscale - 1 do
        fast_for xf from x to xe do
            XpwDrawPoint(rc_window, xf, yf)
        endfor
    endfor
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jul  3 2000
        Added rci_show_cursorcoords to allow cursor position display to be
        switched off. Made window position adjustment contingent on
        having created a new window.
--- David Young, May 30 2000
        Fixed bug which caused window arg to be ignored if a list
        given as first arg. Now just clears such a window - really ought
        to just clear a region.
--- David Young, May 25 2000
        Added live window check to rci_show_destroy, and allowed argument
        to be a window to destroy.
--- David Young, May 22 2000
        Replaced call to rc_start with rc_new_window to avoid resetting coords
--- David Young, Mar  2 2000
        Changed display of x,y coords to use coordinate system appropriate
        to image rather than current rc_graphic coords, and to round.
--- David Young, Feb 28 2000
        Greatly simplified definition of screensize.
--- David Young, Feb 17 2000
        Added optional 3rd arg to globally set coord transform.
        Added callback to show x,y coords in title bar.
--- David S Young, Sep 19 1995
        Put call to XptDefaultSetup into screensize.
--- David S Young, Feb 21 1995
        Changed test for locally created window from not(rc_window)
        to not(rc_window.xt_islivewindow).
        Destruction procedure now tests for rc_mousing, and does not
        destroy the window if mousing is switched on.
--- David S Young, Jan 12 1994
        Deferred evaluation of screenx and screeny for saved images.
--- David S Young, Nov 29 1993
        Added -rci_show_destroy-.
--- David S Young, Jul 19 1993
        Can now lay out the windows across the screen using -rci_show_xshift-,
        -rci_show_yshift, -rci_show_x- and -rci_show_y-.
--- David S Young, Jun  9 1993
        Changed to clear window if list instead of array given.
--- David S Young, Mar  1 1993
        Uses improved mapping in -rc_image-, and -rci_drawpoint- added.
--- David S Young, Jan  8 1993
        Loads LIB RCG_UTILS for versions earlier than 14.22.
 */
