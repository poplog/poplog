/* --- Copyright University of Sussex 2000. All rights reserved. ----------
 > File:            $popvision/lib/random_order.p
 > Purpose:         Produce random orderings of sequences
 > Author:          David Young, May 22 2000
 > Documentation:   HELP * RANDOM_ORDER
 > Related Files:   LIB * ERANDOM
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses erandom

define random_order(invec, outvec) -> ordrep;
    lvars procedure ordrep;
    lconstant ran = erandom("uniform");

    ;;; Create list of pairs containing entries to be sorted with
    ;;; slots for random numbers.
    lvars i, n, list, makelist;
    if invec.isinteger and invec > 0 then
        invec -> n;
        true -> makelist;   ;;; sophisticated users can force vectors
        [% fast_for i from 1 to n do
                conspair(0, i)
            endfor %] -> list
    elseif invec.isvectorclass then
        length(invec) -> n;
        false -> makelist;
        [% fast_for i from 1 to n do
                conspair(0, invec(i))
            endfor %] -> list
    elseif invec.islist then
        0 -> n;
        true -> makelist;
        [% fast_for i in invec do
                n fi_+ 1 -> n;
                conspair(0, i)
            endfor %] -> list
    else
        mishap(invec, 1, 'Vector, list or positive integer needed')
    endif;

    ;;; Check output
    if outvec and length(outvec) /== n then
        mishap(outvec, n, 2, 'Output vector or list wrong length')
    endif;

    define lvars procedure ordrep /* -> result */;
        lvars p;
        fast_for p in list do
            ran() -> fast_front(p)
        endfor;
        nc_listsort(list,
            procedure(x,y); fast_front(x) <= fast_front(y) endprocedure
        ) -> list;
        if outvec.isvectorclass then
            lvars i = 0;
            fast_for p in list do
                i fi_+ 1 -> i;
                fast_back(p) -> outvec(i)
            endfor;
            outvec /* -> result */
        elseif outvec.islist then
            lvars w = outvec;
            fast_for p in list do
                fast_back(p) -> fast_front(w);
                fast_back(w) -> w
            endfor;
            outvec /* -> result */
        elseif makelist then
            [% fast_for p in list do
                    fast_back(p)
                endfor %] /* -> result */
        else
            {% fast_for p in list do
                    fast_back(p)
                endfor %} /* -> result */
        endif
    enddefine
enddefine;

endsection;
