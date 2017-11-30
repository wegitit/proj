#!/bin/bash

source ../stat_getProcessorTasks.fn.sh

stat_getProcessorTasks

echo "stat_ProcessorTasks_total    [$stat_ProcessorTasks_total]"
echo "stat_ProcessorTasks_running  [$stat_ProcessorTasks_running]"
echo "stat_ProcessorTasks_sleeping [$stat_ProcessorTasks_sleeping]"
echo "stat_ProcessorTasks_stopped  [$stat_ProcessorTasks_stopped]"
echo "stat_ProcessorTasks_zombie   [$stat_ProcessorTasks_zombie]"

