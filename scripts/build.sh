#!/bin/bash

#Fail whole script if any command fails
set -e

VERSION=0.0.1
NAME_PREFIX=wfd-sb

BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

docker build -t webfuzzing/$NAME_PREFIX-aratrl:$VERSION     $BASE/../tools/aratrl
docker build -t webfuzzing/$NAME_PREFIX-evomaster:$VERSION  $BASE/../tools/evomaster
