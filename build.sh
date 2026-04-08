#!/usr/bin/env bash

set -x
DOCKER_COMMIT=25.12 SDK_VERSION=25.12 docker build -t ghcr.io/dasharo/dasharo-sdk:latest .
