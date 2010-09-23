# --- Copyright University of Sussex 2010. All rights reserved. ---------
# File:            C.unix/com/popenv.sh
# Purpose:         Set up environment variables for POPLOG
# Author:          John Gibson, Jan 16 1986 (see revisions)
# Documentation:
# Related Files:   C.unix/com/poplog.sh

OLD_pel=${popexternlib=%%%%%%%%%%%%%%%%}	# old value or dummy

# Host specific parts of POPLOG
popcom=$usepop/pop/com
popsrc=$usepop/pop/src
popsys=$usepop/pop/pop
popexternlib=$usepop/pop/extern/lib
popobjlib=$usepop/pop/obj
export popcom popsrc popsys popexternlib popobjlib

# Standard library directories
popautolib=$usepop/pop/lib/auto
popdatalib=$usepop/pop/lib/data
popliblib=$usepop/pop/lib/lib
poppwmlib=$usepop/pop/lib/pwm
popsunlib=$usepop/pop/lib/sun
popvedlib=$usepop/pop/lib/ved
export popautolib popdatalib popliblib poppwmlib popsunlib popvedlib


poppackages=$usepop/pop/packages
export poppackages

# Standard local directories
poplocal=${poplocal=$usepop/..}
poplocalauto=$poplocal/local/auto
poplocalbin=$usepop/poplocalbin
export poplocal poplocalauto poplocalbin

# Contrib directory
popcontrib=${popcontrib=$usepop/pop/contrib}
export popcontrib

# For system startup
# Removed AS 10 Sep 2007
#poplib=${poplib=$HOME}
popsavelib=$usepop/pop/lib/psv
popcomppath=':$poplib:$poplocalauto:$popautolib:$popliblib'
popsavepath=':$poplib:$poplocalbin:$popsavelib'
export poplib popsavelib popsavepath popcomppath

# Base file for external loading
if [ -f $popsys/basepop11.stb ]; then
	popexlinkbase=$popsys/basepop11.stb
	export popexlinkbase
fi

# Commands for system compilation/linking etc (based on corepop)
pop_popc=+$popsys/popc.psv
pop_poplibr=+$popsys/poplibr.psv
pop_poplink=+$popsys/poplink.psv
export pop_popc pop_poplibr pop_poplink

# Definition of system-specific command symbols (pop_pop11, pop_ved etc.)
if [ -f $popsys/popenv.sh ]; then
	. $popsys/popenv.sh
fi

# Set up run-time link environment for shared-library systems
case `uname -s -r` in
	"SunOS 5."* | "unix 4."* | "UNIX_SV "* | "OSF1 "*)
		# SVR4/OSF1
		if [ -n "${LD_LIBRARY_PATH-}" ]; then
			case $LD_LIBRARY_PATH in
				*$OLD_pel*)
					LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | sed -e s%$OLD_pel%$popexternlib%` ;;
				*)
					LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:$popexternlib" ;;
			esac
		else
			LD_LIBRARY_PATH=$popexternlib
		fi
		export LD_LIBRARY_PATH
		;;

	HP-UX*)
		# HP-UX
		if [ -n "${SHLIB_PATH-}" ]; then
			case $SHLIB_PATH in
				*$OLD_pel*)
					SHLIB_PATH=`echo $SHLIB_PATH | sed -e s%$OLD_pel%$popexternlib%` ;;
				*)
					SHLIB_PATH="${SHLIB_PATH}:$popexternlib" ;;
			esac
		else
			SHLIB_PATH=$popexternlib
		fi
		export SHLIB_PATH
		;;
esac


# --- SET UP STANDARD X ENVIRONMENT -----------------------------------------

# Toolkit defaults
XT_DIRS=
XT_FILES="-lXt -lX11"
XT_VER=5

# OLIT defaults
if [ -n "$OPENWINHOME" ]; then
	OpenWinHome=$OPENWINHOME
elif [ -d /usr/openwin ]; then
	OpenWinHome=/usr/openwin
fi
XOL_DIRS=${OpenWinHome+-L$OpenWinHome/lib}
XOL_FILES="-lXol -lXt -lX11"
XOL_VER=3000

# Motif defaults
if [ -n "$MOTIFHOME" ]; then
	MotifHome=$MOTIFHOME
elif [ -n "$IXIMOTIFHOME" ]; then
	MotifHome=$IXIMOTIFHOME
elif [ -d /usr/dt ]; then
	MotifHome=/usr/dt
fi
XM_DIRS=${MotifHome+-L$MotifHome/lib}
XM_FILES="-lXm -lXt -lX11"
XM_VER=3000

# Motif is the toolkit of choice
XLINK=XM

# System-specific configuration
OS_NAME=`uname -s`
OS_RELEASE=`uname -r`
MACHINE=`uname -m`
case $OS_NAME in
	SunOS)
		case $OS_RELEASE in
			4.*)
				XT_VER=4
				XLINK=XOL
				case $MACHINE in
					sun3*) XOL_VER=2000;;
					*) XOL_VER=3000;;
				esac
				;;
			*)	# Solaris
				case $OS_RELEASE in
					5.[0-2]) XOL_VER=3001;;
					*) XOL_VER=3003;;
				esac
				# Add standard lib directories to the run-time path
				if [ "$XOL_DIRS" = -L/usr/openwin/lib ]; then
					XOL_DIRS="$XOL_DIRS -R/usr/openwin/lib"
				fi
				if [ "$XM_DIRS" = -L/usr/dt/lib ]; then
					XM_DIRS="$XM_DIRS -R/usr/dt/lib"
				else
					# Earlier Sun Motif libs tend not to be built properly
					XM_FILES="$XM_FILES -lgen -lsocket"
				fi
				;;
		esac
		# Xt and X11 libs are probably still in $OPENWINHOME/lib
		XT_DIRS="$XT_DIRS $XOL_DIRS"
		XM_DIRS="$XM_DIRS $XT_DIRS"
		X_INCL=${OpenWinHome+$OpenWinHome/include}
		;;

	ULTRIX)
		# special libraries are provided for standard MIT X11R4
		XT_FILES="-lXt-mit -lX11-mit"
		XT_VER=4
		XM_VER=1001
		;;

	HP-UX)
		case $OS_RELEASE in
			*.09.*|*.10.*)
				# X11R5 + Motif 1.2
				XT_DIRS=-L/usr/lib/X11R5
				XM_DIRS="$XM_DIRS -L/usr/lib/Motif1.2 $XT_DIRS"
				X_INCL=/usr/include/X11R5
				;;
			*)
				# 11+: Force link against old libraries (X11R5 + Motif 1.2)
				XT_DIRS=
				XT_FILES="/usr/lib/X11R5/libXt.1 /usr/lib/X11R5/libX11.1"
				XM_DIRS=
				XM_FILES="/usr/lib/Motif1.2/libXm.1 $XT_FILES"
				X_INCL=/usr/include/X11R5
				;;
		esac
		;;

	OSF1)
		# X11R5 + Motif 1.2
		XT_DIRS=-L/usr/shlib
		XM_DIRS=-L/usr/shlib
		;;

	Linux)
		XLINK=XT
		if [ -d /usr/lib ]; then
			XT_DIRS=-L/usr/lib
			XM_DIRS=-L/usr/lib
			# libXm sometimes depends on libXext
			XM_FILES="-lXm -lXt -lXext -lX11"
		elif [ -d /usr/X11R6/lib ]; then
			XT_DIRS=-L/usr/X11R6/lib
			XM_DIRS=-L/usr/X11R6/lib
			# libXm sometimes depends on libXext
			XM_FILES="-lXm -lXt -lXext -lX11"
		elif [ -d /usr/X386/lib ]; then
			XT_DIRS=-L/usr/X386/lib
			XM_DIRS=-L/usr/X386/lib
		fi
		;;

	AIX)
		XM_DIRS=
		;;

	UNIX_SV)
		# NCR's version of SVR4
		XT_FILES="-lXt -lX11 -lsocket -lnsl"
		XOL_FILES="-lXol $XT_FILES"
		XM_FILES="-lXm $XT_FILES"
		;;

	dgux)
		# DG/UX
		# Note the change in library order: X11 defines a data
		# symbol used by Xt; the order doesn't matter at link time
		# but becomes important when doing external load
		XT_FILES="-lX11 -lXt"
		XOL_FILES="-lXol $XT_FILES"
		XM_FILES="-lXm $XT_FILES"
		;;

	unix)
		# Vanilla SVR4
		XT_DIRS=-L/usr/lib/X11
		XOL_DIRS="$XOL_DIRS $XT_DIRS"
		XM_DIRS="$XM_DIRS $XT_DIRS"
		XM_FILES="$XM_FILES -lgen -lsocket"
		;;

	*)
		if [ -f /lib/libPW.a -o -f /usr/lib/libPW.a ]; then
			# libPW may be needed for regular expression matching in Motif,
			# BUT it also defines names which shadow those in libc, so libc
			# must be searched first
			XM_FILES="$XM_FILES -lc -lPW"
		fi
		;;
esac

# Variables used by pglink/poplink options -xm, -xol, -xt
POP_XM_EXLIBS="x=motif/${XM_VER}: $XM_DIRS $XM_FILES"
POP_XOL_EXLIBS="x=openlook/${XOL_VER}: $XOL_DIRS $XOL_FILES"
POP_XT_EXLIBS="x=mit/1100${XT_VER}: $XT_DIRS $XT_FILES"

# Default for X link -- used by pglink/poplink option -xlink (or nothing)
POP_XLINK_EXLIBS===POP_${XLINK}_EXLIBS

# Default include directory for compiling pop X sources
POP_X_INCLUDE=${X_INCL-/usr/include}

export POP_XM_EXLIBS POP_XOL_EXLIBS POP_XT_EXLIBS POP_XLINK_EXLIBS
export POP_X_INCLUDE


# --- Revision History ---------------------------------------------------
# --- Aaron Sloman, 11 Aug 2010
#		updated to favour /usr/lib for X11 libraries
# --- Aaron Sloman, 10 Sep 2007
# 		removed default setting of $poplib
# --- Aaron Sloman, Jan 16 2005
#		Changed for V15.6, including introduction of packages dir
#		New values for poplocal and poplocalbin
# --- Aaron Sloman, 23 Dec 2004
#               Changed default XM_VER to 3000
# --- Aaron Sloman, 21 Aug 2000
#               Changed default XM_VER to 2002
# --- Robert Duncan, Apr 21 1999
#		Set Linux XLINK default to XT
# --- Robert Duncan, Feb 18 1999
#		Changes for HP-UX 11.x
# --- Robert Duncan, Aug 10 1998
#		Added cases for DG/UX
# --- John Gibson, May 13 1998
#		Added AIX case
# --- Robert Duncan, Aug  9 1996
#		Added cases for NCR UNIX SVR4 MP-RAS (UNIX_SV)
# --- Robert Duncan, Apr 25 1996
#		Extended Linux case for alternative X directories
# --- Robert John Duncan, May  3 1995
#		Defaults changed to take account of /usr/dt as a possible MotifHome;
#		references to /usr/openwin included only if it exists.
#		SunOS case changed to include openwin directories in searchpath for
#		Xt and X11 libs, and to add standard library directories to the
#		runpath (using -R); XOL now the XLINK default for SunOS 4.x only.
#		Set XT_VER to 5 by default.
# --- John Gibson, Mar  8 1995
#		Added OSF1 cases
# --- Poplog System, Jan 18 1995 (Julian Clinton)
#		Added case for Linux.
# --- John Gibson, Sep 16 1994
#		Added -lsocket to XM_FILES and set Solaris XLINK to XM
# --- John Gibson, Jul  1 1994
#		Removed spurious $PW in assignment to XM_FILES
# --- John Gibson, Apr 28 1994
#		Now uses MOTIFHOME (if defined) in preference to IXIMOTIFHOME.
#   	Set XM_VER to 1002 by default
# --- Robert John Duncan, Jan 24 1994
#		Added missing definition of $popobjlib
# --- John Gibson, Nov 15 1993
#		Changed to switch on uname -s -r in deciding whether shareable
#		library system or not
# --- John Gibson, Sep 21 1993
#		Stopped it setting OPENWINHOME/IXIMOTIFHOME as local vars --
#		used OpenWinHome/MotifHome instead.
# --- Simon Nichols, Aug 17 1993
#		Removed initialization of X_INCL to null, as this caused
#		POP_X_INCLUDE to default to null rather than /usr/include. This is
#		because the substitution ${parameter=word} only checks whether
#		parameter is set, not whether it is also non-null. This requires
#		${parameter:=word}; however, this is not supported by older shells
#		(as found on Ultrix, for example).
# --- John Gibson, Aug  7 1993
#		Fixed XOL_VER for Sun3 to be 2000.
#		Added code to substitute old $popexternlib on LD_LIBRARY_PATH
#		with new value, so old value doesn't override new
# --- John Gibson, Jul 10 1993  Added popc,poplibr,poplink commands
# --- Simon Nichols, Jun 29 1993
#		Removed LOCAL_X.
# --- Robert John Duncan, Jun  7 1993
#		Added X setup case for SVR4 and further modified treatment of libPW.
#		Added code to set up environment for the run-time linker on shared-
#		library systems (currently SVR4 and HP-UX)
# --- Robert John Duncan, May 25 1993
#		Set X_INCL (thus POP_X_INCLUDE) to $OPENWINHOME/include on SunOS.
#		Modified treatment of libPW: if it's included, libc has to be
#		searched first to prevent problems with duplicate definitions
# --- John Gibson, May 13 1993
#		Added the X setup code
# --- Robert Duncan, Apr 19 1993
#		Made the setting of popexlinkbase conditional on the presence of a
#		.stb file (not needed for dynamically-linked systems).
#		Got rid of the explicit assignments to "pop_X" command symbols.
# --- Robert John Duncan, Nov  7 1991
#		Removed reference to 'pop11.stb' which confused newpop
# --- Robert John Duncan, Oct 24 1991
#		Default popexlinkbase renamed basepop11.stb
# --- Robert John Duncan, May 23 1991
#		Assignments to "pop_X" variables now come from $popsys/popenv.sh
#		[Made this conditional for now ...]
# --- Robert John Duncan, Oct  8 1990
#		Restored explicit assignments to "pop_X" environment variables,
#		removing the reference to $popsrc/newpop.links
# --- Simon Nichols, Oct  5 1990
#       Removed Xpop directories and pseudonyms for X images.
#       Moved definition of popexternlib to host specific section.
# --- John Williams, Sep 28 1990
#		Added $popcontrib
# --- John Gibson, May 20 1990
#		Added $popexternlib
# --- John Williams, May 11 1990
#		Now sets Xpop variables unconditionally
# --- John Williams, May  4 1990
#       Replaced instances of {var:=word} by {var=word} because Dynix
#       won't support the former. Also removed instances of "unset"
#       for same reason.
# --- John Williams, Feb 23 1990
#       Added $poplocalauto to $popcomppath
# --- Ian Rogers, Feb 13 1990
#       Added XPOP variables
# --- John Williams, Feb 23 1989
#       Renamed from "poplib".
#       Assigments to $poplocal and $poplib moved from C.unix/com/poplog.sh
#       Sets up 'pop_' variables from $popsrc/newpop
