#!/bin/sh

# Author :Ceasar Sun
# Chek system status and report the information via mail if necessary

_LOGFILE=/tmp/system-chechk.log
_NEW_ALERT=0

_ADMIN_LIST="Sys_admin01<admin01@email.address>, Sys_admin02<admin02@email.address>"
_ADMIN_LIST_CC="other<other@email.address>"

# [FS_path]:alert_if_less_than_space
_SPACE_CHECK_DEVICE="/:5 /[monitor_FS_path/:100"

SLOAT_NUM_LIST="5"	# 

_Alert_Num=0

[ "$(whoami)" = "root" ] || exit 1;
[ -e "$_LOGFILE" ] && . $_LOGFILE

# check 1: if lost SAN storage ?
#[ ! -d "/mnt/SAN-STORAGE/mirror/" ] && _NEW_ALERTMSG_01="Lost SAN stoage , please check: '/mnt/SAN-STORAGE/mirror/'" && _Alert_Num=$(expr $_Alert_Num + 1)
#[ -n "$_NEW_ALERTMSG_01" ] && [ "$_NEW_ALERTMSG_01" != "$_ALERTMSG_01" ] && _NEW_ALERT=1

# check 2: if system need to uprade ?
apt-get -qq update
[ -n "$(apt-get -s -qq dist-upgrade)" ] && _NEW_ALERTMSG_02="System need to upgrade,please run 'apt-get update/dist-upgrade'" && _Alert_Num=$(expr $_Alert_Num + 1)
[ -n "$_NEW_ALERTMSG_02" ] && [ "$_NEW_ALERTMSG_02" != "$_ALERTMSG_02" ] && _NEW_ALERT=1


# check 3: if free space less then ??G ?
for dev_space_pair in $_SPACE_CHECK_DEVICE;  do
	mou_path="$(echo $dev_space_pair |awk -F':' '{print $1}' )"
	_MIN_FREE_SPACE="$(echo $dev_space_pair |awk -F':' '{print $2}' )"
	free_space="$(df -h -P -B G $mou_path 2>/dev/null | tail -n 1 |awk '{ print $4}'| sed -s -e 's/G//g')"
	[ -n "$free_space" ] && [ $free_space -lt $_MIN_FREE_SPACE ] && _NEW_ALERTMSG_03="$_NEW_ALERTMSG_03 free space of $mou_path less then $_MIN_FREE_SPACE GB;"
done
[ -n "$_NEW_ALERTMSG_03" ] && [ "$_NEW_ALERTMSG_03" != "$_ALERTMSG_03" ] && _NEW_ALERT=1 && _Alert_Num=$(expr $_Alert_Num + 1)

# check 4: if system RAID be stable
#for slot_num in $SLOAT_NUM_LIST ; do
#	error_num="$(hpacucli controller slot=$slot_num logicaldrive all show status | grep -iv ':[[:space:]]*ok$' | awk '{print $2}')"
#	[ -n "$error_num" ] && _NEW_ALERTMSG_04="$_NEW_ALERTMSG_04 Error logical drives:'$error_num' of RAID slot #$slot_num !!;"
#done
#[ -n "$_NEW_ALERTMSG_04" ] && [ "$_NEW_ALERTMSG_04" != "$_ALERTMSG_04" ] && _NEW_ALERT=1 && _Alert_Num=$(expr $_Alert_Num + 1)

# check 5: if 30T NFS be mounted
_nfs_num_current="$(mount -t nfs| wc -l)"
[ $_nfs_num_in_fstab -ne 1 ] && _NEW_ALERTMSG_05="TUX NFS error !" && _NEW_ALERT=1 && _Alert_Num=$(expr $_Alert_Num + 1)

# check 6: if system reboot required
[ -e "/var/run/reboot-required" ] && _NEW_ALERTMSG_06="System reboot required !!" && _Alert_Num=$(expr $_Alert_Num + 1)
[ -n "$_NEW_ALERTMSG_06" ] && [ "$_NEW_ALERTMSG_06" != "$_ALERTMSG_06" ] && _NEW_ALERT=1


# Create log file

_TIMESTAMP="$(date +%c)"
_HOSTNAME="$(/bin/hostname -f)"

cat > /tmp/system-chechk.log<<EOF
#-------------------------------------------------
# This file is auto-generated by system-check.sh
# Author : Ceasar
# 
# Due to the follow items, system sent this mail automatically
# Please fix the issue then delete the log file on server
#
# Note: This script be set in /ect/crontab
# 8 * * * * root /home/ceasar/bin/system-check.sh > /dev/null
#-------------------------------------------------
# Host :$_HOSTNAME
# Log file: $_LOGFILE
# Time: $_TIMESTAMP
# Run script : $0

# check 1: if lost SAN storage
_ALERTMSG_01="$_NEW_ALERTMSG_01"

# check 2: if system need to uprade
_ALERTMSG_02="$_NEW_ALERTMSG_02"

# check 3: if free space less then ??G
_ALERTMSG_03="$_NEW_ALERTMSG_03"

# check 4: if system RAID is stable
_ALERTMSG_04="$_NEW_ALERTMSG_04"

# check 5: if 30T NFS is stable
_ALERTMSG_05="$_NEW_ALERTMSG_05"

# check 6: if system reboot required
_ALERTMSG_06="$_NEW_ALERTMSG_06"

EOF

if [ "$_NEW_ALERT" = 1 ]; then
	# mail to system administrator
	cat $_LOGFILE | mutt -s "Alert !!! $_HOSTNAME system error items: $_Alert_Num " -c "$_ADMIN_LIST_CC" "$_ADMIN_LIST" 
fi


