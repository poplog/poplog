/* --- Copyright University of Sussex 1997. All rights reserved. ----------
 > File:            $popvision/lib/array_peaks.p
 > Purpose:         Find local maxima in an array
 > Author:          David Young, Nov 12 1992 (see revisions)
 > Documentation:   HELP *ARRAY_PEAKS
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses objectfile
uses newsfloatarray
uses boundslist_utils

lconstant macro extname = 'array_peaks',
    obfile = objectfile(extname);

unless obfile then
    mishap(0, 'Cannot find object file')
endunless;

exload extname [^obfile]
    EXT_array_peaks(9):int               <- array_peaks,
    EXT_array_peak(7)                    <- array_peak
endexload;

define array_peaks(arr, threshold, region) -> peaklist;
    lvars arr, threshold, region, peaklist = [];
    lconstant tofloat = number_coerce(% 0.0s0 %);
    lvars maxregion,
        (xd0, xd1, yd0, yd1) = explode(boundslist(arr));
    [% xd0+1, xd1-1, yd0+1, yd1-1 %] -> maxregion;
    unless region then
        maxregion -> region
    else
        region_inclusion_check(maxregion, region)
    endunless;
    lvars (xr0, xr1, yr0, yr1) = explode(region);

    ;;; Force the array to be packed single floats.
    unless arr.issfloatarray then
        newsfloatarray(boundslist(arr), arr) -> arr
    endunless;

    ;;; Set up output vector for the C routine.
    ;;; The next constant says how many peaks are expected for the
    ;;; average array.  Threshold should preferably be set to keep
    ;;; the number of peaks below this.
    lconstant
        init_peakno = 1000,
        init_peakvec = initintvec(2 * init_peakno);
    lvars nleft, npeaks,
        peakno = init_peakno,
        peakvec = init_peakvec,
        (, xoffset) = arrayvector_bounds(arr);

    ;;; Call external procedure.  If too many peaks are found, create
    ;;; a bigger vector and try again. We cope correctly with
    ;;; arrays that are offset in their arrayvectors.
    until (exacc EXT_array_peaks(
                arrayvector(arr),           ;;; arr
                xd1 - xd0 + 1,              ;;; xsize
                xr0 - xd0 + xoffset - 1,    ;;; xstart
                xr1 - xd0,                  ;;; xend
                yr0 - yd0,                  ;;; ystart
                yr1 - yd0,                  ;;; yend
                tofloat(threshold),         ;;; threshold
                peakvec,                    ;;; out
                peakno                      ;;; n
            ) ->> nleft) >= 0 do
        ;;; failed, so increase vector size
        peakno * 2 -> peakno;
        initintvec(2 * peakno) -> peakvec
    enduntil;
    peakno - nleft -> npeaks;

    lvars x, y, i;
    for i from 1 by 2 to 2*npeaks-1 do
        peakvec(i) fi_+ xd0 -> x;
        peakvec(i fi_+ 1) fi_+ yd0 -> y;
        conspair( {% arr(x, y), x, y %}, peaklist) -> peaklist
    endfor;

    ;;; Get the peaks out of the peak list
    ;;; Put in order
    syssort(peaklist,
        procedure(x,y); lvars x, y;
            x(1) > y(1)
        endprocedure) -> peaklist;

enddefine;

define array_peak(arr, region) /* -> peak */;
    lvars arr, region, peak;
    lvars (xd0, xd1, yd0, yd1) = explode(boundslist(arr));
    unless region then
        boundslist(arr) -> region
    else
        region_inclusion_check(arr, region)
    endunless;
    lvars (xr0, xr1, yr0, yr1) = explode(region);

    ;;; Force the array to be packed single floats.
    unless arr.issfloatarray then
        newsfloatarray(boundslist(arr), arr) -> arr
    endunless;

    ;;; Set up output vector for the C routine.
    lconstant peakvec = initintvec(2);
    lvars (, xoffset) = arrayvector_bounds(arr);

    ;;; Call external procedure.
    ;;; We cope correctly with arrays that are offset in their arrayvectors.
    exacc EXT_array_peak(
        arrayvector(arr),           ;;; arr
        xd1 - xd0 + 1,              ;;; xsize
        xr0 - xd0 + xoffset - 1,    ;;; xstart
        xr1 - xd0,                  ;;; xend
        yr0 - yd0,                  ;;; ystart
        yr1 - yd0,                  ;;; yend
        peakvec,                    ;;; out
    );

    lvars x, y;
    peakvec(1) fi_+ xd0 -> x;
    peakvec(2) fi_+ yd0 -> y;
    {% arr(x, y), x, y %} /* -> peak */

enddefine;

define refine_peaks(image,peaklist,avx,avy) -> peaklist;
    ;;; Given an image, a peaklist as returned by array_peaks, and
    ;;; a region to average over, will refine the position of each
    ;;; peak to subpixel accuracy by finding the centre of gravity of
    ;;; the region; also refines the magnitude of each peak.
    ;;; avx and avy specify the no of pixels to go either side of
    ;;; the central peak.
    lvars image, peaklist, avx, avy;
    lvars (x0, x1, y0, y1) = explode(boundslist(image));

    define lconstant procedure refpeak(peak) /* -> peak */;
        lvars peak;
        lvars v, ysum = 0, xsum = 0, n = 0, val = 0,
            ( , xc, yc) = explode(peak),
            x, y, xmin, xmax, ymin, ymax;
        max(x0,xc-avx) -> xmin; max(y0,yc-avy) -> ymin;
        min(x1,xc+avx) -> xmax; min(y1,yc+avy) -> ymax;
        fast_for x from xmin to xmax do
            fast_for y from ymin to ymax do
                image(x,y) -> v;
                v + val -> val;
                xsum + x * v -> xsum;
                ysum + y * v -> ysum;
                n fi_+ 1 -> n;
            endfor
        endfor;
        {% val/n, xsum/val, ysum/val %} /* -> peak */
    enddefine;

    round(avx) -> avx;  round(avy) -> avy;
    unless avx == 0 and avy == 0 then
        if peaklist.islist then
            maplist(peaklist,refpeak) -> peaklist;
            ;;; Put in order
            syssort(peaklist,
                procedure(x,y); lvars x, y;
                    x(1) > y(1)
                endprocedure) -> peaklist;
        else ;;; assume it is a single peak vecotr
            refpeak(peaklist) -> peaklist
        endif
    endunless
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Feb 20 1997
        Changed ispair to islist in test of peaklist type to allow correct
        processing of empty list.
--- David S Young, Jul 13 1993
        Changed -newfloatarray- to -newsfloatarray- and -isfloatarray- to
        -issfloatarray- to avoid clash with *VEC_MAT package.
--- David S Young, Jan 30 1993
        Added -array_peak-
 */
