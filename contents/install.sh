#!/bin/bash
#
# Script to install from the installer

while [[ $# -gt 0 ]]; do
    opt="$1"
    shift
    case "$opt" in
        "--list" )
            echo "'sudo install.sh' options: SecLists, ghidra, terraform, zap, john";
            exit;;
        "SecLists" )
            rpath="/SecLists";
            lpath="/opt/SecLists";;
        "ghidra" )
            rpath="/ghidra";
            lpath="/opt/ghidra";;
        "terraform" )
            rpath="/terraform";
            lpath="/usr/bin/terraform";;
        "zap" )
            rpath="/zap";
            lpath="/opt/zap";;
        "john" )
            rpath="/opt/john";
            lpath="/opt/john";;
        *) echo >&2 "Unknown installation $opt"
    esac
done

docker pull silarsis/infra-util-installer
id=$(docker create silarsis/infra-util-installer)
docker cp $id:$rpath $lpath
docker rm -v $id