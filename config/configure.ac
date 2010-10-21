#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.65])
AC_INIT([Poplog], [15.7.0], [poplog-dev@cs.bham.ac.uk], [http://github.com/IanRogers/Poplog])
AC_CONFIG_SRCDIR([../pop/extern/lib/XtPoplog.c])
AC_CONFIG_HEADERS([config.h])

# Checks environment
AC_GNU_SOURCE

# Checks for programs.

AC_PROG_CC
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_PROG_RANLIB

# Checks for libraries.
AC_CHECK_LIB(X, main)
AC_CHECK_LIB(X11, main)
AC_CHECK_LIB(Xext, main)
AC_CHECK_LIB(Xm, main)

# Checks for header files.
AC_PATH_X
AC_CHECK_HEADERS([fcntl.h locale.h netinet/in.h stddef.h stdlib.h string.h strings.h sys/ioctl.h sys/param.h sys/time.h unistd.h values.h bits/wordsize.h X11/Intrinsic.h Xm/Xm.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_TYPE_OFF_T
AC_TYPE_SIZE_T

AC_CHECK_SIZEOF([size_t])
# AC_COMPUTE_INT(SST, [sizeof(size_t)])
# AC_SUBST(SST)
# AC_SUBST(SIZEOF_SIZE_T)

# Checks for library functions.
AC_FUNC_FORK
AC_FUNC_LSTAT_FOLLOWS_SLASHED_SYMLINK
AC_FUNC_MALLOC
AC_FUNC_MMAP
AC_FUNC_REALLOC
AC_CHECK_FUNCS([alarm bzero floor munmap pow select setlocale sqrt strcasecmp strchr strdup unamei])

# AC_CONFIG_FILES([Makefile
                 # config/Makefile
                 # pop/extern/lib/Makefile
                 # pop/pop/Makefile
                 # pop/x/Xpw/Makefile])
AC_CONFIG_FILES([Makefile make])
AC_CONFIG_FILES([stamp-h], [echo timestamp > stamp-h])


AC_OUTPUT
