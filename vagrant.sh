#!/bin/bash

set -ex

VAGRANT_USER=vagrant
VAGRANT_HOME=/home/$VAGRANT_USER

# Create Vagrant user (if not already present)
if ! id -u $VAGRANT_USER >/dev/null 2>&1; then
    /usr/sbin/groupadd $VAGRANT_USER
    /usr/sbin/useradd $VAGRANT_USER -g $VAGRANT_USER -G sudo -d $VAGRANT_HOME --create-home
    echo "${VAGRANT_USER}:${VAGRANT_USER}" | chpasswd
fi

# Set up sudo
echo "${VAGRANT_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers


# Install SSH
DEBIAN_FRONTEND=noninteractive apt-get install openssh-server -y
echo "UseDNS no" >> /etc/ssh/sshd_config


date > /etc/vagrant_box_build_time
