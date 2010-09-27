/* --- Copyright University of Sussex 1988. All rights reserved. ----------
 > File:            $popneural/lib/convarr.p
 > Purpose:         Real*4/real*8 array conversion using Fortran
 > Author:          David Young, Dec  7 1988
 > Related Files:   convarr.f, convarr.o, convarrcomp, convfordef.p
 */

section;

uses convarrfordef;

vars convarr = true;

define updaterof doublearr(sarr,darr);
    lvars sarr darr;
    lvars n;
    datalength(sarr) -> n;
    unless datalength(darr) >= n then
        mishap('output array too small',[^sarr ^darr])
    endunless;
    stodarr(n,sarr,darr)
enddefine;

define doublearr(sarr) -> darr;
    lvars sarr darr;
    array_of_double(boundslist(sarr)) -> darr;
    sarr -> doublearr(darr)
enddefine;

define updaterof singlearr(darr,sarr);
    lvars sarr darr;
    lvars n;
    datalength(darr) -> n;
    unless datalength(sarr) >= n then
        mishap('output array too small',[^darr ^sarr])
    endunless;
    dtosarr(n,darr,sarr)
enddefine;

define singlearr(darr) -> sarr;
    lvars sarr darr;
    array_of_real(boundslist(darr)) -> sarr;
    darr -> singlearr(sarr)
enddefine;

endsection;

/*  --- Revision History --------------------------------------------------
*/
