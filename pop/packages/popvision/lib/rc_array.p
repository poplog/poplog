/* --- Copyright University of Sussex 2001. All rights reserved. ----------
 > File:            $popvision/lib/rc_array.p
 > Purpose:         Image display under X, in user coordinates
 > Author:          David S Young, Feb 20 1994 (see revisions)
 > Documentation:   HELP * RC_ARRAY, TEACH * RC_ARRAY
 > Related Files:   LIB * RC_GRAPHIC
 */

/*

This library was originally set up for use with 8-bit displays, which
use a colour map. It has been updated for 24-bit displays, but
unfortunately in the process the code has become rather untidy.

Processing is optimised for packed arrays of single precision floats or
bytes, as created by *NEWSFLOATARRAY and *NEWBYTEARRAY.

         CONTENTS - (Use <ENTER> g to access required sections)

 -- Libraries
 -- Global variables
 -- Display depth
 -- ... Miscellaneous routines
 -- Array resizing and value lookup
 -- ... Lookup to colour map entries for 8-bit displays
 -- ... Conversion to 32-bit arrays for 24-bit displays
 -- ... Main array conversion routine
 -- Generating look-up table
 -- ... Obtaining grey-level range for image
 -- ... Histogram equalisation thresholds
 -- ... Dealing with user options
 -- Positioning in window
 -- Overall array preparation procedure
 -- Colour map handling
 -- ... Spectrum generation
 -- ... 8 bits
 -- ... Compressing colour maps when not all entries are needed
 -- ... Allocating colourmap entries
 -- ... Setting up colour-map values
 -- ... 24 bits
 -- ... set colours - 8/24 bit
 -- Copying the image to the window
 -- Dealing with arrays by column
 -- Top-level procedures

The resizing and value lookup section knows how to convert any array
containing only numbers into an array suitable for passing to the X
DrawImage display method.  It needs to be told which part of the array
to use, the region of the window that will be used, in window
coordinates, and the mapping from data to colourmap indices or to r,g,b
values as a lookup table (see *ARRAYLOOKUP). This part knows nothing
about actual display, so is quite general.

The lookup table generation section converts the user options for colour
map specifications into a lookup table. On 8-bit systems it needs to
know the pixels in the colour map that have been allocated.

The positioning section knows about *RC_GRAPHIC coordinate conventions,
and so can work out what the display region should be in window
coordinates.  Getting this exactly right is quite delicate. Although
tied to RC_GRAPHIC in this case, the approach is general.

The overall array preparation procedure calls the main procedure from
each of the preceding sections to produce an array that can be drawn on
a suitable window.

The colour map section interprets the user options for colour map
specifications. On 8-bit systems it returns a vector of the pixel values
allocated. On 24-bit systems it returns the r,g,b values to which the
data are to be mapped.

*/

compile_mode:pop11 +strict;

section;

/*
-- Libraries ----------------------------------------------------------
*/

uses popvision;
uses xlib, XlibMacros;
uses rc_graphic;
uses boundslist_utils;
uses newbytearray;
uses newsfloatarray;
uses arraysample;
uses array_mxmn;
uses arraylookup;
uses array_hist;
uses Xcolour_to_rgb;
uses rgb_arrays;

/*
-- Global variables ---------------------------------------------------
*/

vars rc_array_sample = "nearest";

/*
-- Display depth ------------------------------------------------------
*/

lvars _display_depth = false;

define lconstant active display_depth;
    if _display_depth then
        _display_depth
    else
        unless XptDefaultDisplay then XptDefaultSetup() endunless;
        XDefaultDepth(XptDefaultDisplay,0) ->> _display_depth;
    endif
enddefine;

/*
-- ... Miscellaneous routines -----------------------------------------
*/

define lconstant isintarray(arr) /* -> result */;
    ;;; If an array can only hold integers, return no. bits.
    lvars k = arr.arrayvector.datakey.class_spec;
    if k.isinteger then k else false endif /* -> result */
enddefine;

define lconstant isbitarray(arr) /* -> result */;
    isintarray(arr) == 1 /* -> result */
enddefine;

define lconstant isbytearray(arr) /* -> result */;
    isintarray(arr) == 8 /* -> result */
enddefine;

define lconstant is24bitarray(arr) /* -> result */;
    isintarray(arr) == 24 /* -> result */
enddefine;

define lconstant is32bitarray(arr) /* -> result */;
    lvars nbits = isintarray(arr);
    nbits and abs(nbits) == 32 /* -> result */
enddefine;

define lconstant npoints(region) /* -> int */;
    lvars (x0, x1, y0, y1) = explode(region);
    (abs(x1 - x0) + 1) * (abs(y1 - y0) + 1)
enddefine;

define lconstant posbounds(reg1, reg2) -> (reg1, reg2);
    ;;; Makes sure that the bounds of reg1 are right way round - if
    ;;; any bound pair is not, then the corresponding bounds of reg2
    ;;; are also swapped
    lvars rebuild = false,
        (x01, x11, y01, y11) = explode(reg1),
        (x02, x12, y02, y12) = explode(reg2);
    if x01 > x11 then
        (x01, x11, x02, x12) -> (x11, x01, x12, x02); true -> rebuild
    endif;
    if y01 > y11 then
        (y01, y11, y02, y12) -> (y11, y01, y12, y02); true -> rebuild
    endif;
    if rebuild then
        [% x01, x11, y01, y11 %] -> reg1;
        [% x02, x12, y02, y12 %] -> reg2;
    endif
enddefine;

define lconstant ncshiftarr(arr, reg1, reg2) /* -> newarr */;
    ;;; Return an array sharing the arrayvector of arr, with
    ;;; reg1 in arr mapped to reg2 in newarr. Returns false if
    ;;; region sizes do not match.  2-D only.
    lvars
        (x0, x1, y0, y1) = explode(boundslist(arr)),
        (x01, x11, y01, y11) = explode(reg1),
        (x02, x12, y02, y12) = explode(reg2),
        xsh = x02 - x01,
        ysh = y02 - y01;
    if xsh == x12 - x11 and ysh = y12 - y11 then
        if xsh == 0 and ysh == 0 then
            arr
        else
            lvars ( , v0) = arrayvector_bounds(arr);
            newanyarray([% x0+xsh, x1+xsh, y0+ysh, y1+ysh %], arr, v0-1)
        endif
    else
        false
    endif
enddefine;

define lconstant app_one_or_more(arr_vec, proc) /* -> result */;
    ;;; If arr_vec is not a vector, applies proc and returns result. If arr_vec
    ;;; is a vector applies proc to each element and returns
    ;;; vector of results.
    if arr_vec.isvector then
        mapdata(arr_vec, proc)
    else
        proc(arr_vec)
    endif
enddefine;

define lconstant allsame(vec) -> val;
    ;;; Checks that the elements of a vector are all equal; if so, returns
    ;;; one of them, otherwise false. If argument not a vector, just
    ;;; returns it.
    if vec.isvector then
        vec(1) -> val;
        lvars i;
        for i from 2 to length(vec) do
            if vec(i) /= val then
                false -> val;
                return
            endif
        endfor
    else
        vec -> val
    endif
enddefine;

define lconstant boundslist_one_or_more(arr_vec) -> bounds;
    ;;; If arr_vec is an array, returns its boundslist; if it is a vector,
    ;;; return intersection of boundslists.
    if arr_vec.isarray then
        boundslist(arr_vec) -> bounds
    else
        boundslist(arr_vec(1)) -> bounds;
        lvars i;
        for i from 2 to length(arr_vec) do
            region_intersect(bounds, arr_vec(i)) -> bounds
        endfor
    endif
enddefine;

define lconstant resize3(arrvec, regin, regout) /* -> newarrvec */;
    ;;; Calls resample on each array in a vector of 3.
    ;;; The result may include an array that reuses storage returned on
    ;;; an earlier call.
    lconstant tag1 = consref(0), tag2 = consref(0), tag3 = consref(0);
    lvars arrveckey = datakey(arrayvector(arrvec(1)));
    {%
        arraysample(arrvec(1), regin,
            oldanyarray(tag1, regout, arrveckey), regout, rc_array_sample),
        arraysample(arrvec(2), regin,
            oldanyarray(tag2, regout, arrveckey), regout, rc_array_sample),
        arraysample(arrvec(3), regin,
            oldanyarray(tag3, regout, arrveckey), regout, rc_array_sample)
        %}
enddefine;


/*
-- Array resizing and value lookup ------------------------------------
*/

/*
-- ... Lookup to colour map entries for 8-bit displays ----------------
*/

define lconstant arr_to_byte(arr, region, lut, arrout) -> arrout;
    lconstant lut256 = initbytevec(256);

    unless region then boundslist(arr) -> region endunless;

    unless arr.isbytearray
    and (lut == identfn or lut == round or lut == intof) then
        unless arrout then
            oldbytearray(arr_to_byte, region) -> arrout
        endunless;
        if arr.isbytearray and lut.isvectorclass and length(lut) < 256 then
            ;;; avoid arraylookup limitation
            move_subvector(1, lut, 1, lut256, length(lut));
            lut256 -> lut
        endif;
        arraylookup(arr, region, lut, arrout) -> arrout
    elseunless boundslist(arr) = region then
        unless arrout then
            oldbytearray(arr_to_byte, region) -> arrout
        endunless;
        arraysample(arr, region, arrout, region, "nearest") -> arrout
    else
        arr -> arrout
    endunless
enddefine;

/*
-- ... Conversion to 32-bit arrays for 24-bit displays ----------------
*/

define lconstant arr1_to_32bit(arr, region, lut) -> arr;
    ;;; Convert single array to 32 bits given lut
    lconstant tagr = consref(1), tagb = consref(2), tagg = consref(3);
    lvars r, g, b, vals;
    unless region then boundslist(arr) -> region endunless;
    if lut.isvector then    ;;; array indexes colours directly
        if lut(1).isvectorclass then
            oldbytearray(tagr, region) -> r;
            arr_to_byte(arr, region, lut(1), r) -> r;
            oldbytearray(tagg, region) -> g;
            arr_to_byte(arr, region, lut(2), g) -> g;
            oldbytearray(tagb, region) -> b;
            arr_to_byte(arr, region, lut(3), b) -> b;
        else
            arr_to_byte(arr, region, lut, false) ->> r ->> g -> b
        endif;
        rgbsep_to_32(r, g, b, region, arr1_to_32bit) -> arr
    elseif lut.islist then         ;;; normal lookup
        last(lut) -> vals;
        if vals(1).isvectorclass then
            oldbytearray(tagr, region) -> r;
            vals(1) -> last(lut);
            arr_to_byte(arr, region, lut, r) -> r;
            oldbytearray(tagg, region) -> g;
            vals(2) -> last(lut);
            arr_to_byte(arr, region, lut, g) -> g;
            oldbytearray(tagb, region) -> b;
            vals(3) -> last(lut);
            arr_to_byte(arr, region, lut, b) -> b;
        else
            ;;; greyscale case
            arr_to_byte(arr, region, lut, false) ->> r ->> g -> b
        endif;
        rgbsep_to_32(r, g, b, region, arr1_to_32bit) -> arr
    elseif lut == identfn then
        if arr.is24bitarray then
            rgb24_to_32(arr, region, tagr) -> arr
        else
            unless region = boundslist(arr) then
                arraysample(arr, region, oldintarray(tagr, region),
                    false, "nearest") -> arr
            endunless
        endif
    else
        mishap(lut, 1, 'Unexpected lookup table format')
    endif;
enddefine;

define lconstant arrs_to_32bit(arr_vec, region) -> arr;
    rgbsep_to_32(explode(arr_vec), region, arrs_to_32bit) -> arr
enddefine;

define lconstant arr_to_32bit(arr_vec, region, lut) /* -> arr */;
    if arr_vec.isarray then
        arr1_to_32bit(arr_vec, region, lut)
    else
        arrs_to_32bit(arr_vec, region)
    endif
enddefine;

/*
-- ... Main array conversion routine ----------------------------------
*/

define lconstant rci_drawable_array8 (arr, arr_region, win_region, lut)
        -> newarr;

    if ncshiftarr(arr, arr_region, win_region) ->> newarr then
        ;;; No need for spatial resampling
        arr_to_byte(newarr, win_region, lut, false) -> newarr;

    elseif rc_array_sample /== "nearest"
    or npoints(arr_region) >= npoints(win_region) then
        ;;; Must do spatial resampling - if averaging or interpolating
        ;;; then must sample first; if shrinking then more efficient to do so
        posbounds(win_region, arr_region) -> (win_region, arr_region);
        if arr.isbytearray then
            ;;; keep as bytes
            arraysample(arr, arr_region,
                oldbytearray(rci_drawable_array8, win_region), false,
                rc_array_sample) -> newarr
        else
            ;;; convert to floating point for efficiency
            arraysample(arr, arr_region,
                oldsfloatarray(rci_drawable_array8, win_region), false,
                rc_array_sample) -> newarr
        endif;
        arr_to_byte(newarr, win_region, lut, false) -> newarr

    else
        ;;; Expanding and using "nearest" option - can do lookup first
        posbounds(arr_region, win_region) -> (arr_region, win_region);
        arr_to_byte(arr, arr_region, lut, false) -> newarr;
        posbounds(win_region, arr_region) -> (win_region, arr_region);
        arraysample(newarr, arr_region,
            oldbytearray(rci_drawable_array8, win_region), false,
            rc_array_sample) -> newarr
    endif

enddefine;

define lconstant rci_drawable_array24 (arr, arr_region, win_region, lut)
        -> newarr;

    lconstant tagr = consref(0), tagg = consref(0), tagb = consref(0);

    lvars shiftarr
        = app_one_or_more(arr, ncshiftarr(% arr_region, win_region %));
    if allsame(app_one_or_more(shiftarr, not <> not)) then
        ;;; No need for spatial resampling
        arr_to_32bit(shiftarr, win_region, lut) -> newarr;

    elseif rc_array_sample /== "nearest"
    or npoints(arr_region) >= npoints(win_region) then
        ;;; Must do spatial resampling - if averaging or interpolating
        ;;; then must sample first; if shrinking then more efficient to do so
        posbounds(win_region, arr_region) -> (win_region, arr_region);
        if arr.isarray then
            if arr.isbytearray or
                ((arr.is32bitarray or arr.is24bitarray) and lut == identfn)
            then
                ;;; keep current type
                arraysample(arr, arr_region,
                    oldanyarray(rci_drawable_array24, win_region,
                        datakey(arrayvector(arr))),
                    false, rc_array_sample) -> newarr
            else
                ;;; convert to floating point for efficiency
                arraysample(arr, arr_region,
                    oldsfloatarray(rci_drawable_array24, win_region), false,
                    rc_array_sample) -> newarr
            endif
        else
            ;;; have a vector of arrays
            resize3(arr, arr_region, win_region) -> newarr
        endif;
        arr_to_32bit(newarr, win_region, lut) -> newarr
    else
        ;;; Expanding and using "nearest" option - can do lookup first
        posbounds(arr_region, win_region) -> (arr_region, win_region);
        arr_to_32bit(arr, arr_region, lut) -> newarr;
        posbounds(win_region, arr_region) -> (win_region, arr_region);
        arraysample(newarr, arr_region,
            oldanyarray(rci_drawable_array24,
                win_region, datakey(arrayvector(newarr))),
            win_region,
            rc_array_sample) -> newarr
    endif

enddefine;

define lconstant rci_drawable_array (arr, arr_region, win_region, lut)
        -> newarr;

    ;;; sort out arguments
    lvars arrbounds = boundslist_one_or_more(arr);
    unless arr_region then
        arrbounds -> arr_region
    else
        region_inclusion_check(arrbounds, arr_region)
    endunless;
    unless win_region then
        arr_region -> win_region
    endunless;

    if display_depth == 8 then
        rci_drawable_array8(arr, arr_region, win_region, lut) -> newarr
    elseif display_depth == 24 then
        rci_drawable_array24(arr, arr_region, win_region, lut) -> newarr
    else
        mishap(display_depth, 1, 'Need 8 or 24 bit display')
    endif
enddefine;

/*
-- Generating look-up table -------------------------------------------
*/

/*
-- ... Obtaining grey-level range for image ---------------------------
*/

define lconstant val_lims(arr) -> (mn, mx);
    lvars mn = false, mx = false;
    ;;; Return the min and max values that can be held in an integer
    ;;; array, or false if not an integer array.
    lvars nbits = isintarray(arr);
    if nbits then
        if nbits > 0 then
            0 -> mn;
            2 ** nbits - 1 -> mx
        else
            -(2 ** (abs(nbits)-1)) -> mn;
            -mn - 1 -> mx
        endif
    endif
enddefine;

define lconstant getblims(arr, region, bmin, bmax) -> (bmin, bmax);
    ;;; Gets bounds for brightnesses - either data limits or as specified
    ;;; Input of true means use the max or min possible in the integer
    ;;; array.
    lvars gmin gmax amin amax nbits;

    ;;; handle bit arrays as special case
    if isbitarray(arr) then
        (0,1) -> (bmin, bmax)

    else
        if bmin == true or bmax == true then
            val_lims(arr) -> (amin, amax);
            unless amin then
                if bmin == true then false -> bmin endif;
                if bmax == true then false -> bmax endif
            endunless
        endif;

        unless bmin and bmax then
            array_mxmn(arr, region) -> (gmax, gmin);
            if gmax = gmin then
                gmax + 1 -> gmax        ;;; blank region
            endif
        endunless;

        if bmin == true then
            amin -> bmin
        elseif bmin == false then
            gmin -> bmin
        endif;

        if bmax == true then
            amax -> bmax
        elseif bmax == false then
            gmax -> bmax
        endif
    endif
enddefine;

/*
-- ... Histogram equalisation thresholds ------------------------------
*/

define lconstant histthresh(arr, region, bmin, bmax, ncols)
        -> thresh;
    lvars thresh = initv(ncols - 1);
    lconstant nbins = 256;
    unless region then boundslist(arr) -> region endunless;

    ;;; Get histogram
    if bmin.isintegral and bmax.isintegral then
        ;;; Adjust limits to count integral values in general
        1 + bmax -> bmax
    elseif bmax - bmin >= 2 then
        bmin - 0.5 -> bmin;
        bmax + 0.5 -> bmax
    endif;
    lvars
        (ndone, hist, nabv) = array_hist(arr, region, bmin, nbins, bmax);

    ;;; Convert to thresholds, with linear interpolation
    lvars ithresh, thr,
        isbyte = arr.isbytearray,
        ihist = 1,                          ;;; input bin number
        val = bmin,                         ;;; lower threshold for input bin
        valinc = (bmax - bmin) / nbins,     ;;; input bin size
        nlast = ndone,                      ;;; number in current input bin
        ntotal = region_size(region),
        nperbin = ntotal / ncols,           ;;; number per output bin
        ntarget = nperbin;                  ;;; no to have done in output
    for ithresh from 1 to ncols - 1 do
        until ndone >= ntarget do
            if ihist > nbins then
                ;;; only come here if high - low < 2 and rounding errors!
                nabv -> nlast       ;;; must reach total now
            else
                hist(ihist) -> nlast;
                ihist + 1 -> ihist
            endif;
            ndone + nlast -> ndone;
            val + valinc -> val
        enduntil;
        val - valinc * (ndone - ntarget) / nlast -> thr;
        ;;; Round threshold for byte arrays
        if isbyte then round(thr) else thr endif -> thresh(ithresh);
        ntarget + nperbin -> ntarget
    endfor
enddefine;

/*
-- ... Dealing with user options --------------------------------------
*/

define lconstant getbounds(arr, region, src_vals) -> (bmin, bmax);
    lvars bmin = false, bmax = false;
    if src_vals.islist and tl(src_vals) /== [] then
        src_vals(2) -> bmin;
        src_vals(3) -> bmax
    endif;
    getblims(arr, region, bmin, bmax) -> (bmin, bmax)
enddefine;

define lconstant weedvec1(vec, n) /* -> vec */;
    ;;; Decimate a vector down to n components.
    lvars i, l = length(vec);
    if n == l then
        vec
    else
        {% for i from 1 by (l-1)/(n-1) to l do
                vec(round(i))
            endfor %}
    endif
enddefine;

define lconstant weedvec3(vecs, n) /* -> vecs */;
    mapdata(vecs, weedvec1(%n%))
enddefine;

define lconstant weedvec(vecs, n) /* -> vecs */;
    if vecs(1).isvectorclass then
        weedvec3(vecs, n)
    else
        weedvec1(vecs, n)
    endif
enddefine;

define lconstant getlut8(arr, region, src_vals, dest_cols) -> lut;
    ;;; Returns a lookup-table for arraylookup, given a spec
    ;;; for the source colour mapping and a colour vector.
    lvars bmin, bmax,
        option = src_vals,
        ncols = length(dest_cols);
    unless option then "linear" -> option
    elseif option.islist then hd(option) -> option
    endunless;

    if option == "linear" then
        getbounds(arr, region, src_vals) -> (bmin, bmax);
        ;;; Make linear quantisation table
        lvars incr = (bmax - bmin) / ncols;
        [% bmin + incr, bmax - incr, dest_cols %] -> lut

    elseif option == "sqrt" then
        getbounds(arr, region, src_vals) -> (bmin, bmax);
        ;;; Make square-root quantisation table
        lvars colthresh, colincr = 1/ncols;
        [%
            {% for colthresh from colincr by colincr to 1 - colincr do
                    bmin + colthresh ** 2 * (bmax - bmin)
                endfor %},
            dest_cols %] -> lut

    elseif option == "equalise" then
        getbounds(arr, region, src_vals) -> (bmin, bmax);
        [% histthresh(arr, region, bmin, bmax, ncols),
            dest_cols %] -> lut

    elseif option == "quantise" then
        lvars nquants, quants = src_vals(2);
        if quants.isvector then
            length(quants) + 1 -> nquants
        else
            quants -> nquants
        endif;
        ;;; Weed out colours to correct number
        weedvec1(dest_cols, nquants) -> dest_cols;
        if quants.isvector then
            [% quants, dest_cols %] -> lut
        else
            getbounds(arr, region, tl(src_vals)) -> (bmin, bmax);
            (bmax - bmin) / nquants -> incr;
            if nquants == 2 then
                [% {% bmin + incr %}, dest_cols %] -> lut
            else
                [% bmin + incr, bmax - incr, dest_cols %] -> lut
            endif
        endif

    elseif option == "map" then
        hd(tl(src_vals)) -> lut

    elseif option == "direct" then
        round -> lut

    else
        mishap(option, 1, 'Unrecognised mapping option')
    endif
enddefine;

define lconstant getlut24(arr, region, src_vals, dest_cols) -> lut;
    ;;; Returns a lookup-table for arraylookup, given a spec
    ;;; for the mapping rule and either an rgb vector or a single
    ;;; vector for the destination colours.
    ;;; The last element of the lut list may be a 3-vector covering the
    ;;; r,g and b cases. Test for this is whether its contents are vectors.
    lvars bmin, bmax, ncols, quants,
        option = src_vals;
    unless option then "linear" -> option
    elseif option.islist then hd(option) -> option
    endunless;

    lvars d1 = dest_cols(1);
    if d1.isnumber then
        length(dest_cols) -> ncols
    else
        length(dest_cols(1)) -> ncols
    endif;

    ;;; For all options except "direct" can assume that the array argument
    ;;; is in fact an array, not a vector of r, g and b arrays.
    if option == "linear" then
        getbounds(arr, region, src_vals) -> (bmin, bmax);
        ;;; Make linear quantisation table
        lvars incr = (bmax - bmin) / ncols;
        [% bmin + incr, bmax - incr, dest_cols %] -> lut

    elseif option == "sqrt" then
        getbounds(arr, region, src_vals) -> (bmin, bmax);
        ;;; Make square-root quantisation table
        lvars colthresh, colincr = 1/ncols;
        [% {% for colthresh from colincr by colincr to 1 - colincr do
                    bmin + colthresh ** 2 * (bmax - bmin)
                endfor %}, dest_cols %] -> lut

    elseif option == "equalise" then
        getbounds(arr, region, src_vals) -> (bmin, bmax);
        [% histthresh(arr, region, bmin, bmax, ncols), dest_cols %] -> lut

    elseif option == "quantise" then
        lvars nquants;
        src_vals(2) -> quants;
        if quants.isvector then
            length(quants) + 1 -> nquants
        else
            quants -> nquants
        endif;
        ;;; Weed out colours to correct number
        weedvec(dest_cols, nquants) -> dest_cols;
        if quants.isvector then
            [% quants, dest_cols %] -> lut
        else
            getbounds(arr, region, tl(src_vals)) -> (bmin, bmax);
            (bmax - bmin) / nquants -> incr;
            if nquants == 2 then
                [% {% bmin + incr %}, dest_cols %] -> lut
            else
                [% bmin + incr, bmax - incr, dest_cols %] -> lut
            endif
        endif

    elseif option == "direct" then
        if arr.isvector then    ;;; r,g,b specified
            unless dest_cols == "direct" then
                mishap(0, '"direct" palette required for r,g,b input')
            endunless;
            identfn -> lut
        elseif dest_cols == "direct" then
            if arr.is32bitarray or arr.is24bitarray then
                "nearest" -> rc_array_sample;
                identfn -> lut
            else
                mishap(arr.arrayvector.datakey, 1,
                    'Need 32 or 24 bit array for direct palette')
            endif
        else
            dest_cols -> lut
        endif

    else
        mishap(option, 1, 'Unrecognised mapping option')
    endif;

enddefine;


define lconstant getlut(arr, region, src_vals, dest_cols) -> lut;
    if display_depth == 8 then
        getlut8(arr, region, src_vals, dest_cols) -> lut
    elseif display_depth == 24 then
        getlut24(arr, region, src_vals, dest_cols) -> lut
    else
        mishap(display_depth, 1, 'Need 8 or 24 bit display')
    endif
enddefine;

/*
-- Positioning in window ----------------------------------------------
*/

define lconstant joint_round(x0, x1) -> (x0, x1);
    ;;; Round two numbers. The difference between the results is equal
    ;;; to the difference between the arguments rounded, whilst the mean
    ;;; of the results is as close as possible to the mean of the
    ;;; arguments.
    lvars d = round(x1-x0);
    round(0.5 * (x1 + x0 - d)) -> x0;
    x0 + d -> x1
enddefine;

define lconstant bothcorners(px0, px1, py0, py1, xsize, ysize)
        -> (px0, px1, py0, py1);
    ;;; Given the elements of a boundslist spec of a region, and
    ;;; the size of the region, fills in any missing elements of the
    ;;; region spec to make it the required size.
    unless px1.isnumber then
        px0 + xsize -> px1
    elseunless px0.isnumber then
        px1 - xsize -> px0
    endunless;
    unless py1.isnumber then
        py0 + ysize -> py1
    elseunless py0.isnumber then
        py1 - ysize -> py0
    endunless
enddefine;

define lconstant getwinreg(arr_bounds, arr_reg, u_reg) -> win_reg;

    ;;; This looks elaborate - but I think it is as simple as it can
    ;;; be whilst still getting the mapping exactly right.

    ;;; Returns a region in window coords in which to draw the region
    ;;; of the array given.
    ;;; The arr_reg argument, if a list, specifies which array elements
    ;;; are to be included.
    ;;; The u_reg argument, if a list, gives the region in USER
    ;;; coords of the array limits - by which I mean the line round
    ;;; the very outside of the array.
    ;;; The u_reg argument may be nested inside another list -
    ;;; in this case it refers to the region of the window to be
    ;;; filled by the elements in arr_reg.

    ;;; Get array outer limits in ARRAY coords
    lvars
        (ax0, ax1, ay0, ay1) = explode(region_expand(arr_bounds, 0.5)),
        xasize = ax1 - ax0, yasize = ay1 - ay0;       ;;; array sizes

    ;;; Get array region outer limits in ARRAY coords
    lvars rx0, rx1, ry0, ry1;
    if arr_reg.islist then
        region_inclusion_check(arr_bounds, arr_reg);
        explode(region_expand(arr_reg, 0.5))
    else
        (ax0, ax1, ay0, ay1)
    endif -> (rx0, rx1, ry0, ry1);
    lvars xrsize = rx1 - rx0, yrsize = ry1 - ry0;

    ;;; Get array region limits in USER coords
    lvars ux0, ux1, uy0, uy1;
    if islist(u_reg) then
        if islist(hd(u_reg)) then
            ;;; The destination spec applies to the region
            bothcorners(explode(hd(u_reg)), xrsize, yrsize)
                -> (ux0, ux1, uy0, uy1);

        else
            ;;; The destination spec applies to the whole array
            lvars px0, px1, py0, py1;
            bothcorners(explode(u_reg), xasize, yasize)
                -> (px0, px1, py0, py1);
            ;;; Translate from array to region limits
            lvars
                xrat = (px1 - px0) / xasize,
                yrat = (py1 - py0) / yasize;
            (rx0 - ax0) * xrat + px0 -> ux0;
            (rx1 - ax0) * xrat + px0 -> ux1;
            (ry0 - ay0) * yrat + py0 -> uy0;
            (ry1 - ay0) * yrat + py0 -> uy1;
        endif

    else
        ;;; The destination spec defaults to the region coords
        (rx0, rx1, ry0, ry1) -> (ux0, ux1, uy0, uy1)
    endif;
    ;;; [drawing region, user coords % px0, px1, py0, py1 %] =>

    ;;; Get outer limits of drawing region in WINDOW coords
    ;;; Originally just used rc_transxyout, but need to get at results
    ;;; before rounding.
    lvars sx0, sx1, sy0, sy1;
    ux0 * rc_xscale + rc_xorigin -> sx0;
    ux1 * rc_xscale + rc_xorigin -> sx1;
    uy0 * rc_yscale + rc_yorigin -> sy0;
    uy1 * rc_yscale + rc_yorigin -> sy1;
    ;;; [drawing arr_reg, window coords % sx0, sx1, sy0, sy1 %] =>

    ;;; Now get bounds (in boundslist sense) as opposed to limits of
    ;;; window arr_reg. This means shifting in by half a screen pixel, but
    ;;; want to preserve the size, so do joint rounding.
    lvars signed_half;
    sign(sx1 - sx0) * 0.5 -> signed_half;
    sx0 + signed_half -> sx0;
    sx1 - signed_half -> sx1;
    joint_round(sx0, sx1) -> (sx0, sx1);
    sign(sy1 - sy0) * 0.5 -> signed_half;
    sy0 + signed_half -> sy0;
    sy1 - signed_half -> sy1;
    joint_round(sy0, sy1) -> (sy0, sy1);
    ;;; [drawing arr_reg, rounded % sx0, sx1, sy0, sy1 %] =>

    [% sx0, sx1, sy0, sy1 %] -> win_reg
enddefine;

/*
-- Overall array preparation procedure --------------------------------
*/

define lconstant rci_array_ready
        (arr, orig_bounds, arr_reg, u_reg, src_vals, col_vals) /* -> newarr */;
    ;;; orig_bounds is needed for a by-column array where
    ;;; the size has been reduced by rc_array and u_reg refers to
    ;;; the original array not to the displayed part.

    lvars
        lut = getlut(arr, arr_reg, src_vals, col_vals),
        win_reg = getwinreg(orig_bounds, arr_reg, u_reg);
    rci_drawable_array(arr, arr_reg, win_reg, lut) /* -> newarr */
enddefine;

/*
-- Colour map handling ------------------------------------------------
*/

/*
-- ... Spectrum generation --------------------------------------------
*/

lconstant spectcols_default
    = [black purple4 blue4 cyan4 green3 yellow2 orange red white];

lvars _spectcols = spectcols_default;  ;;; current spectrum in words

define lconstant linrep(t1, t2, n) /* -> rep */;
    ;;; Returns a repeater that gives n equally-spaced values from
    ;;; t1 to t2. (Keeps going above t2, as in this prog not required
    ;;; to return termin.)
    lvars
        t = t1,
        tinc = (t2 - t1) / (n - 1);

    procedure /* -> val */;
        t1; /* -> val */
        t1 + tinc -> t1
    endprocedure
enddefine;

define lconstant spectrum_rgb(colspec, rr, gg, bb);
    ;;; Sets up a colour spectrum using a colour spec given as
    ;;; a list of colour names. rr, gg and bb must be 3 equal-length
    ;;; vectors to take the colour values.
    lvars r, g, b, col1, r0, g0, b0, r1, p, g1, b1, p0, p1, ninseg,
        nsegs = length(colspec) - 1,
        pos = linrep(1, length(rr), nsegs+1);

    round(pos()) -> p0;
    Xcolour_to_rgb(hd(colspec)) -> (r0, g0, b0);
    (r0, g0, b0) -> (rr(p0), gg(p0), bb(p0));
    for col1 in tl(colspec) do
        round(pos()) -> p1;
        Xcolour_to_rgb(col1) -> (r1, g1, b1);
        p1 - p0 + 1 -> ninseg;
        linrep(r0, r1, ninseg) -> r;
        linrep(g0, g1, ninseg) -> g;
        linrep(b0, b1, ninseg) -> b;
        r() -> ; g() -> ; b() -> ;      ;;; first point already done
        for p from p0+1 to p1 do
            (round(r()), round(g()), round(b())) -> (rr(p), gg(p), bb(p));
        endfor;
        p1 -> p0;
        r1 -> r0;   g1 -> g0;   b1 -> b0;
    endfor;
enddefine;

/*
-- ... 8 bits ---------------------------------------------------------
*/

;;; These control the amount of the public colour map we try to grab
;;; for the two general-purpose display options.
lconstant
    NGREYS8    =  64,
    NCOLS8     =  64;

/*
-- ... Compressing colour maps when not all entries are needed --------
*/

define lconstant compressmap(image, region, ncols) /* -> rmap */;
    ;;; Values in the region of the array must be from 0 to ncols-1.
    ;;; Discovers which of these are actually present, and returns a
    ;;; vector containing the values present.
    lconstant hist = initintvec(256);   ;;; optimise for byte case
    lvars nblo, nabv;
    array_hist(image, region, 0, [% 1, ncols, hist %], ncols)
        -> (nblo, , nabv);
    unless nblo == 0 and nabv == 0 then
        mishap(image, ncols, 2, 'Array has values outside colour map range')
    endunless;
    ;;; Construct vector of values present
    lvars ibin;
    {% fast_for ibin from 1 to ncols do
            if hist(ibin) fi_> 0 then
                ibin
            endif
        endfor %}
enddefine;

define lconstant reducecmap(cmap, rmap) /* -> newcmap */;
    ;;; Reduce the entries in a colour map using the output
    ;;; of compressmap.
    lvars i, oval,
        nnew = length(rmap);
    if length(cmap) == 3 and isvectorclass(cmap(1)) then
        ;;; Have vector-type spec
        lvars
            (r, g, b) = explode(cmap),
            newr = initv(nnew),
            newg = initv(nnew),
            newb = initv(nnew);
        fast_for i from 1 to nnew do
            rmap(i) -> oval;
            r(oval) -> newr(i); g(oval) -> newg(i); b(oval) -> newb(i)
        endfor;
        {% newr, newg, newb %} /* -> newcmap */
    else
        ;;; Straightforward
        {% fast_for i from 1 to nnew do
                cmap(rmap(i))
            endfor %}
    endif
enddefine;

define lconstant rmap_to_lut(rmap, pixels) -> lut;
    lvars lut = initintvec(256);
    ;;; Returns a 256-element lookup table for mapping from array
    ;;; values to pixel values for new table.
    lvars i;
    fast_for i from 1 to length(rmap) do
        pixels(i) -> lut(rmap(i))
    endfor
enddefine;

/*
-- ... Allocating colourmap entries -----------------------------------
*/

define lconstant maketestwin /* -> window */;
    ;;; Returns an unmapped widget for colour map manipulation
    ;;; purposes.
    lconstant XpwGraphic = XptWidgetSet("Poplog")("GraphicWidget");
    XptNewWindow('Testwin', {1 1}, [], XpwGraphic,
        [{mappedWhenManaged ^false}])
enddefine;

define lconstant getcrange(win1, win2, ncolours) -> (cols, winused);
    ;;; Grab colours.  If win1 will accept them with its current
    ;;; colour map, then use that; otherwise try and put them in
    ;;; win2; otherwise give win2 a private colour map and use that.

    lvars crange = XpwAllocColorRange(win1, ncolours, 0,0,0, 0,0,0);
    win1 -> winused;
    unless crange then
        win2 -> winused;
        XpwAllocColorRange(win2, ncolours, 0,0,0, 0,0,0) -> crange;
        unless crange then
            XpwCreateColormap(win2);
            XpwAllocColorRange(win2, ncolours, 0,0,0, 0,0,0) -> crange;
            unless crange then
                mishap(ncolours, 1, 'Unable to allocate colour map entries')
            endunless
        endunless
    endunless;

    ;;; Get pixel values
    lvars i;
    {% for i from 1 to ncolours do
            XpwStackColorRangeInfo(crange, i); erasenum(3);
        endfor %} -> cols
enddefine;

/*
-- ... Setting up colour-map values -----------------------------------
*/

;;; For private use by setspect8 to avoid garbage
lvars
    _nspect8 = false,
    _rspect8 = false, _gspect8 = false, _bspect8 = false;

define lconstant setspect8(colspec, win, pixels);
    ;;; Sets up a colour spectrum using a colour spec given as
    ;;; a list of colour names.
    lvars i, N = length(pixels);
    unless _nspect8 == N then
        initv(N) -> _rspect8;
        initv(N) -> _gspect8;
        initv(N) -> _bspect8
    endunless;
    spectrum_rgb(colspec, _rspect8, _gspect8, _bspect8);
    for i from 1 to N do
        XpwChangeColor(win, pixels(i), _rspect8(i), _gspect8(i), _bspect8(i));
    endfor;
enddefine;

;;; Window to hold permanently-allocated grey-level maps
lvars _win = false;
;;; Permanently-allocated grey-level and spectrum pixels
lvars
    _greyscale = false,
    _spectrum8 = false;

define lconstant greypix8 /* -> greyscale */;
    ;;; Sets up grey-scale in colour map, if possible in public
    ;;; colour map associated with permanent window.
    ;;; Refers to:  _greyscale
    ;;;             _win
    ;;;             _rc_window
    lconstant greycols = [black white];
    if _greyscale then
        _greyscale
    else
        lvars g, p, pixels,
            win = _win or (maketestwin() ->> _win);
        getcrange(win, rc_window, NGREYS8) -> (pixels, win);
        setspect8(greycols, win, pixels);
        _win == win and pixels -> _greyscale;   ;;; using perm window
        pixels /* -> greyscale */
    endif
enddefine;

define lconstant spectpix8 /* -> spectrum */;
    ;;; Refers to:  _spectrum8
    ;;;             _spectcols
    ;;;             _win
    ;;;             _rc_window
    display_depth == 8 and
    if _spectrum8 then
        _spectrum8
    else
        lvars g, p, pixels,
            win = _win or (maketestwin() ->> _win);
        getcrange(win, rc_window, NCOLS8) -> (pixels, win);
        setspect8(_spectcols, win, pixels);
        _win == win and pixels -> _spectrum8;   ;;; using perm window
        pixels /* -> spectrum */
    endif
enddefine;

define lconstant privpix8(array, region, cmap) -> pixels;
    ;;; Colour map can be a vector of r, g, b vectors or a vector
    ;;; of individual values. Each value can then be an r,g,b vector
    ;;; or a colour name.
    lvars ncols,
        sep_rgb = length(cmap) == 3 and isvectorclass(cmap(1));
    if sep_rgb then
        length(cmap(1))
    else
        length(cmap)
    endif -> ncols;

    ;;; If array is supplied, compress the colour map
    if array then
        lvars rmap = compressmap(array, region, ncols);
        length(rmap) -> ncols;
        reducecmap(cmap, rmap) -> cmap;
    endif;

    ;;; Do not use permanent window - always assign to rc_window
    getcrange(rc_window, rc_window, ncols) -> (pixels, );
    if sep_rgb then
        lvars i, (r, g, b) = explode(cmap);
        for i from 1 to ncols do
            XpwChangeColor(rc_window, pixels(i), r(i), g(i), b(i))
        endfor
    else
        lvars c, i = 0;
        for c in cmap do
            i + 1 -> i;
            XpwChangeColor(rc_window, pixels(i), Xcolour_to_rgb(c))
        endfor
    endif;

    if array then
        ;;; Need to get lookup table for reduced colour map
        lvars lut = rmap_to_lut(rmap, pixels);
        conspair(lut, pixels) -> pixels
    endif
enddefine;

define lconstant getcols8(array, region, arr_cols, win_cols)
        -> (arr_cols, win_cols);
    ;;; Allocates colours and returns a vector of the pixels used.
    ;;; (The special case of direct mapping is handled messily by
    ;;; returning a pair with pixels and lut.)
    if win_cols == "greyscale" then
        greypix8() -> win_cols
    elseif win_cols == "spectrum" then
        spectpix8() -> win_cols
    elseif ((arr_cols.islist and hd(arr_cols)) or arr_cols) == "direct" then
        "nearest" -> rc_array_sample;   ;;; other options do not make sense
        lvars p = privpix8(array, region, win_cols);
        [map % front(p) %] -> arr_cols;
        back(p) -> win_cols
    else
        privpix8(false, false, win_cols) -> win_cols
    endif
enddefine;

/*
-- ... 24 bits --------------------------------------------------------
*/

;;; NCOLS24 controls number of different colours used for
;;; spectrum on 24 bit displays. It is quite arbitrary and the
;;; only cost of increasing it would be longer vectors used internally
;;; and more time to calculate the spectrum when it is changed - both
;;; very minor costs, but 256 is probably adequate in most cases.

lconstant NCOLS24 = 256, NGREYS24 = 256;

lvars
    _spectrum24 = false,
    _greyvals24 = false;

define lconstant setspect24(colspec, rgb);
    spectrum_rgb(colspec, explode(rgb))
enddefine;

define lconstant spectpix24 /* -> rgb */;
    unless _spectrum24 then
        {% initv(NCOLS24), initv(NCOLS24), initv(NCOLS24) %} -> _spectrum24;
        setspect24(_spectcols, _spectrum24)
    endunless;
    _spectrum24
enddefine;

define lconstant greypix24 /* -> ggg */;
    lvars i;
    unless _greyvals24 then
        {% for i from 0 to NGREYS24-1 do i endfor %} -> _greyvals24
    endunless;
    _greyvals24
enddefine;

define lconstant privpix24(cmap) -> rgb;
    ;;; Colour map can be a vector of r, g, b vectors or a vector
    ;;; of individual values. Each value can then be an r,g,b vector
    ;;; or a colour name.
    if length(cmap) == 3 and isvectorclass(cmap(1)) then
        cmap -> rgb
    else
        lvars c, i = 0, ncols = length(cmap),
            rr = initv(ncols), gg = initv(ncols), bb = initv(ncols);
        for c in cmap do
            i + 1 -> i;
            Xcolour_to_rgb(c) -> (rr(i), gg(i), bb(i))
        endfor;
        {% rr, gg, bb %} -> rgb
    endif;
enddefine;

define lconstant getcols24(win_cols) -> win_cols;
    ;;; Returns rgb values for 24-bit case.
    if win_cols == "greyscale" then
        greypix24() -> win_cols
    elseif win_cols == "spectrum" then
        ;;; return a suitable set of rgb values
        spectpix24() -> win_cols
    elseif win_cols.isvector or win_cols.islist then
        privpix24(win_cols) -> win_cols
    endif
enddefine;

/*
-- ... set colours - 8/24 bit -----------------------------------------
*/

define lconstant getcols(array, region, arr_cols, win_cols)
        -> (arr_cols, win_cols);
    unless win_cols then "greyscale" -> win_cols endunless;    ;;; default
    if display_depth == 8 then
        getcols8(array, region, arr_cols, win_cols) -> (arr_cols, win_cols)
    elseif display_depth == 24 then
        getcols24(win_cols) -> win_cols
    else
        mishap(display_depth, 1, 'Need display depth to be 8 or 24')
    endif
enddefine;

/*
-- Copying the image to the window ------------------------------------
*/

define lconstant tlclip(arr, width, height, x, y) ->
        (arr, width, height, x, y);
    ;;; XpwDrawImage clips the right and bottom of an array if it would
    ;;; go over the edge of the window, but fails to draw at all if the
    ;;; array would go over the top or left of the window.
    ;;; It would be more efficient to do this along with the other
    ;;; resampling, but the code above would get appreciably more fiddly
    ;;; as it would be necessary to project the window back onto the
    ;;; array to find the input bounds for the resampling.
    lvars region;
    if x < 0 or y < 0 then
        width + x -> width;     height + y -> height;
        max(x, 0) -> x;         max(y, 0) -> y;
        width - x -> width;     height - y -> height;
        if width > 0 and height > 0 then
            [% x, x+width-1, y, y+height-1 %] -> region;
            arraysample(arr, region,
                oldanyarray(tlclip, region, datakey(arrayvector(arr))),
                false, "nearest") -> arr
        endif
    endif
enddefine;

define lconstant myXpwDrawImage(w,dx,dy,x,y,image);
    ;;; Need to use a private version of this, as the main version
    ;;; has a serious bug: it expects a 24-bit vector if there is
    ;;; a 24-bit display, but in fact X expects a 32-bit vector in this
    ;;; case.
    lvars w,dx,dy,x,y,image, depth;
    unless image.isvectorclass then arrayvector(image)->image endunless;
    lvars ( , fsize) = field_spec_info(class_field_spec(datakey(image)));
    if fsize == 8 then
        8 -> depth
    elseif fsize == 32 then
        24 -> depth
    else
        mishap(fsize, 1, 'Expecting 8 or 32 bit integer array')
    endif;
    XpwCallMethod(XptCheckWidget(w),XpwMDrawImage,
        fi_check(dx,false,false),fi_check(dy,false,false),
        fi_check(x,false,false),fi_check(y,false,false),
        image,depth, 8, false);
enddefine;

define lconstant drawimage(arr, win);
    ;;; Uses XpwDrawImage to display arr in the window, assuming that
    ;;; arr is all set up with the right boundslist and values.
    lvars
        (x0, x1, y0, y1) = explode(boundslist(arr)),
        w = x1 - x0 + 1,
        h = y1 - y0 + 1;
    tlclip(arr, w, h, x0, y0) -> (arr, w, h, x0, y0);
    myXpwDrawImage(win, w, h, x0, y0, arrayvector(arr))
enddefine;

/*
-- Dealing with arrays by column --------------------------------------
*/

define lconstant byrow1(arr, region, tag) -> arr;
    ;;; If array is ordered by column, reorder by row.
    ;;; Would be more efficient if low-level procedures could handle
    ;;; by-column arrays, but this would need considerable work,
    ;;; especially to arraysample.
    ;;; Expect poparray_by_row to be <true> when called.
    unless arr.isarray_by_row then
        oldanyarray(tag, region or boundslist(arr), arr,
            datakey(arrayvector(arr))) -> arr
    endunless
enddefine;

define lconstant byrow3(arrvec, region) /* -> arrvec */;
    ;;; Applies byrow1 to each of the 3 components of an rgb vector.
    lconstant tag1 = consref(1), tag2 = consref(2), tag3 = consref(3);
    {%
        byrow1(arrvec(1), region, tag1),
        byrow1(arrvec(2), region, tag2),
        byrow1(arrvec(3), region, tag3)
        %}
enddefine;

define lconstant byrow(arr_vec, region) /* -> arrvec */;
    ;;; Applies byrow to array or to elements of vector. (Could have
    ;;; a generic procedure for this kind of thing - the problem is the
    ;;; tags for oldanyarray, which saves garbage.
    if arr_vec.isarray then
        byrow1(arr_vec, region, byrow)
    else
        byrow3(arr_vec, region)
    endif
enddefine;

/*
-- Top-level procedures -----------------------------------------------
*/

define rc_array(arr, arr_region, win_region, arr_cols, win_cols);
    dlocal
        rc_array_sample,        ;;; may be changed if arr_cols is "direct"
        poparray_by_row = true; ;;; for all lower level routines

    ;;; start a new window if necessary - do not call rc_start as this
    ;;; resets the coordinates
    unless rc_window.xt_islivewindow then
        rc_new_window(
            rc_window_xsize, rc_window_ysize, rc_window_x, rc_window_y, false)
    endunless;

    ;;; convert by-column arrays (ought not be necessary, but is at present)
    lvars orig_bounds = boundslist_one_or_more(arr);
    app_one_or_more(arr, byrow(%arr_region%)) -> arr;

    drawimage(rci_array_ready(
            arr, orig_bounds, arr_region, win_region,
            getcols(arr, arr_region, arr_cols, win_cols)
        ),
        rc_window
    )
enddefine;

/* Procedure for changing colour map */

define active rc_spectrum;
    _spectcols
enddefine;

define updaterof active rc_spectrum(cols);
    if cols.islist then
        cols
    else
        spectcols_default
    endif -> _spectcols;

    if display_depth == 8 then
        if _spectrum8 then
            setspect8(_spectcols, _win, _spectrum8)
        endif
    elseif display_depth == 24 then
        if _spectrum24 then
            setspect24(_spectcols, _spectrum24)
        endif
    else
        mishap(display_depth, 1, 'Need display depth to be 8 or 24')
    endif
enddefine;

/* Procedures for getting hold of colour map entries */

define rc_array_greycells /* -> vect */;
    if display_depth == 8 then
        greypix8()
    elseif display_depth == 24 then
        greypix24()
    else
        false
    endif
enddefine;

define rc_array_spectcells /* -> vect */;
    if display_depth == 8 then
        spectpix8()
    elseif display_depth == 24 then
        spectpix8()
    else
        false
    endif
enddefine;

/* Procedure for setting sensible coordinates */

define rc_win_coords;
    ;;; Set the rc user coordinates suitably for images
    0 ->> rc_xorigin -> rc_yorigin;
    1 ->> rc_xscale -> rc_yscale;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Nov 20 2001
        Fixed bug in is32bitarray and lconstanted procedures.
--- David Young, Sep 27 2001
        Added semicolons to uses statements.
--- David Young, Sep 14 2001
        Added uses xlib and XlibMacros in case they are not already there.
--- David Young, Sep  5 2001
        Major revision to deal with 24-bit displays.
--- David S Young, Sep  8 1997
        Fixed bug introduced in previous revision.
--- David S Young, Sep  4 1997
        rc_array now copes with arrays ordered by column.
        Tags for oldXXarray now procedures rather than words to make
        inadvertent reuse outside the package impossible.
--- David S Young, Aug 12 1996
        Added rc_array_greycells and rc_array_spectcells.
--- David S Young, Nov 16 1994
        Uses newbytearray instead of newsarray, and creates work arrays using
        oldbytearray (see * OLDARRAY) to reduce garbage creation.
--- David S Young, Feb 24 1994
        getblims adds one to gmax if region is uniform so that this case
        can be displayed.
*/
