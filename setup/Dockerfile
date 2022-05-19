FROM rocker/shiny:4.2 AS base


##### System libs setup #######################################################
# Install needed linux tools
RUN apt-get update && \
    apt-get install  -y \
	# needed for certain R packages
	libnetcdf-dev \
	libxml2-dev \
	libmysqlclient-dev \
	libssl-dev \
	\
	default-jre \
	default-jdk \
	liblzma-dev \
	libbz2-dev \
	\
	librsvg2-dev \
	\
	git \
	\
    && rm -rf /var/lib/apt

RUN sudo R CMD javareconf
###############################################################################


##### Setup shared host folders ###############################################
RUN mkdir /config
RUN mkdir /data
###############################################################################


##### Install R packages ######################################################
# Copy rev files
# We copy only the core app without modules so that we can faster rebuild if changes are made in modules
COPY ./renv /srv/shiny-server/QC4Metabolomics/renv/
COPY ./.Rprofile /srv/shiny-server/QC4Metabolomics/.Rprofile
COPY ./renv.lock /srv/shiny-server/QC4Metabolomics/renv.lock


# Make renv install all remaining packages
WORKDIR /srv/shiny-server/QC4Metabolomics/
RUN R -e "renv::restore()"
RUN R -e "renv::install('git2r')"

RUN R -e "BiocManager::install('bnosac/cronR')"


# Always use newest version of the package without having to do a renv snapshot
COPY ./MetabolomiQCsR /srv/shiny-server/QC4Metabolomics/MetabolomiQCsR/
RUN R -e "remotes::install_local('MetabolomiQCsR', build_vignettes = FALSE)"
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

# needed outside project folder too
#RUN R -e "install.packages('BiocManager')"
#RUN R -e "BiocManager::install('remotes')"
#RUN R -e "BiocManager::install('bnosac/cronR')"
WORKDIR /srv/shiny-server/QC4Metabolomics/
RUN R -e "library(cronR);cmd <- cron_rscript('/srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.sh', cmd = '/bin/bash', rscript_log = '/var/log/QC_cron.log');cron_add(cmd, frequency = '*/5 * * * *', id = 'QC_processing', description = 'Process files every 5 minute', ask = FALSE)"

RUN mkdir /setup
COPY ./setup/cron_with_env.sh /setup/cron_with_env.sh
RUN chmod +x  /setup/cron_with_env.sh
RUN chmod +x  /srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.sh
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

