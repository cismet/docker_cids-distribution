FROM reg.cismet.de/abstract/cids-distribution-base:7.0.1-debian

# override account extension and codebase in child autodistribution images!
ENV CIDS_ACCOUNT_EXTENSION  CidsDistribution
ENV CIDS_CODEBASE           http://localhost

#
ENV CIDS_DISTRIBUTION_DIR   /cidsDistribution
ENV CIDS_LIB_DIR            ${CIDS_DISTRIBUTION_DIR}/lib
ENV CIDS_GENERATOR_DIR      ${CIDS_DISTRIBUTION_DIR}/gen
ENV CIDS_SERVER_DIR         ${CIDS_DISTRIBUTION_DIR}/server
ENV CIDS_CLIENT_DIR         ${CIDS_DISTRIBUTION_DIR}/client
ENV MAVEN_LIB_DIR           ${CIDS_LIB_DIR}/m2
ENV PATH                    /cidsDistribution/utils:${PATH}

#
WORKDIR ${CIDS_DISTRIBUTION_DIR}/

#
COPY copy/cidsDistribution/ ./
COPY copy/entrypoints/ /
COPY copy/nginx /etc/nginx/sites-available/

ADD http://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/1.5.0/jolokia-jvm-1.5.0-agent.jar /cidsDistribution/utils/jolokia-jvm-agent.jar
ADD https://github.com/cismet/integrity/archive/dev.zip /cidsDistribution/utils/integrity.zip

#
RUN chmod +x ${CIDS_DISTRIBUTION_DIR}/utils/*.sh \
  && ln -s ${CIDS_DISTRIBUTION_DIR}/utils/cids_ctl.sh ${CIDS_DISTRIBUTION_DIR}/cids_ctl.sh \
  && ln -s ${CIDS_DISTRIBUTION_DIR}/utils/container_ctl.sh /container_ctl.sh \
  && unzip /cidsDistribution/utils/integrity.zip -d /cidsDistribution/utils/ \
  && rm /cidsDistribution/utils/integrity.zip \
  && mv /cidsDistribution/utils/integrity-dev /cidsDistribution/utils/integrity \
  && ln -s /cidsDistribution/utils/integrity/lib/integrity.sh /cidsDistribution/utils/teg
#postgresql-client

# expose cids-server port
EXPOSE 9986

# expose cids-server-rest port
EXPOSE 8890

# expose ngnix port
EXPOSE 80

# add /tmp as volume since it may contain data that changes often 
VOLUME /tmp

#
LABEL maintainer="Jean-Michel Ruiz <jean.ruiz@cismet.de>"
