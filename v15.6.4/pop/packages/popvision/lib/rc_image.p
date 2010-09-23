/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/rc_image.p
 > Purpose:         Image display in user-settable coordintes
 > Author:          David Young, Jan 25 1991 (see revisions)
 > Documentation:   HELP * RC_IMAGE, TEACH * RC_IMAGE
 > Related Files:   LIB * RC_GRAPHIC
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses rc_array;

lvars
    colour_rule = "linear",
    palette = "greyscale";

define rc_image(arr, position, region, bmin, bmax);
    lvars arr region position bmin bmax;
    rc_array(arr, region, position, [^colour_rule ^bmin ^bmax], palette)
enddefine;

/* Procedure for changing colour map */

define rci_cmap(option);
    lvars option;
    if option == "linear" then
        option -> colour_rule;
        "greyscale" -> palette
    elseif option == "sqrt" then
        option -> colour_rule;
        "greyscale" -> palette
    elseif option.islist then
        "linear" -> colour_rule;
        option -> rc_spectrum;
        "spectrum" -> palette
    elseif option.isvector then
        "direct" -> colour_rule;
        option -> palette
    else
        mishap(option, 1, 'Unrecognised option')
    endif;
enddefine;

define rci_default_coords;
    rc_win_coords()
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Feb 20 1994
        Superseded by * RC_ARRAY.  The main change is that RC_ARRAY uses
        lookup tables instead of linear mapping, so is much more flexible
        - it can cope with a discontinuous bit of the colour map and
        offers the user many more display options.  The arguments were
        rationalised a little so the name was changed.  This file should
        be withdrawn at some point.
--- David S Young, Nov 29 1993
        Stopped using Xpi, as it is a maintenance problem as well as being
        a sledgehammer to crack a nut in most cases. This means that the
        library is now only usable on 8-bit colour machines, and that
        plenty of colour map entries must be available.
        Added -rci_cmap-.
        Reorganised the whole of the rest of the library.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid name clash with *VEC_MAT package.
--- David S Young, Jul 13 1993
        Uses LIB *ARRAY_MXMN for grey-scale setting (faster)
--- David S Young, Mar  1 1993
        Changed -getwinreg- to be more sensible - DISPLAY_REGION argument
        now refers to outside limit of array consistently, and if given as
        <false>, user coords map to centres of pixels.
--- David S Young, Nov 26 1992
        Introduced -rci_colours- to stop colourmap hogging
--- David S Young, Jun 19 1992
        Gets -isfloatarray- from LIB *NEWFLOATARRAY
--- David S Young, Jun 11 1992
        Completely revised: now handles byte and float arrays efficiently
        using *ARRAYSAMPLE, and uses *Xpi to do the displaying
--- David S Young, Jan  8 1992 XpwCopyFrom removed
--- David S Young, Jul  9 1991 XpwCopyFrom used as temporary fix
--- David S Young, Jul  8 1991 Changed origin to 0 in rci_default_coords
--- David Young, Feb 13 1991 Changes Xpw routines for V.14.
--- David Young, Feb  7 1991 Fixed minor bugs and avoided haltoning when
    binary array is input
 */
