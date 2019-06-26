#!/bin/bash
[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -n "$0" "$0" "$@" || :

# import env that was saved before starting cron
. $HOME/env.sh

# Start R script
/usr/bin/Rscript '/converter_scripts/converter_std.R'


