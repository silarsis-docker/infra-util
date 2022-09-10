#!/bin/bash

# vscode on windows in wsl does this, haven't tracked down why yet
if [[ ${DISPLAY} == "1" ]]; then export DISPLAY=:0; fi

if ! xset q >/dev/null 2>&1; then
    export DISPLAY=host.docker.internal:0
    if ! xset q >/dev/null 2>&1; then
        echo "X11 not working for ${DISPLAY}, try 'xhost +localhost' in host"
    fi
fi
echo "DISPLAY=${DISPLAY}"