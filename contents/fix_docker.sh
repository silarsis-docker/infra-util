#!/bin/bash

if [[ ! -S /var/run/docker.sock ]]; then
    if [[ -S /var/run/docker-host.sock ]]; then
        # We've mounted to docker-host, and we can socat to something owned by our login user
        nohup socat UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user=kevin.littlejohn,group=docker UNIX-CONNECT:/var/run/docker-host.sock >/dev/null 2>&1 &
    else
        echo "No docker socket mounted, docker won't work"
        echo
    fi
else
    if [[ $(stat --printf=%g /var/run/docker.sock) != $(getent group docker | cut -d: -f3 | tr -d '\n') ]]; then
        groupmod -g $(stat --printf=%g /var/run/docker.sock) docker
    fi
    if [[ ! $(id -nG kevin.littlejohn | grep 'docker') ]]; then
        LONG_CID=$(basename $(cat /proc/1/cpuset))
        export CID=${LONG_CID:0:12}
        if [[ -v WORKSPACE_FOLDER ]]; then
            echo "Docker group was wrong, self-kill to restart and reconnect"
            echo "(and fix your devcontainer.json to mount docker.sock to docker-host.sock)"
            echo "sudo docker kill ${CID}"
        else
            echo "The docker group was wrong, please reconnect or restart to fix"
            echo "(and please mount docker.sock to docker-host.sock when running this image)"
        fi
    fi
fi