#!/usr/bin/env bash

display_usage() {
    echo -e "\nUsage: $0 [MASTER BACKUP]\n"
}

# check whether user had supplied -h or --help . If yes display usage
if [[ ($# == "--help") || $# == "-h" ]]; then
    display_usage
    exit 0
fi

# display usage if the script is not run as root user
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

# if less than one argument supplied, display usage
if [ $# -le 0 ]; then
    echo "This script must be run with at least two arguments."
    display_usage
    exit 1
fi

# check if keepalived is installed
if ! command -v keepalived &>/dev/null; then
    echo "keepalived is not installed. Installing..."
    apt-get update
    apt-get install -y keepalived
else
    echo "keepalived is already installed."
fi

# update keepalived.conf
if [ "$STATE" == "MASTER" ]; then
    cp ./conf/keepalived_master.conf /etc/keepalived/keepalived.conf
elif [ "$STATE" == "BACKUP" ]; then
    cp ./conf/keepalived_backup.conf /etc/keepalived/keepalived.conf
fi

# start keepalived
systemctl enable --now keepalived.service

# show some logs
systemctl status keepalived.service
