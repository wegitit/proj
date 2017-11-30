
########################################
#
# Store processor states in variables
#
function stat_getProcessorStates_top() {
 # tr comma->space - protect awk select from: '0.0 ni,100.0 id'
 local top=$(top -b -n 1 | head -n 3 | tail -n 1 | tr ',', ' ')
  
 stat_ProcessorState_us=$(echo "$top" | awk '{print $2}')  # running un-niced user processes
 stat_ProcessorState_sy=$(echo "$top" | awk '{print $4}')  # running kernel processes
 stat_ProcessorState_ni=$(echo "$top" | awk '{print $6}')  # running niced user processes
 stat_ProcessorState_id=$(echo "$top" | awk '{print $8}')  # in the kernel idle handler
 stat_ProcessorState_wa=$(echo "$top" | awk '{print $10}') # waiting for I/O completion
 stat_ProcessorState_hi=$(echo "$top" | awk '{print $12}') # servicing hw interrupts
 stat_ProcessorState_si=$(echo "$top" | awk '{print $14}') # servicing software interrupts
 stat_ProcessorState_st=$(echo "$top" | awk '{print $16}') # stolen by the hypervisor
}

