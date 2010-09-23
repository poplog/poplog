/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/neural/neural.p
 > Linked to:       $poplocal/local/lib/neural.p
 > Purpose:			Make "Popneural" libraries and documentation available
 > Author:          Aaron Sloman,  22 Jan 1999 (see revisions)
 > Documentation:	HELP * POPNEURAL, TEACH * POPNEURAL
 > Related Files:	$poplocalbin/neural.psv
 */

/*

Compile this file to make LIB neural available.

*/

;;; Cancel stuff to do with newexternal, to ensure that
;;; popneural works. See RELEASE_NOTES.doc

	lvars external_section;
	section $-external;

		current_section -> external_section;

	endsection;

	section_cancel(external_section);

	applist([newexternal external exload external_runtime
				typespec_utils p_typespec exacc exload_merge_objfiles],
		procedure(word); sysunprotect(word); syscancel(word) endprocedure);

;;; Now load lib external
uses external;

global constant neural;

section;

unless isundef(neural) then [endsection;] -> proglist endunless;

;;; Use pop-11 global variable if it exists. Default is THIS directory
global vars popneuraldir = sys_fname_path(popfilename);

;;; or use environment variable if it exists
lconstant NEURAL_VAR = systranslate('popneural');

lconstant
	neural_dir =
		if isstring(popneuraldir) then
			popneuraldir ->> systranslate('popneural');
		elseif isstring(NEURAL_VAR) then NEURAL_VAR
		else
			;;; Default is THIS directory
			sys_fname_path(popfilename)->> systranslate('popneural');
			;;; '$poplocal/local/neural/'
		endif;

lconstant neural_auto =    neural_dir dir_>< 'auto/';
lconstant neural_lib =     neural_dir dir_>< 'lib/';
;;; lconstant neural_include = neural_dir dir_>< 'include/';

;;; Load and show from neural_ directory
extend_searchlist(neural_auto, popautolist) -> popautolist;
extend_searchlist(neural_lib, popuseslist) -> popuseslist;
;;; extend_searchlist(neural_include, popincludelist) -> popincludelist;

;;; And extend ved's teach and help and ref lists
lconstant
	neural_teach = [% neural_dir dir_>< 'teach/' % teach],
	neural_help = [% neural_dir dir_>< 'help/' % help],
	neural_ref = [% neural_dir dir_>< 'ref/' % help],
	neural_teachlist = [^neural_teach],
	neural_helplist = [^neural_help],
	neural_reflist = [^neural_ref],
;
extend_searchlist(neural_helplist, vedhelplist) -> vedhelplist;
extend_searchlist(neural_reflist, vedhelplist, true) -> vedreflist;
extend_searchlist(neural_teachlist, vedteachlist) -> vedteachlist;
extend_searchlist(neural_helplist, vedteachlist,true) -> vedteachlist;
extend_searchlist(neural_reflist, vedreflist) -> vedreflist;
extend_searchlist(neural_helplist, vedreflist, true) -> vedreflist;
extend_searchlist(neural_dir, poppackagelist, true) -> poppackagelist;

global constant neural = neural_dir;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar  4 2000
	Altered to cancel everything concerned with LIB NEWEXTERNAL
*/
