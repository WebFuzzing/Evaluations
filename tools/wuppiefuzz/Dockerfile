FROM rust:1.98

ARG VERSION=1.8.1

RUN curl --proto '=https' --tlsv1.2 -LsSf https://github.com/TNO-S3/WuppieFuzz/releases/download/v${VERSION}/wuppiefuzz-installer.sh | sh

ENTRYPOINT ["/bin/sh", "-c", \
    "mkdir -p $OUTPUT_FOLDER \
     && ln -s $OUTPUT_FOLDER reports \
     && wuppiefuzz fuzz  \
        ${SCHEMA_FILE_PATH} \
        --target http://${HOST}:${PORT} \
        --timeout ${TIME_SECONDS} \
        --report=true \
        ${AUTH_FILE_PATH:+--authentication} ${AUTH_FILE_PATH} \
        ${EXTRA_CONFIGS} \
    " \
]
