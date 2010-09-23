/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/new_family_limit.p
 > Purpose:         Change limit of rulefamily dynamically
 > Author:          Aaron Sloman, Jul 25 1996
 > Documentation:	Requested by Peter Waudby
 > Related Files:
 */

section;
uses poprulebase

define global vars procedure new_family_limit(rule_instance, action);
    front(back(action)) ->  prb_family_limit(prb_current_family)
enddefine;


"new_family_limit" -> prb_action_type("NEWLIMIT");

endsection;
