
########################################
#
# Store processor task summary in variables
#
#  stat_ProcessorTasks_total     stat_ProcessorTasks_running
#  stat_ProcessorTasks_sleeping  stat_ProcessorTasks_stopped  stat_ProcessorTasks_zombie
#
function stat_getProcessorTasks() {
 local psaxo=$(ps axo stat=)

 # ps sleeping & ps total seldom agree w/top
 #  stat_ProcessorTasks_sleeping=$(echo -e "${psaxo}" | grep -cE '^D|^S')
 #  stat_ProcessorTasks_total=$(   echo -e "${psaxo}" | wc -l)

 stat_ProcessorTasks_running=$( echo -e "${psaxo}" | grep -c  '^R')
 stat_ProcessorTasks_sleeping=$(grep sleeping /proc/*/status | wc -l)
 stat_ProcessorTasks_stopped=$( echo -e "${psaxo}" | grep -ci '^T')
 stat_ProcessorTasks_zombie=$(  echo -e "${psaxo}" | grep -c  '^Z')
 stat_ProcessorTasks_total=$(($stat_ProcessorTasks_running + $stat_ProcessorTasks_sleeping))
}

