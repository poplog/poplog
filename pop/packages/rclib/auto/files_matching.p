/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/files_matching.p
 > Purpose:			Get a vector of files matching a specification
 > Author:          Aaron Sloman, May 15 1999
 > Documentation:
 > Related Files:	LIB rc_getfile, rc_browsefiles
 */

/*
;;; tests
files_matching(path, filter, with_dirs, with_dotfiles, dirs_first)==>
files_matching('~/v*', false, false, false, false) ==>
files_matching('~/a*', false, false, false, true) ==>
files_matching('~/','v*', true, false, false) ==>
files_matching('~','*', false, true, false) ==>
files_matching('~',false, false, true, false) ==>
files_matching('~/','*', false, true, false) ==>
files_matching('~/',false, false, true, false) ==>
files_matching('~/',false, false, false, true) ==>
files_matching('~/',false, false, true, true) ==>
files_matching('~/', '', true, true, true) ==>
files_matching('~/', '', true, true, true) ==>
files_matching('~', '', true, true, false) ==>
files_matching('~/adm', '', true, true, true ) ==>
files_matching('~', 'a*', true, true, true) ==>
files_matching('~/a*', false, true, true, true) ==>
files_matching('~/a*', '', true, true, true) ==>
files_matching('~/a*', '', true, true, false) ==>
files_matching('~/a*?/.../a*', '', true, true, true) ==>
files_matching('./.../?*.p', '', true, true, true) ==>
files_matching('./.../', '*.p', true, true, true) ==>

*/


section;

compile_mode :pop11 +strict;

uses is_pattern_string;
uses sys_file_match;

define vars procedure files_matching(path, filter, with_dirs, with_dotfiles, dirs_first) -> vec;
	;;; if with_dirs is true, include the directory above the path and
	;;; the directory of the path, as well as the matching files.
	;;; If with_dotfiles is true, include dotfiles.

	sysfileok(path) -> path;
	if path = nullstring then
		current_directory -> path
	elseif path = '..' then
		sys_fname_path(allbutlast(1, current_directory)) -> path
	endif;

	if sysisdirectory(path) then
		;;; add final "/" if necessary:
		path dir_>< nullstring -> path
	endif;

	;;; make a vector of files matching the path
	lvars
		dirs = [],
		repeater =
			sys_file_match(
				path,
				if filter then filter
				elseif with_dotfiles  then '{*,.?*}'
				else false endif,
				false, false),
		vec =
			{%
				if with_dirs then
					if path /= nullstring then
						sys_fname_path(
							if last(path) == `/` then
							allbutlast(1, path)
							else path
							endif);
						if dirs_first then :: dirs -> dirs endif;
					endif,
					unless is_pattern_string(path) or path = nullstring then
						path;
						if dirs_first then :: dirs -> dirs endif;
					endunless,
				endif;
				repeat
					lvars file = repeater();
				quitif(file == termin);
					unless isendstring('/..', file) then
						if sysisdirectory(file) then
							file dir_>< nullstring;
							if dirs_first then :: dirs -> dirs endif;
						else file
						endif
					endunless;
				endrepeat
				%};

	if dirs_first then
		{% explode(ncrev(dirs)), explode(vec) %} -> vec
	endif;

enddefine;


endsection;
