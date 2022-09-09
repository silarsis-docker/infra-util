#!/bin/bash

if [[ $(stat --printf=%g /var/run/docker.sock) != $(getent group docker | cut -d: -f3 | tr -d '\\n') ]]; then
    groupmod -g $(stat --printf=%g /var/run/docker.sock) docker
fi

if id -nG | grep 'docker'; then
    echo "docker group id set properly"
else
    LONG_CID=$(basename $(cat /proc/1/cpuset))
    export CID=${LONG_CID:0:12}
    if [[ -v WORKSPACE_FOLDER ]]; then
        echo "Docker group was wrong, self-kill to restart and reconnect"
        echo "sudo docker kill ${CID}"
        echo
    else
        echo "The docker group was wrong, please reconnect or restart to fix"
        echo
    fi
fi