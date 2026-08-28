FROM python:3.14-slim

RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/codingsoo/ARAT-RL.git

WORKDIR ./ARAT-RL

#last commit  Oct 4, 2025. tagged v0.1 has no option to specify timeout
RUN git checkout e5ccb13fa0dd7e3d9cb1b10b9a3252222fc912c9

RUN pip install -r requirements.txt


ENTRYPOINT ["/bin/sh", "-c", \
    "mkdir -p $OUTPUT_FOLDER \
     && cd $OUTPUT_FOLDER \
     && exec python /ARAT-RL/arat-rl.py \
         ${SCHEMA_FILE_PATH} \
         http://${HOST}:${PORT} \
         ${TIME_SECONDS} \
         ${EXTRA_CONFIGS}" \
]