#!/bin/bash

# removing lockfile for the upgrade script so that it can be re-run as many times as people want
if [ -f "/install/.updateplex.lock" ]; then
    # echo file exists
    rm /install/.updateplex.lock
fi
