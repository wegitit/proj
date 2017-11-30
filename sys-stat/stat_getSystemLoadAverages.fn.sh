
########################################
#
# Store system load averages in variables
#
#  stat_SystemLoadAverage_1m
#  stat_SystemLoadAverage_5m
#  stat_SystemLoadAverage_15m
#
function stat_getSystemLoadAverages() {
 local uptime=$(uptime)
 stat_SystemLoadAverage_1m=$( echo "$uptime" | awk '{print $10}' | tr -d ',')
 stat_SystemLoadAverage_5m=$( echo "$uptime" | awk '{print $11}' | tr -d ',')
 stat_SystemLoadAverage_15m=$(echo "$uptime" | awk '{print $12}')
}

