FROM rocker/shiny:4.4.2 AS base


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
	# for textshaping
	libharfbuzz-dev libfribidi-dev \
	\
	\
	librsvg2-dev \
	\
	git \
	# for easier debugging
	libgit2-dev \
	htop \
	nano \
	\
	# to read in access files (waters samples lists)
	mdbtools \
	\
	dos2unix \ # to convert to unix line endings
	libglpk-dev \ # igraph
	\
	libcurl4-openssl-dev \
    ca-certificates \
    curl \
    gnupg \
    && update-ca-certificates \
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
COPY ./.Rprofile renv.lock .env* /srv/shiny-server/QC4Metabolomics


# Make renv install all remaining packages
WORKDIR /srv/shiny-server/QC4Metabolomics/
RUN R -e "renv::restore()"
RUN R -e "renv::install('git2r')"

RUN R -e "BiocManager::install('bnosac/cronR')"


# Always use newest version of the package without having to do a renv snapshot
COPY ./MetabolomiQCsR /srv/shiny-server/QC4Metabolomics/MetabolomiQCsR/
RUN R -e 'install.packages("MetabolomiQCsR", repos = NULL, type = "source")'
###############################################################################


##### Copy complete Shiny App #################################################
COPY ./Modules /srv/shiny-server/QC4Metabolomics/Modules/
COPY ./setup /srv/shiny-server/QC4Metabolomics/setup/
find /srv/shiny-server/QC4Metabolomics/ -type f -exec dos2unix {} +
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
RUN R -e "library(cronR);cmd <- cron_rscript('/srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.sh', cmd = '/bin/bash', rscript_log = '/var/log/QC_cron.log');cron_add(cmd, frequency = '*/1 * * * *', id = 'QC_processing', description = 'Process files every 1 minute', ask = FALSE)"

RUN mkdir /setup
COPY ./setup/cron_with_env.sh /setup/cron_with_env.sh
find /setup/ -type f -exec dos2unix {} +

RUN chmod +x  /setup/cron_with_env.sh
RUN chmod +x  /srv/shiny-server/QC4Metabolomics/setup/scheduled_tasks.sh
###############################################################################




FROM base AS shiny
##### Misc  ###################################################################
COPY ./Shiny_App /srv/shiny-server/QC4Metabolomics/Shiny_App/
find /srv/shiny-server/QC4Metabolomics/ -type f -exec dos2unix {} +
# Dunno what this is for...
RUN mkdir -p /var/lib/shiny-server/bookmarks/shiny
###############################################################################


##### Shiny config ############################################################
COPY ./setup/shiny-server.conf /etc/shiny-server/shiny-server.conf
EXPOSE 3838
###############################################################################

