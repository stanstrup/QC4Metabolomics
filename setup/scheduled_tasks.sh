#!/bin/bash

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -n "$0" "$0" "$@" || :

# import env that was saved before starting cron
. $HOME/env.sh

# Start R script
/usr/local/bin/Rscript '/srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.R'
