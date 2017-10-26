#!/bin/bash

# getFileOrDefault

# TODO
#  Add command line parameters to return error message for error code
#  (e.g. -m=1 --message=1 returns associated text)

# see $exitMsg_Help below for description and details

# #####################################

prog_name=$(basename $0)



# Outputs:
#  Exit Codes:
    exitCode_Success=0
    exitCode_Success_ByDefault=1
    exitCode_Fail_HasBadArguments=2
    exitCode_Fail_Requested_NotUsable=3
    exitCode_Fail_Requested_NotDefined=4
    exitCode_Fail_Default_NotUsable=5
    exitCode_Fail_Default_NotDefined=6
    exitCode_Fail_Copy_Default_To_Requested=7
    
#  Exit Messages:
    exitMsg_Success=""
    exitMsg_Success_ByDefault="cp Default Requested succeeded"
    exitMsg_Fail_HasBadArguments="Unrecognized argument(s): "
    exitMsg_Fail_RequiredArgumentsMissing="Required arguments missing"
    exitMsg_Fail_Requested_NotUsable="Requested file is not USABLE"
    exitMsg_Fail_Requested_NotDefined="Requested file not specified"
    exitMsg_Fail_Default_NotUsable="Default file is not USABLE"
    exitMsg_Fail_Default_NotDefined="Default file not specified"
    exitMsg_Fail_Copy_Default_To_Requested="Copying Default to Requested failed"
    exitMsg_Fail_Default_And_Requested_Have_Same_Name="Default and Requested must name different files"
    exitMsg_GetHelp="Try '$prog_name --help' for more information."
#begin quoted multi-line variable
    exitMsg_Help="
$prog_name Reports success if Requested file is USABLE.

Attempts recovery by creating Requested file from Default file
Exit code 0 if successfull,
 other codes and messages if errors are encountered


A USABLE file is a regular file (i.e. it exists in the local filesystem, is not a directory & is not zero length)


Inputs:
 Requested Filespec; Required
  -r, --requested
 Default Filespec; Required
  -d, --default
 Verbose; Show error messages
  -v, --verbose
 Help
  -h, --help


Exit Codes:
 0 Success: Requested file is USABLE
 1 Success: Requested file (via Default) is USABLE
 2 Fail: Unrecognized arguments detected
 3 Fail: Requested is not USABLE
 4 Fail: Requested not named
 5 Fail: Default is not USABLE
 6 Fail: Default not named
 7 Fail: cp Default Requested failed


Call with:
$prog_name -r=filespec1 -d=filespec2
"
# end quoted multi-line variable



# REF: stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bas
#       command line parser
#      tldp.org/LDP/abs/html/fto.html
#       fto: file test operators



# -------------------------------------
# SETUP

badArgs=()
exitCode=$exitCode_Success
exitMsg=$exitMsg_Success
cmd_getHelp=0
verbose=0
default=""
requested=""


# -------------------------------------
# Read Command line

for i in "$@"; do
  case $i in
    -d=*|--default=*)
    default="${i#*=}"
    shift # shift past argument=value
    ;;
    -r=*|--requested=*)
    requested="${i#*=}"
    shift # shift past argument=value
    ;;
    -v|--verbose)
    verbose=1
    shift # shift past argument with no value
    ;;
    -h|--help)
    help=1
    shift # shift past argument with no value
    ;;
    *)
    # save unrecognizable (aka "bad") arguments
    badArgs+=("[ "$i" ]")
    ;;
  esac
done



# Messages from this section do not indicate a need for help

# Show Help, exit
# -------------------------------------

if [ "$cmd_getHelp" -eq 1 ]; then
  echo "$exitMsg_Help"
  exit $exitCode_Success
fi


# If bad arguments, exit
# -------------------------------------

if [ ${#badArgs[@]} -ne 0 ]; then
  if [ "$verbose" -eq 1 ]; then
    echo $prog_name": "$exitMsg_Fail_HasBadArguments${badArgs[@]}
    echo $exitMsg_GetHelp
  fi
  exit $exitCode_Fail_HasBadArguments
fi


# If missing required arguments, exit
# -------------------------------------

if [[ "$requested" == "" && "$default" == "" ]]; then
  if [ "$verbose" -eq 1 ]; then
    echo $prog_name": "$exitMsg_Fail_RequiredArgumentsMissing
    echo $exitMsg_GetHelp
  fi
  exit $exitCode_Fail_HasBadArguments
fi


# If requested filespec is not defined, exit
# -------------------------------------

if [ "$requested" == "" ]; then
  if [ "$verbose" -eq 1 ]; then
    echo $prog_name": "$exitMsg_Fail_Requested_NotDefined
    echo $exitMsg_GetHelp
  fi
  exit $exitCode_Fail_Requested_NotDefined
fi


# If default filespec is not defined, exit
# -------------------------------------

if [ "$default" == "" ]; then
  if [ "$verbose" -eq 1 ]; then
    echo $prog_name": "$exitMsg_Fail_Default_NotDefined
    echo $exitMsg_GetHelp
  fi
  exit $exitCode_Fail_Default_NotDefined
fi


# If default and requested filespecs are identical, exit
# -------------------------------------

if [ "$default" == "$requested" ]; then
  if [ "$verbose" -eq 1 ]; then
    echo $prog_name": "$exitMsg_Fail_Default_And_Requested_Have_Same_Name
    echo $exitMsg_GetHelp
  fi
  exit $exitCode_Fail_HasBadArguments
fi



# Messages from this section points to usage issues and indicate a need for help

# RUN
# -------------------------------------

# is requested USABLE
if [[ -f "$requested" && -s "$requested" ]]; then
  exitMsg=$exitMsg_Success
  exitCode=$exitCode_Success
else
  # is requested a directory? Not going there; KISS & bail out
  if [ -d "$requested" ]; then
    # requested is NOT USABLE (it is a directory)
    exitMsg=$exitMsg_Fail_Requested_NotUsable
    exitCode=$exitCode_Fail_Requested_NotUsable
  else
    # requested is NOT USABLE
    #  try to remedy

    # is default USABLE
    if [[ -f "$default" && -s "$default" ]]; then
      # default is USABLE: attempt cp default requested
    
      cp $default $requested
    
      # is requested USABLE (ie copy from default succeeded per cp exit code)
      if [ $? -eq 0 ]; then
        exitMsg=$exitMsg_Success_ByDefault
        exitCode=$exitCode_Success_ByDefault
      else
        exitMsg=$exitMsg_Fail_Copy_Default_To_Requested
        exitCode=$exitCode_Fail_Copy_Default_To_Requested
      fi

    else
      # default is NOT USABLE
      exitMsg=$exitMsg_Fail_Default_NotUsable
      exitCode=$exitCode_Fail_Default_NotUsable
    fi
  fi
fi


# Post non-empty exit message
# -------------------------------------

if [[ "$exitMsg" != "" && "$verbose" -eq 1 ]]; then
  echo $prog_name": "$exitMsg
fi


# Post exit code
# -------------------------------------

exit $exitCode

