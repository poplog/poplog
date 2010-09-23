/* --- Copyright University of Sussex 1994. All rights reserved. ----------
 > File:            $poplocal/local/lib/newmaster/params.p
 > Purpose:         Parameters for NEWMASTER
 > Author:          Robert Duncan and Simon Nichols, May 1987 (see revisions)
 > Documentation:	HELP * NEWMASTER
 > Related Files:	LIB * NEWMASTER
 */

section;

global vars
	newmaster_copyright =
		'University of Birmingham',
;;;		'University of Sussex',
	newmaster_versions =
		[
			['default'								;;; version
				'rsuna'								;;; host
				'master'							;;; type
				'$popmaster/'						;;; root directory
				'$poptestmaster/'					;;; test directory
				'$poplocal/local/com/newmaster/'	;;; com directory
			]
			['frozen'
				'rsuna'
				'master'
				'$frozmaster/'
				'$froztestmaster/'
				'$poplocal/local/com/newmaster/'
			]
			['local'
				^false
				'local'
				'$poplocal/local/'
				^false
				'$poplocal/local/com/newmaster/'
			]
		],
	newmaster_comments =
        [
	        ['p' '/*' ' */' ' >']
	        ['ph' '/*' ' */' ' >']
	        ['pl' '/*' ' */' ' >']
	        ['lsp' '#|' ' |#' ' |']
			['ml' '(*' ' *)' ' *']
			['sig' '(*' ' *)' ' *']
		    ['c' '/*' ' */' ' *']
		    ['h' '/*' ' */' ' *']
		    ['s' '/*' ' */' ' *']
		    ['xbm' '/*' ' */' ' *']
	        ['' '#']
	        ['sh' '#']
	        ['com' '$!']
			['asm' ';']
			['bat' '@rem']
		    [';;;' ';;;']
        ],
    newmaster_verbose =
		false,
;

endsection;


/* --- Revision History ---------------------------------------------------
--- Robert John Duncan, Jun 14 1994
		Added comment styles for DOS '.asm' & '.bat' files
--- John Williams, Dec  1 1993
		Changed 'csuna' to 'rsuna' and '/csuna/pop/frozen/test/' to
		'$froztestmaster/'.
--- Robert John Duncan, Mar 16 1992
		Added copyright string. Moved to newmaster lib directory.
--- Simon Nichols, Nov  6 1991
		Changed default host to rsuna and frozen host to csuna.
--- Jonathan Meyer, May 29 1991
		Added -xbm- type for X bitmaps
--- Robert John Duncan, Dec 10 1990
		Added test and com directories to -newmaster_versions- and revised
		the order of fields.
--- Rob Duncan, Jun  6 1990
		Added 'local' to -newmaster_versions- and extended entries to
		include a 'type' field
--- Rob Duncan, Mar 22 1990
		Changed frozen version to refer to $FROZMASTER
--- Rob Duncan, Feb 13 1990
		Added 'sh' to -newmaster_comments-
--- Rob Duncan, Jul  3 1989
		Added 'ml' and 'sig' to -newmaster_comments-
--- Poplog System, Jan 10 1989
		Added 'frozen' to -newmaster_versions-
 */
