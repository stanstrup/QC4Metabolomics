ARG BASE_IMAGE=ghcr.io/stanstrup/qc4metabolomics/qc_base:latest
FROM ${BASE_IMAGE} AS base

##### Scheduled jobs ##########################################################
FROM base AS process

RUN apt-get update && \
	apt-get install  -y \
	\
	cron \
    && rm -rf /var/lib/apt

# needed outside project folder too
#RUN R -e "install.packages('BiocManager')"
#RUN R -e "BiocManager::install('remotes')"
#RUN R -e "BiocManager::install('bnosac/cronR')"
WORKDIR /srv/shiny-server/QC4Metabolomics/
RUN R -e "library(cronR);cmd <- cron_rscript('/srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.sh', cmd = '/bin/bash', rscript_log = '/var/log/QC_cron.log');cron_add(cmd, frequency = '*/1 * * * *', id = 'QC_processing', description = 'Process files every 1 minute', ask = FALSE)"

RUN mkdir /setup
COPY ./setup/cron_with_env.sh /setup/cron_with_env.sh
RUN find /setup/ -type f -exec dos2unix {} +

RUN chmod +x  /setup/cron_with_env.sh
RUN chmod +x  /srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.sh
###############################################################################


##### Shiny ###################################################################
FROM base AS shiny

COPY ./Shiny_App /srv/shiny-server/QC4Metabolomics/Shiny_App/
RUN find /srv/shiny-server/QC4Metabolomics/ -type f -exec dos2unix {} +
# Dunno what this is for...
RUN mkdir -p /var/lib/shiny-server/bookmarks/shiny



##Shiny config
COPY ./setup/shiny-server.conf /etc/shiny-server/shiny-server.conf
EXPOSE 3838
###############################################################################

