/* --- Copyright University of Sussex 2004. All rights reserved. ----------
 > File:            $popvision/lib/oldarray.p
 > Purpose:         Avoid garbage collection when getting temporary arrays
 > Author:          David S Young, Nov 15 1994 (see revisions)
 > Documentation:   HELP * OLDARRAY
 */

compile_mode:pop11 +strict;

section;

define lconstant boundsize(bounds) -> n;
    ;;; Assume bounds is non-dynamic, because newanyarray does not accept
    ;;; dynamic lists.
    1 -> n;
    lvars x0, x1;
    while ispair(bounds) do
        destpair(fast_destpair(bounds)) -> (x0, x1, bounds);
        n * (x1 - x0 + 1) -> n
    endwhile
enddefine;

define oldanyarray(tag, bounds, key) -> arr;

    ;;; Sort out arguments
    lvars elem_init = [], init_p, size_p = identfn, subscr_p = false;
    ;;; See if initialiser/subscriptor given
    unless key.iskey then
        (tag, bounds, key) -> (tag, bounds, init_p, subscr_p);
        if init_p.ispair then
            destpair(init_p) -> (init_p, size_p)
        endif
    endunless;
    ;;; See if an initialiser given
    unless bounds.islist then
        (tag, bounds) -> (tag, bounds, elem_init)
    endunless;

    lconstant
        propsize1 = 10,
        propsize2 = 50,
        typestore = newproperty([], propsize1, false, "perm");

    if tag then     ;;; act like newanyarray if tag is false

        ;;; Get property for this type of array
        lvars arraystore;
        unless typestore(subscr_p or key) ->> arraystore then
            newproperty([], propsize2, false, "tmpval") ->> arraystore
                -> typestore(subscr_p or key)
        endunless;

        ;;; Get array for this tag
        unless (arraystore(tag) ->> arr) and boundslist(arr) = bounds
        and arr.isarray_by_row == poparray_by_row and elem_init == [] then
            if arr and length(arrayvector(arr)) >= size_p(boundsize(bounds))
            then
                ;;; Create an array on top of the existing arrayvector.
                ;;; Note - this new array is not stored in the property, so that
                ;;; the entry can be garbage collected. This is desirable when
                ;;; a reduction in size has occurred and memory is short.
                newanyarray(bounds,
                    if elem_init /== [] then elem_init endif,
                    arr, if subscr_p then subscr_p endif) -> arr
            else
                ;;; create a completely new array
                newanyarray(bounds,
                    if elem_init /== [] then elem_init endif,
                    if subscr_p then init_p, subscr_p else key endif)
                    ->> arr -> arraystore(tag)
            endif
        endunless

    else

        newanyarray(bounds, if elem_init /== [] then elem_init endif,
            if subscr_p then init_p, subscr_p else key endif) -> arr

    endif
enddefine;

define oldarray with_nargs 2;
    oldanyarray(vector_key)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jan  7 2004
        Speeded up boundsize (thanks to Steve Leach)
--- David Young, Sep  4 2003
        Fixed bug in tag == <false> case introduced with last change.
--- David Young, Jul 14 2003
        Behaviour of initialiser made consistent with newanyarray (i.e.
        can initialise elements to <false>, but not to any sort of list
        except via a procedure).
        Initialisation and subscriptor procedures provided as
        alternative to key, with special provision for cases where the
        length of the array vector is not the number of array elements.
--- David Young, Oct 26 2001
        Changed to act like newarray if the tag is false.
--- David S Young, Sep  4 1997
        Added check to see that poparray_by_row is respected.
 */
