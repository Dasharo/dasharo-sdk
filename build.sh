#!/usr/bin/env bash

DOCKER_COMMIT=24.02.01 CROSSGCC_PARAM=i386 SDK_VERSION=24.02.01 docker build -t ghcr.io/dasharo/dasharo-sdk:latest .
