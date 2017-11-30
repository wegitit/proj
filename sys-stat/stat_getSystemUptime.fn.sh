
########################################
#
# Store system up time in variables
#
#  stat_SystemUptime_Days
#  stat_SystemUptime_Hours
#  stat_SystemUptime_Minutes
#
function stat_getSystemUptime() {
 local uptime=$(uptime)
 local hours_minutes=$(echo "$uptime" | awk '{print $5}' | tr -d ',')

 stat_SystemUptime_Days=$(echo "$uptime" | awk '{print $3}')
 stat_SystemUptime_Hours=$(echo "$hours_minutes" | cut -d ':' -f1)
 stat_SystemUptime_Minutes=$(echo "$hours_minutes" | cut -d ':' -f2)
}

