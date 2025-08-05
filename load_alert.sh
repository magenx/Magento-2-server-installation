#!/bin/bash

# Configuration
LOAD_THRESHOLD=3
EMAIL_TO="ADMIN_EMAIL"
EMAIL_SUBJECT="High Load Average Alert on $(hostname)"

# Get the 1-minute load average
LOAD_AVERAGE=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk -F', ' '{ print $1 }' | tr -d ' ')
# Get conneted IPs qty
ESTABLISHED=$(ss -ntp state established 'sport = :443' | awk '{print $4}' | cut -d: -f1 | sort -u | wc -l)

# Compare the load average with the threshold
if (( $(echo "${LOAD_AVERAGE} > ${LOAD_THRESHOLD}" | bc -l) )); then
EMAIL_BODY=$(cat <<EOF
Warning: High load average detected on $(hostname)

Time: $(date)
1-minute load average: ${LOAD_AVERAGE}
Threshold: ${LOAD_THRESHOLD}

Connections: ${ESTABLISHED}
System information:
$(uptime)

EOF
)
  echo "${EMAIL_BODY}" | mail -s "${EMAIL_SUBJECT}" "${EMAIL_TO}"
fi
