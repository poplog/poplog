/* --- Copyright University of Sussex 1995. All rights reserved. ----------
 > File:            $popvision/lib/appblobs_stats_defs.p
 > Purpose:         Definitions for LIB *APPBLOBS
 > Author:          David S Young, Sep 12 1991 (see revisions)
 */

/* The following constants are useful in dealing with data from blob_stats */

compile_mode:pop11 +strict;

section;

constant (macro (
    BLOB_N,
    BLOB_MINX,
    BLOB_MAXX,
    BLOB_MINY,
    BLOB_MAXY,
    BLOB_MEANX,
    BLOB_MEANY,
    BLOB_MAJSIZE,
    BLOB_MINSIZE,
    BLOB_ORIENT,
    BLOB_X,
    BLOB_Y)) = (1,2,3,4,5,6,7,8,9,10,11,12);

vars appblobs_stats_defs = true;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Feb 20 1995
        Added BLOB_X and BLOB_Y
--- David S Young, Nov 26 1992
        Installed
 */
