#!/bin/bash

## get n98-magerun2
curl -o /usr/local/bin/magerun2 https://files.magerun.net/n98-magerun2.phar

## reset magento admin password
MAGE_NEW_ADMIN_PASS="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)${RANDOM}"

read -e -p "---> Enter your First Name: " -i "Name"  MAGE_ADMIN_NEW_FNAME
read -e -p "---> Enter your Last Name: " -i "Lastname"  MAGE_ADMIN_NEW_LNAME
read -e -p "---> Enter admin login name : " -i "admin" MAGE_NEW_ADMIN_NAME
read -e -p "---> Enter admin email address : " -i "admin@domain.com" MAGE_NEW_ADMIN_EMAIL

## delete admin
/usr/local/bin/magerun2 admin:user:delete admin -f

## create new admin
bin/magento admin:user:create --admin-user='${MAGE_NEW_ADMIN_NAME}' --admin-password='${MAGE_NEW_ADMIN_PASS}' \
--admin-email='${MAGE_NEW_ADMIN_EMAIL}' --admin-firstname='${MAGE_ADMIN_NEW_FNAME}' --admin-lastname='${MAGE_ADMIN_NEW_LNAME}'

echo " > Magento admin name: ${MAGE_NEW_ADMIN_NAME}"
echo " > Magento admin password: ${MAGE_NEW_ADMIN_PASS}"
echo " > Magento admin email: ${MAGE_NEW_ADMIN_EMAIL}"
