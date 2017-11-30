
########################################
#
# Store count of logged in users in a variable
#
#  stat_LoggedinUser_Count
#
function stat_getLoggedinUser_Count() {
 local uptime=$(uptime)
 stat_LoggedinUser_Count=$(echo "$uptime" | awk '{print $6}')
}

