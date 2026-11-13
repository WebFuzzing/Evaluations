#!/bin/bash

##############################################################################################
### WARNING: this requires a "docker login" with credentials for "webfuzzing" domain #########
##############################################################################################

#Fail whole script if any command fails
set -e

# The version of Web Fuzzing Evaluations we are using in this study.
WFE_VERSION="0.1.0"
# Prefix use to determine the Docker images of the tools published in WFE
TOOL_NAME_PREFIX="wfe"

BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

tools=("aratrl" "cats" "evomaster" "restler" "schemathesis" "wuppiefuzz")

for tool in "${tools[@]}"; do
    docker buildx build --platform linux/amd64,linux/arm64 -t "webfuzzing/$TOOL_NAME_PREFIX-$tool:$WFE_VERSION"   --push  $BASE/../tools/$tool
done


### If all worked with no error, should be able to see new images at:
### https://hub.docker.com/u/webfuzzing