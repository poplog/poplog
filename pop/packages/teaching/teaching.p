/* --- Copyright University of Birmingham 2005. All rights reserved. ------
 > File:            $usepop/pop/lib/packages/teaching/teaching.p
 > Purpose:         To link to setup the 'teaching' package of poplog
 > Author:          Aaron Sloman, 8 Jan 2005
 > Documentation:   See teach/ help/ sub-directories
 > Related Files:	
 */

/*

Set up search lists suitable for learners using popfilename to work out
locations relative to the directory containing this file.

Copied code used in popvision, to start with.
*/

compile_mode:pop11 +strict;

section;

;;; Go up one directory level from present file to get $teaching
lvars
	Dir = sys_fname_path(popfilename) ;

;;; Dir =>

define lconstant add_search_dirs(Sdir);

    ;;; Extend list for uses construct
    extend_searchlist(Sdir dir_>< 'lib', popuseslist) -> popuseslist;
    extend_searchlist(Sdir dir_>< 'auto', popautolist) -> popautolist;
    extend_searchlist(Sdir dir_>< 'include', popincludelist) -> popincludelist;

    ;;; And extend ved's teach and help lists
    lvars
        Sdoc = [% Sdir dir_>< 'doc' % doc],
        Steach = [% Sdir dir_>< 'teach' % teach],
        Shelp = [% Sdir dir_>< 'help' % help],
        Sref = [% Sdir dir_>< 'ref' % ref],

        Sdoclist = [^Sdoc ^Shelp ^Sref ^Steach],
        Shelplist = [^Shelp ^Sref ^Steach ^Sdoc],
        Sreflist = [^Sref ^Shelp ^Steach ^Sdoc],
        Steachlist = [^Steach ^Shelp ^Sref ^Sdoc];

    extend_searchlist(ident Sdoclist, veddoclist) -> veddoclist;
    extend_searchlist(ident Shelplist, vedhelplist) -> vedhelplist;
    extend_searchlist(ident Steachlist, vedteachlist) -> vedteachlist;
    extend_searchlist(ident Sreflist, vedreflist) -> vedreflist;
	extend_searchlist(Sdir, poppackagelist, true) -> poppackagelist;
enddefine;


add_search_dirs(Dir);

;;; And set up a variable to point to the data library

global vars teachingdatalib = Dir dir_>< 'data/';

;;; Later consider moving stuff from exising $popdatalib
;;; to teachingdatalib

;;; Stop uses doing it again, and make directory available

global vars teaching = Dir;


endsection;
