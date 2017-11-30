#!/bin/bash

source ../stat_getProcessorStates_top.fn.sh

stat_getProcessorStates_top

echo "stat_ProcessorState_us [$stat_ProcessorState_us]"
echo "stat_ProcessorState_sy [$stat_ProcessorState_sy]"
echo "stat_ProcessorState_ni [$stat_ProcessorState_ni]"
echo "stat_ProcessorState_id [$stat_ProcessorState_id]"
echo "stat_ProcessorState_wa [$stat_ProcessorState_wa]"
echo "stat_ProcessorState_hi [$stat_ProcessorState_hi]"
echo "stat_ProcessorState_si [$stat_ProcessorState_si]"
echo "stat_ProcessorState_st [$stat_ProcessorState_st]"

