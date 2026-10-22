FROM webfuzzing/evomaster:v6.2.0


ENTRYPOINT ["/bin/sh", "-c", \
    "java  \
    -jar /evomaster.jar \
    --runningInDocker true \
    --showProgress false \
    --maxTime ${TIME_SECONDS}s \
    --schema ${SCHEMA_FILE_PATH} \
    --base http://${HOST}:${PORT} \
    --outputFolder ${OUTPUT_FOLDER} \
    ${AUTH_FILE_PATH:+--configPath} ${AUTH_FILE_PATH} \
    ${EXTRA_CONFIGS} \
    " \
]

