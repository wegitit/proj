
########################################
#
# Store processor task summary in variables
#
#  stat_ProcessorTasks_total    stat_ProcessorTasks_running
#  stat_ProcessorTasks_sleeping stat_ProcessorTasks_stopped stat_ProcessorTasks_zombie
#
function stat_getProcessorTasks() {
 local top=$(top -b -n 1 | head -n 2 | tail -n 1)

 stat_ProcessorTasks_total=$(   echo "$top" | awk '{print $2}')
 stat_ProcessorTasks_running=$( echo "$top" | awk '{print $4}')
 stat_ProcessorTasks_sleeping=$(echo "$top" | awk '{print $6}')
 stat_ProcessorTasks_stopped=$( echo "$top" | awk '{print $8}')
 stat_ProcessorTasks_zombie=$(  echo "$top" | awk '{print $10}')
}

