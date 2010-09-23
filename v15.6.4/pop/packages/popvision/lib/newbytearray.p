/* --- Copyright University of Sussex 2003. All rights reserved. ----------
 > File:            $popvision/lib/newbytearray.p
 > Purpose:         Create packed arrays of bytes
 > Author:          David S Young, Nov 15 1994 (see revisions)
 > Documentation:   HELP * NEWBYTEARRAY
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses oldarray

defclass bytevec :byte;

define newbytearray = newanyarray(% bytevec_key %); enddefine;

define oldbytearray = oldanyarray(% bytevec_key %); enddefine;

define isbytearray(arr) /* -> result */;
    ;;; Returns false unless arr is an array with an arrayvector containing
    ;;; only byte values.
    lvars arr;
    lconstant (value_spec, ) = field_spec_info("byte");
    arr.isarray and arr.arrayvector.datakey.class_spec == value_spec
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- David Young, Jul 15 2003
        Made oldbytearray a closure.
 */
