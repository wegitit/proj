#!/bin/bash


# Get a bare host SSH key fingerprint
# see showHelp() for more

# TODO
# Look at moving the defaults set on
#  hashType_cli & keyType_cli
#  to hashType_normed & keyType_normed

# one liners
# REMOTE
# ssh-keygen -E md5 -lf <(ssh-keyscan -t ecdsa 127.0.0.1) 2>/dev/null
# 127.0.0.1:22 SSH-2.0-OpenSSH_7.4
# 256 MD5:02:8b:32:6f:71:71:0a:7a:52:ba:7a:6e:7d:7a:13:6a 127.0.0.1 (ECDSA)
#
# ssh-keygen -lf <(ssh-keyscan -t ecdsa 127.0.0.1) 2>/dev/null
# 127.0.0.1:22 SSH-2.0-OpenSSH_7.4
# 256 SHA256:LW7OGvIYGQ3A6phT/jZK78imqEP98RkfBE7IktPO+KU 127.0.0.1 (ECDSA)

# FILE SYSTEM
# ssh-keygen -E md5 -lf /etc/ssh/ssh_host_ecdsa_key.pub
# 256 MD5:02:8b:32:6f:71:71:0a:7a:52:ba:7a:6e:7d:7a:13:6a no comment (ECDSA)
#
# ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key.pub
# 256 SHA256:LW7OGvIYGQ3A6phT/jZK78imqEP98RkfBE7IktPO+KU no comment (ECDSA


# CONSTANTS
CLI_PARMS="${@}"
CLI_PARM_COUNT=${#@}
HASH_TYPE_MD5='MD5'
HASH_TYPE_SHA256='SHA256'
KEY_TYPE_ECDSA='ECDSA'
KEY_TYPE_ED25519='ED25519'
KEY_TYPE_RSA='RSA'

E_NO_ERROR=0
E_MISSING_ARGS=1
E_TOO_MANY_ARGS=2
E_UNRECOGNIZED_ARGS=3
E_BAD_ADDR_FMT=4
E_BAD_HASH_FMT=5
E_BAD_KEY_FMT=6
E_HOST_UNREACHABLE=7
E_ERROR=8


# variables
hashType_cli="$HASH_TYPE_MD5"
hashType_normed=''
hostAddr_cli=''
hostKey=''
keyType_cli="$KEY_TYPE_RSA"
keyType_normed=''
unknownArgs_cli=''


########################################
#
function main() {
 checkParmCount
 parseCommandLine
 getBareFingerprint_md5
 getBareFingerprint_sha256
}


# ######################################
#
# Return code indicating that parm1 
#  does ($E_NO_ERROR) or does not ($E_BAD_ADDR_FMT)
#  look like an IPv4 address
#
# Parms
#  ipv4 address
#
# Return
#  error code: int
#
function isIPv4Address() {
 local ADDR="${1}"
 local GRP='[[:digit:]]{1,3}'
 local PARM_TEST=$(grep -E "^($GRP\.){3}$GRP$" <<< "$ADDR")

 [ -z "$PARM_TEST" ] && echo $E_BAD_ADDR_FMT || echo $E_NO_ERROR
}


# ######################################
#
# Return
#  host key
#
function getHostKey() {
 local err=$E_NO_ERROR
 local RESULT=$(isIPv4Address "$hostAddr_cli")
 
 # exit on ip address error
 [ "$RESULT" -ne $E_NO_ERROR ] && return $RESULT

 # when norma... is set and this is a ternary, ;err gets the wrong value
 if [ ! "$keyType_normed" ]; then
  setNormalizedKeyType; err=$?
 fi

 [ "$err" -ne $E_NO_ERROR ] && exit $err

 case "$keyType_normed" in
  "$KEY_TYPE_ECDSA") 
  ;;
  "$KEY_TYPE_ED25519")
  ;;
  "$KEY_TYPE_RSA")
  ;;
  *)
   return $E_BAD_KEY_FMT
  ;;
 esac
 
 echo $(ssh-keyscan -t "$keyType_normed" "$hostAddr_cli" 2>/dev/null)
}


# ######################################
#
# Return
#  fingerprint of public ssh host key
#
function getFingerprint() {
 local err=$E_NO_ERROR

 [ ! "$hostKey" ] && hostKey=$(getHostKey); err=$?
 [ "$err" -ne $E_NO_ERROR ] && return $err
# DEBUG TODO
 [ ! "$hostKey" ] && return 208 # $E_HOST_UNREACHABLE

 echo $(ssh-keygen -lE "$hashType_normed" -f <(echo "$hostKey"))
}


# ######################################
#
function getBareFingerprint_md5() {
 local err=$E_NO_ERROR

 # when norma... is set and this is a ternary, ;err gets the wrong value
 if [ ! "$hashType_normed" ]; then
  setNormalizedHashType; err=$?
 fi

 [ "$err" -ne $E_NO_ERROR ] && exit $err
 [ "$hashType_normed" != "$HASH_TYPE_MD5" ] && return

 local SUB_PTRN='[a-z0-9]{2}'
 local PATTERN="($SUB_PTRN:){15}$SUB_PTRN"

 # when local and err are on the same line, err is always zero
 local FINGERPRINT=''
 FINGERPRINT=$(getFingerprint); err=$?

 [ "$err" -ne $E_NO_ERROR ] && exit $err
 [ ! "$FINGERPRINT" ] && exit $E_HOST_UNREACHABLE

 local RESULT=$(grep -o -E "$PATTERN" <<< "$FINGERPRINT")

 # Check for minimum length
 [ -z "$RESULT" ] && exit $E_ERROR

 echo "$RESULT"
}


# ######################################
#
function getBareFingerprint_sha256() {
 local err=$E_NO_ERROR

 # when norma... is set and this is a ternary, err gets the wrong value
 if [ ! "$hashType_normed" ]; then
  setNormalizedHashType; err=$?
 fi

 [ "$err" -ne $E_NO_ERROR ] && exit $err
 [ "$hashType_normed" != "$HASH_TYPE_SHA256" ] && return

 # when local and err are on the same line, err is always zero
 local str=''
 str=$(getFingerprint); err=$?

 [ "$err" -ne $E_NO_ERROR ] && exit $err
 [ ! "$str" ] && exit $E_HOST_UNREACHABLE

 # Extract sha string
 #  expected sha format:
 #  '256 SHA256:NLaxBzyrrgMEZkJL8/77wWDo90nBiAZWnmZqkGYijwU 192.168.1.33 (ECDSA)'
 # here again, local and the actual val to assign can't be on the same line
 local arr=''
 IFS=':'; arr=(${str});
 str="${arr[1]}"
 IFS=' '; arr=(${str});
 str="${arr[0]}"

 # Check for minimum length
 [ "${#str}" -lt 43 ] && $E_ERROR

 echo "$str"
}


# ##########################################################
# command line #############################################

# ######################################
#
# Too few parms, show help, exit with error code
# Too many parms, exit with error code
#
function handleUnknownArgs() {
 echo
 echo 'Unrecognized arguments: ['$unknownArgs_cli']'
 showHelp
 exit $E_UNRECOGNIZED_ARGS
}
# ######################################
#
# Too few parms, show help, exit with error code
# Too many parms, exit with error code
#
function checkParmCount() {
 if [ "$CLI_PARM_COUNT" -lt 1 ]; then
  echo
  echo Arguments missing
  showHelp
  exit $E_MISSING_ARGS
 elif [ "$CLI_PARM_COUNT" -gt 3 ]; then
  exit $E_TOO_MANY_ARGS
 fi
}


# #####################################
#
# Set/create vars from the command line args
#
# vars
#  hostAddr_cli    : -a= | --addr= (required)
#  hashType_cli    : -h= | --hash= (optional, default: md5)
#  keyType_cli     : -k= | --key=  (optional, default: rsa)
#  unknownArgs_cli : string, delim: space
#
# NOTE
#  repeated args replace previous args
#
function parseCommandLine() {
 local parm=''

 for parm in $CLI_PARMS; do
   case "$parm" in
     -a=*|--addr=*)
     hostAddr_cli=${parm#*=}
     shift # past argument=value
     ;;
     -h=*|--hash=*)
     hashType_cli=${parm#*=}
     shift # past argument=value
     ;;
     -k=*|--key=*)
     keyType_cli=${parm#*=}
     shift # past argument=value
     ;;
     *)
     unknownArgs_cli+="$parm "
     ;;
   esac
 done

 unknownArgs_cli="${unknownArgs_cli% }"

 [ "$unknownArgs_cli" ] && handleUnknownArgs
}


# ######################################
#
# Set/create cannononically formatted hash type var
#
function setNormalizedHashType() {
 hashType_normed=${hashType_cli^^}

 if [[ "$hashType_normed" != "$HASH_TYPE_MD5"        && \
       "$hashType_normed" != "$HASH_TYPE_SHA256" ]]; then
  return $E_BAD_HASH_FMT
 else
  return $E_NO_ERROR
 fi
}


# ######################################
#
# Set/create cannononically formatted key type var
#
function setNormalizedKeyType() {
 keyType_normed=${keyType_cli^^}

 if [[ "$keyType_normed" != "$KEY_TYPE_ECDSA"   && \
       "$keyType_normed" != "$KEY_TYPE_ED25519" && \
       "$keyType_normed" != "$KEY_TYPE_RSA" ]]; then
  return $E_BAD_KEY_FMT
 else
  return $E_NO_ERROR
 fi
}


# ######################################
#
function showHelp() {
 echo 
 echo This script returns a bare host key fingerprint \(
 echo ECDSA, ED25519 or RSA2 key with MD5 or SHA256 hash\)
 echo for comparing with, for example, the keys presented by SSH\'s \'authenticiy\' prompt.
 echo
 echo Examples:
 echo ' MD5    '2d:4e:4b:bf:c5:ae:0b:01:6f:69:32:ef:cf:f1:12:dd
 echo ' SHA256 'NLaxBzyrrgMEZkJL8/77wWDo90nBiAZWnmZqkGYijwU
 echo 
 echo There are 3 required arguments:
 echo ' -a=, --addr=  (ip address)'
 echo ' -h=, --hash=  options: md5,   sha256       - optional, default: md5'
 echo ' -k=, --key=   options: ecdsa, ed25519, rsa - optional, default: rsa'
 echo 
 echo This message is shown when an argument is missing or there are unrecognized arguments.
 echo All other messages are return codes.
 echo
 echo Return codes:
 echo ' '0 - No error
 echo ' '1 - Missing args
 echo ' '2 - Too many args
 echo ' '3 - Unrecognized args
 echo ' '4 - Bad IP Address format
 echo ' '5 - Unrecognized hash type
 echo ' '6 - Unrecognized key type
 echo ' '7 - Host Unreachable
 echo ' '8 - Murky fail
 echo
}



############################################################
main

