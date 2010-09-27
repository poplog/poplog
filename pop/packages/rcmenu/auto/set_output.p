/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/set_output.p
 > Purpose:         Send output to desired file
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

section;

define global vars procedure set_output(filename) -> consumer;
	lvars filename, consumer;
	unless filename == true then
		check_string(filename);
	endunless;

	;;; Create a consumer that selects the desired output file and
	;;; prints into it. It will be a closure of the string and
	;;; a reference containing the file structure (eventually).
	;;; The consumer is a closure of this:
	;;; If the filename is == true, then print in current file,
	;;; starting on next line. Otherwise at end of file.
	procedure(/* char, */ filename, file_ref) with_props set_output;
		;;; Invoked with the character on the stack

		lvars
			filename, file_ref,
			outfile = cont(file_ref);

		unless outfile == vedcurrentfile then
			;;; Set up output file
			if outfile then vedselect(outfile, false)
			else
				if isstring(filename) then
					vedselect(filename, false)
				endif;
			endif;

			unless outfile then
				;;; save the file for future use
				vedcurrentfile -> cont(file_ref);
				;;; Raise the file. May not stay on top.
				true -> xved_value("currentWindow", "raised");
				if filename == true then vednextline()
				else
					vedendfile();
				endif;
			endunless;
		endunless;
		;;; now print the character into the file
		vedcharinsert(/* char */)
	endprocedure(%filename, consref(false)%) -> consumer

enddefine;

endsection;
