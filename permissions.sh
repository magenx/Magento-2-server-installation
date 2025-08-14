#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 <MAGENTO_ROOT> <PHP_USER> <MAX_DEPTH>"
    echo "Example: $0 /var/www/html magento 2"
    exit 1
}

# Check arguments
[ $# -ne 3 ] && usage

MAGENTO_ROOT="$1"
PHP_USER="$2"
MAX_DEPTH="$3"
FULL_LOG="/var/tmp/$$.permissions.log"

# Check if setfacl exists
USE_ACL=true
if ! command -v getfacl &>/dev/null; then
    echo ""
    echo "[!] Warning: getfacl not found. ACL details will not be logged."
    echo "[!] Permissions could be exploited if misconfigured."
    USE_ACL=false
    sleep 5
else
    echo ""
    echo "[OK] Good: getfacl found. ACL details will be logged."
fi

echo ""
echo "[?] Checking write permissions for ${PHP_USER} in: ${MAGENTO_ROOT} (Depth: ${MAX_DEPTH})"
echo "--------------------------------------------------"

find "${MAGENTO_ROOT}" -maxdepth "${MAX_DEPTH}" -type d -print0 |
while IFS= read -r -d '' dir; do
    if sudo -u "${PHP_USER}" test -w "$dir" 2>/dev/null; then
        echo "[WRITABLE] ${dir}"
        ${USE_ACL} && getfacl -p "${dir}" >> "${FULL_LOG}"
        echo "----------------------------------------"
    fi
done
echo ""
${USE_ACL} && echo "See full log in ${FULL_LOG}"
echo ""
