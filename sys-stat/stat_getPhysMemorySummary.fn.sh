
########################################
#
# Store free memory summary in variables
#
#  stat_PhysMemory_Total   stat_PhysMemory_Used   stat_PhysMemory_Free
#  stat_PhysMemory_Shared  stat_PhysMemory_Cache  stat_PhysMemory_Avail
#
#  Units: kilobytes
#
stat_getPhysMemorySummary () {
 local ln=$(free -k | head -n 2 | tail -n 1)

 stat_PhysMemory_Total=$( echo "$ln" | awk '{print $2}')
 stat_PhysMemory_Used=$(  echo "$ln" | awk '{print $3}')
 stat_PhysMemory_Free=$(  echo "$ln" | awk '{print $4}')
 stat_PhysMemory_Shared=$(echo "$ln" | awk '{print $5}')
 stat_PhysMemory_Cache=$( echo "$ln" | awk '{print $6}')
 stat_PhysMemory_Avail=$( echo "$ln" | awk '{print $7}')
}

