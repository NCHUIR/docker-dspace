# dspace_53_nchuir
# ================

FROM tomcat:8

# Install required apt-get packages
RUN apt-get update && apt-get install -y -q --force-yes \
  postgresql-client \
  openjdk-7-jdk \
  ant \
  git \
  unzip \
  less \
  rsync \
  vim \
  && apt-get clean \
  && rm -rf /tmp/* /var/tmp/*  \
  && rm -rf /var/lib/apt/lists/*

# Install Maven
COPY install/maven.sh /tmp/
RUN bash /tmp/maven.sh; rm -rf /tmp/* /var/tmp/*

# Prepare clean_after_run Scripts as command
COPY install/bin/clean_after_run.sh /usr/bin/clean_after_run
RUN chmod +x /usr/bin/clean_after_run

# Fixed Environment Variables
ENV \
DSPACE_SOURCE_PATH=/dspace-src \
DSPACE_INSTALL_PATH=/dspace \
DATA_VOLUME=/data \
VOLUME_DATA_DIRS=log,webapps,config,handle_server \
DBDATA_VOLUME=/dbdata \
VOLUME_DBDATA_DIRS=assetstore,solr \
ENV_FILE_PATH=/etc/environment

# Misc
COPY install/conf/env.conf install/misc.sh /tmp/
RUN bash /tmp/misc.sh; rm -rf /tmp/* /var/tmp/*

# Provide Dspace source code, download it if dspace-src directory is empty
ADD dspace-src /dspace-src
COPY install/download_dspace.sh /tmp/
RUN clean_after_run /tmp/download_dspace.sh

# Configure DSpace
COPY install/config_dspace.sh /tmp/
COPY install/build-more_targets.xml /usr/dspace-build-more_targets.xml
ENV BUILD_MORE_TARGETS_PATH=/usr/dspace-build-more_targets.xml
RUN clean_after_run /tmp/config_dspace.sh

# Build (mvn and ant) DSpace
COPY install/bin/dspace.build.sh /usr/bin/dspace.build
RUN chmod +x /usr/bin/dspace.build
RUN dspace.build "package" "fresh_install_without_db"

# Post-install
ADD install/bin /tmp/bin/
COPY install/post-install.sh /tmp/
RUN clean_after_run /tmp/post-install.sh

# Configure Tomcat
COPY install/tomcat.sh /install/conf/tomcat.conf /tmp/
RUN clean_after_run /tmp/tomcat.sh

# Data volumes
COPY install/mv_data.sh /tmp/
RUN clean_after_run /tmp/mv_data.sh
VOLUME ["/data", "/dbdata"]

# Default Service port
EXPOSE 8080

# for executable /dspace/bin/dspace
WORKDIR /dspace/bin

# Use baseimage-docker's init system.
CMD ["dspace.run"]

