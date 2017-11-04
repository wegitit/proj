#!/bin/bash


# Mini virt-install wrapper
#
# Create a virtual machine
#  (that connects to host via bridge adapter br0)
#  with basic options & sanity checks
#
# All options and flags have defaults. View the current settings with --help
# Option settings require an equal sign, e.g. -c=2
#
#  Options
#    name              -n, --name
#    description       -d, --description (default: name)
#N/A media             -m, --media (iso filename, default: set internally)
#    cpu               -c, --cpu (default: 1)
#    diskSize          -s, --storage (GB) (default: 4 GB)
#    ram               -r, --ram (MB) (default: 1024)
#    placement         -p, --placement [big|fast|mixed] (default: mixed)
#N/A ipAddressProvider -p, --ipAddressProvider [dhcp|static] (default: dhcp)
#N/A ipAddress         -i, --ip
#N/A usersFilename     -u, --usersFile (.ks)
#
#  Flags
#    execute           -e, --execute
#    quiet             -q, --quiet
#    help              -h, --help
#
#  Configuration - script looks first to use:
#   vm config file {name}.ks,
#    if that fails, it tries to create it from default-{ipAddressProvider}.ks
#   users config file {name}.ks
#    if that fails, it tries to create it from default-users.ks
#
# Expects
#  getFileOrDefault (utility script)
#  virt-install
#  install media (*.iso)
#  kickstart file (default-{dhcp,static}.ks or name.ks)
#  target dirs with valid SELinux context
#  users file (default-users.ks or name-users.ks)
#
# Internal Options
#  Big, Fast, Mixed storage placement selection
#   (placement of configs, distros and images)
#   configureStoragePlacement args:
#    STORAGE_PLACEMENT_BIG   - All files on Big volume
#    STORAGE_PLACEMENT_FAST  - All files on Fast volume (libvirt default)
#    STORAGE_PLACEMENT_MIXED - Configs/Distros on Big, Images on Fast (SCRIPT default)
#
# REF:
#  1. stackoverflow.com/questions/32025742/virt-install-script-in-crontab-how-to-control-tty
#  2. bugs.launchpad.net/ubuntu/+source/qemu-kvm/+bug/957957/comments/10 (a fancier virt-install - it is copied below)
#  3. linuxjournal.com/content/return-values-bash-functions
#
#
# NOTE
#  see also: script_name.notes
#
#  The libvirt default image dir is /var/lib/libvirt/images
#  For non-default image dirs/* the required SELinux context is: virt_image_t
#   The steps are:
#    1. semanage fcontext --add -t virt_image_t '/vm-images(/.*)?'
#    2. semanage fcontext -l | grep virt_image_t
#    3. restorecon -R -v /vm-images 
#    4. ls –aZ /vm-images
#   Explanation & detail, cf pg 7 of: 
#    linux.dell.com/files/whitepapers/KVM_Virtualization_in_RHEL_7_Made_Easy.pdf
#
# TODO
#  Do Not call with $() Note:
#    The Do Not Call with $() functions should all 'return' a code to check
#    so the caller can logBadParm for them
#  Consider
#   Sending non-executable messages to stderr
#   Adding SELinux context check/warnings



# |====================================|
# Constants ============================


#[ booleans ]
TRUE=1
FALSE=0

#[ file extensions ]
CONFIG_FILE_EXT='ks'
DISTRO_FILE_EXT='iso'
IMAGE_FILE_EXT='img'
USERS_FILE_EXT='ks'

#[ filename suffixes ]
USERS_FILE_SUFFIX='users'

#[ misc ]
DEFAULT='default'
PARM_COUNT="$#"
SCRIPT=$(basename $0)

#[ network ]
DHCP='dhcp'
STATIC='static'
IPADDRESS_DEFAULT='0.0.0.0'
IPADDRESS_PROVIDER_DEFAULT=$DHCP

#[ storage ]
STORAGE_PLACEMENT_BIG='b'
STORAGE_PLACEMENT_FAST='f'
STORAGE_PLACEMENT_MIXED='m'
STORAGE_PLACEMENT_DEFAULT=$STORAGE_PLACEMENT_MIXED

#[ MISC DEFAULTS ]
CPU_COUNT_DEFAULT=1
DESCRIPTION_DEFAULT='centos'
DISK_SIZE_DEFAULT=4
DISTRO_FILENAME_DEFAULT='CentOS-7-x86_64-Minimal-1708.iso'
NAME_DEFAULT='centos'
RAM_SIZE_DEFAULT=1024
USERS_FILENAME_DEFAULT=$DEFAULT'-'$USERS_FILE_SUFFIX'.'$CONFIG_FILE_EXT



# |====================================|
# Variables ============================


# [ record keepers ]
badParmsList=()

## [ cli flag defaults ]
cliCmd_execute=$FALSE
cliCmd_quiet=$FALSE
cliCmd_showHelp=$FALSE

## [ cli option defaults ]
### [ cli options:base config ]
name=$NAME_DEFAULT
name_cli=''

description=$DESCRIPTION_DEFAULT
description_cli=''

### [ source media ]
distroFilename=$DISTRO_FILENAME_DEFAULT
#distroFilename_cli=''

### [ resources ]
cpuCount=$CPU_COUNT_DEFAULT
cpuCount_cli=0

diskSize=$DISK_SIZE_DEFAULT
diskSize_cli=0

ramSize=$RAM_SIZE_DEFAULT
ramSize_cli=0

### [ network ]
#### STATIC ipAddress
ipAddress=$IPADDRESS_DEFAULT
ipAddress_cli=''

ipAddressProvider=$IPADDRESS_PROVIDER_DEFAULT
ipAddressProvider_cli=''

### [ user ]
usersFilename=$USERS_FILENAME_DEFAULT
usersFilename_cli=''

### [ dirs: base ]
configDIR_Base='kickstarts'
distroDIR_Base='distros'
imageDIR_Base='images'

### [ dirs: Big ]
homeDIR_Big='/srv/data/virt'
configDIR_Big=$homeDIR_Big'/'$distroDIR_Base'/'$configDIR_Base
distroDIR_Big=$homeDIR_Big'/'$distroDIR_Base
imageDIR_Big=$homeDIR_Big'/'$imageDIR_Base

### [ dirs: Fast ]
homeDIR_Fast='/var/lib/libvirt'
configDIR_Fast=$homeDIR_Fast'/'$imageDIR_Base
distroDIR_Fast=$homeDIR_Fast'/'$imageDIR_Base
imageDIR_Fast=$homeDIR_Fast'/'$imageDIR_Base

## [ configure storage: Big, Fast or Mixed ]
storagePlacement=$STORAGE_PLACEMENT_DEFAULT
storagePlacement_cli=''

### [ network ]
networkAttachmentDevice='br0'

# Find what networkAttachmentType[s] are available in KVM/Linux
#  VirtualBox lists:
#   "Bridged Adapter" "Generic Driver" "Host-only Adapter" "Internal Network"
#    "NAT" "NAT Network" "Not attached"
networkAttachmentType='bridge'

### [ exit codes ]
    EXITcode_Success=0
    EXITcode_Fail_HasBadParms=1

### [ exit messages ]
    EXITmsg_Success=''
    EXITmsg_Fail_HasBadParms='Invalid Parameter:'
#    EXITmsg_Fail_RequiredParmsMissing='Required arguments missing'
#    EXITmsg_Fail_Requested_NotUsable='Requested file is not USABLE'
#    EXITmsg_Fail_Requested_NotDefined='Requested file not specified'
#    EXITmsg_Fail_default_NotUsable='Default file is not USABLE'
#    EXITmsg_Fail_default_NotDefined='Default file not specified'
    EXITmsg_GetHelp='Try '$SCRIPT' --help for more information.'
#    EXITmsg_Help=''



# |============================================================================|
# Functions ====================================================================


# |========================================================|
# Bad Parm list mgmt =======================================


########################################
# Update Bad Parms list
#
# If supplied, parm is lightly formatted
# and placed before msg
#
# Expects
#  msg:          parm1
#  parm:         parm2 optional
#  badParmsList: global
#
# Returns
#  void
#
# NOTE
#  view items: ${array_name[*]}
#  view count: ${#array_name[@]}
#  Do Not call with $()
#
function logBadParm() {
 local msg="$1"
 local parm="$2"
 local final="$msg"

 if [ -n "$msg" ]; then
  if [ -n "$parm" ]; then final=\'["$parm"]' << '"$msg"\'; fi
  badParmsList+=("$final") # remove quotes to ruin element count
 fi
}


########################################
# Checks if Bad Parms contains entries
#
# Expects
#  badParmsList: global
#
# Returns
#  (int) bool
#
function thereAreBadParms() {
# weigh this variant: ${#array_name[@]}
 [ "${#badParmsList[*]}" -gt 0  ] && echo $TRUE || echo $FALSE
}



# |========================================================|
# File Functions ===========================================


# |====================================|
# File Modifier Functions ==============


########################################
# Check that needed files are available, attempt fallback to default, report unavailabilities
#
#  getFileOrDefault attempts a fallback when the config file is not available
#   by creating the (requested) -r file from a copy of the (default) -d file
#
#   getFileORDefault exit codes:
#    0: no problems
#    1: Using a copy of the default file to create the requested file
#   >1: FATAL error (see getFileOrDefault.sh for text)
#
# Expects
#  void
#
# Returns
#  void
#
function doFinalFileChecksAndFallbacks() {
 # CONFIG FILE
 if [ $(isFileReadable "$configFilespec") == $FALSE ]; then
  getFileOrDefault.sh -r="$configFilespec" -d="$configFilespecDEFAULT" > /dev/null
  tmp="$?"
 
  if [ "$tmp" -gt 1 ]; then
   echo 'ERROR [getFileOrDefault:'$tmp'] encountered attempting fallback to default config'
   echo ' source:      ['"$configFilespecDEFAULT"']'
   echo ' destination: ['"$configFilespec"']'
   echo
   # this may be a TODO, rather than an error
   exit
  elif [ "$tmp" -eq 1 ]; then
   echo 'INFO: Generated config from default'
  fi
 fi

 if [ $(isFileWritable "$configFilespec") == $FALSE ]; then
  # see getFileOrDefault for recovery options
  echo 'config file not writable'
  echo ' ... exiting'
  echo
  echo 'Hints:'
  echo ' Rerun with the --help flag to review settings'
  echo ' Confirm that the file exists and is accessible'
  echo
  exit
 fi

 # USERS FILE
 if [ $(isFileReadable "$usersFilespec") == $FALSE ]; then
  getFileOrDefault.sh -r="$usersFilespec" -d="$usersFilespecDEFAULT" > /dev/null
  tmp="$?"
 
  if [ "$tmp" -gt 1 ]; then
   echo 'ERROR [getFileOrDefault:'$tmp'] encountered attempting fallback to default users'
   echo ' source:      ['"$usersFilespecDEFAULT"']'
   echo ' destination: ['"$usersFilespec"']'
   echo
   echo 'Hints:'
   echo ' Rerun with the --help flag to review settings'
   echo ' Confirm that the file is accessible'
   echo
   exit
  elif [ "$tmp" -eq 1 ]; then
   echo 'INFO: Generated users from default'
  fi
 fi

 # DISTRO FILE
 if [ $(isFileReadable "$distroFilespec") == $FALSE ]; then
  # FATAL error
  echo 'distro file not readable'
  echo ' ... exiting'
  echo
  echo 'Hints:'
  echo ' Rerun with the --help flag to review settings'
  echo ' Confirm that the file exists and is accessible'
  echo
  exit
 fi

 # IMAGE FILE
 if [ $(isFileCreatable "$imageFilespec") == $FALSE ]; then
  # FATAL error
  echo 'image file not creatable'
  echo ' ... exiting'
  echo
  echo 'Hints:'
  echo ' Rerun with the --help flag to review settings'
  echo ' Confirm that the file is accessible'
  echo
  exit
 fi


 # DO insert users into config
 insertFileContents "$usersFilespec" "$configFilespec"
 result="$?"

 # Check insert users into config
 #  anything gt 1 is serious
 if [ "$result" -gt 1 ]; then
  CLI_handleBadParms
 fi
}


########################################
# Insert the contents of the source file into the target file,
#  replacing the Insertion Point marker
#
#  If either is not a regular, non-zero length file
#   it and the error are added to the Bad Parms list
#
# Expects
#  sourceFilespec: parm1
#  targetFilespec: parm2
#
# Returns
#  Exit code (capture with $?):
#   0 no error
#   1 insert is repeat
#   2 insert point not found
#   3 insert failed
#
# NOTE
#  InsertionPoint marker
#   MUST exist EXACTLY ONCE in target
#  Snippet Marker:
#   REQUIRED in source
#   Its presence in target indicates insert has occurred
#  Do Not call with $()
#
function insertFileContents() {
 # original sed, appended:
 #  sed "/$insertionPoint/ r $sourceFilespec" -i "$targetFilespec" --follow-symlinks
 # new sed replaces:
 #  REF: unix.stackexchange.com/questions/49377/substitute-pattern-within-a-file-with-the-content-of-other-file

 local sourceFilespec="$1"
 local targetFilespec="$2"
 local msg_SourceError='source file is not usable'
 local msg_TargetError='target file is not usable'
 local insertionPoint='^#{{ INSERT USERS HERE }}#$'
 local snippetMarker='^#### ROOT USER'
 local E_NO_ERROR=0
 local E_INSERT_IS_REPEAT=1
 local E_UNKNOWN_ERROR=2
 local E_INSERT_POINT_NOT_FOUND=3
 local E_INSERT_FAILED=4
 local E_FILE_NOT_AVAILABLE=5

 # sed treats missing source like /dev/null
 #     exits with its code 2 ("can't read ???: No such ...") if target inaccessible
 #     is silent if Insertion Point is not found

 if [ -z "$sourceFilespec" ]; then
  logBadParm 'No name received for source file' "$sourceFilespec"
  return $E_FILE_NOT_AVAILABLE
 elif [[ ! -f "$sourceFilespec" || ! -s "$sourceFilespec" ]]; then
  logBadParm 'The source file is not readable' "$sourceFilespec"
  return $E_FILE_NOT_AVAILABLE
 elif [ -z "$targetFilespec" ]; then
  logBadParm 'No name received for destination file' "$targetFilespec"
  return $E_FILE_NOT_AVAILABLE
 elif [[ ! -f "$targetFilespec" || ! -s "$targetFilespec" ]]; then
  logBadParm 'The destination file is not writeable' "$targetFilespec"
  return $E_FILE_NOT_AVAILABLE
 elif [ -z "$(grep "$snippetMarker" "$targetFilespec")" ]; then
  if [ -z "$(grep "$insertionPoint" "$targetFilespec")" ]; then
   return $E_INSERT_POINT_NOT_FOUND
  else
   sed -e "/$insertionPoint/ {" -e "r $sourceFilespec" -e 'd' -e '}' -i "$targetFilespec" --follow-symlinks
   if [ -z "$(grep "$SnippetMarker" "$targetFilespec")" ]; then
    return $E_INSERT_FAILED
   else
    return $E_NO_ERROR
   fi
  fi
 else
  return $E_INSERT_IS_REPEAT
 fi
 return $E_UNKNOWN_ERROR
}



# |====================================|
# File/Path Name Retrieval Functions ===


########################################
# Get the config file name
#
# Expects
#  void
#
# Returns
#  string
#
function getConfigFilename() {
 echo $name'.'$CONFIG_FILE_EXT
}


########################################
# Get the default config file name
#
# Expects
#  void
#
# Returns
#  string
#
function getConfigFilenameDEFAULT() {
 echo $DEFAULT'-'$ipAddressProvider'.'$CONFIG_FILE_EXT
}


########################################
# Get the path spec of the config file
#
# Expects
#  void
#
# Returns
#  string
#
function getConfigFilespec() {
 local nm=$(getConfigFilename)
 echo $configDIR'/'$nm
}


########################################
# Get the default path spec of the config file
#
# Expects
#  void
#
# Returns
#  string
#
function getConfigFilespecDEFAULT() {
 local fs=$(getConfigFilenameDEFAULT)
 echo $configDIR'/'$fs
}


########################################
# Get the path spec of the distro file
#
# Expects
#  void
#
# Returns
#  string
#
function getDistroFilespec() {
 echo $distroDIR'/'$distroFilename
}


########################################
# Get the path spec of the image file
#
# Expects
#  void
#
# Returns
#  string
#
function getImageFilespec() {
 echo $imageDIR'/'$name'.'$IMAGE_FILE_EXT
}


########################################
# Get the users file name
#
# Expects
#  void
#
# Returns
#  string
#
function getUsersFilename() {
 echo $name'-'$USERS_FILE_SUFFIX'.'$USERS_FILE_EXT
}


########################################
# Get the path spec of the users file
#
# Expects
#  void
#
# Returns
#  string
#
function getUsersFilespec() {
 local nm=$(getUsersFilename)
 echo $configDIR'/'$nm
}


########################################
# Get the default path spec of the users file
#
# Expects
#  void
#
# Returns
#  string
#
function getUsersFilespecDEFAULT() {
 echo $configDIR'/'$USERS_FILENAME_DEFAULT
}


########################################
# Configure config, distro & image dirs
#
#  Ensures var storagePlacement exists and is set to
#  (libvirt) FAST default or, if provided, a STORAGE_PLACEMENT_* option
#
# Expects
#  STORAGE_PLACEMENT_*: parm1 optional
#
# Returns
#  void
#
function configureStoragePlacement() {
 local p="$1"

 # treat the parm in re-calls as fixing prev val so
 #  capture it on entry, not on exit after stack unwind
 storagePlacement="$p"

 if [ "$p" == $STORAGE_PLACEMENT_BIG ]; then
  configDIR=$configDIR_Big
  distroDIR=$distroDIR_Big
  imageDIR=$imageDIR_Big
 elif [ "$p" == $STORAGE_PLACEMENT_FAST ]; then
  configDIR=$configDIR_Fast
  distroDIR=$distroDIR_Fast
  imageDIR=$imageDIR_Fast
 elif [ "$p" == $STORAGE_PLACEMENT_MIXED ]; then
  configDIR=$configDIR_Big
  distroDIR=$distroDIR_Big
  imageDIR=$imageDIR_Fast
 else configureStoragePlacement $STORAGE_PLACEMENT_FAST
 fi
}



# |====================================|
# File Status Functions ================

########################################
# Checks if file can be created
#
#  file path must exist
#  filespec must not exist
#  filespec must be creatable (not a dir, dev, or link)
#
# Returns
#  (int) bool
#
# TODO
#  Error: [./usr/local/bin/dir.test/no_file] exist          reported
#          [/usr/local/bin/dir.test/no_file] does not exist reported
#
function isFileCreatable() {
 local f="$1"
 local path=$(readlink -f $(dirname "$f"))
 local tmp=''

 # List of filenames blocked (because the file test oper -e said they exist, don't know why):
 #  empty
 #  all periods
 
 # TODO
 #  retry built-in replacement for sed: tldp.org/LDP/abs/html/string-manipulation.html
 #   the 1 or more syntax didn't catch all the dots ${tmp##.} because shopt extglob is off
 tmp=$(echo $f | sed -r 's/^\.+//')
 if [ -z "$tmp" ]; then f=$tmp; fi

 if [[ -n "$f" && -d "$path" ]]; then
  [ -e "$f" ] && echo $FALSE || echo $TRUE
 else
  echo $FALSE
 fi
}


########################################
# Checks if file is readable
#
#  A "readable" file is a non-empty regular file
#
# Returns
#  (int) bool
#
# TODO
#  Returned false for soft links (due to -s ? -r ?)
#
function isFileReadable() {
 local f="$1"

 # -f: is regular (not dir or dev), -s: not empty, -r: user has read permission
 [[ -f "$f" && -s "$f" ]] && echo $TRUE || echo $FALSE
}


########################################
# Checks if file is writable
#
# Returns
#  (int) bool
#
# TODO
#  Returned true for soft links
#
function isFileWritable() {
 local f="$1"

 # -f: is regular (not dir or dev), -w: writable
 [[ -f "$f" && -w "$f" ]] && echo $TRUE || echo $FALSE
}



# |========================================================|
# Help =====================================================


# |====================================|
# Help Handlers ========================


########################################
# Display feedback when CLI has zero or missing parms
#
# If not quiet, show bad parms
# In either case, exit with code: HasBadParms
#
# Returns
#  void
#  EXITcode_Fail_HasBadParms
#
# NOTE
#  In the current flow it is VERY important that the call to this function
#   1) Succeed the command line processor and
#   2) Precede the reconciliation block
#  Do Not call with $()
#
#
function CLI_handleBadParms() {
 if [ "$PARM_COUNT" -eq 0 ]; then
  logBadParm 'Arguments are required'
 fi

 if [ $(thereAreBadParms) -eq $TRUE ]; then
  if [ "$cliCmd_quiet" -eq $FALSE ]; then
   showBadParms
  fi
  exit $EXITcode_Fail_HasBadParms
 fi
}


########################################
# Display help on request
#
#  includes Bad Parms if any exist
#
# NOTE
#  In the current flow, it is VERY important that the call to this function
#   1) follow cli reconciliation and
#   2) precede file system changes
#
# Returns
#  void
#  EXITcode_Success
#
function CLI_handleHelpRequest() {
 if [ "$cliCmd_showHelp" -eq $TRUE ]; then
  showHelp
  if [ $(thereAreBadParms) -eq $TRUE ]; then
   showBadParms
  fi
  exit $EXITcode_Success
 fi
}



# |====================================|
# Help Texts ===========================


########################################
# Display Bad Parms list
#
#  list is followed by "How to get help" msg
#
# Returns
#  string
#
# TODO
#  Review handling of multiple entries
#
function showBadParms() {
 echo $SCRIPT': '$EXITmsg_Fail_HasBadParms ${badParmsList[*]}
 echo $EXITmsg_GetHelp
}


########################################
# Display help page
#
# Expects
#  Access to everything
#
# Returns
#  string
#
function showHelp() {
 local yn=''

 printf "\nA simple virt-install cli wrapper.
 Requires local ISO, default.ks (kickstart file),
 target directories with proper SELinux context

 Options
  name, description, cpu, storage (GB), ram (MB)

 Option settings require an equal sign, e.g. -c=2

 Flags
  execute, quiet, help

 NOTE
  Avoid writing to soft links\n\n"

 echo 'Options settings:'
 echo '  -n, -name'
 echo '          default: '$NAME_DEFAULT
 echo '          >current: '"$name"
 echo '  -d  --description'
 echo '          default: '$DESCRIPTION_DEFAULT
 echo '          >current: '"$description"
# echo '  -m, --media'
# echo '          installation media (.iso) filename'
# echo '          default: '$DISTRO_FILENAME_DEFAULT
# echo '          >current: '"$distroFilename"
 echo '  -c, --cpu, --cpus'
 echo '          cpu allocation'
 echo '          default: '$CPU_COUNT_DEFAULT
 echo '          >current: '$cpuCount
 echo '  -s, --storage'
 echo '          disk allocated (GB)'
 echo '          default: '$DISK_SIZE_DEFAULT
 echo '          >current: '$diskSize
 echo '  -r, --ram'
 echo '          ram allocated (MB)'
 echo '          default: '$RAM_SIZE_DEFAULT
 echo '          >current: '$ramSize
 echo '  -p, --placement'
 echo '          file placement (see below)'
 echo '          default: '$STORAGE_PLACEMENT_DEFAULT
 echo '          >current: '$storagePlacement
# cli options not yet implemented moved to Internal Settings section below
 echo

 echo 'Flags set:'
 echo '  -e, --execute'
 echo '          create vm (vs print generated command)'
 echo '          default: n'
 yn=$(yn $cliCmd_execute)
 echo '          >current: '$yn
 echo '  -q, --quiet'
 echo '          supress messages'
 echo '          default: n'
 yn=$(yn $cliCmd_quiet)
 echo '          >current: '$yn
 echo '  -h --help'
 echo '          display this info'
 echo
 echo
 echo 'Internal Settings'
 echo ' Network:'
 echo '   attachment device: '$networkAttachmentDevice

# BEG cli options not yet implemented
# echo '  -p, --ipAddressProvider'
# echo '   ipAddressProvider'
 echo '   address provider (dhcp|static): '$ipAddressProvider
# echo '     default: '$IPADDRESS_PROVIDER_DEFAULT
# echo '     >current: '$ipAddressProvider
 if [ "$ipAddressProvider_cli" == $STATIC ]; then
  echo '  -i, --ip'
  echo '         static ip address'
  echo '         default: '$IPADDRESS_DEFAULT
  echo '         >current: '"$ipAddress"
 fi
 echo
 echo ' Installation media:'
 echo '   '"$distroFilename"
 echo 
# echo '  -u, --usersFile'
# echo '        usersFile'
# echo '          user settings: password & etc'
# echo '          default: '$USERS_FILENAME_DEFAULT
# echo '          >current: '$usersFilename
# END cli options not yet implemented
# echo


 echo 'Storage Settings'
 echo ' Placement'
 if [ "$storagePlacement" == $STORAGE_PLACEMENT_BIG ]; then
  echo '  - All on Big drive'
 elif [ "$storagePlacement" == $STORAGE_PLACEMENT_FAST ]; then
  echo '  - All on Fast drive'
 elif [ "$storagePlacement" == $STORAGE_PLACEMENT_MIXED ]; then
  echo '  - Mixed (Config/Distro: on Big drive, Output image: on Fast drive)'
 fi
 echo
 
 echo ' Filespecs:'
 echo '  config (*.ks):  '"$configFilespec"
 echo '  distro (*.iso): '"$distroFilespec"
 echo '  output (*.img): '"$imageFilespec"
 echo
}



# |========================================================|
# Misc =====================================================


########################################
# Pre-exec initializations
#
# Expects
#  void
#
# Returns
#  void
#
function init() {
 configureStoragePlacement $storagePlacement
}


########################################
# Create the script result command then,
#  per CLI, execute it or write it to stdout
#
# Are there other useful parms? e.g. accelerate or accelerator?
#  REF: linux.die.net/man/1/virt-install for --network
#
function deliverResults() {
 cmd="virt-install
   --connect=qemu:///system
   --name $name
   --description '$description'
   --network bridge:br0,model=virtio
   --ram=$ramSize
   --vcpus=$cpuCount
   --disk path=$imageFilespec,size=$diskSize
   --location=$distroFilespec
   --extra-args='ks=file:/$configFilename console=tty0 console=ttyS0,115200n8'
   --controller type=scsi,model=virtio-scsi
   --initrd-inject=$configFilespec
   --graphics none"


 if [ "$cliCmd_execute" -eq $TRUE ]; then
  eval $cmd
 else
  printf "\n#!/bin/bash\n$cmd\n\n"
 fi
}



# |========================================================|
# Parm Processors ==========================================


# |====================================|
# Parm Checkers ========================


########################################
# Trap bad parm: vCPU count out-of-range
#
#  Lower bound: 1
#  Upper bound: vCPU count in /proc/cpuinfo
#
# Expects
#  parmStr: parm1
#  parmVal: parm2
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
# 
function parmCheck_CpuCount() {
 local parmStr="$1"
 local parmVal="$2"
 local minCount=1
 local maxCount=0

 if [ $(isInteger "$parmVal") -eq $FALSE ]; then
  logBadParm '['"$parmStr"']; Integer Required'
 else
   maxCount=$(grep 'cpu cores' /proc/cpuinfo | wc -l)
   if [[ "$parmVal" -lt "$minCount" || "$parmVal" -gt "$maxCount" ]]; then
     logBadParm '['"$parmStr"']; CPU out-of-range (min: '$minCount' max: '$maxCount')'
   fi
 fi
}


########################################
# Trap bad parm: Disk size out-of-range
#
#  Lower bound: 3
#  Upper bound: floor of df reported available space
#  Units: GB
#
# Expects
#  parmStr:  parm1
#  parmVal:  parm2
#  imageDIR: global
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
#
# TODO
#  Boost robustness:
#   Routine assumes GB.
#    The actual unit designation, though reported by df, are not checked nor adjusted for.
#    Be sure the routine is dealing with what's avail at that path only.
#
function parmCheck_DiskSize() {
 local parmStr="$1"
 local parmVal="$2"
 local minSize=3
 local maxSize=0

 if [ $(isInteger "$parmVal") -eq $FALSE ]; then
  logBadParm 'Integer Required' "$parmStr"
 elif [ ! -d "$imageDIR" ]; then
  logBadParm '$imageDIR does not appear to be a dir' "$parmStr"
 else
  # df:  get size in human units
  # sed: get 2nd line of df output
  # awk: get 4th column ("Avail") of df output
  # sed: replace non number related chars with empty string
  # cut: truncate float to integer
  maxSize=$(df -h "$imageDIR" | sed -n 2p | awk '{ print $4 }' | sed 's/[^\.0-9]//' | cut -f1 -d .)
  if [[ "$parmVal" -lt "$minSize" || "$parmVal" -gt "$maxSize" ]]; then
   logBadParm 'Disk out-of-range (min: '$minSize' max: '$maxSize')' "$parmStr"
  fi
 fi
}


########################################
# Trap bad parm: IpAddress not valid
#
# Expects
#  parmStr: parm1
#  parmVal: parm2
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
#
function parmCheck_IpAddress() {
 local parmStr="$1"
 local parmVal="$2"

 if [ $(isIpAddress "$parmVal") -eq $FALSE ]; then
  logBadParm 'Invalid Format for IPv4 Address' "$parmStr"
 fi
}


########################################
# Trap bad parm: IpAddress Provider not valid
#
# Expects
#  parmStr: parm1
#  parmVal: parm2
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
#
function parmCheck_IpAddressProvider() {
 local parmStr="$1"
 local parmVal="$2"

 if [[ "$parmVal" != "$DHCP" && "$parmVal" != "$STATIC" ]]; then
  logBadParm 'Invalid IP Address Provider, expecting dhcp or static' "$parmStr"
 fi
}


########################################
# Trap bad parm: RAM size out-of-range
#
#  Lower bound: 756
#  Upper bound: free memory (per /proc/meminfo)
#  Units: MB
#
# Expects
#  parmStr: parm1
#  parmVal: parm2
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
#
# REF:
#  linuxconfig.org/how-to-extract-a-number-from-a-string-using-bash-example
#
function parmCheck_RamSize() {
 local parmStr="$1"
 local parmVal="$2"
 local minSize=756
 local maxSize=0

 if [ $(isInteger "$parmVal") -eq $FALSE ]; then
  logBadParm 'Integer Required' "$parmStr"
 else
  # Available options: MemAvailable, MemFree, MemTotal
  # get the result line | get the result from the line,
  # egrep for digits only ie, no indicator, eg "KB")
  maxSize=$(grep MemFree /proc/meminfo | egrep -o '[0-9]+')

  # get MB from KB
  let "maxSize=$maxSize / 1024"

  if [[ "$parmVal" -lt "$minSize" || "$parmVal" -gt "$maxSize" ]]; then
   logBadParm 'RAM out-of-range (min: '$minSize' max: '$maxSize')' "$parmStr"
  fi
 fi
}


########################################
# Trap bad parm: storage placement not valid
#
#  value must match a STORAGE_PLACEMENT_*
#
# Expects
#  parmStr: parm1
#  parmVal: parm2
#  STORAGE_PLACEMENT_*: global
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
#
function parmCheck_StoragePlacement() {
 local parmStr="$1"
 local parmVal="$2"

 if [[ "$parmVal" != $STORAGE_PLACEMENT_BIG
    && "$parmVal" != $STORAGE_PLACEMENT_FAST
    && "$parmVal" != $STORAGE_PLACEMENT_MIXED ]]; then
  logBadParm 'Invalid Entry: ['$STORAGE_PLACEMENT_BIG$STORAGE_PLACEMENT_FAST$STORAGE_PLACEMENT_MIXED'] expected' "$parmStr"
fi
}


########################################
# Trap bad parm: invalid string
#
# Handles:
#  parm value not provided
#
# Expects
#  parmStr: parm1
#  parmVal: parm2
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
#
function parmCheck_String() {
 local parmStr="$1"
 local parmVal="$2"

 if [ -z "$parmVal" ]; then
  logBadParm 'Argument value missing or empty' "$parmStr"
 fi
}


########################################
# Trap bad parm: invalid string identifier
#
# Handles:
#  parm value not provided
#  parm value contains whitespace
#
# Expects
#  parmStr: parm1
#  parmVal: parm2
#
# Returns
#  void
#
# NOTE
#  Do Not call with $()
#  See the top level TODO re Do Not call with $() Note
#   This should be able to call parmCheck_String, not repeat its code
#
function parmCheck_StringIdentifier() {
 local parmStr="$1"
 local parmVal="$2"

 if [ -z "$parmVal" ]; then
  logBadParm 'Argument value missing or empty' "$parmStr"
 elif [[ "$parmVal" =~ [[:space:]]+ ]]; then
  logBadParm 'Argument value may not contain whitespace' "$parmStr"
 fi
}



# |====================================|
# Parm Dispatch ========================


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
 for parm in "$@"; do
  case "$parm" in
   -n=*|--name=*)
   name_cli="${parm#*=}"
   parmCheck_StringIdentifier "$parm" "$name_cli"
   shift
   ;;
   -d=*|--description=*)
   description_cli="${parm#*=}"
   parmCheck_String "$parm" "$description_cli"
   shift
   ;;
 #  -m=*|--media=*)
 #  distroFilename_cli="${parm#*=}"
 #  parmCheck_String "$parm" "$distroFilename_cli"
 #  shift
 #  ;;
   -c=*|--cpu=*|--cpus=*)
   cpuCount_cli="${parm#*=}"
   parmCheck_CpuCount "$parm" "$cpuCount_cli"
   shift
   ;;
   -s=*|--storage=*)
   diskSize_cli="${parm#*=}"
   parmCheck_DiskSize "$parm" "$diskSize_cli"
   shift
   ;;
   -r=*|--ram=*)
   ramSize_cli="${parm#*=}"
   parmCheck_RamSize "$parm" "$ramSize_cli"
   shift
   ;;
   -p=*|--placement=*)
 # [B]ig, [F]ast, [M]ixed (case insensitive, default fast)
   storagePlacement_cli=$(echo "${parm#*=}" | tr [:upper:] [:lower:])
   parmCheck_StoragePlacement "$parm" "$storagePlacement_cli"
   shift
   ;;
 # N/A TODO
 #  -p=*|--ipAddressProvider=*)
 #  change where tr is done to preserver orig user entry
 #  ipAddressProvider_cli=$(echo "${parm#*=}" | tr '[:upper:]' '[:lower:]')
 #  parmCheck_IpAddressProvider "$parm" "$ipAddressProvider_cli"
 #  shift
 #  ;;
 #  -i=*|--ip=*)
 #  ipAddress_cli="${parm#*=}"
 #  parmCheck_IpAddress "$parm" "$ipAddress_cli"
 #  shift
 #  ;;
 #  -u=*|--usersFile=*)
 #  usersFilename_cli="${parm#*=}"
 #  parmCheck_String "$parm" "$usersFilename_cli"
 #  shift
 #  ;;
 #
 # FLAGS
   -e|--execute)
   cliCmd_execute=$TRUE
   shift
   ;;
   -q|--quiet)
   cliCmd_quiet=$TRUE
   shift
   ;;
   -h|--help)
   cliCmd_showHelp=$TRUE
   shift
   ;;
   *)
   # save unrecognized parms
   logBadParm 'Unrecognized or invalid entry' "$parm"
   ;;
  esac
 done
}



# |=====================================|
# Parm Reconciliation =================== 


########################################
# merge CLI inputs with defaults
#
# Expects
#  void
#
# Returns
#  void
#
function mergeCLInputs() {
 if [[ -n "$name_cli"
       && "$name_cli" != "$name" ]]; then
  name=$name_cli
 fi

 # update on name
 if [[ -n "$description_cli"
       && "$description_cli" != "$description" ]]; then
  description=$description_cli
 else
  description=$name
 fi

 if [[ "$cpuCount_cli" -gt 0
    && "$cpuCount_cli" -ne "$cpuCount" ]]; then
  cpuCount=$cpuCount_cli
 fi

 if [[ "$diskSize_cli" -gt 0
    && "$diskSize_cli" -ne "$diskSize" ]]; then
  diskSize=$diskSize_cli
 fi

 if [[ "$ramSize_cli" -gt 0
    && "$ramSize_cli" -ne "$ramSize" ]]; then
  ramSize=$ramSize_cli
 fi

 if [[ -n "$storagePlacement_cli"
       && "$storagePlacement_cli" != "$storagePlacement" ]]; then
  storagePlacement=$storagePlacement_cli
  configureStoragePlacement $storagePlacement 
 fi


 # Most of these need update on:
 #  name, ipAddressProvider or storagePlacement
 configFilename=$(getConfigFilename)
 configFilenameDEFAULT=$(getConfigFilenameDEFAULT)
 configFilespec=$(getConfigFilespec)
 configFilespecDEFAULT=$(getConfigFilespecDEFAULT)
 distroFilespec=$(getDistroFilespec)
 imageFilespec=$(getImageFilespec)
 usersFilename=$(getUsersFilename)
 usersFilespec=$(getUsersFilespec)
 usersFilespecDEFAULT=$(getUsersFilespecDEFAULT)
}



# |========================================================|
# Translators ==============================================


########################################
# Translate boolean indicator to y/n string
#
# Expects
#  (int) bool
#
# Returns
#  string
#
# Usage:
#  ans=$(yn $TRUE)
#
function yn() {
 [ "$1" == $TRUE ] && echo 'y' || echo 'n'
}



# |========================================================|
# Type Checkers ============================================


########################################
# Checks if a value is formatted as an IPv4 address
#
# TODO
# VERY IMPORTANT
#  This is a complicated question that, for IPv6 addresses, will require a lot of testing
#  one starting point:
#   https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
#
# given whether IPv6 is nailed down, modify the caller call to each IPvX checker and reply yes if one or the other matches
# as for ports, a bad port returns no
# checker can handle ports+ or ports-
#
#  
#  change name to reflect that it is callin
#
# Expects
#  string of the form: '1.2.3.4'
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
# Checks if a value is numeric
#
# Returns
#  (int) bool
#
# NOTE
#  Usage:
#   ans=$(isNumeric $val)
#  Numeric values can flexibly formatted:
#   quoted/unquoted, negative/positive, decimal/float
#
function isNumeric() {
 local result=$FALSE

 if [ -n "$1" ]; then
  # 0..1 dashes ((0+ digits 0..1 dots) 0..1 times), 1+ digits
  local match=$(echo "$1" | egrep '^[-]?([0-9]*[\.]?)?[0-9]+$')

  if [ -n "$match" ]; then result=$TRUE; fi
 fi

 echo $result
}



# |============================================================================|
# Main =========================================================================
 init
 handleCommandLine "$@"
 CLI_handleBadParms
 mergeCLInputs
 CLI_handleHelpRequest
 doFinalFileChecksAndFallbacks
 deliverResults

