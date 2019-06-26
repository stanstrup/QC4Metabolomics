#!/bin/bash

printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' > $HOME/env.sh

echo 'Starting cron'
cron -f
