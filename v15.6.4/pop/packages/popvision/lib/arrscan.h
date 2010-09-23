/* --- Copyright University of Sussex 2004. All rights reserved. ----------
 * File:            $popvision/lib/arrscan.h
 * Purpose:         Header file for arrscan.c
 * Author:          David Young, Dec 16 2003 (see revisions)
 * Documentation:   LIB * ARRPACK
 * Related Files:   LIB * ARRSCAN.C
 */

/* Function prototypes for arrscan */

int arrspec(int *spec, int cdopt, int ordopt,
    int *off, int *dp, int *ndp, int **spp, int **wkp);
int arrscan_check(int *spec1, int *spec2);
int arrscan_check_total(int *spec1, int *spec2);
int arrscan_dimpars1(int dim, int *spec, int *istart, int *iinc);
int arrscan_dimpars(int *spec, int *istarts, int *iincs);
int arrind(int *spec, int *nelp, int *d0p, int **dp, int **dendp);

/* --- Revision History ---------------------------------------------------
--- David Young, Apr  1 2004
        Added arrscan_dimpars1, arrscan_dimpars and arrind
 */
