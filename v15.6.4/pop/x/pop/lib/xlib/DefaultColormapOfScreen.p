/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            C.x/x/pop/lib/xlib/DefaultColormapOfScreen.p
 > Purpose:         Default colormap of a screen
 > Author:          Adrian Howard, Jun 21 1993 (see revisions)
 > Documentation:   * DefaultColormapOfScreen
 > Related Files:	LIB * XPT_SCREENINFO, LIB * XColormaps,
 >					LIB * XlibMacros
 */

compile_mode: pop11 +strict;
section;

uses fast_xpt_screeninfo;

/*
 * Moved from ___LIB * __________XlibMacros and ___LIB * __________XColormaps to avoid code
 * duplication
 */

define DefaultColormapOfScreen = fast_XDefaultColormapOfScreen enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Adrian Howard, Jul  4 1993
		Now uses ___LIB * ___________________FAST_XPT_SCREENINFO
 */
