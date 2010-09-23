/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            $popneural/lib/cload.p
 > Purpose:         Convenient macros for loading c procs
 > Author:          Julian Clinton, Feb 26 1993.
 */

section;


include sysdefs;

lvars systype = systranslate('HOST_TYPE') or
				if length(sys_machine_type) == 1 then
                    hd(sys_machine_type) sys_>< nullstring
                else
                    sprintf(sys_machine_type(2), sys_machine_type(1),
                            '%p_%p')
                endif;


lvars popneural_dir =
                    #_IF DEF VMS
                        systranslate('popneural') or
                            systranslate('popneural', 2:1000)
                    #_ELSE
                        systranslate('popneural')
                    #_ENDIF
;

unless isstring(popneural_dir) then
    mishap(popneural_dir, 1, 'Undefined symbol: popneural');
endunless;

#_IF DEF UNIX
lvars popneural_bindir = popneural_dir dir_>< 'bin/'
                            dir_>< systype dir_>< '/';

#_ELSE	;;; VAX/VMS
lvars popneural_bindir = popneural_dir dir_>< '[bin.vax]';
#_ENDIF



#_IF not(DEF SHARED_LIBRARIES)
lvars popexlinkbase = systranslate('popexlinkbase');

unless isstring(popexlinkbase) then
    mishap(0, 'Undefined symbol: popexlinkbase');
endunless;
#_ENDIF

global vars c_liblist;

    npr(';;; cload: using C libraries...');
#_IF DEF SUN
    ['-lm']
#_ELSEIF DEF DECSTATION
    ['-L/usr/lib' '-lm_G0']
#_ELSEIF DEF IRIS
	#_IF DEFV IRIX >= 5.0
	    ['-lm']
    #_ELSE
	    ['-L/usr/lib' '-lm_G0']
	#_ENDIF
#_ELSEIF DEF HP9000_300
    ['-L /lib' '-lm']
#_ELSEIF DEF HP9000_700
    ['-L /lib' '-lm']
#_ELSEIF DEF VMS
    []
#_ELSE
    ['-lm']
#_ENDIF
    -> c_liblist;

printf(c_liblist, ';;; Link options: %p\n');


#_IF (DEF SHARED_LIBRARIES) and (DEF UNIX)

;;; specify location of shared library
;;;
#_IF DEF HPUX

lvars link_file_stub =
    sprintf(systype, '$popneural/bin/%p/%%p.sl')
;

#_ELSEIF DEF SUN4 or DEF IRIX

lvars link_file_stub =
    sprintf(systype, '$popneural/bin/%p/%%p.so')
;

#_ELSE	/* Currently just Alpha/OSF */

lvars link_file_stub =
    sprintf(systype, '$popneural/bin/%p/%%p.so')
;

#_ENDIF

;;; load shared library
;;;
define global macro cload name;
lvars name file;

    pr(';;; Linking ');
    sprintf(name, link_file_stub) -> file;
    npr(file);
    "external", "load", name, ";",
        explode(c_liblist), file;
    "endexternal", ";"
enddefine;

#_ELSE

;;; specify location of object file
;;;
lvars link_file_stub =
#_IF DEF UNIX
    popneural_bindir <> '%p.o'
#_ELSE
    popneural_bindir <> '%p.obj'
#_ENDIF
;

;;; load object file
;;;
define global macro cload name;
lvars name file;

    sprintf(name, link_file_stub) -> file;
    pr(';;; Linking ');
    npr(file);
    "external", "load", name, ";",
        file, explode(c_liblist);
    "endexternal", ";"
enddefine;

#_ENDIF

endsection;

/*  --- Revision History --------------------------------------------------
--- Julian Clinton, Aug 25 1995
	Changes for 15.0.
--- Julian Clinton, Jul 11 1994
    Added support for IRIX 5.x
--- Julian Clinton, Mar  7 1994
    Added support for Solaris 2
--- Julian Clinton, Aug  5 1993
    Changed back to use external instead of newexternal.
--- Julian Clinton, Jul  6 1993
    Changed to use newexternal instead of external.
--- Julian Clinton, Jun 17 1993
    Modified DECstation load options.
*/
