#!/usr/bin/env bash

set -x
DOCKER_COMMIT=24.02.01 SDK_VERSION=24.02.01 docker build -t ghcr.io/dasharo/dasharo-sdk:latest .
