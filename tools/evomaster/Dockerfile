FROM webfuzzing/evomaster:v6.1.1


ENTRYPOINT ["/bin/sh", "-c", \
    "java  \
    -jar /evomaster.jar \
    --runningInDocker true \
    --showProgress false \
    --maxTime ${TIME_SECONDS}s \
    --schema ${API_SCHEMA_FILE_PATH} \
    --base http://${HOST}:${PORT} \
    --outputFolder ${OUTPUT_FOLDER} \
    ${AUTH_FILE_PATH:+--configPath} ${AUTH_FILE_PATH} \
    ${EXTRA_CONFIGS} \
    " \
]

