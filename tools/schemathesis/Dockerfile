FROM python:3.14-slim

RUN pip install --no-cache-dir schemathesis==4.25.2

# https://schemathesis.readthedocs.io/en/stable/reference/cli/
# no timeout option? but has something related named "--max-examples"

ENTRYPOINT ["/bin/sh", "-c", \
    "schemathesis run  \
    ${SCHEMA_FILE_PATH} \
    --continue-on-failure  \
    --url http://${HOST}:${PORT} \
    --report-dir ${OUTPUT_FOLDER} \
    ${EXTRA_CONFIGS} \
    " \
]

