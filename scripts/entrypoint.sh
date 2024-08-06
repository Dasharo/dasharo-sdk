#!/bin/bash

if [[ -v USER_ID ]]; then
	usermod -u $USER_ID coreboot
fi
if [[ -v GROUP_ID ]]; then
	groupmod -g $GROUP_ID coreboot
fi

runuser -u coreboot -- "$@"
