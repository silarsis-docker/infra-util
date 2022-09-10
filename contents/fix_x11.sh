#!/bin/bash

# vscode on windows in wsl does this, haven't tracked down why yet
if [[ ${DISPLAY} == "1" ]]; then export DISPLAY=:0; fi

if ! xset q >/dev/null; then
    # If we have a HOSTNAME var, use that to generate DISPLAY = ${HOSTNAME}:0
    if [[ -n ${HOSTNAME} ]]; then
        export DISPLAY=${HOSTNAME}:0
        if xset q >/dev/null; then
            export DISPLAY=${HOSTNAME}.local:0
            if xset q >/dev/null; then
                echo "X11 not working, not sure how to fix (tried HOSTNAME)"
            fi
        fi
    else
        echo "X11 not working, not sure how to fix (no HOSTNAME)"
    fi
fi