#!/bin/bash

cd "$(dirname "$0")"

docker run --rm -it --name=clamav-sigs -v ${PWD}:/usr/local/bin/ --entrypoint=/usr/local/bin/pipeline.sh ubuntu:latest

