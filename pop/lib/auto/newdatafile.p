/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:			C.all/lib/auto/newdatafile.p
 > Purpose:			For backward compatibility. Old and new versions now merged
 > Author:			Aaron Sloman, Sep  1 2009
 > Documentation:
 > Related Files:
 */

/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/lib/newdatafile.p
 > Purpose:			Extend datafile to deal with closures and procedures
 > Author:          Riccardo Poli, 13 Nov 1995
 > Documentation:	See revision notes below and HELP * DATAFILE
 > Related Files:
 */


compile_mode :pop11 +strict;


section;

uses datafile;

global vars newdatafile = datafile;
endsection;
