#!/bin/bash

#Fail whole script if any command fails
set -e

# TODO info
WFC_SB_VERSION=0.0.1
TOOL_NAME_PREFIX=wfd-sb

BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

docker build -t webfuzzing/$TOOL_NAME_PREFIX-aratrl:$WFC_SB_VERSION        $BASE/../tools/aratrl
docker build -t webfuzzing/$TOOL_NAME_PREFIX-cats:$WFC_SB_VERSION          $BASE/../tools/cats
docker build -t webfuzzing/$TOOL_NAME_PREFIX-evomaster:$WFC_SB_VERSION     $BASE/../tools/evomaster
docker build -t webfuzzing/$TOOL_NAME_PREFIX-restler:$WFC_SB_VERSION       $BASE/../tools/restler
docker build -t webfuzzing/$TOOL_NAME_PREFIX-schemathesis:$WFC_SB_VERSION  $BASE/../tools/schemathesis
docker build -t webfuzzing/$TOOL_NAME_PREFIX-wuppiefuzz:$WFC_SB_VERSION    $BASE/../tools/wuppiefuzz
