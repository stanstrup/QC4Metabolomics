#!/bin/bash

# Save the container env for cron jobs. export -p quotes values safely, so
# settings containing quotes or < > (e.g. msconvert titleMaker) survive.
export -p > $HOME/env.sh

echo 'Starting cron'
cron -f
