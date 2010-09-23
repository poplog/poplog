/* --- Copyright University of Sussex 1995. All rights reserved. ----------
 > File:            $popvision/lib/popvision.p
 > Purpose:         Make popvision files available
 > Author:          David S Young, Jul 19 1994 (see revisions)
 */

/* Simply adds the current directory tree to the search lists - assume that
this file is in the vision directory itself, so this must be loaded by
something that knows where it lives in order to get started. */

compile_mode:pop11 +strict;

section;

define lconstant add_search_dirs(Sdir);
    lvars Sdir;

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
enddefine;

;;; Go up two directory levels from present file and add to search lists
lvars Dir = sys_fname_path(allbutlast(1, sys_fname_path(popfilename)));

add_search_dirs(Dir);

;;; And set up a variable to point to the data library

global vars popvision_data = Dir dir_>< 'data';

;;; If using a POPLOG without features such as in_array, load an
;;; extra library

#_IF pop_internal_version < 145100
    add_search_dirs(Dir dir_>< 'pre14.51');
#_ENDIF

;;; Stop uses doing it again, and make directory available

global vars popvision = Dir;

endsection;

/* --- Revision History ---------------------------------------------------
--- David S Young, Jan 11 1995
        Included popautolist in the set of lists extended.
        Added code to include extra directories for version before 14.51
 */
