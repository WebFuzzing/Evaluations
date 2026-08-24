FROM webfuzzing/evomaster:v6.1.1


ENTRYPOINT ["/bin/sh", "-c", \
    "java  \
    -jar /evomaster.jar \
    --runningInDocker true \
    --showProgress false \
    --maxTime ${TIME_MINUTES}m \
    --schema /schemas/${API_SCHEMA_FILE} \
    --base http://${HOST}:${PORT} \
    --outputFolder ${OUTPUT_FOLDER} \
    " \
]

