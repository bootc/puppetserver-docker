# Version of Puppet Server to install
ARG version=7.11.0

# Puppet repository suite to install from (NOT the base image)
ARG UBUNTU_CODENAME=focal

FROM ubuntu:22.04

ARG version
ARG UBUNTU_CODENAME

LABEL org.label-schema.maintainer="Puppet Release Team <release@puppet.com>" \
      org.label-schema.vendor="Puppet" \
      org.label-schema.url="https://github.com/puppetlabs/puppetserver" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.vcs-url="https://github.com/puppetlabs/puppetserver" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/Dockerfile"

# used by entrypoint to submit metrics to Google Analytics;
# published images should use "production" for this build_arg
ARG pupperware_analytics_stream="dev"

ENV PUPPERWARE_ANALYTICS_TRACKING_ID="UA-132486246-4" \
    PUPPERWARE_ANALYTICS_APP_NAME="puppetserver" \
    PUPPERWARE_ANALYTICS_ENABLED=false \
    PUPPERWARE_ANALYTICS_STREAM="$pupperware_analytics_stream" \
    PUPPETSERVER_JAVA_ARGS="-XX:+UseContainerSupport --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED" \
    PATH=/opt/puppetlabs/server/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:$PATH \
    SSLDIR=/etc/puppetlabs/puppet/ssl \
    LOGDIR=/var/log/puppetlabs/puppetserver \
    PUPPETSERVER_HOSTNAME="" \
    DNS_ALT_NAMES="" \
    PUPPET_MASTERPORT=8140 \
    AUTOSIGN="" \
    PUPPETSERVER_MAX_ACTIVE_INSTANCES=1 \
    PUPPETSERVER_MAX_REQUESTS_PER_INSTANCE=0 \
    CA_ENABLED=true \
    CA_HOSTNAME=puppet \
    CA_MASTERPORT=8140 \
    CA_ALLOW_SUBJECT_ALT_NAMES=false \
    USE_PUPPETDB=true \
    PUPPETDB_SERVER_URLS=https://puppetdb:8081 \
    PUPPET_STORECONFIGS_BACKEND="puppetdb" \
    PUPPET_STORECONFIGS=true \
    PUPPET_REPORTS="puppetdb"

# NOTE: this is just documentation on defaults
EXPOSE 8140

ENTRYPOINT ["dumb-init", "/docker-entrypoint.sh"]
CMD ["foreground"]

COPY puppetserver/docker-entrypoint.sh puppetserver/healthcheck.sh /
COPY puppetserver/docker-entrypoint.d /docker-entrypoint.d

# k8s uses livenessProbe, startupProbe, readinessProbe and ignores HEALTHCHECK
HEALTHCHECK --interval=20s --timeout=15s --retries=12 --start-period=3m CMD ["/healthcheck.sh"]

# no need to pin versions or clear apt cache as its still being used
# hadolint ignore=DL3008,DL3009
RUN chmod +x /docker-entrypoint.sh /healthcheck.sh /docker-entrypoint.d/*.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        dumb-init \
        git \
        netbase \
        openjdk-17-jre-headless \
    ;

ADD https://apt.puppetlabs.com/puppet7-release-$UBUNTU_CODENAME.deb /puppet.deb

# hadolint ignore=DL3008,DL3028
RUN dpkg -i /puppet.deb && \
    rm /puppet.deb && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        puppetserver="$version"-1"$UBUNTU_CODENAME" \
        puppetdb-termini \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install --no-doc r10k && \
    puppet config set autosign true --section master && \
    cp -pr /etc/puppetlabs/puppet /var/tmp && \
    cp -pr /opt/puppetlabs/server/data/puppetserver /var/tmp && \
    rm -rf /var/tmp/puppet/ssl

COPY puppetserver/puppetserver /etc/default/puppetserver
COPY puppetserver/logback.xml \
     puppetserver/request-logging.xml \
     /etc/puppetlabs/puppetserver/
COPY puppetserver/puppetserver.conf /etc/puppetlabs/puppetserver/conf.d/
COPY puppetserver/puppetdb.conf /var/tmp/puppet/

LABEL org.label-schema.name="Puppet Server ($build_type)" \
      org.label-schema.version="$version" \
      org.label-schema.vcs-ref="$vcs_ref" \
      org.label-schema.build-date="$build_date"

