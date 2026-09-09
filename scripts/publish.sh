#!/bin/bash

##############################################################################################
### WARNING: this requires a "docker login" with credentials for "webfuzzing" domain #########
##############################################################################################

#Fail whole script if any command fails
set -e

# The version of Web Fuzzing Evaluations we are using in this study.
WFE_VERSION="0.0.2"
# Prefix use to determine the Docker images of the tools published in WFE
TOOL_NAME_PREFIX="wfe"

docker push webfuzzing/$TOOL_NAME_PREFIX-aratrl:$WFE_VERSION
docker push webfuzzing/$TOOL_NAME_PREFIX-cats:$WFE_VERSION
docker push webfuzzing/$TOOL_NAME_PREFIX-evomaster:$WFE_VERSION
docker push webfuzzing/$TOOL_NAME_PREFIX-restler:$WFE_VERSION
docker push webfuzzing/$TOOL_NAME_PREFIX-schemathesis:$WFE_VERSION
docker push webfuzzing/$TOOL_NAME_PREFIX-wuppiefuzz:$WFE_VERSION

### If all worked with no error, should be able to see new images at:
### https://hub.docker.com/u/webfuzzing