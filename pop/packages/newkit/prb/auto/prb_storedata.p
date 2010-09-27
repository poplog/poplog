/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_storedata.p
 > Purpose:         Store the current database in a named file
 > Author:          Aaron Sloman, Dec  8 1996
 > Documentation:	Temporarily below
 > Related Files:
 */

/*
prb_storedata(<filename>);

Stores the current poprulebase database in a format which can later
be read and edited, or recompiled to create a new database.

e.g. (example from TEACH PRBRIVER).

global vars
	prb_database=
	prb_newdatabase(32,
		[
    		[chicken isat left]
    		[fox isat left]
    		[grain isat left]
    		[man isat left]
    		[plan]
    		[history]

    		[opposite right left]
    		[fox can eat chicken]
    		[chicken can eat grain]

    		[constraint Eat
        		[[?thing1 isat ?side]
            		[NOT man isat ?side]
            		[?thing1 can eat ?thing2]
            		[?thing2 isat ?side]]
        		[?thing1 can eat ?thing2 GO BACK]]

    		[constraint Loop
        		[[state ?state] [history == [= ?state] == ]]
        		['LOOP found - Was previously in state: ' ?state]]

    		[state [apply thing_data]]
		]);

prb_storedata('temp1.p');

prb_newdatabase(1,[]) -> prb_database;

compile('temp1.p');

prb_print_database();

*/

section;

;;; some text to go at the top of the file.
lconstant
headerstring1 =
';;; FILE CREATED BY PRB_STOREDATA\
\
;;; Instruction to read in rest of file and create database\
uses poprulebase;\
\
lvars temp_database;\
([% until null(proglist) do\
	 if hd(proglist) == "[" then listread()\
	 else readitem()\
	 endif\
	enduntil\
%] -> temp_database,\
\
prb_newdatabase(',

headerstring2 =
', temp_database) -> prb_database);\
;;; DO NOT EDIT ANYTHING ABOVE THIS LINE\
\
'
;


define prb_storedata(filename);

	dlocal
		pop_pr_quotes = false,
		cucharout = discout(filename),
		pop_=>_flag = nullstring;

	lvars
		keys = prb_database_keys(prb_database),
		;;; increase database table size to allow for growth
		hashlen = 32 + listlength(keys),
		key, item;

	;;; Put code at top of file to read in rest of file
	;;; and create prb_database.
    pr(headerstring1);
	pr(hashlen);
    pr(headerstring2);

	;;; Ensure strings are printed with quotes
	true -> pop_pr_quotes;

	for key in keys do
		for item in prb_database(key) do
			;;; print each item in the database separately, each starting on
			;;; a new line, and suitably indented if too long for a line.
			pretty(item);
		endfor;
	endfor;
	cucharout(`\n`);

    cucharout(termin);

enddefine;

endsection;
