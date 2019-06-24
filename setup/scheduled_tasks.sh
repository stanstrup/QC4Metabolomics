#!/bin/bash

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -n "$0" "$0" "$@" || :

/usr/local/bin/Rscript '/srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.R'
