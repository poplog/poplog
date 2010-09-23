/* --- Copyright University of Sussex 1996. All rights reserved. ----------
 > File:            $popvision/lib/rawarrayfile.p
 > Purpose:         Primitive array read/write procedure, mainly for sequences
 > Author:          David S Young, Aug  9 1996
 > Documentation:   HELP * RAWARRAYFILE
 */

/* Read and write arrayvectors with no heading information. */

compile_mode:pop11 +strict;

section;

define rawarrayfile(filename, arr) -> arr;
    ;;; Reads data from filename into the arrayvector of arr, returning arr.
    ;;; Assumes that the length and type of data in the file is correct.
    lconstant ( , bits_per_byte) = field_spec_info("byte");
    lvars
        dev = sysopen(filename, 0, true, `N`),
        (fsub, bsub) = arrayvector_bounds(arr),
        nel = fsub - bsub + 1,
        v = arrayvector(arr),
        ( , bits_per_element) = field_spec_info(class_spec(datakey(v))),
        nbytes = (nel * bits_per_element) / bits_per_byte;
    unless nbytes.isintegral then
        intof(nbytes) + 1 -> nbytes
    endunless;
    unless sysread(dev, bsub, v, nbytes) == nbytes then
        mishap(filename, nbytes, 2, 'Could not read data')
    endunless;
    sysclose(dev)
enddefine;

define updaterof rawarrayfile(arr, filename);
    ;;; Writes the arrayvector of arr to a disc file, raw and naked.
    lconstant ( , bits_per_byte) = field_spec_info("byte");
    lvars
        dev = syscreate(filename, 1, true, `N`),
        (fsub, bsub) = arrayvector_bounds(arr),
        nel = fsub - bsub + 1,
        v = arrayvector(arr),
        ( , bits_per_element) = field_spec_info(class_spec(datakey(v))),
        nbytes = (nel * bits_per_element) / bits_per_byte;
    unless nbytes.isintegral then
        intof(nbytes) + 1 -> nbytes
    endunless;
    syswrite(dev, bsub, v, nbytes);
    sysclose(dev)
enddefine;

endsection;
