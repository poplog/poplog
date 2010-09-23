/*  --- Copyright University of Sussex 1993.  All rights reserved. ---------
 >  File:           C.all/lib/obsolete/old_actor.p
 >  Purpose:        Old library
 >  Author:         Jonathan Cunningham, (see revisions)
 >  Documentation:  HELP * ACTOR
 */

#_TERMIN_IF DEF POPC_COMPILING

uses-now popobsoletelib;
uses actor, old_newqueue;

section;

identof("actor_apocalypse")	-> identof("apocalypse");
identof("actor_askactor")	-> identof("askactor");
identof("actor_answer")		-> identof("answer");
identof("actor_aeons")		-> identof("aeons");
identof("actor_die")		-> identof("die");
identof("actor_exists")		-> identof("exists");
identof("actor_genesis")	-> identof("genesis");
identof("actor_gpo")		-> identof("gpo");
identof("actor_kill")		-> identof("kill");
identof("actor_mymessagequeue") -> identof("mymessagequeue");
identof("actor_myname") 	-> identof("myname");
identof("actor_myparent")	-> identof("myparent");
identof("actor_newactor")	-> identof("newactor");
identof("actor_receive")	-> identof("receive");
identof("actor_say")		-> identof("say");
identof("actor_saytime")	-> identof("saytime");
identof("actor_send")		-> identof("send");
identof("actor_simtime")	-> identof("simtime");
identof("actor_sleep")		-> identof("sleep");
identof("actor_wait")		-> identof("wait");
identof("actor_wake")		-> identof("wake");

global constant old_actor = true;

endsection;


/* --- Revision History ---------------------------------------------------
--- John Gibson, Aug 24 1993
		Moved to lib/obsolete/old_actor.p
--- John Gibson, Nov 12 1992
		Moved to lib new*_actor with above renaming of procedures.
 */
