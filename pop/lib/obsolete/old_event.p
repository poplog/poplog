/*  --- Copyright University of Sussex 1993. All rights reserved. ----------
 >  File:           C.all/lib/obsolete/old_event.p
 >  Purpose:        Old library
 >  Author:         Unknown, ??? (see revisions)
 >  Documentation:  HELP * ACTOR
 */

#_TERMIN_IF DEF POPC_COMPILING

uses actor;
uses actor_event;

section;

identof("actor_eventhandler")	-> identof("eventhandler");
identof("actor_event")			-> identof("event");
identof("actor_waitevent")		-> identof("waitevent");
identof("actor_diewhen")		-> identof("diewhen");

global constant old_event = true;

endsection;


/* --- Revision History ---------------------------------------------------
--- John Gibson, Aug 24 1993
		Made lib/obsolete/old_event.p
--- John Gibson, Nov 12 1992
		Moved to lib actor_event with above renaming of procedures.

 */
