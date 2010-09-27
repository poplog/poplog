/* --- Copyright University of Sussex 1992. All rights reserved. ----------
 > File:            $popvision/lib/convolve_1d.p
 > Purpose:         Convolution of 1-D arrays
 > Author:          David S Young, Nov 26 1992
 > Documentation:   HELP *CONVOLVE_1D
 > Related Files:   LIB *CONVOLVE_NX1D
 */

compile_mode:pop11 +strict;

section;

uses popvision
uses convolve_nx1d

define convolve_1d(arrin, mask, arrout, region) /* -> arrout */;
    lvars arrin, mask, arrout, region;
    convolve_nx1d(arrin, mask, 1, arrout, region) /* -> arrout */
enddefine;

endsection
