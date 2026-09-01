#!/bin/bash

#Fail whole script if any command fails
set -e

# The version of Web Fuzzing Evaluations we are using in this study.
WFE_VERSION="0.0.1"
# Prefix use to determine the Docker images of the tools published in WFE
TOOL_NAME_PREFIX="wfe"

BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

docker build -t webfuzzing/$TOOL_NAME_PREFIX-aratrl:$WFE_VERSION        $BASE/../tools/aratrl
docker build -t webfuzzing/$TOOL_NAME_PREFIX-cats:$WFE_VERSION          $BASE/../tools/cats
docker build -t webfuzzing/$TOOL_NAME_PREFIX-evomaster:$WFE_VERSION     $BASE/../tools/evomaster
docker build -t webfuzzing/$TOOL_NAME_PREFIX-restler:$WFE_VERSION       $BASE/../tools/restler
docker build -t webfuzzing/$TOOL_NAME_PREFIX-schemathesis:$WFE_VERSION  $BASE/../tools/schemathesis
docker build -t webfuzzing/$TOOL_NAME_PREFIX-wuppiefuzz:$WFE_VERSION    $BASE/../tools/wuppiefuzz

