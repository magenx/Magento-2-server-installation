#!/bin/bash
MAILTO="MAGENTO_ADMIN_EMAIL"
MAILFROM="MAGENTO_DOMAIN"
SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
SERVICE=$1

SERVICE_STATUS=$(systemctl status ${SERVICE})

############################################################################################
## PUSHOVER NOTIFICATIONS
## Before continuing, you’ll need a user key and API key from the official Pushover website.

## Sign up for an account using https://pushover.net/login
## Make note of the user key found in the top right after logging in
## Create an app using https://pushover.net/apps
## Make note of the API key shown after creating an app

## Pushover extra settings
#PUSHOVER_URL="https://api.pushover.net/1/messages.json"
#PUSHOVER_TOKEN=""
#PUSHOVER_USER=""

#    curl -s -F "token=${PUSHOVER_TOKEN}" \
#    -F "user=${PUSHOVER_USER}" \
#    -F "title=[ALERT] on ${MAILFROM} ${SERVER_IP_ADDR}" \
#    -F "message=${SERVICE_STATUS}" ${PUSHOVER_URL} \
#    -F "priority=1"

# Simple email function
sendmail ${MAILTO} <<EOF
From:${MAILFROM}
To:${MAILTO}
Subject:[ALERT] - ${SERVICE} failed to start on ${MAILFROM} ${SERVER_IP_ADDR}
Importance: High
Content-type: text/plain

Status report for unit: ${SERVICE}

${SERVICE_STATUS}
EOF
