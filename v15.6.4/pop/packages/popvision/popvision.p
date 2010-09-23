/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/popvision/popvision.p
 > Purpose:         To link to $poplocal/local/lib/popvision.p
 > Author:          Aaron Sloman, Sep 25 1999
 > Documentation:
 > Related Files:	$popvision/ * especially lib/popvision.p
 */

/* Simply compile
	$popvision/lib/popvision.p
	Work out location relative to this file
*/


section;

;;; Go up one directory level from present file to get $popvision
lvars
	Dir = sys_fname_path(popfilename),
	file = Dir dir_>< 'lib/popvision.p';

unless trycompile(file) then
	mishap('CANNOT FIND FILE ' <> file, [])
endunless;

extend_searchlist(Dir, poppackagelist, true) -> poppackagelist;

;;; Stop uses doing it again, and make directory available

global vars popvision = Dir;


endsection;
