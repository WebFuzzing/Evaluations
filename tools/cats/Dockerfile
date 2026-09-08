FROM amazoncorretto:25-jdk

ARG VERSION=14.0.0
ARG TAR_FILE=/cats.tar.gz

RUN yum install -y tar gzip && yum clean all

ADD https://github.com/Endava/cats/releases/download/cats-${VERSION}/cats_uberjar_${VERSION}.tar.gz  ${TAR_FILE}

RUN tar -xzf ${TAR_FILE} -C / && rm ${TAR_FILE}

# https://endava.github.io/cats/docs/getting-started/running-cats
# doesn't seem there is any global timeout?
# there is a "--stopAfterTimeInSec" but that is for when testing only specific endpoints, and not whole API?

ENTRYPOINT ["/bin/sh", "-c", \
    "java  \
    -jar /cats.jar \
    --blackbox \
    --reportFormat JUNIT \
    --contract ${SCHEMA_FILE_PATH} \
    --skipReportingForSuccess \
    --output ${OUTPUT_FOLDER} \
    --server http://${HOST}:${PORT} \
    ${AUTH_FILE_PATH:+--wfcAuthName} ${AUTH_FILE_PATH} \
    ${EXTRA_CONFIGS} \
    " \
]

# TODO removed following for now, as generating 10s of GB of data
#    --output ${OUTPUT_FOLDER} \
#