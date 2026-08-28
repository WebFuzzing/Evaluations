FROM mcr.microsoft.com/dotnet/sdk:8.0

RUN apt-get update && apt-get install -y git python3

RUN git clone https://github.com/microsoft/restler-fuzzer.git

WORKDIR /restler-fuzzer

# Last release from Jan 2025
RUN git checkout v9.3.1

RUN mkdir restler_bin

RUN python3 ./build-restler.py --dest_dir /restler-fuzzer/restler_bin

# https://github.com/microsoft/restler-fuzzer/blob/main/restler-quick-start.py
# no timeout option?

ENTRYPOINT ["/bin/sh", "-c", \
    "mkdir -p $OUTPUT_FOLDER \
     && cd $OUTPUT_FOLDER \
     && exec python3 /restler-fuzzer/restler-quick-start.py  \
         --restler_drop_dir /restler-fuzzer/restler_bin \
         --api_spec_path ${SCHEMA_FILE_PATH} \
         --host ${HOST} \
         --port ${PORT} \
         ${EXTRA_CONFIGS}" \
]

