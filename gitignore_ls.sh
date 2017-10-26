#!/bin/bash
for x in $(ls -p -1 --group-directories-first mkvm); do echo mkvm/$x; done
