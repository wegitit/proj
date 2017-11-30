
########################################
#
# Store summary swap memory stats in variables
#
#  stat_SwapMemory_Total  stat_SwapMemory_Used  stat_SwapMemory_Free
#
#  Units: kilobytes
#
function stat_getSwapMemorySummary() {
 local ln=$(free -k | tail -n 1)

 stat_SwapMemory_Total=$(echo "$ln" | awk '{print $2}')
 stat_SwapMemory_Used=$( echo "$ln" | awk '{print $3}')
 stat_SwapMemory_Free=$( echo "$ln" | awk '{print $4}')
}

