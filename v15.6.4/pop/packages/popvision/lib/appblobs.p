/* --- Copyright University of Sussex 1998. All rights reserved. ----------
 > File:            $popvision/lib/appblobs.p
 > Purpose:         Apply procedures to blobs in an image
 > Author:          David S Young, Sep 12 1991 (see revisions)
 > Documentation:   HELP *APPBLOBS
 > Related Files:   LIB *APPBLOB_STATS_DEFS
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses appblobs_stats_defs        ;;; defines the constants used below

define lconstant fast_deref2(ref) -> (ref, refcont);
    ;;; Like fast_deref but returns both the last ref in the chain and
    ;;; its cont. Must be given a ref as argument (does not check)
    ;;; and ignores the value of the contents.
    lvars ref, refcont;
    while isref(fast_cont(ref) ->> refcont) do
        refcont -> ref
    endwhile
enddefine;

define lconstant fast_ncdelete1(item,list) -> list;
    ;;; Deletes the first occurrence of item from the list, reusing
    ;;; the original links, and testing for identity with ==.
    ;;; item MIST be present in the list - there is no check and if
    ;;; it is missing already disaster is possible.
    lvars item, list;
    lvars newb,
        l = list,
        (f,b) = fast_destpair(list);

    if f == item then
        b -> list
    else
        until (fast_destpair(b) -> newb) == item do
            b -> l;
            newb -> b
        enduntil;
        newb -> fast_back(l)
    endif
enddefine;

define vars appblobs_test(v) /* -> bool */;
    lvars v;
    v /= 0
enddefine;

define appblobs8(array, RECORD, MERGE) -> regionlist;
    lvars array, procedure(RECORD, MERGE), regionlist = [];
    lvars colour = 0,
        x y g u l ul ur tref trec cref crec xm1 buff buffu,
        (x0, x1, y0, y1) = explode(boundslist(array));

    ;;; Arrays corresponding to two adjacent raster lines. Extra element
    ;;; each end allows whole array to be used.
    ;;; Each element is either false to mean not in a blob, or a REF whose
    ;;; contents are something returned by the RECORD argument, or else
    ;;; a REF pointing to a REF pointing to ... pointing to a thing returned
    ;;; by RECORD.
    ;;; This is to allow regions to be merged - the REF can just be made
    ;;; to point to the new structure. Refs have to be chained otherwise
    ;;; remote pointers to the structure get lost.
    newarray([% x0-1,  x1+1 %], false) -> buffu;
    newarray([% x0-1,  x1+1 %], false) -> buff;

    ;;; This is optimised for the case where most of the array is non-blob.
    ;;; For arrays with a lot of blob, it would be more efficient to assign
    ;;; cref -> l, and ur -> u -> ul on every pixel. Could have just one
    ;;; buffer in this case too, and maybe save a bit on dereferencing. See
    ;;; appblobs4, which uses this method.

    fast_for y from y0 to y1 do
        fast_for x from x0 to x1 do
            if appblobs_test(array(x,y) ->> g) then      ;;; in a blob

                x fi_- 1 -> xm1;
                buffu(x fi_+ 1) -> ur;      ;;; 4 neighbours already processed
                buffu(x) -> u;
                buffu(xm1) -> ul;
                buff(xm1) -> l;

                ;;; Look clockwise round current pixel to see if connected -
                ;;; relies on left to right evaluation of POP-11 OR
                if l or ul or u or ur ->> cref then

                    fast_deref2(cref) -> (cref,crec);
                    (x, y, g) -> RECORD(crec);  ;;; add current pixel to region

                    ;;; Check if this causes a connection between 2 regions
                    ;;; - if (u and ur) then ur and u must be the same.
                    ;;; Testing ref rather than rec means that do not need to
                    ;;; worry about what RECORD returns.
                    if (l or ul) and ((u or ur) ->> tref)
                    and (fast_deref2(tref) -> (tref, trec), tref /== cref) then

                        ;;; remove the two regions from the list
                        fast_ncdelete1(trec, regionlist) -> regionlist;
                        fast_ncdelete1(crec, regionlist) -> regionlist;

                        ;;; form new region, update region list
                        MERGE(crec, trec) -> crec;
                        conspair(crec, regionlist) -> regionlist;

                        ;;; update pointers in the buffer - really do
                        ;;; need another consref!
                        consref(crec) ->> fast_cont(cref) ->> fast_cont(tref)
                            -> cref
                    endif

                else    ;;; create new region
                    RECORD(x, y, g) -> crec;
                    conspair(crec, regionlist) -> regionlist;
                    consref(crec) -> cref
                endif;

                ;;; store the reference to the current region in the buffer
                cref -> buff(x)

            else    ;;; not in a blob

                false -> buff(x)

            endif
        endfor;
        (buff, buffu) -> (buffu, buff)  ;;; swap buffers
    endfor

enddefine;

define appblobs4(array, RECORD, MERGE) -> regionlist;
    lvars array, procedure(RECORD, MERGE), regionlist = [];
    lvars colour = 0,
        x y g u l tref trec cref crec buff,
        (x0, x1, y0, y1) = explode(boundslist(array));

    ;;; Like appblobs8 but for 4-connectivity. See comments in appblobs8.
    ;;; Main modification is that single-buffer method is used, as tradeoff
    ;;; is a little different.
    newarray([% x0,  x1 %], false) -> buff;

    fast_for y from y0 to y1 do
        false -> l;                 ;;; l is updated every pixel
        fast_for x from x0 to x1 do

            if appblobs_test(array(x,y) ->> g) then      ;;; in a blob
                buff(x) -> u;
                if l or u ->> cref then
                    fast_deref2(cref) -> (cref,crec);
                    (x, y, g) -> RECORD(crec);  ;;; add current pixel to region

                    if l and (u ->> tref)
                    and (fast_deref2(tref) -> (tref, trec), tref /== cref) then

                        fast_ncdelete1(trec, regionlist) -> regionlist;
                        fast_ncdelete1(crec, regionlist) -> regionlist;
                        MERGE(crec, trec) -> crec;
                        conspair(crec, regionlist) -> regionlist;
                        consref(crec) ->> fast_cont(cref) ->> fast_cont(tref)
                            -> cref
                    endif
                else    ;;; create new region
                    RECORD(x, y, g) -> crec;
                    conspair(crec, regionlist) -> regionlist;
                    consref(crec) -> cref
                endif;

                cref ->> l -> buff(x)
            else    ;;; not in a blob
                false ->> l -> buff(x)
            endif
        endfor
    endfor

enddefine;

define appblobs(array, RECORD, MERGE, four_or_eight) /* -> list */;
    lvars array, RECORD, MERGE, four_or_eight;
    if four_or_eight == 8 then
        appblobs8(array,RECORD,MERGE)
    elseif four_or_eight == 4 then
        appblobs4(array,RECORD,MERGE)
    else
        mishap(four_or_eight, 1, 'Connectivity must be 4 or 8')
    endif
enddefine;

/* Examples of applications. blob_stats is the most likely to be useful
as a basis for modification. */

define blob_count(array, four_or_eight) /* -> no_blobs */;
    ;;; This just builds a list (of what is irrelevant), one entry
    ;;; for each blob, and takes its length. An alternative would be
    ;;; to increment a global on each call of RECORD (not the updater)
    ;;; and to decrement it on each call of MERGE.

    lvars array, four_or_eight;

    define lconstant RECORD(x, y, g) /* -> 0 */;
        lvars x, y, g;
        0           ;;; does not matter what this returns
    enddefine;

    define updaterof RECORD(x, y, g, rec);
        lvars x, y, g, rec;
        ;;; does nothing except remove its arguments
    enddefine;

    define lconstant MERGE(r1, r2) /* -> 0 */;
        lvars r1, r2;
        0       ;;; does not matter what this returns
    enddefine;

    length(appblobs(array, RECORD, MERGE, four_or_eight))
enddefine;

define blob_stats(array, four_or_eight) -> list;
    lvars array, four_or_eight, list;

    /* Returns a list of vectors, one for each blob. Each vector contains:

        1. no of pixels in blob
        2. min x of pixels in blob
        3. max x
        4. min y
        5. max y
        6. mean x (x position of centroid of blob)
        7. mean y
        8. sd of blob measured along longer principle axis
        9. sd of blob measured along shorter principle axis
        10. orientation of principal axis of blob to x-axis
        11. x coord of a pixel which is in the blob
        12. y coord of the same pixel

    First argument can be an array or a list as produced by blob_pixels.
    */

    define lconstant RECORD(x, y, g) /* -> vector */;
        ;;; The initial record for a single-pixel blob
        lvars x, y, g;
        {%
            1,                          ;;; no pixels
            x, x, y, y,                 ;;; min & max
            x, y,                       ;;; sums of coords
            x * x, y * y,               ;;; sums of squares
            x * y,                      ;;; sum of cross term
            x, y                        ;;; the pixel coords
            %}
    enddefine;

    define updaterof RECORD(x, y, g, rec);
        ;;; Update the quantities given above when a new pixel is added.
        ;;; Note that these quantities do not get the meanings implied
        ;;; by their names until PROCESS, below, is run.
        lvars x, y, g, rec;
        rec(BLOB_N) + 1 -> rec(BLOB_N);               ;;; one more pixel
        min(rec(BLOB_MINX), x) -> rec(BLOB_MINX);           ;;; min & max
        max(rec(BLOB_MAXX), x) -> rec(BLOB_MAXX);
        min(rec(BLOB_MINY), y) -> rec(BLOB_MINY);
        max(rec(BLOB_MAXY), y) -> rec(BLOB_MAXY);
        rec(BLOB_MEANX) + x -> rec(BLOB_MEANX);               ;;; sums of coords
        rec(BLOB_MEANY) + y -> rec(BLOB_MEANY);
        rec(BLOB_MAJSIZE) + x * x -> rec(BLOB_MAJSIZE);           ;;; sums of squares
        rec(BLOB_MINSIZE) + y * y -> rec(BLOB_MINSIZE);
        rec(BLOB_ORIENT) + x * y -> rec(BLOB_ORIENT);         ;;; sum of cross term
        ;;; BLOB_X and BLOB_Y stay the same
    enddefine;

    define lconstant MERGE(rec, reca) -> rec;
        ;;; Merge two regions. Use of min, max and + is straightforward
        ;;; Note that these quantities do not get the meanings implied
        ;;; by their names until PROCESS, below, is run.
        lvars rec, reca;
        rec(BLOB_N) + reca(BLOB_N) -> rec(BLOB_N);
        min(rec(BLOB_MINX), reca(BLOB_MINX)) -> rec(BLOB_MINX);
        max(rec(BLOB_MAXX), reca(BLOB_MAXX)) -> rec(BLOB_MAXX);
        min(rec(BLOB_MINY), reca(BLOB_MINY)) -> rec(BLOB_MINY);
        max(rec(BLOB_MAXY), reca(BLOB_MAXY)) -> rec(BLOB_MAXY);
        rec(BLOB_MEANX) + reca(BLOB_MEANX) -> rec(BLOB_MEANX);
        rec(BLOB_MEANY) + reca(BLOB_MEANY) -> rec(BLOB_MEANY);
        rec(BLOB_MAJSIZE) + reca(BLOB_MAJSIZE) -> rec(BLOB_MAJSIZE);
        rec(BLOB_MINSIZE) + reca(BLOB_MINSIZE) -> rec(BLOB_MINSIZE);
        rec(BLOB_ORIENT) + reca(BLOB_ORIENT) -> rec(BLOB_ORIENT);
        ;;; BLOB_X and BLOB_Y from rec
    enddefine;

    define lconstant SUMSFROMLIST(pixlist) /* -> vec */;
        ;;; Compute the same sums as above but for a single blob whose
        ;;; pixel coords are held as pairs in the (non-empty) list.
        lvars pixlist;
        lvars (x, y) = explode(hd(pixlist)),
            n = 1, minx = x, maxx = x, miny = y, maxy = y,
            meanx = x, meany = y,
            majsize = x*x, minsize = y*y, orient = x*y,
            x1 = x, y1 = y,
            pixel;
        for pixel in tl(pixlist) do
            explode(pixel) -> (x, y);
            n + 1 -> n;
            min(minx, x) -> minx;   max(maxx, x) -> maxx;
            min(miny, y) -> miny;   max(maxy, y) -> maxy; meanx + x -> meanx;
            meany + y -> meany;
            majsize + x*x -> majsize;  minsize + y*y -> minsize;
            orient + x*y -> orient
        endfor;
        {% n, minx, maxx, miny, maxy, meanx, meany, majsize,
            minsize, orient, x1, y1 %}
    enddefine;

    if array.isarray then
        appblobs(array, RECORD, MERGE, four_or_eight)
    else
        maplist(array, SUMSFROMLIST)
    endif-> list;

    ;;; list now has sums - but means and sds will be more meaningful
    ;;; normally. So do the conversion.

    define lconstant PROCESS(rec);
        ;;; Updates vec, converting sums to means, sds, slopes etc.
        lvars rec;
        lvars n, xmean, ymean, xvar, yvar, xyvar, theta2, cts, sts, ctst2;

        number_coerce(rec(BLOB_N), 0.0) -> n;       ;;; make real for efficiency

        ;;; means
        rec(BLOB_MEANX) / n ->> xmean -> rec(BLOB_MEANX);
        rec(BLOB_MEANY) / n ->> ymean -> rec(BLOB_MEANY);

        ;;; variances
        rec(BLOB_MAJSIZE) / n - xmean * xmean -> xvar;
        rec(BLOB_MINSIZE) / n - ymean * ymean -> yvar;
        rec(BLOB_ORIENT)/ n - xmean * ymean -> xyvar;

        ;;; orientation of principal axis
        arctan2( xvar - yvar,   2.0 * xyvar ) -> theta2;
        0.5 * (cos(theta2) + 1.0) -> cts;
        1.0 - cts -> sts;
        sin(theta2) -> ctst2;

        ;;; rotate into principal axes
        sqrt( xvar * cts + yvar * sts + xyvar * ctst2 ) -> rec(BLOB_MAJSIZE);
        ;;; go up to zero in case of rounding errors
        sqrt( max( 0, xvar * sts + yvar * cts - xyvar * ctst2 ) ) -> rec(BLOB_MINSIZE);
        0.5 * theta2 -> rec(BLOB_ORIENT)

    enddefine;

    applist(list, PROCESS)

enddefine;

define blob_pixels(array, four_or_eight) /* -> pixlist */;
    ;;; This records the coordinates of every blob pixel.
    ;;; It returns a list containing one list for each blob.
    ;;; The list for a given blob contains pairs, each of which
    ;;; contains the column and row of a pixel in the blob.

    lvars array, four_or_eight;

    define lconstant RECORD(x, y, g) /* -> coordspairinlist */;
        lvars x, y, g;
        ;;; Start list of pairs.
        conspair(conspair(x, y), [])
    enddefine;

    define updaterof RECORD(x, y, g, rec);
        lvars x, y, g, rec;
        ;;; New pair goes into second place in list.
        conspair(conspair(x, y), fast_back(rec)) -> fast_back(rec)
    enddefine;

    define lconstant MERGE(r1, r2) /* -> r1 */;
        lvars r1, r2;
        r1 ncjoin r2
    enddefine;

    appblobs(array, RECORD, MERGE, four_or_eight)
enddefine;

define ncblob_paint(array, firstval, NEXTVAL, four_or_eight);
    ;;; Updates the array, storing firstval in the pixels contained in
    ;;; the first blob encountered, then applying NEXTVAL to firstval
    ;;; to get the value to store in the pixels of the second blob, and
    ;;; so on. To number the blobs, see below.
    lvars array, firstval, NEXTVAL, four_or_eight;

    lvars list,
        contact = 0;        ;;; incremented when we contact a new blob

    define lconstant RECORD(x, y, g) /* -> rec */;
        lvars x, y, g;
        contact + 1 -> contact;
        [ ^contact ]        ;;; record the contact number for this region
    enddefine;

    define updaterof RECORD(x, y, g, rec);
        lvars x, y, g, rec;
        ;;; do nothing
    enddefine;

    lconstant MERGE = nonop nc_<>;

    appblobs(array, RECORD, MERGE, four_or_eight) -> list;

    ;;; We now have, for each blob, a list identifying which new contacts
    ;;; hit it. So we can build a table relating these numbers to the things
    ;;; to be stored in the array.

    lvars blob_list,
        value = firstval,
        table = initv(contact);

    for blob_list in list do
        for contact in blob_list do
            value -> table(contact)
        endfor;
        NEXTVAL(value) -> value
    endfor;

    ;;; Now define procedures that update the array. The updater of RECORD2
    ;;; is used to update the array rather than the record!

    0 -> contact;       ;;; reset so will track first run

    define lconstant RECORD2(x, y, g) /* -> contact */;
        lvars x, y, g;
        contact + 1 -> contact;
        table(contact) -> array(x,y);       ;;; update array
        contact         ;;; just return the contact number
    enddefine;

    define updaterof RECORD2(x, y, g, contact);
        ;;; Note CONTACT is an argument, not the global - very important!
        ;;; This tells us which blob we are on.
        lvars x, y, g, contact;
        table(contact) -> array(x,y)        ;;; update array
    enddefine;

    define lconstant MERGE2(rec1, rec2) -> rec1;
        ;;; Does not matter which we return
        lvars rec1, rec2;
    enddefine;

    ;;; Run this lot over the array

    appblobs(array, RECORD2, MERGE2, four_or_eight) -> ;

enddefine;

define blob_paint(array, four_or_eight) -> newarr;
    ;;; Safe and simple blob painter, that copies the array and numbers the
    ;;; blobs from 1 upwards.
    lvars array, four_or_eight,
        newarr = copy(array);
    ncblob_paint(newarr, 1, nonop +(%1%), four_or_eight)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Jan 23 1998
        blob_pixels added, and blob_stats modified so that it can take
        a list of pixels as input
--- David S Young, Feb 20 1995
        BLOB_X and BLOB_Y added
--- David S Young, Feb  8 1995
        appblobs_test made vars so as to be user-definable
--- David S Young, Nov 26 1992
        Installed.
 */
