#!/bin/bash

source ../stat_getSwapMemorySummary.fn.sh

stat_getSwapMemorySummary

echo "stat_SwapMemory_Total [$stat_SwapMemory_Total]"
echo "stat_SwapMemory_Used  [$stat_SwapMemory_Used]"
echo "stat_SwapMemory_Free  [$stat_SwapMemory_Free]"

