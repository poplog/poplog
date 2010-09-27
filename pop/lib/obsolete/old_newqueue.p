/*  --- Copyright University of Sussex 1993.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/old_newqueue.p
 >  Purpose:        Old library
 >  Author:         Jonathan Cunningham, March 1984 (see revisions)
 >  Documentation:  HELP * NEWQUEUE
 >  Related Files:
 */

#_TERMIN_IF DEF POPC_COMPILING

section;

uses newqueue;

identof("queuelist")	-> identof("qlist");
identof("queuelength")	-> identof("qlength");

global constant old_newqueue = true;

endsection;


/* --- Revision History ---------------------------------------------------
--- John Gibson, Aug 24 1993
		Moved to lib/obsolete/old_newqueue.p
--- John Gibson, Nov 11 1992
		Moved to lib new_new*queue with above renaming of procedures.
 */
