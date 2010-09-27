NEWS: 5 Sep 2010
	The temporary patch mentioned below has been replaced by patches
	to c_core.c and to mklibpop proposed by Joe Wood
	He wrote to the poplog-dev mailing list about problems found
	compiling 64-bit linux poplog and suggesting a solution.

	Apparently, GNU have been tiding up their header files and the
	associated compiler handling, see
     	http://www.cyrius.com/journal/gcc

	Our inclusion of ucontext.h falls foul of this. The problem is that
	ucontext.h is now pulled in earlier before we define _USE_GNU.

	In any event, we should not be defining _USE_GNU this is done by
	features.h, and we should treat it as read-only.

	So he proposed patches, which were modified by Aaron Sloman for
	32 bit poplog and installed here.

NEWS: 11 Aug 2010
	There are problems compiling c_core.c, for which a
	temporary patch has been included.
	This was used to build libpop.a
	The previous versions of both files are in old/c_core.c
Aaron Sloman
http://www.cs.bham.ac.uk/~axs

====
Summary of older changes

    XtPoplog.c
		New recommended version which passes X11 warning messages
		to be handled by Pop-11
		Required changes in
	        $usepop/pop/x/src/xt_error.p
		These changes have been compiled into the libraries here:
			../../obj/

    XtPoplog.c.OK
		Alternative new version which does not pass X11 warning
		messages to Pop-11, but prints them directly, except
		that it ignores messages about "non-existent passive grab"

    XtPoplog.c.orig
		Previous version for comparison

    c_core.c
		New version of c_core.c compatible with latest gcc
		compiler (Thanks to Waldek Hebisch)
		Modified  2 Dec 2008 to include linux_setper, to make
		use of 'setarch' unnecessary when running poplog on linux

    c_core.c.orig
		Previous version for comparison

    libpop.a
		Prebuild libpop.a, created using 'mklibpop'

Aaron Sloman
http://www.cs.bham.ac.uk/~axs/
2 Dec 2008
