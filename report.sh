#!/usr/bin/env bash


OS=$(cat /etc/os-release | grep -oP '^(?:NAME=")\K(\w+)(")')


DOCKER_V

STORAGE_SPACE

ROOT_ACCESS_INSTALL

SELINUX

cat <<EOF
OS Ver.:\t$OS
Docker Ver.:\t$DOCKER_V
Space Found:\t$STORAGE_SPACE
Root Avail?:\t$ROOT_ACCESS_INTALL
SELinux On?:\t$SELIUX
EOF


