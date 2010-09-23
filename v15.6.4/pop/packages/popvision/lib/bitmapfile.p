/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $popvision/lib/bitmapfile.p
 > Purpose:         Read and write ASCII version of bitmap files
 > Author:          David S Young, Jan 20 1994
 > Documentation:   HELP * BITMAPFILE, MAN * BITMAP
 */

/* Writes an array as an ASCII file which can be converted to a bitmap
file by atobm(1).

Reads such files too, into bit arrays. */

compile_mode:pop11 +strict;

section;

uses bitvectors

;;; Characters used by atobm and bmtoa

lconstant ZERO = `-`, ONE = `#`;

define bitmapfile(filename) /* -> array */;
    lvars filename, array;
    lvars chin = discin(filename),
        ch, c, r, nc, ncols = false, nrows = 0, bv;
    consbitvector(
        until (chin() ->> ch) == termin do
            nrows + 1 -> nrows;
            0 -> nc;
            repeat
                nc + 1 -> nc;
                if ch == ONE then
                    1               ;;; on stack
                elseif ch == ZERO then
                    0               ;;; on stack
                else
                    mishap (filename, ch, 2, 'Unexpected character')
                endif;
            quitif ((chin() ->> ch) == `\n`) endrepeat;
            if ncols then
                unless nc == ncols then
                    mishap (filename, nrows, 2, 'Change in line length')
                endunless
            else
                nc -> ncols
            endif
        enduntil, nrows * ncols) -> bv;
    newanyarray([1 ^ncols 1 ^nrows], bv) /* -> array */;
enddefine;

define updaterof bitmapfile(array, filename);
    lvars array, filename;
    lvars chout = discout(filename), c, r,
        (c0, c1, r0, r1) = explode(boundslist(array));
    for r from r0 to r1 do
        for c from c0 to c1 do
            if array(c, r) = 0 then
                chout(ZERO)
            else
                chout(ONE)
            endif
        endfor;
        chout(`\n`)
    endfor;
    chout(termin)
enddefine;

endsection;
