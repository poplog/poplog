#!/bin/bash
# 25 Dec 2007: changed to use 'bash' instead of 'sh'
# $usepop/bin/poplog.sh
# Aaron Sloman
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
