#! /bin/bash


# Get SSH public key fingerprint (RSA) for host or local user
#
# REF:
#  https://unix.stackexchange.com/questions/321525/how-to-confirm-ssh-fingerprint
#  http://www.phcomp.co.uk/Tutorials/Unix-And-Linux/ssh-check-server-fingerprint.html
#  https://serverfault.com/questions/132970/can-i-automatically-add-a-new-host-to-known-hosts
#  https://unix.stackexchange.com/questions/126908/get-ssh-server-key-fingerprint
#   contains examples:
#    ssh-keyscan 192.168.1.13 2>/dev/null | ssh-keygen -E md5 -lf -
#    ssh-keygen -E md5 -lf <(ssh-keyscan 192.168.1.13 2>/dev/null)



# constants
E_NO_ERROR=0
E_MISSING_ARGS=1
E_BAD_ARGS=2
E_KEY_FILE_NOT_AVAILABLE=3
E_UNKNOWN_USER=4
E_UNKNOWN_ERROR=5

TRUE=1
FALSE=0

#variables
cliCmd_ipKey=$FALSE
cliCmd_userKey=$FALSE
subject=''



########################################
#
function getFingerprint() {
 local FINGERPRINT_PATTERN='([a-z0-9]{2}:){15}[a-z0-9]{2}'
 local parm="$subject"
 local result=''
 local tmp=''

 if [[ "$cliCmd_ipKey" -eq $TRUE && "$cliCmd_userKey" -eq "$TRUE" ]]; then
  showHelp $E_BAD_ARGS "choose host or user check, not both"
 fi

 if [ "$cliCmd_ipKey" -eq "$TRUE" ]; then
  tmp=$(getFingerprintForHost "$parm")
 elif [ "$cliCmd_userKey" -eq "$TRUE" ]; then
  tmp=$(getFingerprintForUser "$parm")
 else
  showHelp "$E_MISSING_ARGS"
 fi

 local rc="$?"
 if [ "$rc" -gt 0 ]; then
  exit $rc
 fi

 result=$(grep -o -E "$FINGERPRINT_PATTERN" <<< "$tmp")

 if [ -z "$result" ]; then
  exit $E_UNKNOWN_ERROR
 fi
 
 echo $result
 exit $E_NO_ERROR
}


########################################
# get the host's SSH public key fingerprint
# RSA, md5
#
# NOTE:
#  may exit with "return"
#
function getFingerprintForHost() {
 local parm="$1"

 if [ "$(isIpAddress $parm)" -eq "$FALSE" ]; then
  return $E_BAD_ARGS
 fi

 ssh-keygen -E md5 -l -t rsa -f <(ssh-keyscan -t rsa "$parm" 2>/dev/null)
}


########################################
# get user's SSH public key fingerprint
# RSA, md5
#
# NOTE:
#  may exit with "return"
#
function getFingerprintForUser() {
 local user="$1"
 local userDir=$(getHomeDirForUser "$user")
 
 if [ -z "$userDir" ]; then
  return $E_UNKNOWN_USER
 fi

 local fspec="$userDir"/.ssh/id_rsa.pub

 if [[ ! -f "$fspec" ]]; then
  return $E_KEY_FILE_NOT_AVAILABLE
 fi

 ssh-keygen -E md5 -l -t rsa -f "$fspec"
}


########################################
# Returns user's home directory
#
# user not given: returns current user
# user not recognized: return empty string
# 
# Expects
#  user name
#
# Returns
#  home dir
#
function getHomeDirForUser() {
 local user="$1"

 # if user is not given, return current user
 if [ -z "$1" ]; then
  user=$(whoami)
 fi

 echo $(getent passwd $user | cut -d: -f6)
}


########################################
# Command Line Processor
#
# Expects
#  script parms passed in, ie called with arg: "$@"
#
# Returns
#  void
#
# REF:
#  stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#
function handleCommandLine() {
 if [ "$#" -lt 1 ]; then
  showHelp "$E_MISSING_ARGS"
 elif [ "$#" -gt 2 ]; then
  showHelp "$E_BAD_ARGS" "too many parms"
 fi

 for parm in "$@"; do
  case "$parm" in
   -i)
   cliCmd_ipKey="$TRUE"
   shift
   ;;
   -u)
   cliCmd_userKey="$TRUE"
   shift
   ;;
   -h)
   showHelp "$E_NO_ERROR"
   ;;
   *)
   subject="$parm"
   ;;
  esac
 done
}


########################################
# Checks if a value is an integer
#
# Returns
#  (int) bool
#
# NOTE
#  Usage:
#   ans=$(isInteger $val)
#
function isInteger() {
 local result=$FALSE

 # if non-empty parm exists
 if [[ "$#" -gt 0 && -n "$1" ]]; then
  # do bash compare, hide std err
  # REF: grzechu.blogspot.com/2006/06/bash-scripting-checking-if-variable-is.html
  #      stackoverflow.com/questions/3623662/bash-testing-if-a-variable-is-an-integer
  if [ "$1" -eq "$1" 2>/dev/null ]; then result=$TRUE; fi
 fi

 echo $result
}


########################################
# Checks if a value is formatted as an IPv4 address
#
# Expects
#  dot-decimal ip address eg '1.2.3.4'
#
# Returns
#  (int) bool
#
function isIpAddress() {
 local ip="$1"
 local octet=0
 local octets=()
 local result=$FALSE

 local match=$(echo "$ip" | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')

 if [ -n "$match" ]; then
  result=$TRUE

  # create octets array
  #  per: stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash/918931#918931
  #  this formulation limits scope of the IFS change to the duration of the read command
  IFS='.'; read -ra octets <<< "$match"

  # if invalid element found, result = FALSE
  for octet in ${octets[*]} # quotes will break this
   do
    if [ "$octet" -gt 255 ]; then
     result=$FALSE
     break
    fi
   done
 fi

 echo $result
}


########################################
#
# Display help, exit with assigned return code
#
# Expects:
#  exit code: parm#1
#  message: parm#2 [optional]
#
# Returns:
#  void
#
function showHelp() {
 local code="$1"
 local parm="$2"

 echo
 echo "get SSH public key fingerprint"
 echo
 echo " An IPv4 address or local user name is required"
 echo
 echo " host key location: [ /etc/ssh/ssh_host_rsa_key.pub ]"
 echo " user key location: [ ~/.ssh/id_rsa.pub ]"
 echo
 echo " Exit Codes"
 echo "  "$E_NO_ERROR": No Error"
 echo "  "$E_MISSING_ARGS": Missing Args"
 echo "  "$E_BAD_ARGS": Unrecognized Args"
 echo "  "$E_KEY_FILE_NOT_AVAILABLE": Pub Key File Not Available"
 echo "  "$E_UNKNOWN_USER": User Not Recognized"
 echo "  "$E_UNKNOWN_ERROR": Unknown Error"
 echo

 # TODO
 # maybe: if p1 && p1 <> int, print it
 #        if p1 == int && p2, print p2, exit p1
 if [ $(isInteger "$code") -eq "$FALSE" ]; then
  code=$E_UNKNOWN_ERROR
 elif [[ "$code" -eq "$E_BAD_ARGS" && "$parm" ]]; then
  echo
  echo 'Unrecognized argument: '$badParm
  echo
 fi

 exit $code
}


########################################
#
function main() {
 handleCommandLine "$@"
 getFingerprint
}



############################################################
############################################################
main "$@"

