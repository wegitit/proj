#!/bin/bash

source ../stat_getSystemUptime.fn.sh

stat_getSystemUptime

echo "stat_SystemUptime_Days    [$stat_SystemUptime_Days]"
echo "stat_SystemUptime_Hours   [$stat_SystemUptime_Hours]"
echo "stat_SystemUptime_Minutes [$stat_SystemUptime_Minutes]"

