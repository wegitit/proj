# ##############################################################################
# Guest system kickstart #######################################################

# base file: default-dhcp.ks

# This file as is, will not pass the ksvalidator check
#  Sections marked 'TARGET' may require changes
#  to pass validation


# REFS:
#  1 https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/chap-kickstart-installations.html
#  2 https://github.com/rhinstaller/pykickstart/blob/master/docs/kickstart-docs.rst
#  3 http://docs.virtuozzo.com/virtuozzo_storage_2_installation_using_pxe_guide/creating-a-kickstart-file/kickstart-file-example.html
#  4 (not sure about keeping this one - review) https://github.com/rhinstaller/anaconda/commit/1b916ff762ab15330c2644a8e4fb4357167c2ca9
#  5 https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/sect-kickstart-syntax.html#sect-kickstart-commands



# ######################################
# TESTING ##############################
#  review REF#5 for more options


# ######################################
# NOTES follow code ####################


# ######################################
#version=DEVEL


# ######################################
# Auth style ###########################
auth --enableshadow --passalgo=sha512


# ######################################
# Install media ########################
cdrom


# ######################################
# Install mode: unattended #############
#  REF#5 "spec" (text|cmdline), REF#3 "working example" (cmdline)
cmdline


# ######################################
# Setup Agent (firstboot) ##############
#  will not run in a low mem, cli, auto install so skip it:
# firstboot --enable


# Storage ##############################
## ignore ##############################
ignoredisk --only-use=vda

##  Bootloader
#    Removed: --append=" crashkernel=auto"
#    Use kernel dump only on physical machines
bootloader --location=mbr --boot-drive=vda --timeout=0

### Bootloader-Organization
#    Options: --type=(plain|lvm) (default=lvm)
autopart --type=plain

## init
#   Options: --disklabel=(gpt|mbr)
#   gpt needs: zerombr
zerombr
clearpart --disklabel=gpt --drives=vda --all


# ######################################
# Network ############ TARGET hostname #
network --bootproto=dhcp --hostname=localhost.localdomain --device=eth0 --noipv6 --activate


# ######################################
# Users ############# TARGET user list #
#{{ INSERT USERS HERE }}#


# ######################################
# UI ###################################

## Keyboard
keyboard --vckeymap=us --xlayouts='us'

## Language
lang en_US.UTF-8

## X Window
### do not install
skipx


# ######################################
# Services #############################
#  enable: --enabled="service", disable: --disabled="service"

## Time Service
### guest time: chrony, host time: ntp
services --enabled="chronyd"

## Time zone, type, sync
timezone America/Chicago --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org


# ######################################
# Packages #############################
%packages --excludedocs --instLangs=en_US
  # options must be on the packages line

# ALL machines
  @core

# adaptec cards
  -aic94xx-firmware

# graphical boot
  -plymouth
  -plymouth-*

# iTVC15 MPEG codec (e.g. Hauppauge PVR)
  -ivtv-firmware

# net teaming
  -teamd
  
#  NetworkManager
  -NetworkManager-team
  -NetworkManager-tui
 #-NetworkManager-wifi (see "no wifi" section)

# sound support
  -alsa-*

# wireless: general
  -NetworkManager-wifi 
  -wpa-supplicant
# wireless: intel
  -iwl*-firmware


# Guest machines ###
  chrony
  -kexec-tools
  -man-db
  -ntp
%end


# ######################################
# Pre Ops ##############################
#%pre
#%end


# ######################################
# Post Ops #############################

## Main Group
%post
  # no-gui-elements
  #  graphics
  #  kde
  # no-documentation
  # no-unsafe-elements


  # Beg Group: Set yum options (before any installs)
  #  tag:footprint

   # REF[1]: linuxconfig.org/how-to-substitute-only-a-first-match-occurrence-using-sed-command
   # added because %packages: --excludedocs & --instLangs didn't seem to work
   yum fs filter documentation
   yum fs filter languages en

   # Update installonly_limit
   sed s/^.*installonly_limit.*/installonly_limit=2/ -i /etc/yum.conf
  # End Group


  # Beg Group: Set English as the sole locale
  #  tag:footprint

   # Get the latest available glibc-common
   #  Older releases (e.g. in a default CentOS 7.2 (1511) install)
   #   may cause build-locale-archive to fail
   yum -qy --errorlevel=0 install glibc-common &> /dev/null

   # Delete ^en if it is a dir, keep locale.alias
   for x in $(ls -p /usr/share/locale | grep "/" | grep -v -i ^en | grep -v -i local); \
    do rm -rf /usr/share/locale/$x; done

   localedef --quiet --list-archive | \
    grep -v -i ^en | \
    xargs localedef --quiet --delete-from-archive

   mv -f /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl

   # on success, .tmpl size=0
   build-locale-archive
  # End Group

  # Begin Group: upgrade
  #  tag:SOP
    yum -qy --errorlevel=0 upgrade &> /dev/null
  # End Group

  # Beg Group: Remove docs (Post install)
   # rm doc dir contents
   for x in $(ls -1 /usr/share/doc); do rm -rf /usr/share/doc/$x; done
   rm -rf /usr/share/firstboot/themes
   rm -rf /usr/share/kde4
   # rm man dir contents
   for x in $(ls -1 /usr/local/share/man); do rm -rf /usr/local/share/man/$x; done
   for x in $(ls -1 /usr/share/man); do rm -rf /usr/share/man/$x; done
  # End Group

  # Beg Group: remove unneeded users and groups for better security
   # user deletes must precede group deletes
   userdel adm      &> /dev/null
   userdel ftp      &> /dev/null
   userdel games    &> /dev/null
   userdel halt     &> /dev/null
   userdel lp       &> /dev/null
   userdel operator &> /dev/null
   userdel shutdown &> /dev/null
   userdel sync     &> /dev/null
   # group deletes must folllow user deletes
   groupdel adm    &> /dev/null #should not exist, user prev deleted
   groupdel dip    &> /dev/null
   groupdel floppy &> /dev/null
   groupdel ftp    &> /dev/null #should not exist, user prev deleted
   groupdel games  &> /dev/null
   groupdel lp     &> /dev/null #should not exist, user prev deleted
   groupdel tape   &> /dev/null
   groupdel users  &> /dev/null
   groupdel video  &> /dev/null 
  # End Group
%end


## Secondary Group
#%post
#  --nochroot
#%end


# ######################################
## Addons ##############################

### Security
# requires packages: openscap, openscap-scanner, scap-security-guide
%addon org_fedora_oscap
 content-type = scap-security-guide
 profile = standard
%end

### Crash Recovery
#### kernel dump (mandatory: the installer does not honor --disable)
%addon com_redhat_kdump
 --enable
%end


# ######################################
# END ##################################
#  After installation, reboot (robot style)
#   Other options: shutdown and forgotten something
reboot



# ##############################################################################
# NOTES ########################################################################

# gpt worked
#  gdisk -l /dev/vda reports:
#   Found valid GPT with protective MBR; using GPT


# /etc/yum.conf options are probably best done with Ansible
#  installonly_limit=3


# /usr/share begins at
#  251MB
#  76 entries


# REMOVE
#  compiler (gcc) stuff
#  desktop stuff (just kde4 so far)
##  doc contents
#  graphics (just firstboot/themes so far)
##  man page contents
#  x window stuff


# aclocal
# alsa
# anaconda
# applications
# augeas
# authconfig
# awk
# backgrounds
# bash-completion
# centos-logos
# centos-release
# cracklib
# dbus-1
# desktop-directories
# dict
# (rm ./*) doc
# empty
# file
# (rm ./themes) firstboot
# games
# gcc-4.8.2
# gcc-4.8.5 -> gcc-4.8.2
# GConf
# gdb
# gettext
# ghostscript
# glib-2.0
# gnome
# gnome-background-properties
# gnupg
# groff
# grub
# hwdata
# i18n
# icons
# idl
# info
# (rm) kde4
# kdump
# licenses
# locale
# lua
# magic -> misc/magic
# (rm ./*) man
# mime
# mime-info
# misc
# mysql
# omf
# openscap
# os-prober
# p11-kit
# pixmaps
# pkgconfig
# pki
# plymouth
# polkit-1
# redhat-release -> centos-release
# scap-security-guide
# selinux
# sgml
# sounds
# systemd
# systemtap
# tabset
# terminfo
# themes
# tuned
# wallpapers
# X11
# xml
# xsessions
# yum-cli
# yum-plugins
# zoneinfo
# zsh
