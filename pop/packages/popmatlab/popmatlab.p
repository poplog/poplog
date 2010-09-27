/* --- Copyright University of Sussex 2008. All rights reserved. ------
 > File:            $usepop/pop/packages/popmatlab/popmatlab.p
 > Purpose:         Make available a subset of popvision, concerned
 >                      concerned with array processing, linear algebra,
 >                      matrices, etc.
 > Author:          David Young (see revisions)
 >                  Installed by Aaron Sloman, Jan 12 2005
 > Documentation:   HELP POPMATLAB, HELP POPVISION
 > Related Files:   LIB POPVISION
 */


section;

global constant popmatlab;

unless isundef(popmatlab) then [endsection;] -> proglist endunless;


;;; Default root dir for package is THIS directory
lconstant popmatlab_dir = sys_fname_path(popfilename);

;;; popmatlab_dir ==>

;;; just make the popvision libraries available
uses popvision


;;; these utilities are precompiled for convenience
uses newintarray

uses newdfloatarray

uses newrfloatarray

uses newcfloatarray

uses newzfloatarray

;;; global variable, for uses

extend_searchlist(popmatlab_dir, poppackagelist, true) -> poppackagelist;

extend_searchlist(popmatlab_dir dir_>< 'help', vedhelplist, true) -> vedhelplist;


global vars popmatlab = popmatlab_dir;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May  1 2008
		extended vedhelplist to make HELP popmatlab
		available
 */
