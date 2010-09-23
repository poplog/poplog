/* --- Copyright University of Sussex 1995. All rights reserved. ----------
 > File:            C.all/src/shortvec.p
 > Purpose:
 > Author:          Aled Morris Aug 13 1987 (see revisions)
 > Documentation:	REF *INTVEC
 */

;;; ---------------- 16-BIT (SIGNED INTEGER) VECTORS -------------------------

#_INCLUDE 'declare.ph'

;;; ------------------------------------------------------------------------

defclass shortvec :short;


/* --- Revision History ---------------------------------------------------
--- John Gibson, Apr  5 1995
		Replaced whole lot with defclass
--- John Gibson, Sep  2 1992
		Added M_K_NO_FULL_FROM_PTR to key flags
--- John Gibson, May 17 1990
		Fixed bug in -initshortvec- (wasn't rounding the size given to
		_fill to a word offset).
--- John Gibson, Apr  2 1990
		Changed K_SPEC to "short"
--- John Gibson, Mar 14 1990
		Change to key layout.
--- John Gibson, Dec  2 1989
		Changes for new pop pointers
--- John Gibson, Mar 28 1988
		Moved out of vectors.p
 */
