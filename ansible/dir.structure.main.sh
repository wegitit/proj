# !/bin/bash


# Description
#  In the current directory,
#   create the main "best practices" directory layout guidance
#   described in:
#    docs.ansible.com/ansible/latest/playbooks_best_practices.html#directory-layout


# TODO
#  Look into calling trim whitespace once per value
#  Look into using trailing slash to distinguish directories and remove fsObj_TYPE_x

# NOTE
#  passing strings to a f() trim changed the string

# REF
#  Strip leading and trailing whitespace
#   03-07-2005 Perderabo
#   unix.com/shell-programming-and-scripting/17374-strip-leading-trailing-spaces-only-shell-variable-embedded-spaces.html



# #########################################################
# declarations

# constants
DIR='scaffold'
FALSE=0
TRUE=1

fsObj_NOCODE=0
fsObj_PREVCREATED=10
fsObj_CREATED=11
fsObj_CREATEFAILED=12
# [file system object types]
fsObj_TYPE_DIR=20
fsObj_TYPE_FILE=21

ec_NOERROR=0
ec_CREATEERROR=1
ec_UKNOWNERROR=2
ec_ILLEGALPARM=3
ec_INTERNALERROR=4

em_NOERROR=''
em_SUCCESS='Operations completed successfully'
em_INTERNALERROR='Internal error'

# vars
exitCode=$ec_NOERROR
exitMessage="$em_NOERROR"



# #########################################################
# functions

########################################
# Create a directory
#
# Parms
# path - the path of the directory to create
#
# Returns
# fsObj_PREVCREATED
# fsObj_CREATED
# fsObj_CREATEFAILED
#
function createDir() {
 local spec="$1"

 if [ $(dirExists "$spec") -eq $TRUE ]; then
  echo "$fsObj_PREVCREATED"
 else
  mkdir -p "$spec"
  if [ $(dirExists "$spec") -eq $TRUE ]; then
   echo "$fsObj_CREATED"
  else
   echo "$fsObj_CREATEFAILED"
  fi
 fi
}

########################################
# Create a file in an existing directory
#
# Parms
# path - the path of the file to create
#
# Returns
# fsObj_PREVCREATED
# fsObj_CREATED
# fsObj_CREATEFAILED
#
# TODO
#  missing directory check
#
function createFile() {
 local spec="$1"

 if [ $(isRegularFile "$spec") -eq $TRUE ]; then
  echo "$fsObj_PREVCREATED"
 else
  touch "$spec"
  if [ $(isRegularFile "$spec") -eq $TRUE ]; then
   echo "$fsObj_CREATED"
  else
   echo "$fsObj_CREATEFAILED"
  fi
 fi
}

########################################
# Create an object in the file system
# 
# Parms
# type - the type of the object to create, defined under: [file system object types]
# path - path of the object to create
# desc - description of file system object
#
# Returns
#  void
#
# echos exitMessage
# Sets exitCode
#
function createFsObj() {
 local statusCode=$fsObj_NOCODE
 local fsObj_type=$1
 local fsObj_path=$(sed 's/^[[:space:]]*//g;s/[[:space:]]*$//g' <<<"${2}")
 local fsObj_desc=$3

 
 exitCode=$ec_NOERROR
 exitMessage="em_NOERROR"

 if [ $fsObj_type -eq $fsObj_TYPE_DIR ]; then
  statusCode=$(createDir "$fsObj_path")
 elif [ $fsObj_type -eq $fsObj_TYPE_FILE ]; then
  statusCode=$(createFile "$fsObj_path")
 else
  exitCode=$ec_ILLEGALPARM
  echo -e "An $em_INTERNALERROR error occurred creating\n    [$fsObj_path]\n"
  return
 fi

 if [ $statusCode -eq $fsObj_PREVCREATED ]; then
  exitMessage="The '$fsObj_desc' exists\n    [$fsObj_path]"
 elif [ $statusCode -eq $fsObj_CREATED ]; then
  exitMessage="Created '$fsObj_desc'\n    [$fsObj_path]"
 elif [ $statusCode -eq $fsObj_CREATEFAILED ]; then
  exitCode=$ec_CREATEERROR
  exitMessage="Failed creating '$fsObj_desc'\n    [$fsObj_path]"
 else
  exitCode=$ec_INTERNALERROR
  exitMessage="An $em_INTERNALERROR error occurred creating\n    [$fsObj_path]"
 fi

 [ "$exitMessage" != "$em_NOERROR" ] && echo -e "$exitMessage\n"
}

########################################
# Tests whether a directory exists
#
# Parms
# path - path of the directory to test
#
# Returns
# $TRUE if the directory exists
# $FALSE if the directory does not exist or its existence cannot be determined
#
function dirExists() {
 local spec=$(sed 's/^[[:space:]]*//g;s/[[:space:]]*$//g' <<<"${1}")
 local result=$FALSE

 [[ -n "$spec" && -d "$spec" ]] && result=$TRUE
 echo $result
}

########################################
# Tests whether a file exists
#
# Parms
# path - path of the file to test
#
# Returns
# $TRUE if the file exists
# $FALSE if the file does not exist or its existence cannot be determined
#
function fileExists() {
 local spec=$(sed 's/^[[:space:]]*//g;s/[[:space:]]*$//g' <<<"${1}")
 local result=$FALSE

 [[ -n "$spec" && -e "$spec" ]] && result=$TRUE
 echo $result
}

########################################
# Tests whether a file is a 'regular' file
# 
# Parms
# path - path of the file to test
#
# Returns
# $TRUE if the file is a regular file
# $FALSE if the file's existence cannot be determined, it does not exist or it
#  is not a regular file, a directory, a device or a link
#
function isRegularFile() {
 local spec=$(sed 's/^[[:space:]]*//g;s/[[:space:]]*$//g' <<<"${1}")
 local result=$FALSE

 [[ $(fileExists "$spec") -eq $TRUE && -f "$spec"  && ! -h "$spec" ]] && result=$TRUE
 echo $result
}



# #########################################################
# main

echo
echo 'Creating directory layout for Ansible playbooks'
echo ' New files will be empty, existing files will be "touched"'
echo
echo ------------------------------------------------------------


createFsObj $fsObj_TYPE_DIR "$DIR" 'playbook directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode


# production                 inventory file for production servers
createFsObj $fsObj_TYPE_FILE "$DIR/production" 'production inventory file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode


# staging                    inventory file for staging environment
createFsObj $fsObj_TYPE_FILE "$DIR/staging" 'staging inventory file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

# group_vars/
createFsObj $fsObj_TYPE_DIR "$DIR/group_vars" 'group variables directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#   all                      assign variables for all groups
createFsObj $fsObj_TYPE_FILE "$DIR/group_vars/all" '-all groups- variables file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#    group1                  here we assign variables to particular groups
#    group2                  ""

# host_vars/
createFsObj $fsObj_TYPE_DIR "$DIR/host_vars" 'host variables directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#    hostname1               if systems need specific variables, put them here
#    hostname2               ""

# library/                   if any custom modules, put them here (optional)
# module_utils/              if any custom module_utils to support modules, put them here (optional)
# filter_plugins/            if any custom filter plugins, put them here (optional)

# site.yml                   master playbook
createFsObj $fsObj_TYPE_FILE "$DIR/site.yml" 'main playbook'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

# webservers.yml             playbook for webserver tier
# dbservers.yml              playbook for dbserver tier

# roles/
createFsObj $fsObj_TYPE_DIR "$DIR/roles" 'custom roles directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#     common/                this hierarchy represents a "role"
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common" 'sample role directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#         tasks/            
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common/tasks" 'tasks directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#             main.yml        <-- tasks file, can 'include' smaller files if warranted
createFsObj $fsObj_TYPE_FILE "$DIR/roles/common/tasks/main.yml" 'main tasks file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#         handlers/         
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common/handlers" 'handlers directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#             main.yml        <-- handlers file
createFsObj $fsObj_TYPE_FILE "$DIR/roles/common/handlers/main.yml" 'main handlers file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#         templates/          <-- files for use with the template resource
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common/templates" 'templates directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#             ntp.conf.j2     <------- templates end in .j2

#         files/            
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common/files" 'files directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#             bar.txt         <-- files for use with the copy resource
#             foo.sh          <-- script files for use with the script resource

#         vars/             
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common/vars" 'variables directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#             main.yml        <-- variables associated with this role
createFsObj $fsObj_TYPE_FILE "$DIR/roles/common/vars/main.yml" 'main variables file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#         defaults/         
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common/defaults" 'variables defaults directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#             main.yml        <-- default lower priority variables for this role
createFsObj $fsObj_TYPE_FILE "$DIR/roles/common/defaults/main.yml" 'main variables defaults file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#         meta/             
createFsObj $fsObj_TYPE_DIR "$DIR/roles/common/meta" 'meta directory'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#             main.yml        <-- role dependencies
createFsObj $fsObj_TYPE_FILE "$DIR/roles/common/meta/main.yml" 'main dependencies file'
[ $exitCode -ne $ec_NOERROR ] && exit $exitCode

#         library/           roles can also include custom modules
#         module_utils/      roles can also include custom module_utils
#         lookup_plugins/    or other types of plugins, like lookup in this case


#     webtier/               same kind of structure as "common" was above, done for the webtier role
#     monitoring/            ""
#     fooapp/                ""


echo ------------------------------------------------------------
echo "$em_SUCCESS"; echo
exit $ec_NOERROR

