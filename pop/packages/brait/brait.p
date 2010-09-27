/* --- copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/brait.p
 > Purpose:         Make "brait" libraries and documents available
 > Author:          Duncan Fewkes, Aug 30 2000
 > Documentation:   TEACH BRAIT1, BOXDEMO
 > Related Files:

    LIB braitenberg_sim.p,
        matrix_functions.p,
        activation_functions.p,
        decay_functions.p,
        tools.p,
        box_object.p,
        source_object.p,
        vehicle_agent.p,
        ball_object.p,
        mousehandlers.p,
        interface.p,
        tutorialsupplement.p
 */

/*

Compile this file to make brait available.
Then try TEACH brait to get a detailed introduction to the package

or TEACH boxdemo to get a quick demonstration of the main facilities.

This file should be linked to $poploca/local/lib/brait.p so that

    uses brait

works.
*/

section;

global constant brait;   ;;; Made true at the end


;;; Prevent recompilation if brait has a value
unless isundef(brait) then [endsection;] -> proglist endunless;


;;; Set up root directory for the package, i.e.  THIS directory
;;; Typically '$poplocal/local/brait/'

;;; However the following should work no matter where the package
;;; is located.

lconstant brait_dir = sys_fname_path(popfilename);

;;; Set up directories fto be added to library search lists
lconstant brait_auto =    brait_dir dir_>< 'auto/';
lconstant brait_lib =     brait_dir dir_>< 'lib/';

;;; Uncomment this if necessary
;;; lconstant brait_data =     brait_dir dir_>< 'data/';

;;; Uncomment this if necessary (See HELP INCLUDE)
;;; lconstant brait_include = brait_dir dir_>< 'include/';

;;; Load and show from brait_ directory
extend_searchlist(brait_auto, popautolist) -> popautolist;
extend_searchlist(brait_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(brait_include, popincludelist) -> popincludelist;

;;; Extend ved's teach and help and ref lists. See REF LIBRARY
;;; comment out or uncomment, as necessary
lconstant
    brait_teach = [% brait_dir dir_>< 'teach/' % teach],
    brait_help = [% brait_dir dir_>< 'help/' % help],
;;; brait_ref = [% brait_dir dir_>< 'ref/' % help],
    brait_teachlist = [^brait_teach],
    brait_helplist = [^brait_help],
;;; brait_reflist = [^brait_ref],
    ;

;;; Put the new items at the *beginning* of each searchlist by
;;; default. If desired at the end, add "true" as third argument
;;; for extend_searchlist. See HELP extend_searchlist

extend_searchlist([^brait_help], vedhelplist) -> vedhelplist;
extend_searchlist(brait_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(brait_helplist, vedteachlist,true) -> vedteachlist;
extend_searchlist(brait_dir, poppackagelist, true) -> poppackagelist;

;;; extend_searchlist(brait_reflist, vedreflist) -> vedreflist;

;;; Some people like to put the ref and teach directories at the end
;;; of vedhelplist, and vice versa, etc., like this:
;;; extend_searchlist(brait_helplist, vedreflist, true) -> vedreflist;
;;; extend_searchlist(brait_teachlist, vedreflist, true) -> vedreflist;

uses braitenberg_sim

;;; Declare brait as an identifier and make it true so that "uses brait"
;;; will compile this only once.

global constant brait = brait_dir;

endsection;
