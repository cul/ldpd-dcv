FROM solr:6.3.0

WORKDIR /data

# Set up template cores in image

COPY --chown=solr:solr './solr_cores/dcv-solr-6-3' /template-cores/dcv
RUN echo 'name=dcv' > /template-cores/dcv/core.properties

# When image runs, the command below will copy template cores to final location (on mounted docker
#  volume) if they don't already exist, and then will start solr.

CMD [ ! -d /opt/solr/server/solr/dcv ] && cp -pr /template-cores/dcv /data/dcv && \
    ln -s /data/dcv /opt/solr/server/solr/dcv && \
    solr-foreground
