#!/bin/bash

source ../stat_getPhysMemorySummary.fn.sh

stat_getPhysMemorySummary

echo "stat_PhysMemory_Total  [$stat_PhysMemory_Total]"
echo "stat_PhysMemory_Used   [$stat_PhysMemory_Used]"
echo "stat_PhysMemory_Free   [$stat_PhysMemory_Free]"
echo "stat_PhysMemory_Shared [$stat_PhysMemory_Shared]"
echo "stat_PhysMemory_Cache  [$stat_PhysMemory_Cache]"
echo "stat_PhysMemory_Avail  [$stat_PhysMemory_Avail]"

