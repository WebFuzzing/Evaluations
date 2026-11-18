FROM amazoncorretto:25-jdk

ARG VERSION=15.6.0
ARG TAR_FILE=/cats.tar.gz

RUN yum install -y tar gzip && yum clean all

ADD https://github.com/Endava/cats/releases/download/cats-${VERSION}/cats_uberjar_${VERSION}.tar.gz  ${TAR_FILE}

RUN tar -xzf ${TAR_FILE} -C / && rm ${TAR_FILE}

ENTRYPOINT ["/bin/sh", "-c", \
    "java  \
    -jar /cats.jar \
    --srs --srw \
    --reportFormat WFC_REPORT \
    --contract ${SCHEMA_FILE_PATH} \
    --output ${OUTPUT_FOLDER} \
    --server http://${HOST}:${PORT} \
    ${TIME_SECONDS:+--stopAfterTimeInSec} ${TIME_SECONDS} \
    ${TIME_SECONDS:+--fillTimeBudget} \
    ${AUTH_FILE_PATH:+--wfcAuth} ${AUTH_FILE_PATH} \
    ${EXTRA_CONFIGS} \
    " \
]
