/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$poplocal/local/rclib/auto/ved_buffer_pathname.p
 > Purpose:			Return path name given file structure.
 > Author:			Aaron Sloman, Sep  7 2002
 > Documentation:
 > Related Files:
 */



section;

include vedfile_struct.ph

define ved_buffer_pathname(struct) -> path;
	subscrv(VF_PATHNAME, struct) -> path;
enddefine;

endsection;
