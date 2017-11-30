#!/bin/bash

source ../stat_getSystemLoadAverages.fn.sh

stat_getSystemLoadAverages

echo "stat_SystemLoadAverage_1m  [$stat_SystemLoadAverage_1m]"
echo "stat_SystemLoadAverage_5m  [$stat_SystemLoadAverage_5m]"
echo "stat_SystemLoadAverage_15m [$stat_SystemLoadAverage_15m]"

