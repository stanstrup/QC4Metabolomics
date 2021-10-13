FROM rocker/shiny:3.6.0 AS base


##### System libs setup #######################################################
# Install needed linux tools
RUN apt-get update && \
    apt-get install  -y \
	# needed for certain R packages
	libnetcdf-dev \
	libxml2-dev \
	libmariadb-client-lgpl-dev \
	libssl-dev \
	\
	default-jre \
	default-jdk \
	liblzma-dev \
	libbz2-dev \
	\
	librsvg2-dev \
	\
    && rm -rf /var/lib/apt

RUN sudo R CMD javareconf
###############################################################################


##### Setup shared host folders ###############################################
RUN mkdir /config
RUN mkdir /data
###############################################################################


##### Install R packages ######################################################
# Copy packrat files
# We copy only the core app without modules so that we can faster rebuild if changes are made in modules
COPY ./packrat /srv/shiny-server/QC4Metabolomics/packrat/
COPY ./.Rprofile /srv/shiny-server/QC4Metabolomics/.Rprofile

#Initialise packrat
# Dir need to exist for manual install there
RUN mkdir -p "/srv/shiny-server/QC4Metabolomics/packrat/lib/x86_64-pc-linux-gnu/3.6.0"

# To install packages that doesn't work from packrat.
RUN R -e "install.packages('BiocManager')"

# Doesn't compile from source. Maybe the space bug in the end?
RUN R -e "BiocManager::install('Rhdf5lib', lib='/srv/shiny-server/QC4Metabolomics/packrat/lib/x86_64-pc-linux-gnu/3.6.0')"
RUN R -e "BiocManager::install('mzR', lib='/srv/shiny-server/QC4Metabolomics/packrat/lib/x86_64-pc-linux-gnu/3.6.0')"

# If packrat updates during restore it might fail everything so we make sure to have the latest version.
RUN R -e "BiocManager::install('packrat', lib='/srv/shiny-server/QC4Metabolomics/packrat/lib/x86_64-pc-linux-gnu/3.6.0')"

# Make colors available in a console connection. Installed here since it cannot install on windows
RUN R -e "BiocManager::install('remotes')"
RUN R -e "BiocManager::install('jalvesaq/colorout', lib='/srv/shiny-server/QC4Metabolomics/packrat/lib/x86_64-pc-linux-gnu/3.6.0')"

# Make packrat install all remaining packages
WORKDIR /srv/shiny-server/QC4Metabolomics/ 
RUN R -e "packrat::restore()"
WORKDIR /
###############################################################################


##### Copy complete Shiny App #################################################
COPY ./Modules /srv/shiny-server/QC4Metabolomics/Modules/
COPY ./setup /srv/shiny-server/QC4Metabolomics/setup/
###############################################################################


##### File permissions ########################################################
# make all app files readable (solves issue when dev in Windows, but building in Ubuntu)
# Evidently not needed and takes a lot of space
# RUN chmod -R 755 /srv/shiny-server/
###############################################################################




FROM base AS process
##### Scheduled jobs ##########################################################
RUN apt-get update && \
	apt-get install  -y \
	\
	cron \
    && rm -rf /var/lib/apt

RUN R -e "BiocManager::install('bnosac/cronR')"
RUN R -e "library(cronR);cmd <- cron_rscript('/srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.sh', cmd = '/bin/bash', rscript_log = '/var/log/QC_cron.log');cron_add(cmd, frequency = '*/5 * * * *', id = 'QC_processing', description = 'Process files every 5 minute', ask = FALSE)"

RUN mkdir /setup
COPY ./setup/cron_with_env.sh /setup/cron_with_env.sh
###############################################################################




FROM base AS shiny
##### Misc  ###################################################################
COPY ./Shiny_App /srv/shiny-server/QC4Metabolomics/Shiny_App/

# Dunno what this is for...
RUN mkdir -p /var/lib/shiny-server/bookmarks/shiny
###############################################################################


##### Shiny config ############################################################
COPY ./setup/shiny-server.conf /etc/shiny-server/shiny-server.conf
EXPOSE 3838
###############################################################################

