/*  --- Copyright Integral Solutions Ltd. 1989. All Rights Reserved --------
 > File:           $popneural/lib/bp_cl_lib.p
 > Purpose:        declarations for networks to allow users without
 >                 Fortran compilers to use the pre-linked system
 > Author:         Julian Clinton, Jan 1990
 > Documentation:
 > Related Files:
*/

section;

uses fortload;
uses bp_cl_fordef;
vars bp_cl_lib = true;
fortload bp_cl_lib;

endsection;

/*  --- Revision History --------------------------------------------------
*/
