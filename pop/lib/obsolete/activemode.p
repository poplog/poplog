/*  --- Copyright University of Sussex 1996. All rights reserved. ----------
 *  File:           C.all/lib/obsolete/activemode.p
 *  Purpose:        extension to lib active
 *  Author:         Roger Evans, June 1983 (see revisions)
 *  Documentation:
 *  Related Files:  LIB * ACTIVE
 */

;;; activemode is a macro which allows users to specify use of lib active IO
;;; (ie half screen as picture, half as scroll window) within the context of
;;; a given procedure (and any procedures called from it) only. It assumes
;;; lib active (strictly,v200graph) is already loaded - if not it does
;;; nothing.

vars Vin Vout;
unless isprocedure(Vin) then charin -> Vin;charout -> Vout; endunless;


vars macro activemode;
[;vars cucharin cucharout proglist;
  Vin -> cucharin;
  Vout -> cucharout;
  pdtolist(incharitem(cucharin)) -> proglist;] -> nonmac activemode;


/* --- Revision History ---------------------------------------------------
--- John Williams, Jan  3 1996
		Moved from C.all/lib/turtle to C.all/lib/obsolete
 */
