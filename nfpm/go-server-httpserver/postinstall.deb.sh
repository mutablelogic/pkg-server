#!/bin/bash

# Add nginx user
id -u nginx &>/dev/null || useradd --system nginx

# Change permissions on var folder
if [ -d "/opt/go-server/var" ] ; then
  chown -R nginx:root "/opt/go-server/var"
  chmod 0750 "/opt/go-server/var"
fi

# Enable service
systemctl link /opt/go-server/etc/go-server.service
systemctl enable go-server.service

# Restart server
systemctl restart go-server.service
