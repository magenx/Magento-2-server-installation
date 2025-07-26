#!/bin/bash
#=================================================================================#
#        MagenX e-commerce stack for Magento 2                                    #
#        Copyright (C) 2013-present admin@magenx.com                              #
#        All rights reserved.                                                     #
#=================================================================================#
SELF=$(basename $0)
MAGENX_VERSION=$(curl -s https://api.github.com/repos/magenx/Magento-2-server-installation/tags 2>&1 | head -3 | grep -oP '(?<=")\d.*(?=")')
MAGENX_BASE="https://magenx.sh"
###################################################################################
###                              REPOSITORY AND PACKAGES                        ###
###################################################################################

# Github installation repository raw url
MAGENX_INSTALL_GITHUB_REPO="https://raw.githubusercontent.com/magenx/Magento-2-server-installation/master"

# Magento
VERSION_LIST=$(curl -s https://api.github.com/repos/magento/magento2/tags 2>&1 | grep -oP '(?<=name": ").*(?=")' | sort -r)
PROJECT="composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"

COMPOSER_NAME="8c681734f22763b50ea0c29dff9e7af2" 
COMPOSER_PASSWORD="02dfee497e669b5db1fe1c8d481d6974" 

## Version lock
COMPOSER_VERSION="2.7"
RABBITMQ_VERSION="4*"
ERLANG_VERSION="1:27*"
MARIADB_VERSION="11.4"
PHP_VERSION="8.4"
OPENSEARCH_VERSION="2.x"
VARNISH_VERSION="76"
REDIS_VERSION="8"
NODE_VERSION="20"
NVM_VERSION="0.40.3"

# Repositories
MARIADB_REPO_CONFIG="https://r.mariadb.com/downloads/mariadb_repo_setup"

# Nginx configuration
NGINX_VERSION=$(curl -s http://nginx.org/en/download.html | grep -oP '(?<=gz">nginx-).*?(?=</a>)' | head -1)
MAGENX_NGINX_GITHUB_REPO="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/"
MAGENX_NGINX_GITHUB_REPO_API="https://api.github.com/repos/magenx/Magento-nginx-config/contents/magento2"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"

# Malware detector
MALDET="https://www.rfxn.com/downloads/maldetect-current.tar.gz"

# WebStack Packages .deb
WEB_STACK_CHECK="mysql* rabbitmq* elasticsearch opensearch percona-server* maria* php* nginx* ufw varnish* certbot* redis* webmin"

EXTRA_PACKAGES="curl jq gnupg2 auditd apt-transport-https apt-show-versions ca-certificates lsb-release make autoconf snapd automake libtool uuid-runtime \
perl openssl unzip screen nfs-common inotify-tools iptables smartmontools mlocate vim wget sudo apache2-utils \
logrotate git netcat-openbsd patch ipset postfix strace rsyslog moreutils lsof sysstat acl attr iotop expect imagemagick snmp ssl-cert-check"

PERL_MODULES="liblwp-protocol-https-perl libdbi-perl libconfig-inifiles-perl libdbd-mysql-perl libterm-readkey-perl"

PHP_PACKAGES=(cli fpm common mysql zip lz4 gd mbstring curl xml bcmath intl ldap soap oauth apcu)
###################################################################################
###                                    COLORS                                   ###
###################################################################################
RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"
### Background
DGREYBG="  \e[100m"
BLUEBG="  \e[1;44m"
REDBG="  \e[41m"
### Styles
BOLD="\e[1m"
### Reset
RESET="\e[0m"
###################################################################################
###                            ECHO MESSAGES DESIGN                             ###
###################################################################################
WHITETXT () {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "  ${WHITE}${MESSAGE}${RESET}"
}
BLUETXT () {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "  ${BLUE}${MESSAGE}${RESET}"
}
REDTXT () {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "  ${RED}${MESSAGE}${RESET}"
}
GREENTXT () {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "  ${GREEN}${MESSAGE}${RESET}"
}
YELLOWTXT () {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "  ${YELLOW}${MESSAGE}${RESET}"
}
BLUEBG () {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}
pause () {
   read -p "  $*"
}
_echo () {
  echo -en "  $@"
}

PACKAGES_INSTALLED () {
GREENTXT "Installed: "
apt -qq list --installed $@ 2>/dev/null | awk '{print "   " $0}'
}
###################################################################################
###                            ARROW KEYS UP/DOWN MENU                          ###
###################################################################################
updown_menu () {
i=1;for items in $(echo $1); do item[$i]="${items}"; let i=$i+1; done
i=1
echo -e "\n  Use up/down arrow keys then press [ Enter ] to select $2"
while [ 0 ]; do
  if [ "$i" -eq 0 ]; then i=1; fi
  if [ ! "${item[$i]}" ]; then let i=i-1; fi
  echo -en "\r                                 " 
  echo -en "\r${item[$i]}"
  read -sn 1 selector
  case "${selector}" in
    "B") let i=i+1;;
    "A") let i=i-1;;
    "") echo; read -sn 1 -p "  [?] To confirm [ "$(echo -e $BOLD${item[$i]}$RESET)" ] press "$(echo -e $BOLD$GREEN"y"$RESET)" or "$(echo -e $BOLD$RED"n"$RESET)" for new selection" confirm
      if [[ "${confirm}" =~ ^[Yy]$  ]]; then
        printf -v "$2" '%s' "${item[$i]}"
        break
      else
        echo
        echo -e "\n  Use up/down arrow keys then press [ Enter ] to select $2"
      fi
      ;;
  esac
done }
###################################################################################
###           CHECK IF ROOT AND CREATE DATABASE TO SAVE ALL SETTINGS            ###
###################################################################################
echo ""
echo ""
# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "[!] This script must be run as root user!"
  YELLOWTXT "[!] Login as root and run this script again."
  exit 1
else
  GREENTXT "PASS: ROOT!"
fi

# Config path
MAGENX_CONFIG_PATH="/opt/magenx/config"
if [ ! -d "${MAGENX_CONFIG_PATH}" ]; then
  mkdir -p ${MAGENX_CONFIG_PATH}
fi

# SQLite check, create database path and command
if ! which sqlite3 >/dev/null; then
  echo ""
  YELLOWTXT "[!] SQLite is not installed on this system!"
  YELLOWTXT "[!] Installing..."
  echo ""
  echo ""
  apt update
  apt -y install sqlite3
fi

SQLITE3_DB="magenx.db"
SQLITE3_DB_PATH="${MAGENX_CONFIG_PATH}/${SQLITE3_DB}"
SQLITE3="sqlite3 ${SQLITE3_DB_PATH}"
if [ ! -f "${SQLITE3_DB_PATH}" ]; then
  ${SQLITE3} "" ""

# Create base tables to save configuration
${SQLITE3} "CREATE TABLE IF NOT EXISTS system(
   machine_id             text,
   distro_name            text,
   distro_version         text,
   web_stack              text,
   timezone               text,
   system_test            text,
   ssh_port               text,
   terms                  text,
   system_update          text,
   php_version            text,
   nginx_version          text,
   mariadb_version        text,
   webmin_password        text,
   mysql_root_password    text,
   opensearch_admin_password text
   );"
   
${SQLITE3} "CREATE TABLE IF NOT EXISTS magento(
   redis_password            text,
   rabbitmq_password         text,
   indexer_password          text,
   version_installed         text,
   domain                    text,
   owner                     text,
   php_user                  text,
   root_path                 text,
   database_host             text,
   database_name             text,
   database_user             text,
   database_password         text,
   admin_login               text,
   admin_password            text,
   admin_email               text,
   locale                    text,
   admin_path                text,
   crypt_key                 text,
   tfa_key                   text,
   private_ssh_key           text,
   public_ssh_key            text,
   github_actions_private_ssh_key    text,
   github_actions_public_ssh_key     text
   );"
   
${SQLITE3} "CREATE TABLE IF NOT EXISTS menu(
   lemp        text,
   magento     text,
   database    text,
   install     text,
   config      text,
   csf         text,
   webmin      text
   );"
   
${SQLITE3} "INSERT INTO menu (lemp, magento, database, install, config, csf, webmin)
 VALUES('-', '-', '-', '-', '-', '-', '-');"
fi
###################################################################################
###                              CHECK IF WE CAN RUN IT                         ###
###################################################################################
## Ubuntu Debian
## Distro detectction
distro_error() {
  echo ""
  REDTXT "[!] ${OS_NAME} ${OS_VERSION} detected"
  echo ""
  echo " Unfortunately, your operating system distribution and version are not supported by this script"
  echo " Supported: Ubuntu 22|24; Debian 12|13"
  echo " Please email admin@magenx.com and let us know if you run into any issues"
  echo ""
  exit 1
}

# Check if distribution name and version are already in the database
DISTRO_INFO=($(${SQLITE3} -list -separator '  ' "SELECT distro_name, distro_version FROM system;"))
if [ -n "${DISTRO_INFO[0]}" ]; then
  DISTRO_NAME="${DISTRO_INFO[0]}"
  DISTRO_VERSION="${DISTRO_INFO[1]}"
  GREENTXT "PASS: [ ${DISTRO_NAME} ${DISTRO_VERSION} ]"
else
  # Detect distribution name and version
  if [ -f "/etc/os-release" ]; then
    . /etc/os-release
    DISTRO_NAME="${NAME}"
    DISTRO_VERSION="${VERSION_ID}"

    # Check if distribution is supported
    if [ "${DISTRO_NAME%% *}" == "Ubuntu" ] && [[ "${DISTRO_VERSION}" =~ ^(22.04|24.04) ]]; then
      DISTRO_NAME="Ubuntu"
    elif [ "${DISTRO_NAME%% *}" == "Debian" ] && [[ "${DISTRO_VERSION}" =~ ^(12|13) ]]; then
      DISTRO_NAME="Debian"
    else
      distro_error
    fi

    # Confirm distribution detection with user input
    echo ""
    _echo "${YELLOW}[?]${REDBG}${BOLD}[ ${DISTRO_NAME} ${DISTRO_VERSION} ]${RESET} ${YELLOW}detected correctly ? [y/n][n]: ${RESET}"
    read distro_detect
    if [ "${distro_detect}" = "y" ]; then
      echo ""
      GREENTXT "PASS: [ ${DISTRO_NAME} ${DISTRO_VERSION} ]"
      # Get machine id
      MACHINE_ID="$(cat /etc/machine-id)"
      ${SQLITE3} "INSERT INTO system (machine_id, distro_name, distro_version) VALUES ('${MACHINE_ID}', '${DISTRO_NAME}', '${DISTRO_VERSION}');"
    else
      distro_error
    fi
  else
    distro_error
  fi
fi

# network is up?
host1=${MAGENX_BASE}
host2=github.com

RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo ""
  REDTXT "[!] Network is down ?"
  YELLOWTXT "[!] Please check your network settings."
  echo ""
  echo ""
  exit 1
fi

# install packages to run CPU and HDD test
dpkg-query -l curl time bc bzip2 tar >/dev/null || { echo; echo; apt update -o Acquire::ForceIPv4=true; apt -y install curl time bc bzip2 tar; }

# check if you need self update
MD5_NEW=$(curl -sL ${MAGENX_BASE} > ${SELF}.new && md5sum ${SELF}.new | awk '{print $1}')
MD5=$(md5sum ${SELF} | awk '{print $1}')
 if [[ "${MD5_NEW}" == "${MD5}" ]]; then
   GREENTXT "PASS: INTEGRITY CHECK FOR '${SELF}' OK"
   rm ${SELF}.new
  elif [[ "${MD5_NEW}" != "${MD5}" ]]; then
   echo ""
   YELLOWTXT "Integrity check for '${SELF}'"
   YELLOWTXT "detected different md5 checksum"
   YELLOWTXT "remote repository file has some changes"
   echo ""
   REDTXT "IF YOU HAVE LOCAL CHANGES REMOVE INTEGRITY CHECK OR SKIP UPDATES"
   echo ""
   _echo "[?] Would you like to update the file now?  [y/n][y]: "
   read update_agree
  if [ "${update_agree}" == "y" ];then
   mv ${SELF}.new ${SELF}
   echo ""
   GREENTXT "The file has been upgraded, please run it again"
   echo ""
  exit 1
  else
   echo ""
   YELLOWTXT "New file saved to ${SELF}.new"
   echo
  fi
fi

# check if memory is enough
TOTALMEM=$(awk '/MemTotal/{print $2}' /proc/meminfo | xargs -I {} echo "scale=4; {}/1024^2" | bc | xargs printf "%1.0f")
if [ "${TOTALMEM}" -ge "4" ]; then
  GREENTXT "PASS: TOTAL RAM [${TOTALMEM}Gb]"
 else
  echo
  REDTXT "[!] Total RAM less than ${BOLD}4Gb"
  YELLOWTXT "[!] To run complete stack you need more RAM"
  echo
fi

# check if web stack is clean
WEB_STACK=$(${SQLITE3} "SELECT web_stack FROM system;")
if [ "${WEB_STACK}" != "magenx" ]; then
  installed_packages="$(apt -qq list --installed ${WEB_STACK_CHECK} 2> /dev/null | cut -d'/' -f1 | tr '\n' ' ')"
  if [ ! -z "$installed_packages" ]; then
    REDTXT  "[!] Some webstack packages already installed"
    YELLOWTXT "[!] You need to remove them or reinstall minimal OS version"
    echo
    echo -e "\t\t apt -y remove ${installed_packages}"
    echo
    echo
    exit 1
  else
    # set web_stack clean
    ${SQLITE3} "UPDATE system SET web_stack = 'magenx';"
  fi
fi

# print path
GREENTXT "PATH: ${PATH}"

# configure system/magento timezone
TIMEZONE="$(${SQLITE3} "SELECT timezone FROM system;")"
if [ -z "${TIMEZONE}" ]; then
  echo ""
  echo ""
  YELLOWTXT "[!] Server and Magento timezone configuration:"
  echo ""
  pause "[] Press [Enter] key to proceed"
  echo ""
  dpkg-reconfigure tzdata
  TIMEZONE=$(timedatectl | awk '/Time zone:/ {print $3}')
  ${SQLITE3} "UPDATE system SET timezone = '${TIMEZONE}';"
fi
GREENTXT "TIMEZONE: ${TIMEZONE}"

echo
echo
SYSTEM_TEST=$(${SQLITE3} "SELECT system_test FROM system;")
if [ -z "${SYSTEM_TEST}" ]; then
 echo
 BLUEBG "~    QUICK SYSTEM TEST    ~"
 WHITETXT "-------------------------------------------------------------------------------------"
 echo
  # run I/O and CPU tests
  TEST_FILE="TEST_FILE__$$"
  TAR_FILE="TAR_FILE"
  _echo "${YELLOW}[?] I/O PERFORMANCE${RESET}:"
  IO=$( ( dd if=/dev/zero of=${TEST_FILE} bs=64k count=16k conv=fdatasync && rm -f ${TEST_FILE} ) 2>&1 | awk -F, '{IO=$NF} END { print IO}' )
  _echo ${IO}
  echo
  _echo "${YELLOW}[?] CPU PERFORMANCE${RESET}:"
  dd if=/dev/urandom of=${TAR_FILE} bs=1024 count=25000 >>/dev/null 2>&1
  CPU_TIME=$( (/usr/bin/time -f "%es" tar cfj ${TAR_FILE}.bz2 ${TAR_FILE}) 2>&1 )
  rm -f ${TAR_FILE}*
  _echo ${CPU_TIME}
 echo
 echo
 echo
 # set system_test tested
 ${SQLITE3} "UPDATE system SET system_test = 'I/O:${IO} CPU:${CPU_TIME}';"
 echo
 pause "[] Press [Enter] key to proceed"
 echo
fi
echo

# ssh port test
SSH_PORT=$(${SQLITE3} "SELECT ssh_port FROM system;")
if [ -z "${SSH_PORT}" ]; then
echo ""
OVERRIDE_DIR="/etc/ssh/sshd_config.d"
echo ""
YELLOWTXT "SSH config optimization:"
tee ${OVERRIDE_DIR}/10-magenx-security.conf << 'EOF'
LoginGraceTime 30
MaxAuthTries 6
X11Forwarding no
PrintLastLog yes
TCPKeepAlive yes
ClientAliveInterval 600
ClientAliveCountMax 3
UseDNS no
PrintMotd no
#Subsystem sftp /usr/lib/openssh/sftp-server -l INFO
EOF

echo ""
echo ""
CURRENT_PORT=$(sshd -T | grep '^port ' | awk '{print $2}')
if [ "${CURRENT_PORT}" = "22" ]; then
  SSH_PORT=$(shuf -i 9537-9554 -n 1)
tee ${OVERRIDE_DIR}/20-magenx-custom-port.conf << EOF
Port ${SSH_PORT}
EOF
  echo "Changed SSH port from 22 to ${SSH_PORT}"
fi

chmod 600 ${OVERRIDE_DIR}/*magenx*.conf

systemctl restart sshd.service
  echo
  GREENTXT "SSH configurations were updated - OK"
  echo
  GREENTXT "[!] SSH Port: ${SSH_PORT}"
  echo
  systemctl restart sshd.service
  ss -tlp | grep sshd
  echo
echo
REDTXT "[!] IMPORTANT: Now open new SSH session with the new port!"
REDTXT "[!] IMPORTANT: Do not close your current session!"
echo
_echo "[?] Have you logged in another session? [y/n][n]: "
read ssh_test
if [ "${ssh_test}" == "y" ]; then
  echo
   GREENTXT "[!] SSH Port: ${SSH_PORT}"
   echo
   ${SQLITE3} "UPDATE system SET ssh_port = '${SSH_PORT}';"
   echo
   echo
   pause "[] Press [Enter] key to proceed"
  else
   echo
   rm ${OVERRIDE_DIR}/*magenx*.conf
   REDTXT "Restoring sshd_config file back to defaults ${GREEN} [ok]"
   systemctl restart sshd.service
   echo
   GREENTXT "SSH configuration has been restored - OK"
   ss -tlp | grep sshd
  fi
fi

# Enter domain name and ssh user per environment
DOMAIN=($(${SQLITE3} "SELECT domain FROM magento;"))
if [ "${DOMAIN}" = "" ]; then
 echo ""
 echo ""
 echo ""
 read -e -p "$(echo -e ${YELLOW}"  [?] Store domain name: "${RESET})" -i "yourdomain.tld" DOMAIN
 read -e -p "$(echo -e ${YELLOW}"  [?] Files owner/SSH user: "${RESET})" -i "${DOMAIN//[-.]/}" OWNER
 
 ${SQLITE3} "INSERT INTO magento (domain, owner, php_user, root_path) VALUES ( '${DOMAIN}', '${OWNER}', 'php-${OWNER}', '/home/${OWNER}/public_html' );"
 else
   GREENTXT "DOMAIN: ${DOMAIN}"
fi
 echo ""
 echo ""
###################################################################################
###                                  AGREEMENT                                  ###
###################################################################################
echo ""
TERMS=$(${SQLITE3} "SELECT terms FROM system;")
if [ "${TERMS}" != "agreed" ]; then
echo
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
  YELLOWTXT "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
  YELLOWTXT "YOU ACKNOWLEDGE AND AGREE:"
  echo
  YELLOWTXT "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
  YELLOWTXT "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
  echo
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
   echo
    _echo "[?] Do you agree to these terms ?  [y/n][y]: "
    read terms_agree
    if [ "${terms_agree}" == "y" ]; then
      # set terms agreed
      ${SQLITE3} "UPDATE system SET terms = 'agreed';"
    else
      REDTXT "Going out."
      echo
      exit 1
  fi
fi
###################################################################################
###                                  MAIN MENU                                  ###
###################################################################################
showMenu () {
MENU_CHECK=($(${SQLITE3} -list -separator '  ' "SELECT lemp, magento, database, install, config, csf, webmin FROM menu;"))
printf "\033c"
    echo ""
      echo ""
        echo -e "${DGREYBG}${BOLD}  MAGENTO SERVER CONFIGURATION v.${MAGENX_VERSION}  ${RESET}"
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo ""
        WHITETXT "[${MENU_CHECK[0]}] Install repository and LEMP packages :  ${YELLOW}\tlemp"
        WHITETXT "[${MENU_CHECK[1]}] Download Magento latest version      :  ${YELLOW}\tmagento"
        WHITETXT "[${MENU_CHECK[2]}] Setup Magento database               :  ${YELLOW}\tdatabase"
        WHITETXT "[${MENU_CHECK[3]}] Install Magento no sample data       :  ${YELLOW}\tinstall"
        WHITETXT "[${MENU_CHECK[4]}] Post-Installation config             :  ${YELLOW}\tconfig"
        echo ""
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo ""
        WHITETXT "[${MENU_CHECK[5]}] Install CSF Firewall                 :  ${YELLOW}\tfirewall"
        WHITETXT "[${MENU_CHECK[6]}] Install Webmin control panel         :  ${YELLOW}\twebmin"
        echo ""
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo ""
        WHITETXT "[-] To quit and exit                     :  ${RED}\texit"
      echo ""
    echo ""
}
while [ 1 ]
do
  showMenu
  read CHOICE
  case "${CHOICE}" in
  "lemp")
echo ""
echo ""
###################################################################################
###                                  SYSTEM UPGRADE                             ###
###################################################################################
# Get distro_name to make sure its set
DISTRO_NAME=$(${SQLITE3} "SELECT distro_name FROM system;")

# check if system update still required
SYSTEM_UPDATE=$(${SQLITE3} "SELECT system_update FROM system;")
if [ -z "${SYSTEM_UPDATE}" ]; then
  ## install all extra packages
  echo ""
BLUEBG "[~]    SYSTEM UPDATE AND PACKAGES INSTALLATION   [~]"
WHITETXT "-------------------------------------------------------------------------------------"
  echo ""
  debconf-set-selections <<< "postfix postfix/mailname string localhost"
  debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
  apt update && apt upgrade -y
  apt -y install software-properties-common
  apt-add-repository -y contrib
  apt update
  DEBIAN_FRONTEND=noninteractive apt -y install ${EXTRA_PACKAGES} ${PERL_MODULES}
  echo ""
 if [ "$?" != 0 ]; then
  echo ""
  REDTXT "[!] Installation error."
  REDTXT "[!] Please correct errors and run it again."
  exit 1
  echo ""
 fi
  # Set system_update to full release version
  [ "${DISTRO_NAME}" == "Debian" ] && FULL_VERSION="$(cat /etc/debian_version )" || FULL_VERSION="$(lsb_release -d | awk '/(20|22)\.04.+/{print $3}')"
  ${SQLITE3} "UPDATE system SET system_update = 'installed @ ${FULL_VERSION}';"
  echo ""
fi
  echo ""
  echo ""
BLUEBG "[~]    LEMP WEB STACK INSTALLATION    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
  echo ""
  echo ""
  _echo "${YELLOW}[?] Install MariaDB ${MARIADB_VERSION} database ? [y/n][n]:${RESET} "
  read mariadb_install
if [ "${mariadb_install}" == "y" ]; then
  echo ""
  read -e -p "$(echo -e ${YELLOW}"  [?] Enter required MARIADB version: "${RESET})" -i "${MARIADB_VERSION}" MARIADB_VERSION
  # Set mariadb-server-version
  ${SQLITE3} "UPDATE system SET mariadb_version = '${MARIADB_VERSION}';"
  curl -LsS "${MARIADB_REPO_CONFIG}" | bash -s -- --mariadb-server-version="mariadb-${MARIADB_VERSION}" --skip-maxscale --skip-verify --skip-eol-check
  echo ""
 if [ "$?" = 0 ] # if repository installed then install package
   then
    echo ""
    GREENTXT "MariaDB repository installed  -  OK"
    echo ""
    YELLOWTXT "MariaDB ${MARIADB_VERSION} database installation:"
    echo ""
    apt update
    systemctl stop mariadb
    apt install -y mariadb-server
  if [ "$?" = 0 ] # if package installed then configure
    then
     echo ""
     GREENTXT "MariaDB installed  -  OK"
     echo ""
     systemctl enable mariadb
     echo ""
     PACKAGES_INSTALLED mariadb*
     echo "127.0.0.1 mariadb" >> /etc/hosts
     echo ""
     WHITETXT "Downloading my.cnf file from MagenX Github repository"
     curl -sSo /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
     echo ""
     WHITETXT "[?] Calculating [innodb_buffer_pool_size]:"
     INNODB_BUFFER_POOL_SIZE=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
     if [ "${INNODB_BUFFER_POOL_SIZE}" == "0" ]; then IBPS=1; fi
     sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${INNODB_BUFFER_POOL_SIZE}G/" /etc/my.cnf
     ##sed -i "s/innodb_buffer_pool_instances = 4/innodb_buffer_pool_instances = ${INNODB_BUFFER_POOL_SIZE}/" /etc/my.cnf
     echo ""
     WHITETXT "innodb_buffer_pool_size = ${INNODB_BUFFER_POOL_SIZE}G"
     WHITETXT "innodb_buffer_pool_instances = ${INNODB_BUFFER_POOL_SIZE}"
     echo ""
    else
     echo ""
     REDTXT "MariaDB installation error"
    exit # if package is not installed then exit
  fi
    else
     echo ""
     REDTXT "MariaDB repository installation error"
    exit # if repository is not installed then exit
   fi
    else
     echo
     YELLOWTXT "MariaDB installation was skipped by user input. Proceeding to next step."
fi
  echo
WHITETXT "============================================================================="
  echo
  _echo "${YELLOW}[?] Install Nginx ${NGINX_VERSION} ? [y/n][n]:${RESET} "
  read nginx_install
if [ "${nginx_install}" == "y" ]; then
  echo ""
  read -e -p "$(echo -e ${YELLOW}"  [?] Enter required NGINX version: "${RESET})" -i "${NGINX_VERSION}" NGINX_VERSION
  # Set nginx version
  ${SQLITE3} "UPDATE system SET nginx_version = '${NGINX_VERSION}';"
  echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/${DISTRO_NAME,,} `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
  curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
   if [ "$?" = 0 ]; then # if repository installed then install package
    echo
    GREENTXT "Nginx repository installed  -  OK"
    echo
    YELLOWTXT "Nginx ${NGINX_VERSION} installation:"
    echo
    apt update
    apt -y install nginx nginx-module-perl nginx-module-image-filter
    if [ "$?" = 0 ]; then
     echo
     GREENTXT "Nginx ${NGINX_VERSION} installed  -  OK"
     echo
     systemctl enable nginx >/dev/null 2>&1
     PACKAGES_INSTALLED nginx*
    else
     echo
     REDTXT "Nginx ${NGINX_VERSION} installation error"
    exit # if package is not installed then exit
  fi
    else
     echo
     REDTXT "Nginx repository installation error"
    exit
    fi
   else
    echo
    YELLOWTXT "Nginx installation was skipped by user input. Proceeding to next step."
fi
echo
WHITETXT "============================================================================="
echo
_echo "${YELLOW}[?] Install PHP ? [y/n][n]:${RESET} "
read php_install
if [ "${php_install}" == "y" ]; then
  echo ""
  read -e -p "$(echo -e ${YELLOW}"  [?] Enter required PHP version: "${RESET})" -i "${PHP_VERSION}" PHP_VERSION
  # Set php_version
  ${SQLITE3} "UPDATE system SET php_version = '${PHP_VERSION}';"
  echo ""
 if [ "${DISTRO_NAME}" == "Debian" ]; then
  curl -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
 else
  add-apt-repository ppa:ondrej/php -y
 fi
 if [ "$?" = 0 ]; then
   echo ""
   GREENTXT "PHP repository installed  -  OK"
   echo ""
   echo ""
   YELLOWTXT "PHP ${PHP_VERSION} installation:"
   echo
   apt update
   apt -y install php${PHP_VERSION} ${PHP_PACKAGES[@]/#/php${PHP_VERSION}-} php-pear
  if [ "$?" = 0 ]; then
    echo ""
    GREENTXT "PHP ${PHP_VERSION} installed  -  OK"
    echo ""
    PACKAGES_INSTALLED php${PHP_VERSION}*
    echo ""
    # composer download
    echo ""
    YELLOWTXT "Composer ${COMPOSER_VERSION} installation:"
    echo ""
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --${COMPOSER_VERSION} --install-dir=/usr/bin --filename=composer
    php -r "unlink('composer-setup.php');"
   else
    echo ""
    REDTXT "PHP installation error"
   exit 1 # if package is not installed then exit
   fi
    else
     echo
     REDTXT "PHP repository installation error"
    exit 1 # if repository is not installed then exit
  fi
   else
    echo
    YELLOWTXT "PHP installation was skipped by user input. Proceeding to next step."
fi
echo
echo
WHITETXT "============================================================================="
echo
_echo "${YELLOW}[?] Install Redis ${REDIS_VERSION} ? [y/n][n]:${RESET} "
read redis_install
if [ "${redis_install}" == "y" ]; then
  curl -fL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
 if [ "$?" = 0 ]; then # 
     echo
     GREENTXT "Redis repository installed - OK"
     echo
     YELLOWTXT "Redis installation:"
     echo
     apt update
     apt -y install redis
     echo ""
     if [ "$?" = 0 ]; then
      echo ""
      GREENTXT "Redis installed  -  OK"
      echo ""
      PACKAGES_INSTALLED redis-server*
      echo ""
      echo ""
      YELLOWTXT "Redis configuration per environment:"
      echo ""

systemctl stop redis-server
systemctl disable redis-server

# Create Redis config
cat > /etc/systemd/system/redis@.service <<END
[Unit]
Description=Advanced key-value store at %i
After=network.target

[Service]
Type=notify
User=redis
Group=redis

# Security options
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadOnlyPaths=/

# Resource limits
LimitNOFILE=65535

# Directories to create and permissions
RuntimeDirectory=redis
RuntimeDirectoryMode=2755
UMask=007

# Directories and files that Redis can read and write
ReadWritePaths=-/var/lib/redis
ReadWritePaths=-/var/log/redis
ReadWritePaths=-/run/redis

# Command-line options
PIDFile=/run/redis/%i.pid
ExecStartPre=/usr/bin/test -f /etc/redis/%i.conf
ExecStart=/usr/bin/redis-server /etc/redis/%i.conf --daemonize yes --supervised systemd

# Timeouts
Restart=on-failure
TimeoutStartSec=5s
TimeoutStopSec=5s

[Install]
WantedBy=multi-user.target

END

mkdir -p /var/lib/redis
chmod 750 /var/lib/redis
chown redis /var/lib/redis
mkdir -p /etc/redis/
rm /etc/redis/redis.conf

PORT=6379
# Loop through services to create redis config
REDIS_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@%&?' | fold -w 32 | head -n 1)"
${SQLITE3} "UPDATE magento SET redis_password = '${REDIS_PASSWORD}';"
for SERVICE in session cache
do
if [ "${SERVICE}" = "session" ]; then
# Perfect options for sessions
CONFIG_OPTIONS="
save 900 1
save 300 10
save 60 10000

appendonly yes
appendfsync everysec
"
else
# Default options for cache
CONFIG_OPTIONS="save \"\""
fi

cat > /etc/redis/${SERVICE}.conf<<END

bind 127.0.0.1
port ${PORT}

daemonize yes
supervised auto
protected-mode yes
timeout 0

requirepass ${REDIS_PASSWORD}

dir /var/lib/redis
logfile /var/log/redis/${SERVICE}.log
pidfile /run/redis/${SERVICE}.pid

${CONFIG_OPTIONS}

maxmemory 1024mb
maxmemory-policy allkeys-lru

lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
lazyfree-lazy-user-del yes

rename-command SLAVEOF ""
rename-command CONFIG ""
rename-command PUBLISH ""
rename-command SAVE ""
rename-command SHUTDOWN ""
rename-command DEBUG ""
rename-command BGSAVE ""
rename-command BGREWRITEAOF ""
END

((PORT++))

chown redis /etc/redis/${SERVICE}.conf
chmod 640 /etc/redis/${SERVICE}.conf

echo "127.0.0.1 ${SERVICE}" >> /etc/hosts

systemctl daemon-reload
systemctl enable redis@${SERVICE}
systemctl restart redis@${SERVICE}
done
   else
    echo
    REDTXT "Redis installation error"
   exit 1 # if package is not installed then exit
   fi
 else
  echo
  REDTXT "Redis repository installation error"
 exit 1
 fi
  else
   echo
   YELLOWTXT "Redis installation was skipped by user input. Proceeding to next step."
fi
echo
WHITETXT "============================================================================="
echo
echo
_echo "${YELLOW}[?] Install RabbitMQ ${RABBITMQ_VERSION} ? [y/n][n]:${RESET} "
read rabbitmq_install
if [ "${rabbitmq_install}" == "y" ];then
  curl -1sLf 'https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/setup.deb.sh' | bash
  curl -1sLf 'https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/setup.deb.sh' | bash
 cat > /etc/apt/preferences.d/erlang <<END
Package: erlang*
Pin: version ${ERLANG_VERSION}
Pin-Priority: 999
END
  if [ "$?" = 0 ]; then
    echo
    GREENTXT "RabbitMQ repository installed - OK"
    echo
    YELLOWTXT "RabbitMQ ${RABBITMQ_VERSION} installation:"
    echo ""
    apt update
    apt -y install rabbitmq-server=${RABBITMQ_VERSION}  --fix-missing
    if [ "$?" = 0 ]; then
     echo ""
     GREENTXT "RabbitMQ ${RABBITMQ_VERSION} installed  -  OK"
     echo ""
     PACKAGES_INSTALLED rabbitmq* erlang*
     echo "127.0.0.1 rabbitmq" >> /etc/hosts
     echo ""
     echo ""
     YELLOWTXT "RabbitMQ ${RABBITMQ_VERSION} configuration per environment:"
     echo ""
     systemctl stop rabbitmq-server
     systemctl stop epmd*
     epmd -kill

cat > /etc/rabbitmq/rabbitmq-env.conf <<END
NODENAME=rabbit@localhost
NODE_IP_ADDRESS=127.0.0.1
ERL_EPMD_ADDRESS=127.0.0.1
PID_FILE=/var/lib/rabbitmq/mnesia/rabbitmq_pid
END

echo '[{kernel, [{inet_dist_use_interface, {127,0,0,1}}]},{rabbit, [{tcp_listeners, [{"127.0.0.1", 5672}]}]}].' > /etc/rabbitmq/rabbitmq.config

cat >> /etc/sysctl.conf <<END
net.ipv6.conf.lo.disable_ipv6 = 0
END

sysctl -q -p

cat > /etc/systemd/system/epmd.service <<END
[Unit]
Description=Erlang Port Mapper Daemon
After=network.target
Requires=epmd.socket

[Service]
ExecStart=/usr/bin/epmd -address 127.0.0.1 -daemon
Type=simple
StandardOutput=journal
StandardError=journal
User=epmd
Group=epmd

[Install]
Also=epmd.socket
WantedBy=multi-user.target
END

cat > /etc/systemd/system/epmd.socket <<END
[Unit]
Description=Erlang Port Mapper Daemon Activation Socket

[Socket]
ListenStream=4369
BindIPv6Only=both
Accept=no

[Install]
WantedBy=sockets.target
END

systemctl daemon-reload
systemctl start rabbitmq-server
rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbitmq_pid
sleep 5

# delete guest user
rabbitmqctl delete_user guest

# generate rabbitmq password
  RABBITMQ_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)"
  ${SQLITE3} "UPDATE magento SET rabbitmq_password = '${RABBITMQ_PASSWORD}';"
  OWNER=$(${SQLITE3} "SELECT owner FROM magento;")
  rabbitmqctl add_user ${OWNER} ${RABBITMQ_PASSWORD}
  rabbitmqctl add_vhost /${OWNER}
  rabbitmqctl set_permissions -p /${OWNER} ${OWNER} ".*" ".*" ".*"
   else
    echo ""
    REDTXT "RabbitMQ ${RABBITMQ_VERSION} installation error"
   exit 1 # if package is not installed then exit
   fi
  else
   echo ""
   REDTXT "RabbitMQ repository installation error"
   exit 1
  fi
  else
   echo
   YELLOWTXT "RabbitMQ ${RABBITMQ_VERSION} installation was skipped by user input. Proceeding to next step."
fi
echo
WHITETXT "============================================================================="
echo
echo
_echo "${YELLOW}[?] Install Varnish Cache ? [y/n][n]:${RESET} "
read varnish_install
if [ "${varnish_install}" == "y" ];then 
  curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.deb.sh | bash
  if [ "$?" = 0 ]; then
    echo ""
    GREENTXT "Varnish Cache repository installed - OK"
    echo
    YELLOWTXT "Varnish Cache installation:"
    echo ""
    apt update
    apt -y install varnish
   if [ "$?" = 0 ]; then
     echo
     GREENTXT "Varnish Cache installed  -  OK"
     echo
     curl -sSo /etc/systemd/system/varnish.service ${MAGENX_INSTALL_GITHUB_REPO}/varnish.service
     curl -sSo /etc/varnish/varnish.params ${MAGENX_INSTALL_GITHUB_REPO}/varnish.params
     uuidgen > /etc/varnish/secret
     systemctl daemon-reload
     PACKAGES_INSTALLED varnish*
     echo "127.0.0.1 varnish" >> /etc/hosts
    else
    echo ""
    REDTXT "Varnish Cache installation error"
   exit 1
   fi
  else
   echo ""
   REDTXT "Varnish Cache repository installation error"
   exit 1
  fi
  else
   echo ""
   YELLOWTXT "Varnish installation was skipped by user input. Proceeding to next step."
fi
echo
WHITETXT "============================================================================="
echo
_echo "${YELLOW}[?] Install OpenSearch ${OPENSEARCH_VERSION} ? [y/n][n]:${RESET} "
read opensearch_install
if [ "${opensearch_install}" == "y" ];then
   curl -o- https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor --batch --yes -o /usr/share/keyrings/opensearch-keyring
   echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VERSION}/apt stable main" > /etc/apt/sources.list.d/opensearch-${OPENSEARCH_VERSION}.list
  if [ "$?" = 0 ]; then
    echo ""
    GREENTXT "OpenSearch ${OPENSEARCH_VERSION} repository installed - OK"
    echo ""
    YELLOWTXT "OpenSearch ${OPENSEARCH_VERSION} installation:"
    echo ""
    YELLOWTXT "Re-generating random password for admin user"
    if [[ -z "$(${SQLITE3} "SELECT opensearch_admin_password FROM system;")" ]]; then
      OPENSEARCH_ADMIN_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9-#?$&' | fold -w 20 | head -n 1)"
      ${SQLITE3} "UPDATE system SET opensearch_admin_password = '${OPENSEARCH_ADMIN_PASSWORD}';"
    fi
    
    apt update
    OPENSEARCH_ADMIN_PASSWORD="$(${SQLITE3} "SELECT opensearch_admin_password FROM system;")"
    env OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OPENSEARCH_ADMIN_PASSWORD} apt -y install opensearch
    
    YELLOWTXT "OpenSearch pre-configuration:"
    echo ""
    ## opensearch settings
    OWNER=$(${SQLITE3} "SELECT owner FROM magento LIMIT 1;")
    if ! grep -q "${OWNER}" /etc/opensearch/opensearch.yml >/dev/null 2>&1 ; then
    cp /etc/opensearch/opensearch.yml /etc/opensearch/opensearch.yml_default
cat > /etc/opensearch/opensearch.yml <<END
#--------------------------------------------------------------------#
#----------------------- MAGENX CONFIGURATION -----------------------#
# -------------------------------------------------------------------#
# original config saved: /etc/opensearch/opensearch.yml_default

cluster.name: ${OWNER}
node.name: ${OWNER}-node1
node.attr.rack: r1
node.max_local_storage_nodes: 1

discovery.type: single-node

path.data: /var/lib/opensearch
path.logs: /var/log/opensearch

network.host: 127.0.0.1
http.port: 9200

# WARNING: revise all the lines below before you go into production
plugins.security.ssl.transport.pemcert_filepath: esnode.pem
plugins.security.ssl.transport.pemkey_filepath: esnode-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: root-ca.pem

plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.ssl.http.enabled: false
plugins.security.allow_unsafe_democertificates: true
plugins.security.allow_default_init_securityindex: true

plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
plugins.security.system_indices.enabled: true
plugins.security.system_indices.indices: [".plugins-ml-config", ".plugins-ml-connector", ".plugins-ml-model-group", ".plugins-ml-model", ".plugins-ml-task", ".plugins-ml-conversation-meta", ".plugins-ml-conversation-interactions", ".opendistro-alerting-config", ".opendistro-alerting-alert*", ".opendistro-anomaly-results*", ".opendistro-anomaly-detector*", ".opendistro-anomaly-checkpoints", ".opendistro-anomaly-detection-state", ".opendistro-reports-*", ".opensearch-notifications-*", ".opensearch-notebooks", ".opensearch-observability", ".ql-datasources", ".opendistro-asynchronous-search-response*", ".replication-metadata-store", ".opensearch-knn-models", ".geospatial-ip2geo-data*"]


END

## OpenSearch jvm options
HEAP_SIZE=$(echo "0.30*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
if [ "${HEAP_SIZE}" == "0" ]; then HEAP_SIZE=1; fi

cat <<END > /etc/opensearch/jvm.options.d/${parameter["BRAND"]}.options
-Xms${HEAP_SIZE}g
-Xmx${HEAP_SIZE}g
END

fi
    
   if [ "$?" = 0 ]; then
    echo ""
    GREENTXT "OpenSearch ${OPENSEARCH_VERSION} installed  -  OK"
    echo ""

chown -R :opensearch /etc/opensearch/*
systemctl daemon-reload
systemctl enable opensearch.service
systemctl restart opensearch.service

    if [ "$?" != 0 ]; then
      echo ""
      REDTXT "[!] OpenSearch startup error"
      REDTXT "[!] Please correct error above and try again"
      echo ""
      exit 1
    fi

# generate opensearch password
  INDEXER_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)"
  ${SQLITE3} "UPDATE magento SET indexer_password = '${INDEXER_PASSWORD}';"
  OWNER=$(${SQLITE3} "SELECT owner FROM magento;")
  echo ""
  YELLOWTXT "Waiting for OpenSearch initialization ..."
  timeout 10 sh -c 'until nc -z $0 $1; do sleep 1; done' 127.0.0.1 9200
  curl -XGET -u admin:${OPENSEARCH_ADMIN_PASSWORD} "http://127.0.0.1:9200/_cluster/health?wait_for_status=green&timeout=60s"
  sleep 5
  
  # Create role
  curl -u admin:${OPENSEARCH_ADMIN_PASSWORD} -XPUT "http://127.0.0.1:9200/_plugins/_security/api/roles/indexer_${OWNER}" \
  -H "Content-Type: application/json" \
  -d "$(cat <<EOF
{
    "cluster_permissions": [
      "cluster_composite_ops_monitor",
      "cluster:monitor/main",
      "cluster:monitor/state",
      "cluster:monitor/health"
    ],
    "index_permissions": [
      {
        "index_patterns": ["indexer_${OWNER}*"],
        "fls": [],
        "masked_fields": [],
        "allowed_actions": ["*"]
      },
      {
        "index_patterns": ["*"],
        "fls": [],
        "masked_fields": [],
        "allowed_actions": [
	        "indices:admin/aliases/get",
		"indices:data/read/search",
		"indices:admin/get"]
      }
    ],
    "tenant_permissions": []
}
EOF
)"

echo ""

  # Create user
  curl -u admin:${OPENSEARCH_ADMIN_PASSWORD} -XPUT "http://127.0.0.1:9200/_plugins/_security/api/internalusers/indexer_${OWNER}" \
  -H "Content-Type: application/json" \
  -d "$(cat <<EOF
{
    "password": "${INDEXER_PASSWORD}",
    "opendistro_security_roles": ["indexer_${OWNER}", "own_index"]
}
EOF
)"
echo ""
YELLOWTXT "Created OpenSearch user: indexer_${OWNER} and role: indexer_${OWNER}"
echo ""
YELLOWTXT "Installing OpenSearch plugins:"
/usr/share/opensearch/bin/opensearch-plugin install --batch \
  analysis-icu \
  analysis-phonetic
echo ""
  echo ""
  PACKAGES_INSTALLED opensearch
  echo "127.0.0.1 opensearch" >> /etc/hosts
  else
  echo ""
    REDTXT "OpenSearch ${OPENSEARCH_VERSION} installation error"
   exit 1
   fi
 else
echo ""
REDTXT "OpenSearch ${OPENSEARCH_VERSION} repository installation error"
exit 1
fi
else
echo ""
YELLOWTXT "OpenSearch ${OPENSEARCH_VERSION} installation was skipped by user input. Proceeding to next step."
fi
echo ""
echo ""
${SQLITE3} "UPDATE menu SET lemp = 'x';"
## keep versions for critical services to avoid issues
apt-mark hold opensearch erlang rabbitmq-server
echo ""
echo ""
GREENTXT "~    REPOSITORIES AND PACKAGES INSTALLATION IS COMPLETED    ~"
WHITETXT "-------------------------------------------------------------------------------------"
echo ""
echo ""
pause '[] Press [Enter] key to show the menu'
printf "\033c"
;;
###################################################################################
###                                  MAGENTO DOWNLOAD                           ###
###################################################################################
"magento")
printf "\033c"
echo
BLUEBG "[~]  MAGENTO 2 CONFIGURATION  [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo ""
# configure
 DOMAIN="$(${SQLITE3} "SELECT domain FROM magento;")"
 OWNER="$(${SQLITE3} "SELECT owner FROM magento;")"
 PHP_USER="$(${SQLITE3} "SELECT php_user FROM magento;")"
 ROOT_PATH="$(${SQLITE3} "SELECT root_path FROM magento;")"
 ## create magento/ssh user
 useradd -d ${ROOT_PATH%/*} -s /bin/bash ${OWNER}
 mkdir -p ${ROOT_PATH}
 ## create magento php user
 useradd -M -s /sbin/nologin -d ${ROOT_PATH%/*} ${PHP_USER}
 usermod -g ${PHP_USER} ${OWNER}
 chmod 711 ${ROOT_PATH%/*}
 chown -R ${OWNER}:${PHP_USER} ${ROOT_PATH}
 # magento root folder permissions
 chmod 2750 ${ROOT_PATH}
 setfacl -R -m m:r-X,u:${OWNER}:rwX,g:${PHP_USER}:r-X,o::-,d:u:${OWNER}:rwX,d:g:${PHP_USER}:r-X,d:o::- ${ROOT_PATH}
 setfacl -R -m u:nginx:r-X,d:u:nginx:r-X ${ROOT_PATH}

 cd ${ROOT_PATH}
 echo ""
 _echo "[?] Download Magento 2 ? [y/n][n]: "
 read download_magento
 if [ "${download_magento}" == "y" ];then
   echo ""
   echo ""
   YELLOWTXT "[?] Select Magento full version: "
   updown_menu "${VERSION_LIST}" VERSION_INSTALLED
   echo ""
   echo ""
   echo "   [!] Magento [ ${VERSION_INSTALLED} ]"
   echo "   [!] Downloading to [ ${ROOT_PATH} ]"
   echo ""
   echo ""
   pause '[] Press [Enter] key to start downloading'
   echo ""
   ## create some dirs and files
   touch ${ROOT_PATH%/*}/{.bashrc,.bash_profile,.bash_history}
   mkdir -p ${ROOT_PATH%/*}/{.config,.cache,.local,.composer,.nvm}
   chmod 2700 ${ROOT_PATH%/*}/{.config,.cache,.local,.composer,.nvm}
   chmod 600 ${ROOT_PATH%/*}/{.bashrc,.bash_profile,.bash_history}
   chown -R ${OWNER}:${OWNER} ${ROOT_PATH%/*}/{.config,.cache,.local,.composer,.nvm,.bashrc,.bash_profile,.bash_history}
   ##

   su ${OWNER} -s /bin/bash -c "composer -n -q config -g http-basic.repo.magento.com ${COMPOSER_NAME} ${COMPOSER_PASSWORD}"
   su ${OWNER} -s /bin/bash -c "${PROJECT}=${VERSION_INSTALLED} . --no-install"

   # composer replace bloatware
   curl -sO ${MAGENX_INSTALL_GITHUB_REPO}/composer_replace
   sed -i '/"conflict":/ {
   r composer_replace
   N
   }' composer.json

   rm composer_replace

   ### install magento from here ###
   su ${OWNER} -s /bin/bash -c "composer install"
   
    if [ "$?" != 0 ]; then
      echo ""
      REDTXT "[!] Magento composer installation error"
      REDTXT "[!] Please correct error above and try again"
      echo ""
      exit 1
    fi
   
   # make magento great again
   sed -i "s/\[2-6\]/(1\[0-3\]\|\[2-9\])/" app/etc/di.xml
 fi
  
   # reset permissions
   su ${OWNER} -s /bin/bash -c "echo 007 > umask"
   su ${OWNER} -s /bin/bash -c "mkdir -p  generated pub/static var pub/media"
   su ${OWNER} -s /bin/bash -c "mkdir -p var/tmp"
   setfacl -R -m u:${OWNER}:rwX,g:${PHP_USER}:rwX,o::-,d:u:${OWNER}:rwX,d:g:${PHP_USER}:rwX,d:o::- var pub/media

   # save all the variables
   ${SQLITE3} "UPDATE menu SET magento = 'x';"
   ${SQLITE3} "UPDATE magento SET version_installed = '${VERSION_INSTALLED}';" 

echo ""
echo ""
echo ""
GREENTXT "[~]    MAGENTO ${VERSION_INSTALLED} DOWNLOADED AND READY FOR SETUP    [~]"
WHITETXT "--------------------------------------------------------------------"
echo
echo
pause '[] Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
###                                  DATABASE SETUP                             ###
###################################################################################
"database")
printf "\033c"
echo
BLUEBG "[~]    CREATE MYSQL USER AND DATABASE    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
if [ ! -f /root/.my.cnf ]; then
MYSQL_ROOT_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)${RANDOM}"
systemctl restart mariadb
mariadb-admin status --wait=2 &>/dev/null || { REDTXT "\n [!] MYSQL SERVER DOWN \n"; exit 1; }
mariadb --connect-expired-password  <<EOMYSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY "${MYSQL_ROOT_PASSWORD}";
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
exit
EOMYSQL

cat > /root/.my.cnf <<END
[client]
user=root
password="${MYSQL_ROOT_PASSWORD}"
END
cat > /root/.mytop <<END
user=root
pass=${MYSQL_ROOT_PASSWORD}
db=mysql
END
cat > /root/.my.cnf <<END
[client]
user=root
password="${MYSQL_ROOT_PASSWORD}"
END

# set mysql root password
${SQLITE3} "UPDATE system SET mysql_root_password = '${MYSQL_ROOT_PASSWORD}';"
fi

chmod 600 /root/.my.cnf /root/.mytop

# configure database
 echo ""
 OWNER=$(${SQLITE3} "SELECT owner FROM magento;")
 YELLOWTXT "[-] Settings for database:"
 read -e -p "$(echo -e ${YELLOW}"  [?] Host name: "${RESET})" -i "mariadb"  DATABASE_HOST
 read -e -p "$(echo -e ${YELLOW}"  [?] Database name: "${RESET})" -i "${OWNER}"  DATABASE_NAME
 read -e -p "$(echo -e ${YELLOW}"  [?] User name: "${RESET})" -i "${OWNER}"  DATABASE_USER
 read -e -p "$(echo -e ${YELLOW}"  [?] Password: "${RESET})" -i "$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9%^&+_{}()<>-' | fold -w 15 | head -n 1)${RANDOM}"  DATABASE_PASSWORD
 echo ""
for USER_HOST in ${DATABASE_HOST} localhost 127.0.0.1
  do
mariadb <<EOMYSQL
 CREATE USER '${DATABASE_USER}'@'${USER_HOST}' IDENTIFIED BY '${DATABASE_PASSWORD}';
 CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME};
 GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO '${DATABASE_USER}'@'${USER_HOST}' WITH GRANT OPTION;
 exit
EOMYSQL
done

 # save database variables
 ${SQLITE3} "UPDATE menu SET database = 'x';"
 ${SQLITE3} "UPDATE magento SET
  database_host = '${DATABASE_HOST}',
  database_name = '${DATABASE_NAME}',
  database_user = '${DATABASE_USER}',
  database_password = '${DATABASE_PASSWORD}';"

echo ""
echo ""
echo ""
pause '[] Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
###                                  MAGENTO SETUP                              ###
###################################################################################
"install")
printf "\033c"
echo
BLUEBG   "[~]    MAGENTO CONFIGURATION TO SETUP   [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo ""
echo ""
REDIS_PORTS="$(awk '/port /{print $2}' /etc/redis/[case]*.conf)"
for PORT_SELECTED in ${REDIS_PORTS} 9200 5672 3306; do nc -4zvw3 localhost ${PORT_SELECTED}; if [ "$?" != 0 ]; then REDTXT "  [!] SERVICE ${PORT_SELECTED} OFFLINE"; exit 1; fi;  done

  # Create an associative array
  declare -A GET_
  # Get the data for the Magento mode from the magento table | sqlite .mode line key=value
  QUERY=$(${SQLITE3} -line "SELECT * FROM magento;")
  # Loop through the lines of the query output and add the key=value pairs to the associative array
  while IFS='=' read -r KEY VALUE; do
    # Extract the key and value from the line separated by ' = '
    KEY=$(echo "${KEY}" | tr -d '[:space:]')
    VALUE=$(echo "${VALUE}" | tr -d '[:space:]')
    # Skip adding key=value pair if value is empty
    if [[ -n "${VALUE}" ]]; then
      # Add the key=value pair to the associative array
      GET_["${KEY}"]="${VALUE}"
    fi
  done <<< "${QUERY}"
# Use associative array here
if [ -f "${GET_[root_path]}/bin/magento" ]; then
 echo ""
 YELLOWTXT "[-] Configuration for Magento ${GET_[version_installed]}"
 echo ""
 TIMEZONE=$(${SQLITE3} "SELECT timezone FROM system;")
 cd ${GET_[root_path]}
 chown -R ${GET_[owner]}:${GET_[php_user]} *
 chmod u+x bin/magento
 YELLOWTXT "[-] Administrator settings and store base url:"
 read -e -p "$(echo -e ${YELLOW}"  [?] First name: "${RESET})" -i "Magento"  ADMIN_FIRSTNAME
 read -e -p "$(echo -e ${YELLOW}"  [?] Last name: "${RESET})" -i "Administrator"  ADMIN_LASTNAME
 read -e -p "$(echo -e ${YELLOW}"  [?] Email: "${RESET})" -i "admin@${GET_[domain]}"  ADMIN_EMAIL
 read -e -p "$(echo -e ${YELLOW}"  [?] Login name: "${RESET})" -i "admin"  ADMIN_LOGIN
 read -e -p "$(echo -e ${YELLOW}"  [?] Password: "${RESET})" -i "$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9%&?=' | fold -w 10 | head -n 1)${RANDOM}"  ADMIN_PASSWORD
 echo
 YELLOWTXT "[-] Language and currency settings:"
 updown_menu "$(bin/magento info:language:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" LOCALE
 echo ""
 updown_menu "$(bin/magento info:currency:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" CURRENCY
 echo ""
 echo ""
 YELLOWTXT "[-] Magento ${GET_[version_installed]} ready to be installed"
 echo ""
 pause '[!] Press [Enter] key to run setup:install'
 echo
 su ${GET_[owner]} -s /bin/bash -c "bin/magento setup:install --base-url=https://${GET_[domain]}/ \
 --db-host=${GET_[database_host]} \
 --db-name=${GET_[database_name]} \
 --db-user=${GET_[database_user]} \
 --db-password='${GET_[database_password]}' \
 --admin-firstname=${ADMIN_FIRSTNAME} \
 --admin-lastname=${ADMIN_LASTNAME} \
 --admin-email=${ADMIN_EMAIL} \
 --admin-user=${ADMIN_LOGIN} \
 --admin-password='${ADMIN_PASSWORD}' \
 --language=${LOCALE} \
 --currency=${CURRENCY} \
 --timezone=${TIMEZONE} \
 --cleanup-database \
 --use-rewrites=1 \
 --session-save=redis \
 --session-save-redis-host=session \
 --session-save-redis-port=$(awk '/port /{print $2}'  /etc/redis/session.conf) \
 --session-save-redis-log-level=3 \
 --session-save-redis-db=0 \
 --session-save-redis-password='${GET_[redis_password]}' \
 --session-save-redis-compression-lib=lz4 \
 --cache-backend=redis \
 --cache-backend-redis-server=cache \
 --cache-backend-redis-port=$(awk '/port /{print $2}' /etc/redis/cache.conf) \
 --cache-backend-redis-db=0 \
 --cache-backend-redis-password='${GET_[redis_password]}' \
 --cache-backend-redis-compress-data=1 \
 --cache-backend-redis-compression-lib=l4z \
 --amqp-host=rabbitmq \
 --amqp-port=5672 \
 --amqp-user=${GET_[owner]} \
 --amqp-password='${GET_[rabbitmq_password]}' \
 --amqp-virtualhost='/${GET_[owner]}' \
 --consumers-wait-for-messages=0 \
 --search-engine=opensearch \
 --opensearch-host=opensearch \
 --opensearch-port=9200 \
 --opensearch-index-prefix=indexer_${GET_[owner]} \
 --opensearch-enable-auth=1 \
 --opensearch-username=indexer_${GET_[owner]} \
 --opensearch-password='${GET_[indexer_password]}'"

 if [ "$?" != 0 ]; then
   echo ""
   REDTXT "[!] Magento setup:install error"
   REDTXT "[!] Please correct error above and try again"
   echo ""
   exit 1
 fi
 
 # save config variables
 ${SQLITE3} "UPDATE magento SET
  admin_login = '${ADMIN_LOGIN}',
  admin_password = '${ADMIN_PASSWORD}',
  admin_email = '${ADMIN_EMAIL}',
  locale = '${LOCALE}',
  admin_path = '$(grep -Po "(?<='frontName' => ')\w*(?=')" ${GET_[root_path]}/app/etc/env.php)',
  crypt_key = '$(grep -Po "(?<='key' => ')\w*(?=')" ${GET_[root_path]}/app/etc/env.php)';"
  
  ${SQLITE3} "UPDATE menu SET install = 'x';"
fi

echo ""
echo ""
echo ""
    WHITETXT "============================================================================="
    echo
    GREENTXT "Magento ${GET_[version_installed]} installed"
    echo
    WHITETXT "============================================================================="
echo

pause '[] Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
###                                FINAL CONFIGURATION                          ###
###################################################################################
"config")
printf "\033c"
echo ""
BLUEBG "[~]    POST-INSTALLATION CONFIGURATION    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo ""
# network is up?
host1=google.com
host2=github.com

RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo
  REDTXT "[!] NETWORK IS DOWN"
  YELLOWTXT "[!] PLEASE CHECK YOUR NETWORK SETTINGS"
  echo
  echo
  exit 1
fi

# Get variables for configuration
SSH_PORT="$(${SQLITE3} "SELECT ssh_port FROM system;")"
PHP_VERSION="$(${SQLITE3} "SELECT php_version FROM system;")"
TIMEZONE="$(${SQLITE3} "SELECT timezone FROM system;")"

echo ""
YELLOWTXT "[-] Server hostname settings"
DOMAIN="$(${SQLITE3} "SELECT domain FROM magento LIMIT 1;")"
hostnamectl set-hostname "${DOMAIN}" --static
hostname

echo ""
YELLOWTXT "[-] Create motd banner"
curl -o /etc/motd "${MAGENX_INSTALL_GITHUB_REPO}/motd"
sed -i "s/MAGENX_VERSION/${MAGENX_VERSION}/" /etc/motd

echo ""
YELLOWTXT "[-] Sysctl parameters"
tee /etc/sysctl.conf <<END
fs.file-max = 1000000
fs.inotify.max_user_watches = 1000000
vm.swappiness = 10
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65535
kernel.msgmax = 65535
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65535 8388608
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_challenge_ack_limit = 1073741823
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 400000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_sack = 1
net.ipv4.route.flush = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535
END

sysctl -q -p

echo ""
YELLOWTXT "[-] Downloading mysqltuner and mytop"
curl -o /usr/local/bin/mysqltuner ${MYSQL_TUNER}
ln -s /usr/bin/mytop /usr/local/bin/mytop

for dir in cli fpm
do
echo ""
YELLOWTXT "[-] PHP global system settings overrides ${dir} ini"
tee /etc/php/${PHP_VERSION}/$dir/conf.d/zz-magenx-overrides.ini <<END
opcache.enable_cli = 1
opcache.memory_consumption = 512
opcache.interned_strings_buffer = 4
opcache.max_accelerated_files = 60000
opcache.max_wasted_percentage = 5
opcache.use_cwd = 1
opcache.validate_timestamps = 0
;opcache.revalidate_freq = 2
;opcache.validate_permission= 1
opcache.validate_root= 1
opcache.file_update_protection = 2
opcache.revalidate_path = 0
opcache.save_comments = 1
opcache.load_comments = 1
opcache.fast_shutdown = 1
opcache.enable_file_override = 0
opcache.optimization_level = 0xffffffff
opcache.inherited_hack = 1
opcache.blacklist_filename=/etc/opcache-default.blacklist
opcache.max_file_size = 0
opcache.consistency_checks = 0
opcache.force_restart_timeout = 60
opcache.error_log = "/var/log/php-fpm/opcache.log"
opcache.log_verbosity_level = 1
opcache.preferred_memory_model = ""
opcache.protect_memory = 0
;opcache.mmap_base = ""

max_execution_time = 7200
max_input_time = 7200
memory_limit = 2048M
post_max_size = 64M
upload_max_filesize = 64M
expose_php = Off
realpath_cache_size = 4096k
realpath_cache_ttl = 86400
short_open_tag = On
max_input_vars = 50000
session.gc_maxlifetime = 28800
mysql.allow_persistent = On
mysqli.allow_persistent = On
date.timezone = "${TIMEZONE}"
END
done

echo ""
YELLOWTXT "[-] Downloading: /usr/local/bin/n98-magerun2"
curl -o /usr/local/bin/n98-magerun2 https://files.magerun.net/n98-magerun2.phar

echo ""
YELLOWTXT "[-] Creating cache cleaner script: /usr/local/bin/cacheflush"
tee /usr/local/bin/cacheflush <<END
#!/bin/bash
sudo -u \${SUDO_USER} n98-magerun2 --root-dir=/home/\${SUDO_USER}/public_html cache:flush
/usr/bin/systemctl restart php${PHP_VERSION}-fpm.service
nginx -t && /usr/bin/systemctl restart nginx.service || echo "[!] Error: check nginx config"
END

echo ""
YELLOWTXT "[-] Certbot installation with snapd"
snap install --classic certbot

echo ""
YELLOWTXT "[-] Generating dhparam for nginx ssl config"
openssl dhparam -dsaparam -out /etc/ssl/certs/dhparams.pem 4096

echo ""
YELLOWTXT "[-] Generating default selfsigned ssl cert for nginx"
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout /etc/ssl/private/default_server.key -out /etc/ssl/certs/default_server.crt \
-subj "/CN=default_server" -days 3650 -subj "/C=US/ST=Oregon/L=Portland/O=default_server/OU=Org/CN=default_server"

echo ""
YELLOWTXT "[-] Downloading nginx configuration files"
curl -o /etc/nginx/fastcgi_params  ${MAGENX_NGINX_GITHUB_REPO}magento2/fastcgi_params
curl -o /etc/nginx/nginx.conf  ${MAGENX_NGINX_GITHUB_REPO}magento2/nginx.conf
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
curl ${MAGENX_NGINX_GITHUB_REPO_API}/sites-available 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -O "$4)}' >/dev/null
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
mkdir -p /etc/nginx/conf_m2 && cd /etc/nginx/conf_m2/
curl ${MAGENX_NGINX_GITHUB_REPO_API}/conf_m2 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -O "$4)}' >/dev/null
mkdir -p /etc/nginx/ipset && cd /etc/nginx/ipset/
curl ${MAGENX_NGINX_GITHUB_REPO_API}/ipset 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -O "$4)}' >/dev/null

echo ""
YELLOWTXT "[-] Magento profiler configuration in nginx"
PROFILER_PLACEHOLDER="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)"
sed -i "s/PROFILER_PLACEHOLDER/${PROFILER_PLACEHOLDER}/" /etc/nginx/conf_m2/maps.conf
echo "  Magento profiler query => ${PROFILER_PLACEHOLDER}"

echo ""
YELLOWTXT "[-] phpMyAdmin installation and configuration"
PHPMYADMIN_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
BLOWFISH_SECRET=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo "  phpMyAdmin location => ${PHPMYADMIN_FOLDER}"
echo ""
mkdir -p /usr/share/phpMyAdmin && cd $_
composer -n create-project phpmyadmin/phpmyadmin .

tee config.inc.php <<'END'
<?php
declare(strict_types=1);
$cfg['blowfish_secret'] = 'BLOWFISH_SECRET_PLACEHOLDER';
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['UploadDir'] = '/tmp/';
$cfg['SaveDir'] = '/tmp/';
$cfg['TempDir'] = '/tmp/';
END
sed -i "s|BLOWFISH_SECRET_PLACEHOLDER|${BLOWFISH_SECRET}|" config.inc.php

tee /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf <<END
[www]
user = www-data
group = www-data
listen = /var/run/php/php${PHP_VERSION}-fpm.sock
listen.owner = nginx
listen.group = www-data
pm = ondemand
pm.max_children = 5
END

sed -i "s|PHP_FPM_PLACEHOLDER|unix:/var/run/php/php${PHP_VERSION}-fpm.sock|"  /etc/nginx/conf_m2/phpmyadmin.conf

echo ""
YELLOWTXT "[-] Varnish Cache configuration file"
systemctl enable varnish.service
curl -o /etc/varnish/devicedetect.vcl https://raw.githubusercontent.com/varnishcache/varnish-devicedetect/master/devicedetect.vcl
curl -o /etc/varnish/devicedetect-include.vcl ${MAGENX_INSTALL_GITHUB_REPO}/devicedetect-include.vcl
curl -o /etc/varnish/default.vcl ${MAGENX_INSTALL_GITHUB_REPO}/default.vcl
sed -i "s/PROFILER_PLACEHOLDER/${PROFILER_PLACEHOLDER}/" /etc/varnish/default.vcl

echo ""
YELLOWTXT "[-] Realtime malware monitor with email alerts"
cd /usr/local/src
curl -Lo maldetect-current.tar.gz ${MALDET}
tar -zxf maldetect-current.tar.gz
cd maldetect-*/
./install.sh

sed -i 's/email_alert="0"/email_alert="1"/' /usr/local/maldetect/conf.maldet
sed -i 's/quarantine_hits="0"/quarantine_hits="1"/' /usr/local/maldetect/conf.maldet
sed -i '/default_monitor_mode="users"/d' /usr/local/maldetect/conf.maldet
sed -i 's,# default_monitor_mode="/usr/local/maldetect/monitor_paths",default_monitor_mode="/usr/local/maldetect/monitor_paths",' /usr/local/maldetect/conf.maldet
sed -i 's/inotify_base_watches="16384"/inotify_base_watches="35384"/' /usr/local/maldetect/conf.maldet

maldet --monitor /usr/local/maldetect/monitor_paths

echo ""
YELLOWTXT "[-] GoAccess real-time web log analyzer"
curl -o- https://deb.goaccess.io/gnugpg.key | gpg --dearmor | tee /usr/share/keyrings/goaccess.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/goaccess.gpg arch=$(dpkg --print-architecture)] https://deb.goaccess.io/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/goaccess.list
apt update
apt -y install goaccess

##
# Configuration
# Create an associative array
  declare -A GET_
  # Get the data for the Magento mode from the magento table | sqlite .mode line key=value
  QUERY=$(${SQLITE3} -line "SELECT * FROM magento;")
  # Loop through the lines of the query output and add the key=value pairs to the associative array
  while IFS='=' read -r KEY VALUE; do
    # Extract the key and value from the line separated by ' = '
    KEY=$(echo "${KEY}" | tr -d '[:space:]')
    VALUE=$(echo "${VALUE}" | tr -d '[:space:]')
    # Skip adding key=value pair if value is empty
    if [[ -n "${VALUE}" ]]; then
      # Add the key=value pair to the associative array
      GET_["${KEY}"]="${VALUE}"
    fi
  done <<< "${QUERY}"
  echo ""
# Use associative array here
_echo "${YELLOW}[?]${REDBG}${BOLD}[ Configuration ]${RESET} ${YELLOW}${RESET}"
echo ""
echo ""

YELLOWTXT "[-] Php-fpm pool configuration"
tee /etc/php/${PHP_VERSION}/fpm/pool.d/${GET_[owner]}.conf <<END
[${GET_[owner]}]

;;
;; Pool user
user = php-\$pool
group = php-\$pool

listen = /var/run/php/\$pool.sock
listen.owner = nginx
listen.group = php-\$pool
listen.mode = 0660

;;
;; Pool size and settings
pm = ondemand
pm.max_children = 100
pm.max_requests = 1000

;;
;; [php ini] settings
php_admin_flag[expose_php] = Off
php_admin_flag[short_open_tag] = On
php_admin_flag[display_errors] = Off
php_admin_flag[log_errors] = On
php_admin_flag[mysql.allow_persistent] = On
php_admin_flag[mysqli.allow_persistent] = On
php_admin_value[default_charset] = "UTF-8"
php_admin_value[memory_limit] = 1024M
php_admin_value[max_execution_time] = 7200
php_admin_value[max_input_time] = 7200
php_admin_value[max_input_vars] = 50000
php_admin_value[post_max_size] = 64M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[realpath_cache_size] = 4096k
php_admin_value[realpath_cache_ttl] = 86400
php_admin_value[session.gc_maxlifetime] = 28800
php_admin_value[error_log] = "/home/\$pool/public_html/var/log/php-fpm-error.log"
php_admin_value[date.timezone] = "${TIMEZONE}"
php_admin_value[upload_tmp_dir] = "/home/\$pool/public_html/var/tmp"
php_admin_value[sys_temp_dir] = "/home/\$pool/public_html/var/tmp"

;;
;; [opcache] settings
php_admin_flag[opcache.enable] = On
php_admin_flag[opcache.use_cwd] = On
php_admin_flag[opcache.validate_root] = On
php_admin_flag[opcache.revalidate_path] = Off
php_admin_flag[opcache.validate_timestamps] = Off
php_admin_flag[opcache.save_comments] = On
php_admin_flag[opcache.load_comments] = On
php_admin_flag[opcache.fast_shutdown] = On
php_admin_flag[opcache.enable_file_override] = Off
php_admin_flag[opcache.inherited_hack] = On
php_admin_flag[opcache.consistency_checks] = Off
php_admin_flag[opcache.protect_memory] = Off
php_admin_value[opcache.memory_consumption] = 512
php_admin_value[opcache.interned_strings_buffer] = 4
php_admin_value[opcache.max_accelerated_files] = 60000
php_admin_value[opcache.max_wasted_percentage] = 5
php_admin_value[opcache.file_update_protection] = 2
php_admin_value[opcache.optimization_level] = 0xffffffff
php_admin_value[opcache.blacklist_filename] = "/home/\$pool/opcache.blacklist"
php_admin_value[opcache.max_file_size] = 0
php_admin_value[opcache.force_restart_timeout] = 60
php_admin_value[opcache.error_log] = "/home/\$pool/public_html/var/log/opcache.log"
php_admin_value[opcache.log_verbosity_level] = 1
php_admin_value[opcache.preferred_memory_model] = ""
php_admin_value[opcache.jit_buffer_size] = 536870912
php_admin_value[opcache.jit] = 1235
END

systemctl daemon-reload

echo ""
YELLOWTXT "[-] Nginx configuration"
cp /etc/nginx/sites-available/magento2.conf  /etc/nginx/sites-available/${GET_[domain]}.conf
ln -s /etc/nginx/sites-available/${GET_[domain]}.conf /etc/nginx/sites-enabled/${GET_[domain]}.conf

sed -i "s/DOMAIN_PLACEHOLDER/${GET_[domain]}/g" /etc/nginx/sites-available/${GET_[domain]}.conf
sed -i "s/ADMIN_PLACEHOLDER/${GET_[admin_path]}/" /etc/nginx/conf_m2/admin_protect.conf

sed -i "s/DOMAIN_PLACEHOLDER/${GET_[domain]}/g" /etc/nginx/conf_m2/maps.conf
sed -i "s,PHP_FPM_PLACEHOLDER,unix:/var/run/php/${GET_[owner]}.sock,"  /etc/nginx/conf_m2/maps.conf
sed -i "s,MAGE_ROOT_PLACEHOLDER,${GET_[root_path]}," /etc/nginx/conf_m2/maps.conf

echo ""
YELLOWTXT "[-] Add user ${GET_[owner]} to sudo to execute cacheflush"
tee -a /etc/sudoers <<END
${GET_[owner]} ALL=(ALL) NOPASSWD: /usr/local/bin/cacheflush
END

echo ""
YELLOWTXT "[-] Logrotate script for Magento logs"
tee /etc/logrotate.d/${GET_[owner]} <<END
${GET_[root_path]}/var/log/*.log
{
su ${GET_[owner]} ${GET_[php_user]}
create 660 ${GET_[owner]} ${GET_[php_user]}
weekly
rotate 2
notifempty
missingok
compress
}
END

echo ""
YELLOWTXT "[-] Audit configuration for Magento folders and files"
sed -i "s/you@domain.com/${GET_[admin_email]}/" /usr/local/maldetect/conf.maldet
tee -a /usr/local/maldetect/monitor_paths <<END
${GET_[root_path]}
END
tee -a /etc/audit/rules.d/audit.rules <<END
## audit magento files for ${GET_[owner]}
-a never,exit -F dir=${GET_[root_path]}/var/ -k exclude
-w ${GET_[root_path]} -p wa -k ${GET_[owner]}
END
service auditd reload
service auditd restart
auditctl -l

echo ""
if [ -f "${GET_[root_path]}/bin/magento" ]; then
 _echo "${YELLOW}[?] Apply config optimization and settings ? [y/n][n]:${RESET} "
read apply_config
if [ "${apply_config}" == "y" ]; then
 echo ""
 YELLOWTXT "[-] Enable Varnish Cache and add cache hosts to Magento env.php"
 cd ${GET_[root_path]}
 chmod u+x bin/magento
 su ${GET_[owner]} -s /bin/bash -c "${GET_[root_path]}/bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento setup:config:set --http-cache-hosts=varnish:8081"

 chown -R ${GET_[owner]}:${GET_[php_user]} ${GET_[root_path]}
 
 echo ""
 YELLOWTXT "[-] Clean Magento cache add some optimization config"
 rm -rf var/*
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set trans_email/ident_general/email ${GET_[admin_email]}"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set web/url/catalog_media_url_format image_optimization_parameters"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set dev/css/minify_files 1"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set dev/js/minify_files 1"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set dev/js/move_script_to_bottom 1"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set web/secure/enable_hsts 1"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set web/secure/enable_upgrade_insecure 1"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set dev/caching/cache_user_defined_attributes 1"
 su ${GET_[owner]} -s /bin/bash -c "mkdir -p var/tmp"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento setup:upgrade"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento deploy:mode:set production"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento cache:flush"

 rm -rf var/log/*.log
 rm -rf ../{.config,.cache,.local,.composer}/*
 
 echo ""
 YELLOWTXT "[-] Configure Google 2FA code for ${GET_[admin_login]}"
 echo ""
 GOOGLE_TFA_CODE="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&' | fold -w 15 | head -n 1 | base32)"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set twofactorauth/general/force_providers google"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento config:set twofactorauth/google/otp_window 29"
 su ${GET_[owner]} -s /bin/bash -c "bin/magento security:tfa:google:set-secret ${GET_[admin_login]} ${GOOGLE_TFA_CODE}"
 echo "  Google Authenticator mobile app configuration:"
 echo "  - select: Enter a setup key"
 echo "  - type in: Account name"
 echo "  - Paste passkey: ${GOOGLE_TFA_CODE}"
 echo "  - Choose Time based"
 echo ""
 ${SQLITE3} "UPDATE magento SET tfa_key = '${GOOGLE_TFA_CODE}';"
 echo ""
 fi
 sed -i "s/VERSION_INSTALLED/${GET_[version_installed]}/" /etc/motd
fi

echo ""
YELLOWTXT "[-] Varnish Cache config optimization"
sed -i "s/DOMAIN_PLACEHOLDER/${GET_[domain]}/" /etc/varnish/default.vcl

echo ""
YELLOWTXT "[-] Add Magento cronjob to ${GET_[php_user]} user crontab"
BP_HASH="$(echo -n "${GET_[root_path]}" | openssl dgst -sha256 | awk '{print $2}')"
crontab -l -u ${GET_[php_user]} > /tmp/${GET_[php_user]}_crontab
cat << END | tee -a /tmp/${GET_[php_user]}_crontab
#~ MAGENTO START ${BP_HASH}
* * * * * /usr/bin/php${PHP_VERSION} ${GET_[root_path]}/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> ${GET_[root_path]}/var/log/magento.cron.log
#~ MAGENTO END ${BP_HASH}
END
crontab -u ${GET_[php_user]} /tmp/${GET_[php_user]}_crontab
rm /tmp/${GET_[php_user]}_crontab

echo ""
YELLOWTXT "[-] Creating Magento environment variables to /home/${GET_[owner]}/.env"
tee /home/${GET_[owner]}/.env <<END
MODE="${GET_[mode]}"
DOMAIN="${GET_[domain]}"
ADMIN_PATH="${GET_[admin_path]}"
REDIS_PASSWORD="${GET_[redis_password]}"
REDIS_SESSION_PORT="$(awk '/port /{print $2}' /etc/redis/session-${GET_[owner]}.conf)"
REDIS_CACHE_PORT="$(awk '/port /{print $2}' /etc/redis/cache-${GET_[owner]}.conf)"
RABBITMQ_PASSWORD="${GET_[rabbitmq_password]}"
CRYPT_KEY="${GET_[crypt_key]}"
GRAPHQL_ID_SALT="$(awk -F"'" '/id_salt/{print $4}' ${GET_[root_path]}/app/etc/env.php)"
DATABASE_NAME="${GET_[database_name]}"
DATABASE_USER="${GET_[database_user]}"
DATABASE_PASSWORD="${GET_[database_password]}"
INDEXER_PASSWORD="${GET_[indexer_password]}"
INSTALLATION_DATE="$(date -u "+%a, %d %b %Y %H:%M:%S %z")"
END

cp ${GET_[root_path]}/app/etc/env.php /home/${GET_[owner]}/env.php.installed

echo ""
YELLOWTXT "[-] Creating .mytop config to /home/${GET_[owner]}/.mytop"
tee /home/${GET_[owner]}/.mytop <<END
user=${GET_[database_user]}
pass=${GET_[database_password]}
db=${GET_[database_name]}
END

cd /home/${GET_[owner]}/
chown ${GET_[owner]} /home/${GET_[owner]}/.mytop

echo ""
YELLOWTXT "[-] Generating SSH keys for Magento user and Github Actions"
mkdir .ssh
SSH_KEY="private_ssh_key"
ssh-keygen -o -a 256 -t ed25519 -f ${MAGENX_CONFIG_PATH}/${SSH_KEY} -C "ssh for ${GET_[domain]}" -N ""
PRIVATE_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${SSH_KEY}")
PUBLIC_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${SSH_KEY}.pub")
${SQLITE3} "UPDATE magento SET private_ssh_key = '${PRIVATE_SSH_KEY}', public_ssh_key = '${PUBLIC_SSH_KEY}';"
tee -a .ssh/authorized_keys <<END
${PUBLIC_SSH_KEY}
END

GITHUB_ACTIONS_SSH_KEY="github_actions_private_ssh_key"
ssh-keygen -o -a 256 -t ed25519 -f ${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY} -C "github actions for ${GET_[domain]}" -N ""
GITHUB_ACTIONS_PRIVATE_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY}")
GITHUB_ACTIONS_PUBLIC_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY}.pub")
${SQLITE3} "UPDATE magento SET github_actions_private_ssh_key = '${GITHUB_ACTIONS_PRIVATE_SSH_KEY}', github_actions_public_ssh_key = '${GITHUB_ACTIONS_PUBLIC_SSH_KEY}';"
cat ${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY}.pub >> .ssh/authorized_keys

echo ""
YELLOWTXT "[-] Creating bash_profile"
tee .bash_profile <<END
# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
# User specific environment and startup programs
PATH=\$PATH:\$HOME/bin
export PATH
END

echo ""
YELLOWTXT "[-] Creating bashrc"
tee .bashrc <<END
# .bashrc
# history timestamp
export HISTTIMEFORMAT="%d/%m/%y %T "
# got to app root folder
cd ~/public_html/
# change prompt color
PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '
END

touch ${ROOT_PATH%/*}/.bash_history
chmod 600 ${ROOT_PATH%/*}/{.bashrc,.bash_profile,.bash_history}
chown -R ${OWNER}:${OWNER} ${ROOT_PATH%/*}/{.bashrc,.bash_profile,.bash_history}

echo ""
echo ""
YELLOWTXT "[-] Add timestamp to bash history and config alias:"
tee -a  ~/.bashrc <<END
### magenx
export HISTTIMEFORMAT="%d/%m/%y %T "
alias magenx_magento='sqlite3 -line /opt/magenx/config/magenx.db "select * from magento;"'
alias magenx_system='sqlite3 -line /opt/magenx/config/magenx.db "select * from system;"'
END

# clean config directory and set permissions
chmod +x /usr/local/bin/*
find ${MAGENX_CONFIG_PATH}/ -maxdepth 1 -type f ! -name "${SQLITE3_DB}" -delete
chmod -R 600 ${MAGENX_CONFIG_PATH}

systemctl daemon-reload
systemctl restart nginx.service
systemctl restart php*fpm.service
systemctl restart varnish.service

echo ""
echo ""
YELLOWTXT "Magento configuration parameters:"
${SQLITE3} -line "SELECT * FROM magento;"
echo ""
echo ""
YELLOWTXT "For issues and support:"
WHITETXT "https://github.com/magenx/Magento-2-server-installation"
echo ""
echo ""
YELLOWTXT "For Github Actions CI/CD integration:"
WHITETXT "https://www.magenx.com/magento-support-and-server-management.html"
echo ""
echo ""
YELLOWTXT "Write a review:"
WHITETXT "https://trustpilot.com/review/www.magenx.com"
echo ""
echo ""
echo "PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '" >> /etc/bashrc
echo ""
## simple installation stats
DOMAIN=$(${SQLITE3} "SELECT domain FROM magento LIMIT 1;")
DISTRO_NAME=$(${SQLITE3} "SELECT distro_name FROM system;")
curl --silent -X POST https://www.magenx.com/ping_back_os_${DISTRO_NAME}_domain_${DOMAIN}_geo_${TIMEZONE}_keep_30d >/dev/null 2>&1
echo ""
echo "#===================================================================================================================#"
GREENTXT "${BOLD}~~  SERVER IS READY. THANK YOU  ~~"
echo "#===================================================================================================================#"
echo ""
${SQLITE3} "UPDATE menu SET config = 'x';"
echo ""
pause '[] Press [Enter] key to show menu'
;;
###################################################################################
###                               FIREWALL INSTALLATION                         ###
###################################################################################
"firewall")
WHITETXT "============================================================================="
echo ""
echo ""
_echo "[?] Install CSF firewall [y/n][n]: "
read csf_firewall
if [ "${csf_firewall}" == "y" ]; then
  DOMAIN=$(${SQLITE3} "SELECT domain FROM magento LIMIT 1;")
  OWNER=$(${SQLITE3} "SELECT owner FROM magento LIMIT 1;")
  ADMIN_EMAIL=$(${SQLITE3} "SELECT admin_email FROM magento LIMIT 1;")
 echo ""
 YELLOWTXT "Downloading CSF Firewall:"
 echo ""
 cd /usr/local/src/
 curl -sSL https://download.configserver.com/csf.tgz | tar -xz
  echo ""
  cd csf
  YELLOWTXT "Testing if you have required iptables modules:"
  echo ""
 if perl csftest.pl | grep "FATAL" ; then
  perl csftest.pl
  echo
  REDTXT "CSF Firewall fatal errors"
  echo
  pause '[] Press [Enter] key to show menu'
 else
  echo
  YELLOWTXT "CSF Firewall installation: "
  echo
  sh install.sh
  echo
  GREENTXT "CSF Firewall installed - OK"
  echo
  YELLOWTXT "Add ip addresses to whitelist/ignore (paypal,api,erp,backup,github,etc)"
  echo
  read -e -p "   [?] Enter ip address/cidr each after space: " -i "${SSH_CLIENT%% *} 169.254.169.254" IP_ADDR_IGNORE
  for ip_addr_ignore in ${IP_ADDR_IGNORE}; do csf -a ${ip_addr_ignore}; done
  ### csf firewall optimization
  sed -i 's/^TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
  sed -i 's/^CT_LIMIT =.*/CT_LIMIT = "60"/' /etc/csf/csf.conf
  sed -i 's/^CT_INTERVAL =.*/CT_INTERVAL = "30"/' /etc/csf/csf.conf
  sed -i 's/^PORTFLOOD =.*/PORTFLOOD = "443;tcp;100;5"/' /etc/csf/csf.conf
  sed -i 's/^PS_INTERVAL =.*/PS_INTERVAL = "120"/' /etc/csf/csf.conf
  sed -i 's/^PS_LIMIT =.*/PS_LIMIT = "5"/' /etc/csf/csf.conf
  sed -i 's/^PS_PERMANENT =.*/PS_PERMANENT = "1"/' /etc/csf/csf.conf
  sed -i 's/^PS_BLOCK_TIME =.*/PS_BLOCK_TIME = "86400"/' /etc/csf/csf.conf
  sed -i 's/^LF_WEBMIN =.*/LF_WEBMIN = "5"/' /etc/csf/csf.conf
  sed -i 's/^LF_WEBMIN_EMAIL_ALERT =.*/LF_WEBMIN_EMAIL_ALERT = "1"/' /etc/csf/csf.conf
  sed -i "s/^LF_ALERT_TO =.*/LF_ALERT_TO = \"${ADMIN_EMAIL}\"/" /etc/csf/csf.conf
  sed -i "s/^LF_ALERT_FROM =.*/LF_ALERT_FROM = \"firewall@${DOMAIN}\"/" /etc/csf/csf.conf
  sed -i 's/^DENY_IP_LIMIT =.*/DENY_IP_LIMIT = "500000"/' /etc/csf/csf.conf
  sed -i 's/^DENY_TEMP_IP_LIMIT =.*/DENY_TEMP_IP_LIMIT = "2000"/' /etc/csf/csf.conf
  sed -i 's/^LF_IPSET =.*/LF_IPSET = "1"/' /etc/csf/csf.conf
  sed -i 's/^LF_DIRWATCH_FILE =.*/LF_DIRWATCH_FILE = "600"/' /etc/csf/csf.conf
  ### this config for directory monitoring alert on file changes and malware
  echo "/home/${OWNER}/public_html" >> /etc/csf/csf.dirwatch
  echo "/home/${OWNER}/public_html/pub" >> /etc/csf/csf.dirwatch
  echo "/home/${OWNER}/public_html/bin" >> /etc/csf/csf.dirwatch
  echo "/home/${OWNER}/public_html/app" >> /etc/csf/csf.dirwatch
  ### this config for directory monitoring ignore
  echo "/home/${OWNER}/public_html/dev/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/generated/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/lib/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/phpserver/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/pub/errors/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/pub/media/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/pub/static/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/setup/.*" >> /etc/csf/csf.fignore
  echo "/home/${OWNER}/public_html/var/.*" >> /etc/csf/csf.fignore
  ### this line will block every blacklisted ip address
  sed -i "/|0|/s/^#//g" /etc/csf/csf.blocklists
  ### scan custom nginx log
  sed -i 's,CUSTOM1_LOG.*,CUSTOM1_LOG = "/var/log/nginx/access.log",' /etc/csf/csf.conf
  sed -i 's,CUSTOM2_LOG.*,CUSTOM2_LOG = "/var/log/nginx/error.log",' /etc/csf/csf.conf
  ### get custom regex template to ban from nginx log
  curl -o /usr/local/csf/bin/regex.custom.pm ${MAGENX_INSTALL_GITHUB_REPO}/regex.custom.pm
  chmod +x /usr/local/csf/bin/regex.custom.pm
  ### whitelist search bots and legit domains
cat >> /etc/csf/csf.rignore <<END
.googlebot.com
.google.com
.crawl.yahoo.net
.bing.com
.search.msn.com
.yandex.ru
.yandex.net
.yandex.com
.crawl.baidu.com
.crawl.baidu.jp
.github.com
END

csf -ra
curl -o /etc/csf/csf_pignore.sh ${MAGENX_INSTALL_GITHUB_REPO}/csf_pignore.sh
chmod +x /etc/csf/csf_pignore.sh
crontab -l > /tmp/csf_crontab
cat << END | tee -a /tmp/csf_crontab

0 */4 * * * /etc/csf/csf_pignore.sh && crontab -l | grep -v "csf_pignore.sh" | crontab -
END
crontab /tmp/csf_crontab
rm /tmp/csf_crontab
 fi
  else
   echo
   YELLOWTXT "CSF Firewall installation was skipped by user input."
  exit 1
fi
echo
echo
pause '[] Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
###                                  WEBMIN INSTALLATION                        ###
###################################################################################
"webmin")
echo ""
echo ""
_echo "[?] Install Webmin Control Panel ? [y/n][n]: "
DOMAIN=$(${SQLITE3} "SELECT domain FROM magento LIMIT 1;")
OWNER=$(${SQLITE3} "SELECT owner FROM magento LIMIT 1;")
ADMIN_EMAIL=$(${SQLITE3} "SELECT admin_email FROM magento LIMIT 1;")
read webmin_install
if [ "${webmin_install}" == "y" ];then
 echo ""
 YELLOWTXT "Webmin installation:"
 echo ""
 curl -s -O https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
 bash setup-repos.sh
 apt update
 apt -y install webmin
if [ "$?" = 0 ]; then
 WEBMIN_PORT=$(shuf -i 17556-17728 -n 1)
 sed -i 's/theme=gray-theme/theme=authentic-theme/' /etc/webmin/config
 sed -i 's/preroot=gray-theme/preroot=authentic-theme/' /etc/webmin/miniserv.conf
 sed -i "s/port=10000/port=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
 sed -i "s/listen=10000/listen=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
 sed -i '/keyfile=\|certfile=/d' /etc/webmin/miniserv.conf
 echo "keyfile=/etc/letsencrypt/live/${DOMAIN}/privkey.pem" >> /etc/webmin/miniserv.conf
 echo "certfile=/etc/letsencrypt/live/${DOMAIN}/cert.pem" >> /etc/webmin/miniserv.conf
 
  if [ -f "/usr/local/csf/csfwebmin.tgz" ]; then
    perl /usr/share/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >/dev/null 2>&1
    GREENTXT "Installed CSF Firewall plugin"
  fi
  
  echo "webmin_${OWNER}:\$1\$84720675\$F08uAAcIMcN8lZNg9D74p1:::::$(date +%s):::0::::" > /etc/webmin/miniserv.users
  sed -i "s/root:/webmin_${OWNER}:/" /etc/webmin/webmin.acl
  WEBMIN_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@#%^?=+_[]{}()' | fold -w 15 | head -n 1)
  /usr/share/webmin/changepass.pl /etc/webmin/ webmin_${OWNER} "${WEBMIN_PASSWORD}"
  
  systemctl enable webmin
  /etc/webmin/restart

  echo
  GREENTXT "Webmin installed - OK"
  echo
  YELLOWTXT "[!] Webmin Port: ${WEBMIN_PORT}"
  YELLOWTXT "[!] User: webmin_${OWNER}"
  YELLOWTXT "[!] Password: ${WEBMIN_PASSWORD}"
  echo ""
  REDTXT "[!] PLEASE ENABLE TWO-FACTOR AUTHENTICATION!"
  
  ${SQLITE3} "UPDATE system SET webmin_password = '${WEBMIN_PASSWORD}';"
  else
   echo
   REDTXT "Webmin installation error"
  fi
  else
   echo
   YELLOWTXT "Webmin installation was skipped by user input."
fi
echo
echo
pause '[] Press [Enter] key to show menu'
echo
;;
"exit")
REDTXT "[!] Exit"
exit
;;

###################################################################################
###                             CATCH ALL MENU - THE END                        ###
###################################################################################

*)
printf "\033c"
;;
esac
done
