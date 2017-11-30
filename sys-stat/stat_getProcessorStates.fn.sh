
########################################
#
# Store processor states in variables
#
#  stat_ProcessorState_us : running un-niced user processes
#  stat_ProcessorState_sy : running kernel processes
#  stat_ProcessorState_ni : running niced user processes
#  stat_ProcessorState_id : in the kernel idle handler
#  stat_ProcessorState_wa : waiting for I/O completion
#  stat_ProcessorState_hi : servicing hw interrupts
#  stat_ProcessorState_si : servicing software interrupts
#  stat_ProcessorState_st : stolen by the hypervisor
#
# Requires
#  sysstat:package
#
# NOTE
#  see stat_getProcessorStates.fn.sh.notes
#
function stat_getProcessorStates() {
 local mpstat=$(mpstat -u | tail -n 1)
 
 stat_ProcessorState_us=$(echo "$mpstat" | awk '{print  $4}')
 stat_ProcessorState_sy=$(echo "$mpstat" | awk '{print  $6}')
 stat_ProcessorState_ni=$(echo "$mpstat" | awk '{print $12}')
 stat_ProcessorState_id=$(echo "$mpstat" | awk '{print $13}')
 stat_ProcessorState_wa=$(echo "$mpstat" | awk '{print  $7}')
 stat_ProcessorState_hi=$(echo "$mpstat" | awk '{print  $8}')
 stat_ProcessorState_si=$(echo "$mpstat" | awk '{print  $9}')
 stat_ProcessorState_st=$(echo "$mpstat" | awk '{print $10}')
}

