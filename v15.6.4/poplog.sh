#!/bin/bash
# $usepop/poplog.sh
# Aaron Sloman
# 17 Jul 2009 Version to be run in the $usepop directory
## See $poplogroot, below
## Useful for testing.
#
# 25 Dec 2007: changed to use 'bash' instead of 'sh'
# The files $usepop/INSTALL/poplog1.sh and $usepop/INSTALL/poplog2.sh
# are used
# by the installation script to create $usepop/bin/poplog.sh

## Poplog startup script for sh, bash and ksh users (sourced or run as a script)
## Created automatically by installation script

# Purpose:
# Script which sets up poplog environment variables, and then runs
# The command given as argument (e.g. pop11, xved, clisp, etc.)
# When used like this it sets the environment variables only in the
# process that runs the script.

# Can be "sourced" instead, to set environment variables for a whole
# login session, or in an xterm, e.g. in the user's startup file


## In the first mode, its csh equivalent can be invoked by users of any
## shell, with commands such as
##
##    poplog pop11
##    poplog ved
##    poplog xved <file>
##    poplog prolog
##    poplog clisp
##    poplog pml
##    poplog pop11 +eliza

## In the second mode, invoke this as something like this:
##    . $usepop/bin/poplog.sh

# setup local directory tree for poplog root
# may be a symbolic link to something else
poplogroot=`pwd`
export poplogroot

if [ ${usepop} ]; then source $poplogroot/pop/packages/com/poplogout.sh ; fi

# The rest of this file is derived from $usepop/INSTALL/poplog2.sh
## THIS MAY NEED TO BE EDITED

usepop=$poplogroot
export usepop

echo "usepop =" $usepop

# Set the poplocal variables

## THIS MAY ALSO NEED TO BE EDITED
poplocal=$poplogroot
local=$poplocal/local
export poplocal local

# Run the initialisation files to set up additional environment
# variables, extend $PATH, etc.
# THIS IS THE "STANDARD" poplog "login" file. It sources several others
. $usepop/pop/com/poplog.sh

# (Optional)
# Set $EDITOR and $VISUAL, unless set by users. Users can undo this.

## UNCOMMENT THESE IF YOU WISH
## Make ved the default visual editor
# EDITOR=${EDITOR=ved}
#     export EDITOR
#
# VISUAL=${VISUAL=ved}
#     export VISUAL

if [ "$DISPLAY" != "" ]
then
    # DISPLAY set. Using X, so set resources

    # Extend X resources for Ved in xterm, Xved etc.
    # Read user's file if it exists, otherwise system version
    if [ -f $HOME/.Xdefaults.poplog ] ;
    then

        # Get user's version
        xrdb -merge $HOME/.Xdefaults.poplog

    else
        # Defaults may not be ideal.
        # E.g. check font size for XVed
        xrdb -merge $usepop/Poplib/Xdefaults.poplog
    fi

fi

## Check if user has a location for init.p, vedinit.p etc. and if not
## use a default location (MUST EXIST)
## Thanks to Simon Nichols for the following code
## 11 Sep 2007

echo setting "poplib"

if [ -n "$poplib" -a -d "$poplib" ]; then
     :
elif [ -d $HOME/Poplib ]; then
     poplib=$HOME/Poplib
elif [ -d $HOME/poplib ]; then
     poplib=$HOME/poplib
elif [ -f $HOME/vedinit.p -o -f $HOME/init.p ]; then
     poplib=$HOME
else
     ## A place where local versions of init.p, vedinit.p init.lsp etc.
     ## can be located (Changed: A.Sloman 17 Jan 2005)
     poplib=$usepop/Poplib
fi
export poplib

echo "poplib set to" $poplib

## Check whether to use setarch to invoke poplog programs
## No longer needed: 2 Dec 2008


## New default
usesetarch="false"
export usesetarch

#echo usesetarch  $usesetarch

# If sourced (with no arguments) do nothing, but leave environment
# variables set.

# If run with arguments, run the command given.
# Use exec to avoid starting an additional process.

if [ "$*" != "" ]
then

        exec $*


fi
