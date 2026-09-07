FROM python:3.14-slim

RUN pip install --no-cache-dir schemathesis==4.26.1

ENTRYPOINT ["/bin/sh", "-c", \
    "schemathesis run  \
    ${SCHEMA_FILE_PATH} \
    --continue-on-failure  \
    --origin http://${HOST}:${PORT} \
    --max-time ${TIME_SECONDS} \
    --report-dir ${OUTPUT_FOLDER} \
    --no-shrink \
    --suppress-health-check all \
    ${AUTH_FILE_PATH:+--auth-wfc} ${AUTH_FILE_PATH} \
    ${EXTRA_CONFIGS} \
    " \
]
