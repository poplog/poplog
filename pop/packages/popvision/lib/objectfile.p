/* --- Copyright University of Sussex 1999. All rights reserved. ----------
 > File:            $popvision/lib/objectfile.p
 > Purpose:         Find an object file
 > Author:          David S Young, Jun  3 1992 (see revisions)
 > Documentation:   HELP OBJECTFILE
 */

compile_mode:pop11 +strict;

section;

#_IF sys_os_type(2) == "sunos" and sys_os_type(3) >= 5.0
    lconstant ARCH = 'sun4r5', SUFFIX = '.so';
#_ELSEIF hd(sys_machine_type) == "alpha"
    lconstant ARCH = 'alpha', SUFFIX = '.so';
#_ELSEIF hd(sys_machine_type) == "pc" and sys_os_type(2) == "linux"
    lconstant ARCH = 'linux', SUFFIX = '.so';
#_ELSEIF hd(sys_machine_type) == "iris"
    lconstant ARCH = 'iris', SUFFIX = '.so';
#_ELSE
    lconstant ARCH = hd(sys_machine_type), SUFFIX = '.o';
#_ENDIF

define procedure objectfile(name) -> obfilename;
    lvars name, obfilename;
    unless popfilename then
        mishap(name, 1, 'Need to be compiling named file')
    endunless;
    sys_fname_path(popfilename)
        dir_>< 'bin' dir_>< ARCH dir_>< (name sys_>< SUFFIX)
        -> obfilename;
    ;;; This should really throw an exception which can be caught
    ;;; by callers which can substitute pop-11 code when an
    ;;; object file is not available. Calling procedures ought to test
    ;;; this result before trying an exload anyway.
    unless readable(obfilename) then false -> obfilename endunless
enddefine;


endsection;


/* --- Revision History ---------------------------------------------------
--- David Young, Sep 24 1999
        Fixed to work with linux (thanks Aaron Sloman) and iris (thanks
        Anthony Worrall). Also tidied conditionals at start a little.
--- David S Young, Nov 13 1995
        Fixed typo in conditional compilation for alpha
--- David S Young, Sep 19 1995
        Made SUFFIX .so if machine type is alpha
--- David S Young, Jan 31 1994
        Made to use popfilename instead of pdprops(cucharin).
--- John Williams, Nov  5 1993
        Fixed for Solaris 2.x
--- David S Young, Nov 26 1992
        Changed to use -sys_machine_type-
 */
