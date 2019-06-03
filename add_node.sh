#!/usr/bin/env bash

if [ ! "$(whoami)"x == "root"x ]; then
    echo "Please use root user"
    exit -1
fi

if [[ "" = "$1" || "" = "$2" || "" = "$3" || "" = "$4" ]]; then
  echo './add_node.sh [http-bind-address(8084)] [bind-address(8085)] [role(data/meta)]'
        exit -1
fi