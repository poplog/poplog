/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/auto/ved_calc.p
 > Purpose:			Calculate and insert value of Pop-11 expression
 > Author:          Aaron Sloman, Oct  8 1994
 > Documentation:	HELP * VED_CALC
 > Related Files: (See HELP VCALC for a VED-based spreadsheet)
 */

/*

LIB VED_CALC							Aaron Sloman Jan 1990

<ENTER> calc, executes the command on the current line to right of
cursor and inserts result at end.
E.g. if done with cusor here *->   (300+5)+88.4/3.6
<ENTER> calc will yield 	 *->   (300+5)+88.4/3.6 = 329.56

*/

section;

define ved_calc;
	dlocal
		cucharout = vedcharinsert,
		pop_pr_places = 6,	;;; 2 usually ok for financial stuff!
		vedbreak = false;
	dlocal pop_autoload = false;

	lvars string =
		substring(vedcolumn, vvedlinesize - vedcolumn + 1, vedthisline()),
		arg = strnumber(vedargument), item;
            dlocal proglist_state = proglist_new_state(stringin(string));
	procedure;

		define dlocal prmishap(string,list);
			;;; redirect errors to output.p file.
			lvars string, list;
			edit('output.p');
			vedendfile();
			dlocal
				cucharerr = vedcharinsert,
				cucharout = vedcharinsert,
				vedbreak = true;
			sysprmishap(string, list)
		enddefine;

		pop11_comp_expr();  sysEXECUTE();
	endprocedure.sysCOMPILE -> item;
	vedtextright();
	pr(' = ');
	if arg then pr_field(item, arg, `\s`, false) else pr(item) endif;

enddefine;

endsection;
