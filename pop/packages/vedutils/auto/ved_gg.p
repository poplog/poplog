/* --- The University of Birmingham 1995.  --------------------------------
 > File:			$poplocal/local/auto/ved_gg.p
 > Purpose:			Like VED_G but uses text on current line
 > Author:			Aaron Sloman, Apr 30 1994 (see revisions)
 > Documentation:	Below, and HELP * VED_INDEXIFY
 > Related Files:	LIB * VED_G, * VED_INDEXIFY
 */

/*
         CONTENTS - (Use <ENTER> g to access required sections)

 -- Introduction
 -- ENTER gg
 -- ved_gg_default_string
 -- EXAMPLE
 -- NOTE
 -- The procedure index for this file

-- Introduction -------------------------------------------------------

-- ENTER gg

ENTER gg -
or
ENTER gg g

	Find space-delimited text at beginning of current line
	and use that as argument for ved_g. Save the string for
	future use with this file.

ENTER gg
	Use remembered string to search in this file, as if ENTER g
		(i.e. go to index or go to location from index)

ENTER gg <string>
	If the string has more than 1 character, use it as argument for
		ENTER indexify
	I.e. build an index (at current location) or rebuild it if it
	already exists

ENTER gg i
	Rebuild the index for this file, using the remembered index string

Note that the file memory lasts only for one Poplog process, and is
lost if you recompile lib ved_gg

-- ved_gg_default_string

If the user has not yet associated an index search string with the
current file, then the value of ved_gg_default_string is used. That
defaults to 'define'

If you wish to associate different defaults with different files, use
vedinitfile (REF * vedinitfile)

-- EXAMPLE

The index of procedures below (after the line with the word "CONTENTS") was
built for this file by doing:

	ENTER gg i

(It could have been: ENTER gg define)

Put the cursor on one of the index entries then do

	ENTER gg g

that will set up the string 'define' as the index search string for
this file. After that you can simply use

	ENTER gg


-- NOTE

This mechanism can be used in parallel with the ENTER g mechanism.
I.e. both sorts of index can exist in the same file, one for section
headings and one for procedure headings. This file is an example.

-- The procedure index for this file

This was created by: ENTER gg define

CONTENTS (define)

 define vars ved_gg_string
 define lconstant get_gg_string() -> string;
 define lconstant get_leading_string() -> string;
 define ved_gg();

*/

section;
uses ved_g
uses ved_indexify

global vars ved_gg_default_string = 'define';

;;; Property to associate an index string with each file
define vars ved_gg_string
	= newproperty([], 16, false, "tmparg")
enddefine;

define lconstant get_gg_string() -> string;
	;;; get the associated string for current file, or use default
	lvars string;
	ved_gg_string(vedcurrentfile) -> string;
	unless string then
		;;; string not set up for this file. Use the default
		ved_gg_default_string -> string;
		string -> ved_gg_string(vedcurrentfile);
	endunless;
enddefine;

define lconstant get_leading_string() -> string;
	;;; Find the leading string on the current line, to be the
	;;; ved_gg_string for the current file

	lvars col1, col2, string = vedthisline();
	skipchar(`\s`, 1, string) -> col1;
	unless col1 then
		vederror('NO NON SPACE CHARACTERS IN LINE')
	endunless;

	locchar(`\s`,col1, string) -> col2;
	if col2 then
		substring(col1, col2 - col1, string)
	else
		allbutfirst(col1 - 1, string)
	endif -> string;
enddefine;

define ved_gg();
	if datalength(vedargument) > 1 then

		;;; indexify the file using the argument
		veddo('indexify ' sys_>< vedargument);
		vedputcommand('gg');
		vedargument -> ved_gg_string(vedcurrentfile);

	elseif vedargument = 'i' then
		;;; indexify the file using existing or default string
		veddo('indexify ' sys_>< get_gg_string())
	else

		if vedargument = '-' or vedargument = 'g' then
			;;; set the search string for the current file
			get_leading_string() -> ved_gg_string(vedcurrentfile);

		elseif datalength(vedargument) == 1 then
			vederror('UNKNOWN ARGUMENT FOR ENTER gg:')
		endif;

		;;; Now access the index, or the location in file
		veddo('g ' sys_>< get_gg_string());
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr  3 1995
	Altered to use property. Generally cleaned up. Improved documentation
 */
