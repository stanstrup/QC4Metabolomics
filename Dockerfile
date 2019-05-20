FROM rocker/shiny:3.6.0


##### System libs setup #######################################################
# Install needed linux tools
RUN apt-get update && apt-get install  -y \
	libcurl4-openssl-dev \
	libv8-3.14-dev \
	libnetcdf-dev \
	libhdf5-dev \
	\
	libxml2-dev \
	libmariadb-client-lgpl-dev \
	libssl-dev \
	\
	default-jre \
	default-jdk \
	liblzma-dev \
	libbz2-dev \
	\
	librsvg2-dev

RUN sudo R CMD javareconf
###############################################################################


##### Setup shared host folders ###############################################
RUN mkdir /config
RUN mkdir /dbdata
RUN mkdir /data
###############################################################################


##### Install R packages ######################################################
# Copy packrat files
# We copy only the core app without modules so that we can faster rebuild if changes are made in modules
COPY ./Shiny_App /srv/shiny-server/QC4Metabolomics/Shiny_App/

#Initialise packrat
# Dir need to exist for manual install there
RUN mkdir -p "/srv/shiny-server/QC4Metabolomics/Shiny_App/packrat/lib/x86_64-pc-linux-gnu/3.6.0"

# To install packages that doesn't work from packrat. "Remotes" only temporary till Rhdf5lib is fixed on BioC
RUN R -e "install.packages('BiocManager');BiocManager::install('remotes')"

# Doesn't compile from source. Maybe the space bug in the end?
RUN R -e "BiocManager::install('grimbough/Rhdf5lib', lib='/srv/shiny-server/QC4Metabolomics/Shiny_App/packrat/lib/x86_64-pc-linux-gnu/3.6.0')"

# If packrat updates during restore it might fail everything so we make sure to have the latest version.
RUN R -e "BiocManager::install('packrat', lib='/srv/shiny-server/QC4Metabolomics/Shiny_App/packrat/lib/x86_64-pc-linux-gnu/3.6.0')"

# Make packrat install all remaining packages
WORKDIR /srv/shiny-server/QC4Metabolomics/Shiny_App 
RUN R -e "packrat::restore()"
WORKDIR /
###############################################################################


##### Copy complete Shiny App #################################################
COPY . /srv/shiny-server/QC4Metabolomics/
###############################################################################


##### Shiny config ############################################################
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
EXPOSE 3838
###############################################################################


##### File permissions ########################################################
# make all app files readable (solves issue when dev in Windows, but building in Ubuntu)
RUN chmod -R 755 /srv/shiny-server/
###############################################################################


##### Start shiny server  #####################################################
# Dunno what this is for...
RUN mkdir -p /var/lib/shiny-server/bookmarks/shiny

# Start Shiny server
CMD ["/usr/bin/shiny-server.sh"] 
###############################################################################
