#!/bin/bash
#=================================================================================#
#        MagenX e-commerce stack for Magento 2                                    #
#        Copyright (C) 2013-present admin@magenx.com                              #
#        All rights reserved.                                                     #
#=================================================================================#
SELF=$(basename $0)
MAGENX_VER=$(curl -s https://api.github.com/repos/magenx/Magento-2-server-installation/tags 2>&1 | head -3 | grep -oP '(?<=")\d.*(?=")')
MAGENX_BASE="https://magenx.sh"

# Config path
MAGENX_CONFIG_PATH="/opt/magenx/config"

###################################################################################
###                            DEFINE LINKS AND PACKAGES                        ###
###################################################################################

# ELK version lock
ELKREPO="7.x"

# Magento
MAGE_VERSION="2"
MAGE_VERSION_FULL=$(curl -s https://api.github.com/repos/magento/magento${MAGE_VERSION}/tags 2>&1 | head -3 | grep -oP '(?<=")\d.*(?=")')

# Repositories
MARIADB_VERSION="10.5"
REPO_MARIADB_CFG="https://downloads.mariadb.com/MariaDB/mariadb_repo_setup"
REPO_REMI_RPM="http://rpms.famillecollet.com/enterprise/remi-release-8.rpm"

# WebStack Packages
EXTRA_PACKAGES_DEB="curl jq gnupg2 auditd apt-transport-https apt-show-versions ca-certificates lsb-release make autoconf snapd automake libtool uuid-runtime \
perl openssl unzip recode ed e2fsprogs screen inotify-tools iptables smartmontools clamav mlocate vim wget sudo bc apache2-utils \
logrotate git python3-pip python3-dateutil python3-dev patch ipset strace rsyslog geoipupdate moreutils lsof xinetd jpegoptim sysstat acl attr iotop expect webp imagemagick snmp"
PERL_MODULES_DEB="liblwp-protocol-https-perl libdbi-perl libconfig-inifiles-perl libdbd-mysql-perl  libterm-readkey-perl"
PHP_PACKAGES_DEB=(cli fpm json common mysql zip lz4 gd mbstring curl xml bcmath intl ldap soap oauth apcu)

EXTRA_PACKAGES_RPM="autoconf snapd jq automake dejavu-fonts-common dejavu-sans-fonts libtidy libpcap libwebp gettext-devel recode gflags tbb ed lz4 libyaml libdwarf \
bind-utils e2fsprogs svn screen gcc iptraf inotify-tools iptables smartmontools net-tools mlocate unzip vim wget curl sudo bc mailx clamav-filesystem clamav-server \
clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib logrotate git patch ipset strace rsyslog \
ncurses-devel GeoIP GeoIP-devel s3cmd geoipupdate openssl-devel ImageMagick libjpeg-turbo-utils pngcrush jpegoptim moreutils lsof net-snmp net-snmp-utils xinetd \
python3-virtualenv python3-wheel-wheel python3-pip python3-devel ncftp postfix augeas-libs libffi-devel mod_ssl dnf-automatic sysstat libuuid-devel uuid-devel acl attr \
iotop expect unixODBC gcc-c++"
PHP_PACKAGES_RPM=(cli common fpm opcache gd curl mbstring bcmath soap mcrypt mysqlnd pdo xml xmlrpc intl gmp gettext-gettext phpseclib recode \
symfony-class-loader symfony-common tcpdf tcpdf-dejavu-sans-fonts tidy snappy ldap lz4) 
PHP_PECL_PACKAGES_RPM=(pecl-redis pecl-lzf pecl-geoip pecl-zip pecl-memcache pecl-oauth pecl-apcu)
PERL_MODULES_RPM=(LWP-Protocol-https Config-IniFiles libwww-perl CPAN Template-Toolkit Time-HiRes ExtUtils-CBuilder ExtUtils-Embed ExtUtils-MakeMaker \
TermReadKey DBI DBD-MySQL Digest-HMAC Digest-SHA1 Test-Simple Moose Net-SSLeay devel)

# Nginx extra configuration
REPO_MAGENX_TMP="https://raw.githubusercontent.com/magenx/Magento-2-server-installation/master/"
NGINX_VERSION=$(curl -s http://nginx.org/en/download.html | grep -oP '(?<=gz">nginx-).*?(?=</a>)' | head -1)
NGINX_BASE="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/"
GITHUB_REPO_API_URL="https://api.github.com/repos/magenx/Magento-nginx-config/contents/magento2"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"
MYSQL_TOP="https://raw.githubusercontent.com/magenx/Magento-mysql/master/mytop"

# Malware detector
MALDET="https://www.rfxn.com/downloads/maldetect-current.tar.gz"

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
include_config () {
    [[ -f "$1" ]] && . "$1"
}
_echo () {
  echo -en "  $@"
}

###################################################################################
###                            ARROW KEYS UP/DOWN MENU                          ###
###################################################################################

updown_menu () {
i=1;for items in $(echo $1); do item[$i]="${items}"; let i=$i+1; done
i=1
echo -e "\n---> Use up/down arrow keys then press [ Enter ] to select $2"
while [ 0 ]; do
  if [ "$i" -eq 0 ]; then i=1; fi
  if [ ! "${item[$i]}" ]; then let i=i-1; fi
  echo -en "\r                                 " 
  echo -en "\r${item[$i]}"
  read -sn 1 selector
  case "${selector}" in
    "B") let i=i+1;;
    "A") let i=i-1;;
    "") echo; read -sn 1 -p "To confirm [ ${item[$i]} ] press "$(echo -e $BOLD$GREEN"y"$RESET)" or "$(echo -e $BOLD$RED"n"$RESET)" for new selection" confirm
      if [[ "${confirm}" =~ ^[Yy]$  ]]; then
        printf -v "$2" '%s' "${item[$i]}"
        break
      else
        echo
        echo -e "\n---> Use up/down arrow keys then press [ Enter ] to select $2"
      fi
      ;;
  esac
done }

clear
###################################################################################
###                              CHECK IF WE CAN RUN IT                         ###
###################################################################################

echo
echo
# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "[!] THIS SCRIPT MUST BE RUN AS ROOT!"
  YELLOWTXT "[!] USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "PASS: ROOT!"
fi

# some selinux, sir?
if [ ! -f "${MAGENX_CONFIG_PATH}/selinux" ]; then
  mkdir -p ${MAGENX_CONFIG_PATH}
  if [ ! -f "/etc/selinux/config" ]; then
    GREENTXT "PASS: SELINUX IS DISABLED"
    echo "${SELINUX}" > ${MAGENX_CONFIG_PATH}/selinux
   else
    SELINUX=$(awk -F "=" '/^SELINUX=/ {print $2}' /etc/selinux/config)
  if [[ ! "${SELINUX}" =~ (disabled|permissive) ]]; then
    echo
    REDTXT "[!] SELINUX IS NOT DISABLED OR PERMISSIVE"
    YELLOWTXT "[!] PLEASE CHECK YOUR SELINUX SETTINGS"
    echo
    _echo "[?] Would you like to disable SELinux and reboot now?  [y/n][y]:"
    read selinux_disable
    if [ "${selinux_disable}" == "y" ];then
      sed -i "s/SELINUX=${SELINUX}/SELINUX=disabled/" /etc/selinux/config
      echo "disabled" > ${MAGENX_CONFIG_PATH}/selinux
      reboot
    else
   echo
  GREENTXT "PASS: SELINUX IS ${SELINUX^^}"
  echo "${SELINUX}" > ${MAGENX_CONFIG_PATH}/selinux
  fi
 fi
 fi
fi

# network is up?
host1=google.com
host2=github.com

RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo
  REDTXT "[!] NETWORK IS DOWN ?"
  YELLOWTXT "[!] PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi

## Ubuntu Debian RedHat CentOS Amazon
## Distro detect and set installation key
distro_error ()
{
    echo
    REDTXT "[!] ${OS_NAME} ${OS_VERSION} DETECTED"
    echo
    echo " Unfortunately, your operating system distribution and version are not supported by this script"
    echo " Supported: Ubuntu 20.04; Debian 11; RedHat 8; Amazon Linux 2"
    echo " Please email support@magenx.com and let us know if you run into any issues"
    echo
  exit 1
}

if [ -f "${MAGENX_CONFIG_PATH}/distro" ]; then
  . ${MAGENX_CONFIG_PATH}/distro
  GREENTXT "PASS: ${OS_NAME} ${OS_VERSION} DETECTED"
  else
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=${NAME}
    OS_VERSION=${VERSION_ID}

  if [ "${OS_NAME%% *}" == "Ubuntu" ] && [[ "${OS_VERSION}" =~ "20.04" ]]; then
    OS_DISTRO_KEY="ubuntu"
  elif [ "${OS_NAME%% *}" == "Debian" ] && [ "${OS_VERSION}" == "11" ]; then
    OS_DISTRO_KEY="debian"
  elif [ "${OS_NAME%% *}" == "Red" ] && [ "${OS_VERSION}" == "8" ]; then
    OS_DISTRO_KEY="redhat"
  elif [ "${OS_NAME%% *}" == "Amazon" ] && [ "${OS_VERSION}" == "2" ]; then
    OS_DISTRO_KEY="amazon"
  else
    distro_error
  fi
    echo
    _echo "[?]${REDBG}${BOLD}[ ${OS_NAME} ${OS_VERSION} ]${RESET} DETECTED CORRECTLY ? [y/n][n]:"
    read distro_detect
   if [ "${distro_detect}" == "y" ]; then
    echo
    GREENTXT "PASS: ${OS_NAME} ${OS_VERSION} DETECTED"
    mkdir -p ${MAGENX_CONFIG_PATH}
    echo "OS_NAME="${OS_NAME}"" >> ${MAGENX_CONFIG_PATH}/distro
    echo "OS_VERSION=${OS_VERSION}" >> ${MAGENX_CONFIG_PATH}/distro
    echo "OS_DISTRO_KEY=${OS_DISTRO_KEY}" >> ${MAGENX_CONFIG_PATH}/distro
   else
    echo
    distro_error
    echo
   fi
  else
   echo
   distro_error
   echo
  fi
fi

# check if memory is enough
if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
  rpm --quiet -q dnf || yum install -y 'dnf*' yum-utils
  rpm --quiet -q epel-release || dnf -y install epel-release
  rpm --quiet -q curl time bc bzip2 tar || dnf -y install time bc bzip2 tar
 else
  dpkg-query -l curl time bc bzip2 tar >/dev/null || { apt-get update; apt-get -y install curl time bc bzip2 tar; }
fi

# check if you need update
MD5_NEW=$(curl -sL ${MAGENX_BASE} > magenx.sh.new && md5sum magenx.sh.new | awk '{print $1}')
MD5=$(md5sum ${SELF} | awk '{print $1}')
 if [[ "${MD5_NEW}" == "${MD5}" ]]; then
   GREENTXT "PASS: INTEGRITY CHECK FOR '${SELF}' OK"
   rm magenx.sh.new
  elif [[ "${MD5_NEW}" != "${MD5}" ]]; then
   echo
   YELLOWTXT "INTEGRITY CHECK FOR '${SELF}'"
   YELLOWTXT "DETECTED DIFFERENT MD5 CHECKSUM"
   YELLOWTXT "REMOTE REPOSITORY FILE HAS SOME CHANGES"
   REDTXT "IF YOU HAVE LOCAL CHANGES - SKIP UPDATES"
   echo
   _echo "[?] Would you like to update the file now?  [y/n][y]:"
   read update_agree
  if [ "${update_agree}" == "y" ];then
   mv magenx.sh.new ${SELF}
   echo
   GREENTXT "THE FILE HAS BEEN UPGRADED, PLEASE RUN IT AGAIN"
   echo
  exit 1
  else
   echo
   YELLOWTXT "NEW FILE SAVED TO magenx.sh.new"
   echo
  fi
fi
    
TOTALMEM=$(awk '/MemTotal/{print $2}' /proc/meminfo | xargs -I {} echo "scale=4; {}/1024^2" | bc | xargs printf "%1.0f")
if [ "${TOTALMEM}" -ge "4" ]; then
  GREENTXT "PASS: YOU HAVE ${TOTALMEM} Gb OF RAM"
 else
  echo
  REDTXT "[!] YOU HAVE LESS THAN 4Gb OF RAM"
  YELLOWTXT "[!] TO PROPERLY RUN COMPLETE STACK YOU NEED 4Gb+"
  echo
fi

# check if webstack is clean
if ! grep -q "webstack_is_clean" ${MAGENX_CONFIG_PATH}/webstack >/dev/null 2>&1 ; then
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    installed_packages="$(rpm -qa --qf '%{name} ' 'mysqld?|firewalld|Percona*|maria*|php-?|nginx*|*ftp*|varnish*|certbot*|redis*|webmin')"
    else
    installed_packages="$(apt -qq list --installed mysqld? percona-server* maria* php* nginx* ufw varnish* certbot* redis* webmin 2> /dev/null | cut -d'/' -f1 | tr '\n' ' ')"
  fi
  if [ ! -z "$installed_packages" ]; then
    REDTXT  "[!] WEBSTACK PACKAGES ALREADY INSTALLED"
    YELLOWTXT "[!] YOU NEED TO REMOVE THEM OR RE-INSTALL MINIMAL OS VERSION"
    echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    echo -e "\t\t dnf remove ${installed_packages} --noautoremove"
  else
    echo -e "\t\t apt-get purge ${installed_packages}"
  fi
    echo
    echo
  exit 1
    else
      mkdir -p ${MAGENX_CONFIG_PATH}
      echo "webstack_is_clean" > ${MAGENX_CONFIG_PATH}/webstack
  fi
fi

GREENTXT "PATH: ${PATH}"
echo
if ! grep -q "yes" ${MAGENX_CONFIG_PATH}/systest >/dev/null 2>&1 ; then
echo
BLUEBG "~    QUICK SYSTEM TEST    ~"
WHITETXT "-------------------------------------------------------------------------------------"
echo    
    test_file=vpsbench__$$
    tar_file=tarfile
    now=$(date +"%m/%d/%Y")

    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
    tram=$( free -m | awk 'NR==2 {print $2}' )   
    echo  
    _echo "${YELLOW}PROCESSING I/O PERFORMANCE${RESET}:"
    io=$( ( dd if=/dev/zero of=$test_file bs=64k count=16k conv=fdatasync && rm -f $test_file ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
    _echo $io
    echo
    echo
    _echo "${YELLOW}PROCESSING CPU PERFORMANCE${RESET}:"
    dd if=/dev/urandom of=$tar_file bs=1024 count=25000 >>/dev/null 2>&1
    tf=$( (/usr/bin/time -f "%es" tar cfj $tar_file.bz2 $tar_file) 2>&1 )
    rm -f tarfile*
    _echo $tf
    echo
    echo

  WHITETXT "${BOLD}SYSTEM DETAILS"
  WHITETXT "CPU model: $cname"
  WHITETXT "Number of cores: $cores"
  WHITETXT "CPU frequency: $freq MHz"
  WHITETXT "Total amount of RAM: $tram MB"

echo
mkdir -p ${MAGENX_CONFIG_PATH} && echo "yes" > ${MAGENX_CONFIG_PATH}/systest
echo
pause "[] Press [Enter] key to proceed"
echo
fi
echo
# ssh test
if ! grep -q "yes" ${MAGENX_CONFIG_PATH}/sshport >/dev/null 2>&1 ; then
      touch ${MAGENX_CONFIG_PATH}/sshport
      echo
      sed -i "s/.*LoginGraceTime.*/LoginGraceTime 30/" /etc/ssh/sshd_config
      sed -i "s/.*MaxAuthTries.*/MaxAuthTries 6/" /etc/ssh/sshd_config     
      sed -i "s/.*X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
      sed -i "s/.*PrintLastLog.*/PrintLastLog yes/" /etc/ssh/sshd_config
      sed -i "s/.*TCPKeepAlive.*/TCPKeepAlive yes/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveInterval.*/ClientAliveInterval 600/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveCountMax.*/ClientAliveCountMax 3/" /etc/ssh/sshd_config
      sed -i "s/.*UseDNS.*/UseDNS no/" /etc/ssh/sshd_config
      sed -i "s/.*PrintMotd.*/PrintMotd no/" /etc/ssh/sshd_config
      
      echo
      SSH_PORT="$(awk '/#?Port [0-9]/ {print $2}' /etc/ssh/sshd_config)"
      if [ "${SSH_PORT}" == "22" ]; then
        REDTXT "[!] DEFAULT SSH PORT :22 DETECTED"
	 cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BACK
          SSH_PORT_NEW=$(shuf -i 9537-9554 -n 1)
         sed -i "s/.*Port 22/Port ${SSH_PORT_NEW}/g" /etc/ssh/sshd_config
	SSH_PORT=${SSH_PORT_NEW}
      fi

     echo
        GREENTXT "SSH PORT AND SETTINGS WERE UPDATED  -  OK"
	echo
        GREENTXT "[!] SSH MAIN PORT: ${SSH_PORT}"
	echo
        systemctl restart sshd.service
        ss -tlp | grep sshd
     echo
echo
REDTXT "[!] IMPORTANT: NOW OPEN NEW SSH SESSION WITH THE NEW PORT!"
REDTXT "[!] IMPORTANT: DO NOT CLOSE YOUR CURRENT SESSION!"
echo
_echo "[?] Have you logged in another session? [y/n][n]:"
read ssh_test
if [ "${ssh_test}" == "y" ];then
  echo
   GREENTXT "[!] SSH MAIN PORT: ${SSH_PORT}"
   echo
   echo "# yes" > ${MAGENX_CONFIG_PATH}/sshport
   echo "SSH_PORT=${SSH_PORT}" >> ${MAGENX_CONFIG_PATH}/sshport
   echo
   echo
   pause "[] Press [Enter] key to proceed"
  else
   echo
   mv /etc/ssh/sshd_config.BACK /etc/ssh/sshd_config
   REDTXT "RESTORING sshd_config FILE BACK TO DEFAULTS ${GREEN} [ok]"
   systemctl restart sshd.service
   echo
   GREENTXT "SSH PORT HAS BEEN RESTORED  -  OK"
   ss -tlp | grep sshd
  fi
fi
echo
echo
###################################################################################
###                                  AGREEMENT                                  ###
###################################################################################
echo
if ! grep -q "yes" ${MAGENX_CONFIG_PATH}/terms >/dev/null 2>&1 ; then
printf "\033c"
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
    _echo "[?] Do you agree to these terms ?  [y/n][y]:"
    read terms_agree
  if [ "${terms_agree}" == "y" ];then
    echo "yes" > ${MAGENX_CONFIG_PATH}/terms
  else
    REDTXT "Going out. EXIT"
    echo
    exit 1
  fi
fi

###################################################################################
###                                  MAIN MENU                                  ###
###################################################################################

showMenu () {
printf "\033c"
    echo
      echo
        echo -e "${DGREYBG}${BOLD}  MAGENTO SERVER CONFIGURATION v.${MAGENX_VER}  ${RESET}"
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "[-] Install repository and LEMP packages :  ${YELLOW}\tlemp"
        WHITETXT "[-] Download Magento latest packages     :  ${YELLOW}\tmagento"
        WHITETXT "[-] Setup Magento database               :  ${YELLOW}\tdatabase"
        WHITETXT "[-] Install Magento no sample data       :  ${YELLOW}\tinstall"
        WHITETXT "[-] Post-Install configuration           :  ${YELLOW}\tconfig"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "[-] Install CSF Firewall or Fail2Ban     :  ${YELLOW}\tfirewall"
        WHITETXT "[-] Install Webmin control panel         :  ${YELLOW}\twebmin"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "[-] To quit and exit                     :  ${RED}\texit"
        echo
    echo
}
while [ 1 ]
do
    showMenu
    read CHOICE
    case "${CHOICE}" in
    "lemp")
echo
echo
###################################################################################
###                                  SYSTEM UPGRADE                             ###
###################################################################################

if ! grep -q "yes" ${MAGENX_CONFIG_PATH}/sysupdate >/dev/null 2>&1 ; then
  ## install all extra packages
  echo
BLUEBG "[~]    SYSTEM UPDATE AND PACKAGES INSTALLATION   [~]"
WHITETXT "-------------------------------------------------------------------------------------"
  echo
 if [ "${OS_DISTRO_KEY}" == "redhat" ]; then
  dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  dnf config-manager --set-enabled codeready-builder-for-rhel-8-rhui-rpms
  dnf -y install ${EXTRA_PACKAGES_RPM} ${PERL_MODULES_RPM[@]/#/perl-}
  dnf -y module reset nginx php redis varnish
  dnf -y upgrade --nobest
  echo
 elif [ "${OS_DISTRO_KEY}" == "amazon" ]; then
  dnf install -y yum-utils
  amazon-linux-extras install epel -y
  dnf -y install ${EXTRA_PACKAGES_RPM} ${PERL_MODULES_RPM[@]/#/perl-}
  dnf -y upgrade --nobest
  echo
 else
  apt-get -y install software-properties-common
  apt-add-repository contrib
  apt-get update
  apt-get -y install ${EXTRA_PACKAGES_DEB} ${PERL_MODULES_DEB}
  echo
 fi
 if [ "$?" != 0 ]; then
  echo
  REDTXT "[!] INSTALLATION ERROR"
  REDTXT "[!] PLEASE CORRECT AND TRY AGAIN"
  exit 1
  echo
 fi
  curl -o /etc/motd -s ${REPO_MAGENX_TMP}motd
  sed -i "s/MAGE_VERSION_FULL/${MAGE_VERSION_FULL}/" /etc/motd
  sed -i "s/MAGENX_VER/${MAGENX_VER}/" /etc/motd
  echo "yes" > ${MAGENX_CONFIG_PATH}/sysupdate
  echo
fi
  echo
  echo
BLUEBG "[~]    LEMP STACK INSTALLATION    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
  echo
  echo
  _echo "[?] Install MariaDB ${MARIADB_VERSION} database ? [y/n][n]:"
  read repo_mariadb_install
if [ "${repo_mariadb_install}" == "y" ]; then
  echo
  curl -sS ${REPO_MARIADB_CFG} | bash -s -- --mariadb-server-version=${MARIADB_VERSION}
  echo
 if [ "$?" = 0 ] # if repository installed then install package
   then
    echo
    GREENTXT "REPOSITORY INSTALLED  -  OK"
    echo
    echo
    GREENTXT "MariaDB ${MARIADB_VERSION} database installation:"
    echo
   if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    dnf module disable -y mysql
    dnf install -y MariaDB-server
   else
    apt-get update
    apt-get install -y mariadb-server
  fi
  if [ "$?" = 0 ] # if package installed then configure
    then
     echo
     GREENTXT "DATABASE INSTALLED  -  OK"
     echo
     systemctl enable mysql
     echo
    if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
     rpm -qa 'mariadb*' | awk '{print "  Installed: ",$1}'
    else
     apt -qq list --installed mariadb*
    fi
     echo
     WHITETXT "Downloading my.cnf file from MagenX Github repository"
     wget -qO /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
     echo
     WHITETXT "Calculating innodb_buffer_pool_size"
     IBPS=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
     sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf
     ##sed -i "s/innodb_buffer_pool_instances = 4/innodb_buffer_pool_instances = ${IBPS}/" /etc/my.cnf
     echo
     YELLOWTXT "innodb_buffer_pool_size = ${IBPS}G"
     YELLOWTXT "innodb_buffer_pool_instances = ${IBPS}"
     echo
    else
     echo
     REDTXT "DATABASE INSTALLATION ERROR"
    exit # if package is not installed then exit
  fi
    else
     echo
     REDTXT "REPOSITORY INSTALLATION ERROR"
    exit # if repository is not installed then exit
   fi
    else
     echo
     YELLOWTXT "MariaDB repository installation was skipped by the user. Next step"
fi
  echo
WHITETXT "============================================================================="
  echo
  _echo "[?] Install Nginx ${NGINX_VERSION} ? [y/n][n]:"
  read repo_nginx_install
if [ "${repo_nginx_install}" == "y" ]; then
  echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
cat > /etc/yum.repos.d/nginx.repo <<END
[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
END
  else
   echo "deb http://nginx.org/packages/mainline/${OS_DISTRO_KEY} `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
   curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
   echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
  fi
   echo
   GREENTXT "REPOSITORY INSTALLED  -  OK"
   echo
   GREENTXT "Nginx package installation:"
   echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   dnf -y -q install nginx nginx-module-perl nginx-module-image-filter
   rpm  --quiet -q nginx
  else
   apt-get update
   apt-get -y install nginx nginx-module-perl nginx-module-image-filter nginx-module-geoip
  fi
  if [ "$?" = 0 ]; then
    echo
    GREENTXT "NGINX INSTALLED  -  OK"
    echo
    systemctl enable nginx >/dev/null 2>&1
   if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    rpm -qa 'nginx*' | awk '{print "  Installed: ",$1}'
   else
    apt -qq list --installed nginx*
   fi
   else
    echo
    REDTXT "NGINX INSTALLATION ERROR"
   exit
  fi
   else
    echo
    YELLOWTXT "Nginx repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
_echo "[?] Install PHP ? [y/n][n]:"
read repo_install
if [ "${repo_install}" == "y" ]; then
  echo
  GREENTXT "PHP repository installation:"
  echo
  read -e -p "  [?] Enter required PHP version: " -i "7.4" PHP_VERSION
  echo
 if [ "${OS_DISTRO_KEY}" == "redhat" ]; then
  dnf install -y ${REPO_REMI_RPM}
  dnf -y module enable php:remi-${PHP_VERSION}
  dnf config-manager --set-enabled remi >/dev/null 2>&1
  rpm  --quiet -q remi-release
 elif [ "${OS_DISTRO_KEY}" == "amazon" ]; then
  dnf install -y ${REPO_REMI_RPM//8/7}
  dnf config-manager --set-enabled remi >/dev/null 2>&1
  rpm  --quiet -q remi-release
 elif [ "${OS_DISTRO_KEY}" == "debian" ]; then
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
 else
  add-apt-repository ppa:ondrej/php -y
 fi
 if [ "$?" = 0 ]; then
   echo
   GREENTXT "REPOSITORY INSTALLED  -  OK"
   echo
   echo
   GREENTXT "PHP ${PHP_VERSION} installation:"
   echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   dnf -y install php ${PHP_PACKAGES_RPM[@]/#/php-} ${PHP_PECL_PACKAGES_RPM[@]/#/php-}
   rpm  --quiet -q php
  else
   apt-get update
   apt-get -y install php${PHP_VERSION} ${PHP_PACKAGES_DEB[@]/#/php${PHP_VERSION}-} php-pear
  fi
  if [ "$?" = 0 ]; then
    echo
    GREENTXT "PHP ${PHP_VERSION} INSTALLED  -  OK"
    echo
   if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    rpm -qa 'php*' | awk '{print "  Installed: ",$1}'
   else
    apt -qq list --installed php*
   fi
   else
    echo
    REDTXT "PHP INSTALLATION ERROR"
   exit 1 # if package is not installed then exit
   fi
    else
     echo
     REDTXT "REPOSITORY INSTALLATION ERROR"
    exit 1 # if repository is not installed then exit
  fi
   else
    echo
    YELLOWTXT "Remi repository installation was skipped by the user. Next step"
fi
echo
echo
WHITETXT "============================================================================="
echo
_echo "[?] Install Redis ? [y/n][n]:"
read redis_install
if [ "${redis_install}" == "y" ]; then
  echo
  GREENTXT "Redis installation:"
  echo
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
  dnf -y -q module install redis:remi-6.0
  rpm  --quiet -q redis
 else
  apt-get -y install redis-server
 fi
 if [ "$?" = 0 ]; then
     echo
     GREENTXT "REDIS INSTALLED OK"
     systemctl disable redis
     echo
    if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
     rpm -qa 'redis*' | awk '{print "  Installed: ",$1}'
     redis_conf="/etc/redis.conf"
        else
     apt -qq list --installed redis-server*
     redis_conf="/etc/redis/redis.conf"
    fi
echo
cat > /etc/systemd/system/redis@.service <<END
[Unit]
Description=Advanced key-value store at %i
After=network.target

[Service]
Type=forking
User=redis
Group=redis
PrivateTmp=true
RuntimeDirectory=redis-%i
RuntimeDirectoryMode=2755

UMask=007
PrivateTmp=yes
LimitNOFILE=65535
PrivateDevices=yes
ProtectHome=yes
ReadOnlyDirectories=/
ReadWritePaths=-/var/lib/redis
ReadWritePaths=-/var/log/redis
ReadWritePaths=-/run/redis-%i

PIDFile=/run/redis-%i/redis-%i.pid
ExecStart=/usr/bin/redis-server /etc/redis/redis-%i.conf
Restart=on-failure
ProtectSystem=true
ReadWriteDirectories=-/etc/redis

[Install]
WantedBy=multi-user.target

END

for REDISPORT in 6379 6380
do
mkdir -p /var/lib/redis-${REDISPORT}
chmod 755 /var/lib/redis-${REDISPORT}
chown redis /var/lib/redis-${REDISPORT}
mkdir -p /etc/redis/
cp -rf ${redis_conf} /etc/redis/redis-${REDISPORT}.conf
chown redis /etc/redis/redis-${REDISPORT}.conf
chmod 644 /etc/redis/redis-${REDISPORT}.conf
sed -i "s/^bind 127.0.0.1.*/bind 127.0.0.1/"  /etc/redis/redis-${REDISPORT}.conf
sed -i "s/^dir.*/dir \/var\/lib\/redis-${REDISPORT}\//"  /etc/redis/redis-${REDISPORT}.conf
sed -i "s/^logfile.*/logfile \/var\/log\/redis\/redis-${REDISPORT}.log/"  /etc/redis/redis-${REDISPORT}.conf
sed -i "s/^pidfile.*/pidfile \/run\/redis-${REDISPORT}\/redis-${REDISPORT}.pid/"  /etc/redis/redis-${REDISPORT}.conf
sed -i "s/^port.*/port ${REDISPORT}/" /etc/redis/redis-${REDISPORT}.conf
sed -i "s/dump.rdb/dump-${REDISPORT}.rdb/" /etc/redis/redis-${REDISPORT}.conf
sed -i "/save [0-9]0/d" /etc/redis/redis-${REDISPORT}.conf
sed -i 's/^#.*save ""/save ""/' /etc/redis/redis-${REDISPORT}.conf
sed -i '/^# rename-command CONFIG ""/a\
rename-command SLAVEOF "" \
rename-command CONFIG "" \
rename-command PUBLISH "" \
rename-command SAVE "" \
rename-command SHUTDOWN "" \
rename-command DEBUG "" \
rename-command BGSAVE "" \
rename-command BGREWRITEAOF ""
'  /etc/redis/redis-${REDISPORT}.conf
done
echo
systemctl daemon-reload
systemctl enable redis@6379
systemctl enable redis@6380
systemctl stop redis-server
systemctl disable redis-server
systemctl restart redis@6379 redis@6380
 else
  echo
  REDTXT "REDIS INSTALLATION ERROR"
 exit 1
 fi
  else
   echo
   YELLOWTXT "Redis installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo
_echo "[?] Install RabbitMQ ? [y/n][n]:"
read rabbit_install
if [ "${rabbit_install}" == "y" ];then
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash
   curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash
   dnf -y install rabbitmq-server
   rpm  --quiet -q rabbitmq-server
 elif [ "${OS_DISTRO_KEY}" == "debian" ]; then
  wget -O- https://packages.erlang-solutions.com/debian/erlang_solutions.asc | apt-key add -
  echo "deb https://packages.erlang-solutions.com/debian bullseye contrib" | tee /etc/apt/sources.list.d/erlang.list
  curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | bash
  apt-get -y install rabbitmq-server
 else
  wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | apt-key add -
  echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | tee /etc/apt/sources.list.d/erlang.list
  curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | bash
  apt-get -y install rabbitmq-server
 fi
 if [ "$?" = 0 ]; then
cat > /etc/rabbitmq/env <<END
NODE_IP_ADDRESS=127.0.0.1
RABBITMQ_NODE_IP_ADDRESS=127.0.0.1
ERL_EPMD_ADDRESS=127.0.0.1
RABBITMQ_PID_FILE=/var/lib/rabbitmq/mnesia/rabbitmq_pid
END

cat > /usr/local/bin/rabbitmq_reset <<END
#!/bin/bash

service rabbitmq-server stop
epmd -kill
epmd -daemon
sleep 5
service rabbitmq-server start
rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbitmq_pid
END

service rabbitmq-server stop
cp /usr/lib/systemd/system/rabbitmq-server.service /etc/systemd/system/rabbitmq-server.service

sed -i '/TimeoutStartSec=600/a\
EnvironmentFile=/etc/rabbitmq/env
' /etc/systemd/system/rabbitmq-server.service

systemctl daemon-reload
service rabbitmq-server stop
epmd -kill
epmd -daemon
sleep 5
service rabbitmq-server start
rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbitmq_pid
sleep 5
RABBITMQ_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
rabbitmqctl add_user magento ${RABBITMQ_PASSWORD}
rabbitmqctl set_permissions -p / magento ".*" ".*" ".*"

cat > ${MAGENX_CONFIG_PATH}/rabbitmq <<END
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
END
   GREENTXT "RabbitMQ INSTALLED  -  OK"
   echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   rpm -qa 'rabbitmq*' | awk '{print "  Installed: ",$1}'
  else
   apt -qq list --installed rabbitmq*
  fi
  else
   echo
   REDTXT "RabbitMQ INSTALLATION ERROR"
   exit 1
  fi
  else
   echo
   YELLOWTXT "RabbitMQ installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo
_echo "[?] Install Varnish Cache ? [y/n][n]:"
read varnish_install
if [ "${varnish_install}" == "y" ];then
 if [ "${OS_DISTRO_KEY}" == "redhat" ]; then
   curl -s https://packagecloud.io/install/repositories/varnishcache/varnish65/script.rpm.sh | bash
  elif [ "${OS_DISTRO_KEY}" == "amazon" ]; then
   curl -s https://packagecloud.io/install/repositories/varnishcache/varnish65/script.rpm.sh | bash os=el dist=7
   echo
   dnf -y install varnish
   rpm  --quiet -q varnish
  else
  curl -s https://packagecloud.io/install/repositories/varnishcache/varnish65/script.deb.sh | bash
  apt-get update
  apt-get -y install varnish
 fi
 if [ "$?" = 0 ]; then
   echo
   wget -qO /etc/systemd/system/varnish.service ${REPO_MAGENX_TMP}varnish.service
   wget -qO /etc/varnish/varnish.params ${REPO_MAGENX_TMP}varnish.params
   uuidgen > /etc/varnish/secret
   systemctl daemon-reload
   GREENTXT "VARNISH INSTALLED  -  OK"
   echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   rpm -qa 'varnish*' | awk '{print "  Installed: ",$1}'
  else
   apt -qq list --installed varnish*
  fi
  else
   echo
   REDTXT "VARNISH INSTALLATION ERROR"
   exit 1
  fi
  else
   echo
   YELLOWTXT "Varnish installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
_echo "[?] Install ElasticSearch ${ELKREPO} ? [y/n][n]:"
read elastic_install
if [ "${elastic_install}" == "y" ];then
echo
if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
GREENTXT "Elasticsearch installation:"
echo
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elastic.repo << EOF
[elasticsearch-${ELKREPO}]
name=Elasticsearch repository for ${ELKREPO} packages
baseurl=https://artifacts.elastic.co/packages/${ELKREPO}/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
echo
   dnf -y -q install --enablerepo=elasticsearch-${ELKREPO} elasticsearch kibana
   rpm  --quiet -q elasticsearch
  else
   wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
   echo "deb https://artifacts.elastic.co/packages/${ELKREPO}/apt stable main" > /etc/apt/sources.list.d/elastic-${ELKREPO}.list
   apt-get update
   apt-get -y install elasticsearch kibana
  fi
  if [ "$?" = 0 ]; then
          echo
echo "discovery.type: single-node" >> /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*cluster.name.*/cluster.name: magento/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*node.name.*/node.name: magento-node1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*network.host.*/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*http.port.*/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*-Xms.*/-Xms512m/" /etc/elasticsearch/jvm.options
sed -i "s/.*-Xmx.*/-Xmx2048m/" /etc/elasticsearch/jvm.options
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
  sed -i "s,#JAVA_HOME=,JAVA_HOME=/usr/share/elasticsearch/jdk/," /etc/sysconfig/elasticsearch
 else
  sed -i "s,#JAVA_HOME=,JAVA_HOME=/usr/share/elasticsearch/jdk/," /etc/default/elasticsearch
 fi
chown -R :elasticsearch /etc/elasticsearch/*
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto -b > /tmp/elasticsearch

cat > ${MAGENX_CONFIG_PATH}/elasticsearch <<END
APM_SYSTEM_PASSWORD="$(awk '/PASSWORD apm_system/ { print $4 }' /tmp/elasticsearch)"
KIBANA_SYSTEM_PASSWORD="$(awk '/PASSWORD kibana_system/ { print $4 }' /tmp/elasticsearch)"
KIBANA_PASSWORD="$(awk '/PASSWORD kibana =/ { print $4 }' /tmp/elasticsearch)"
LOGSTASH_SYSTEM_PASSWORD="$(awk '/PASSWORD logstash_system/ { print $4 }' /tmp/elasticsearch)"
BEATS_SYSTEM_PASSWORD="$(awk '/PASSWORD beats_system/ { print $4 }' /tmp/elasticsearch)"
REMOTE_MONITORING_USER_PASSWORD="$(awk '/PASSWORD remote_monitoring_user/ { print $4 }' /tmp/elasticsearch)"
ELASTIC_PASSWORD="$(awk '/PASSWORD elastic/ { print $4 }' /tmp/elasticsearch)"
END

echo
echo
GREENTXT "ELASTCSEARCH ${ELKVER} INSTALLED  -  OK"
echo
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
  rpm -qa 'elasticsearch*' | awk '{print "  Installed: ",$1}'
 else
  apt -qq list --installed elasticsearch*
 fi
 else
echo
REDTXT "ELASTCSEARCH INSTALLATION ERROR"
exit 1
fi
else
echo
YELLOWTXT "ElasticSearch installation was skipped by the user. Next step"
fi
echo
echo 
GREENTXT "~    REPOSITORIES AND PACKAGES INSTALLATION IS COMPLETED    ~"
WHITETXT "-------------------------------------------------------------------------------------"
echo
echo
pause '[] Press [Enter] key to show the menu'
printf "\033c"
;;

###################################################################################
###                                  MAGENTO DOWNLOAD                           ###
###################################################################################

"magento")
echo
echo
BLUEBG "[~]    DOWNLOAD MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL})    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo
echo
     read -e -p "  [?] ENTER YOUR DOMAIN OR IP ADDRESS: " -i "storedomain.net" MAGE_DOMAIN
     read -e -p "  [?] ENTER MAGENTO FILES OWNER NAME: " -i "example" MAGE_OWNER
	 
     MAGE_WEB_ROOT_PATH="/home/${MAGE_OWNER}/public_html"
	 
     echo
       _echo "[!] MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL}) WILL BE DOWNLOADED TO ${MAGE_WEB_ROOT_PATH}"
     echo

          mkdir -p ${MAGE_WEB_ROOT_PATH} && cd $_
          ## create root user
          useradd -d ${MAGE_WEB_ROOT_PATH%/*} -s /bin/bash ${MAGE_OWNER}
          ## create root php user
          MAGE_PHP_USER="php-${MAGE_OWNER}"
          useradd -M -s /sbin/nologin -d ${MAGE_WEB_ROOT_PATH%/*} ${MAGE_PHP_USER}
          usermod -g ${MAGE_PHP_USER} ${MAGE_OWNER}
          chmod 711 ${MAGE_WEB_ROOT_PATH%/*}
	  mkdir -p ${MAGE_WEB_ROOT_PATH%/*}/{.config,.cache,.local,.composer}
	  chown -R ${MAGE_OWNER}:${MAGE_OWNER} ${MAGE_WEB_ROOT_PATH%/*}/{.config,.cache,.local,.composer}
          chown -R ${MAGE_OWNER}:${MAGE_PHP_USER} ${MAGE_WEB_ROOT_PATH}
          chmod 2770 ${MAGE_WEB_ROOT_PATH}
	  setfacl -R -m u:${MAGE_OWNER}:rwX,g:${MAGE_PHP_USER}:r-X,o::-,d:u:${MAGE_OWNER}:rwX,d:g:${MAGE_PHP_USER}:r-X,d:o::- ${MAGE_WEB_ROOT_PATH}
	  
	echo
MAGE_MINIMAL_OPT="MINIMAL SET OF PACKAGES"
GREENTXT "${MAGE_MINIMAL_OPT} INSTALLATION"
echo
GREENTXT "Benefits of removing bloatware packages:"
WHITETXT "[!] Better memory allocation!"
WHITETXT "[!] Faster cli, backend and frontend operations!"
WHITETXT "[!] Less maintenance work!"
WHITETXT "[!] Less dependencies and security risks!"
echo
pause '[] Press [Enter] key to start'
echo

## pull installation package from github
su ${MAGE_OWNER} -s /bin/bash -c "git clone https://github.com/magenx/Magento-2.git ."
rm -rf .git
#su ${MAGE_OWNER} -s /bin/bash -c "echo 007 > magento_umask"
setfacl -R -m u:${MAGE_OWNER}:rwX,g:${MAGE_PHP_USER}:rwX,o::-,d:u:${MAGE_OWNER}:rwX,d:g:${MAGE_PHP_USER}:rwX,d:o::- var pub/media
chmod +x bin/magento
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento module:enable --all"

## composer version 2 latest
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/bin --filename=composer
php -r "unlink('composer-setup.php');"

echo
_echo "[?] Would you like to run composer update now ? [y/n][n]:"
read composer_update
if [ "${composer_update}" == "y" ];then
echo
su ${MAGE_OWNER} -s /bin/bash -c "composer update"
echo
fi

echo
GREENTXT "[~]    MAGENTO ${MAGE_MINIMAL_OPT} DOWNLOADED AND READY FOR SETUP    [~]"
WHITETXT "--------------------------------------------------------------------"
echo

mkdir -p ${MAGENX_CONFIG_PATH}
cat > ${MAGENX_CONFIG_PATH}/magento <<END
# ${MAGE_MINIMAL_OPT}
MAGE_VERSION="2"
MAGE_VERSION_FULL="${MAGE_VERSION_FULL}"
MAGE_DOMAIN="${MAGE_DOMAIN}"
MAGE_OWNER="${MAGE_OWNER}"
MAGE_PHP_USER="${MAGE_PHP_USER}"
MAGE_WEB_ROOT_PATH="${MAGE_WEB_ROOT_PATH}"
END

echo
pause '[] Press [Enter] key to show menu'
printf "\033c"
;;

###################################################################################
###                                  DATABASE SETUP                             ###
###################################################################################

"database")
printf "\033c"
include_config ${MAGENX_CONFIG_PATH}/distro
include_config ${MAGENX_CONFIG_PATH}/magento
echo
BLUEBG "[~]    CREATE MYSQL USER AND DATABASE    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
if [ ! -f /root/.my.cnf ]; then
MYSQL_ROOT_PASSWORD_GEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD_GEN}${RANDOM}"

systemctl restart mariadb
mysqladmin status --wait=2 &>/dev/null || { REDTXT "\n [!] MYSQL SERVER DOWN \n"; exit 1; }
mysql --connect-expired-password  <<EOMYSQL
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
fi
chmod 600 /root/.my.cnf /root/.mytop
echo
GREENTXT "GENERATE MYSQL USER AND DATABASE NAMES WITH NEW PASSWORD"
MAGE_DB_PASSWORD_GEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9%^&=+_{}()<>-' | fold -w 15 | head -n 1)
MAGE_DB_PASSWORD="${MAGE_DB_PASSWORD_GEN}${RANDOM}"
MAGE_DB_HASH="$(openssl rand -hex 4)"
echo
MAGE_DB_HOST="localhost" 
MAGE_DB_NAME="m${MAGE_VERSION}_${MAGE_DOMAIN//[-.]/}_${MAGE_DB_HASH}_live" 
MAGE_DB_USER="m${MAGE_VERSION}_${MAGE_DOMAIN//[-.]/}_${MAGE_DB_HASH}"
GREENTXT "CREATE MYSQL STATEMENT AND EXECUTE IT"
echo
mysql <<EOMYSQL
CREATE USER '${MAGE_DB_USER}'@'${MAGE_DB_HOST}' IDENTIFIED BY '${MAGE_DB_PASSWORD}';
CREATE DATABASE ${MAGE_DB_NAME};
GRANT ALL PRIVILEGES ON ${MAGE_DB_NAME}.* TO '${MAGE_DB_USER}'@'${MAGE_DB_HOST}' WITH GRANT OPTION;
exit
EOMYSQL

GREENTXT "SAVE VARIABLES TO CONFIG FILE"
mkdir -p ${MAGENX_CONFIG_PATH}
cat > ${MAGENX_CONFIG_PATH}/database <<END
MAGE_DB_HOST="${MAGE_DB_HOST}"
MAGE_DB_NAME="${MAGE_DB_NAME}"
MAGE_DB_USER="${MAGE_DB_USER}"
MAGE_DB_PASSWORD="${MAGE_DB_PASSWORD}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"
END
echo
echo
echo
pause '[] Press [Enter] key to show menu'
printf "\033c"
;;

###################################################################################
###                                  MAGENTO SETUP                              ###
###################################################################################

"install")
printf "\033c"
echo
BLUEBG   "[~]    MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL}) SETUP    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo
include_config ${MAGENX_CONFIG_PATH}/distro
include_config ${MAGENX_CONFIG_PATH}/magento
include_config ${MAGENX_CONFIG_PATH}/database
include_config ${MAGENX_CONFIG_PATH}/rabbitmq
include_config ${MAGENX_CONFIG_PATH}/elasticsearch

echo
for ports in 6379 6380 9200 5672 3306; do nc -zvw3 localhost $ports; if [ "$?" != 0 ]; then REDTXT "  [!] SERVICE $ports OFFLINE"; exit 1; fi;  done
echo

echo "${MAGE_WEB_ROOT_PATH}/app/etc/env.php" >> /etc/opcache-default.blacklist
echo "${MAGE_WEB_ROOT_PATH}/app/etc/config.php" >> /etc/opcache-default.blacklist
systemctl reload php*fpm.service

cd ${MAGE_WEB_ROOT_PATH}
chown -R ${MAGE_OWNER}:${MAGE_PHP_USER} *
chmod u+x bin/magento
echo
WHITETXT "Admin name, email and base url"
echo
read -e -p "  [?] Admin first name: " -i "Magento"  MAGE_ADMIN_FIRSTNAME
read -e -p "  [?] Admin last name: " -i "Administrator"  MAGE_ADMIN_LASTNAME
read -e -p "  [?] Admin email: " -i "admin@${MAGE_DOMAIN}"  MAGE_ADMIN_EMAIL
read -e -p "  [?] Admin login name: " -i "admin"  MAGE_ADMIN_LOGIN
MAGE_ADMIN_PASSWORD_GEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 10 | head -n 1)
read -e -p "  [?] Admin password: " -i "${MAGE_ADMIN_PASSWORD_GEN}${RANDOM}"  MAGE_ADMIN_PASSWORD
read -e -p "  [?] Shop base url: " -i "http://${MAGE_DOMAIN}/"  MAGE_SITE_URL
echo
WHITETXT "Language, Currency and Timezone settings"
updown_menu "$(bin/magento info:language:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_LOCALE
updown_menu "$(bin/magento info:currency:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_CURRENCY
updown_menu "$(bin/magento info:timezone:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_TIMEZONE
echo
echo
GREENTXT "SETUP MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL}) WITHOUT SAMPLE DATA"
echo
pause '[] Press [Enter] key to run setup'
echo
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento setup:install --base-url=${MAGE_SITE_URL} \
--db-host=${MAGE_DB_HOST} \
--db-name=${MAGE_DB_NAME} \
--db-user=${MAGE_DB_USER} \
--db-password='${MAGE_DB_PASSWORD}' \
--admin-firstname=${MAGE_ADMIN_FIRSTNAME} \
--admin-lastname=${MAGE_ADMIN_LASTNAME} \
--admin-email=${MAGE_ADMIN_EMAIL} \
--admin-user=${MAGE_ADMIN_LOGIN} \
--admin-password='${MAGE_ADMIN_PASSWORD}' \
--language=${MAGE_LOCALE} \
--currency=${MAGE_CURRENCY} \
--timezone=${MAGE_TIMEZONE} \
--cleanup-database \
--session-save=files \
--use-rewrites=1 \
--amqp-host=127.0.0.1 \
--amqp-port=5672 \
--amqp-user=magento \
--amqp-password='${RABBITMQ_PASSWORD}' \
--amqp-virtualhost='/' \
--consumers-wait-for-messages=0 \
--search-engine=elasticsearch7 \
--elasticsearch-host=127.0.0.1 \
--elasticsearch-port=9200 \
--elasticsearch-enable-auth=1 \
--elasticsearch-username=elastic \
--elasticsearch-password='${ELASTIC_PASSWORD}'"

if [ "$?" != 0 ]; then
  echo
  REDTXT "[!] SETUP ERROR"
  REDTXT "[!] PLEASE CORRECT AND TRY AGAIN"
  echo
  exit 1
fi

mkdir -p ${MAGENX_CONFIG_PATH}
mysqldump --single-transaction --routines --triggers --events ${MAGE_DB_NAME} | gzip > ${MAGENX_CONFIG_PATH}/${MAGE_DB_NAME}.sql.gz
cp app/etc/env.php  ${MAGENX_CONFIG_PATH}/env.php.default
echo
echo
echo
    WHITETXT "============================================================================="
    echo
    GREENTXT "INSTALLED MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL}) WITHOUT SAMPLE DATA"
    echo
    WHITETXT "============================================================================="
echo
cat > ${MAGENX_CONFIG_PATH}/install <<END
MAGE_ADMIN_LOGIN="${MAGE_ADMIN_LOGIN}"
MAGE_ADMIN_PASSWORD="${MAGE_ADMIN_PASSWORD}"
MAGE_ADMIN_EMAIL="${MAGE_ADMIN_EMAIL}"
MAGE_TIMEZONE="${MAGE_TIMEZONE}"
MAGE_LOCALE="${MAGE_LOCALE}"
MAGE_ADMIN_PATH="$(grep -Po "(?<='frontName' => ')\w*(?=')" ${MAGE_WEB_ROOT_PATH}/app/etc/env.php)"
END

pause '[] Press [Enter] key to show menu'
printf "\033c"
;;

###################################################################################
###                                FINAL CONFIGURATION                          ###
###################################################################################

"config")

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

printf "\033c"

include_config ${MAGENX_CONFIG_PATH}/distro
include_config ${MAGENX_CONFIG_PATH}/magento
include_config ${MAGENX_CONFIG_PATH}/database
include_config ${MAGENX_CONFIG_PATH}/install
include_config ${MAGENX_CONFIG_PATH}/sshport
include_config ${MAGENX_CONFIG_PATH}/elasticsearch

if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
  php_ini="/etc/php.ini"
  php_fpm_pool="/etc/php-fpm.d/www.conf"
  php_opcache_ini="/etc/php.d/10-opcache.ini"
 else
  PHP_VERSION="$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")"
  php_ini="/etc/php/${PHP_VERSION}/fpm/php.ini"
  php_fpm_pool="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
  php_opcache_ini="/etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini"
fi

echo
BLUEBG "[~]    POST-INSTALLATION CONFIGURATION    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo
cat > /etc/sysctl.conf <<END
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

cat > ${php_opcache_ini} <<END
zend_extension=opcache.so
opcache.enable = 1
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
END

cp ${php_ini} ${php_ini}.BACK
sed -i 's/^\(max_execution_time = \)[0-9]*/\17200/' ${php_ini}
sed -i 's/^\(max_input_time = \)[0-9]*/\17200/' ${php_ini}
sed -i 's/^\(memory_limit = \)[0-9]*M/\12048M/' ${php_ini}
sed -i 's/^\(post_max_size = \)[0-9]*M/\164M/' ${php_ini}
sed -i 's/^\(upload_max_filesize = \)[0-9]*M/\164M/' ${php_ini}
sed -i 's/expose_php = On/expose_php = Off/' ${php_ini}
sed -i 's/;realpath_cache_size =.*/realpath_cache_size = 4096k/' ${php_ini}
sed -i 's/;realpath_cache_ttl =.*/realpath_cache_ttl = 86400/' ${php_ini}
sed -i 's/short_open_tag = Off/short_open_tag = On/' ${php_ini}
sed -i 's/;max_input_vars =.*/max_input_vars = 50000/' ${php_ini}
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 28800/' ${php_ini}
sed -i 's/mysql.allow_persistent = On/mysql.allow_persistent = Off/' ${php_ini}
sed -i 's/mysqli.allow_persistent = On/mysqli.allow_persistent = Off/' ${php_ini}
sed -i 's/pm = dynamic/pm = ondemand/' ${php_fpm_pool}
sed -i 's/;pm.max_requests = 500/pm.max_requests = 10000/' ${php_fpm_pool}
sed -i 's/^\(pm.max_children = \)[0-9]*/\1100/' ${php_fpm_pool}

GREENTXT "SERVER HOSTNAME SETTINGS"
hostnamectl set-hostname server.${MAGE_DOMAIN} --static
echo
GREENTXT "SERVER TIMEZONE SETTINGS"
timedatectl set-timezone ${MAGE_TIMEZONE}
echo
GREENTXT "MYSQL TOOLS AND PROXYSQL"
wget -qO /usr/local/bin/mysqltuner ${MYSQL_TUNER}
wget -qO /usr/local/bin/mytop ${MYSQL_TOP}

if [ "${OS_DISTRO_KEY}" == "redhat" ]; then
cat <<EOF | tee /etc/yum.repos.d/proxysql.repo
   [proxysql_repo]
   name= ProxySQL YUM repository
   baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.2.x/centos/$releasever
   gpgcheck=1
   gpgkey=https://repo.proxysql.com/ProxySQL/repo_pub_key
EOF
   dnf -y install proxysql
 elif [ "${OS_DISTRO_KEY}" == "amazon" ]; then
cat <<EOF | tee /etc/yum.repos.d/proxysql.repo
   [proxysql_repo]
   name=ProxySQL YUM repository
   baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.2.x/centos/latest
   gpgcheck=1
   gpgkey=https://repo.proxysql.com/ProxySQL/repo_pub_key
EOF
   dnf -y install proxysql
 else
   wget -O - 'https://repo.proxysql.com/ProxySQL/repo_pub_key' | apt-key add - 
   echo deb https://repo.proxysql.com/ProxySQL/proxysql-2.2.x/$(lsb_release -sc)/ ./ | tee /etc/apt/sources.list.d/proxysql.list
   apt-get update
   apt -y install proxysql
fi

systemctl disable proxysql

echo
GREENTXT "PHP-FPM SETTINGS"
sed -i "s/\[www\]/\[${MAGE_OWNER}\]/" ${php_fpm_pool}
sed -i "s/^user =.*/user = ${MAGE_PHP_USER}/" ${php_fpm_pool}
sed -i "s/^group =.*/group = ${MAGE_PHP_USER}/" ${php_fpm_pool}
sed -i "s/^listen =.*/listen = 127.0.0.1:9000/" ${php_fpm_pool}
sed -ri "s/;?listen.owner =.*/listen.owner = ${MAGE_OWNER}/" ${php_fpm_pool}
sed -ri "s/;?listen.group =.*/listen.group = ${MAGE_PHP_USER}/" ${php_fpm_pool}
sed -ri "s/;?listen.mode = 0660/listen.mode = 0660/" ${php_fpm_pool}
sed -ri "s/;?listen.allowed_clients =.*/listen.allowed_clients = 127.0.0.1/" ${php_fpm_pool}
sed -i '/sendmail_path/,$d' ${php_fpm_pool}
sed -i '/PHPSESSID/d' ${php_ini}
sed -i "s,.*date.timezone.*,date.timezone = ${MAGE_TIMEZONE}," ${php_ini}

cat >> ${php_fpm_pool} <<END
;;
;; Custom pool settings
php_flag[display_errors] = off
php_admin_flag[log_errors] = on
php_admin_value[error_log] = "${MAGE_WEB_ROOT_PATH}/var/log/php-fpm-error.log"
php_admin_value[default_charset] = UTF-8
php_admin_value[memory_limit] = 1024M
php_admin_value[date.timezone] = ${MAGE_TIMEZONE}
END

systemctl daemon-reload
echo
GREENTXT "NGINX SETTINGS"
wget -qO /etc/nginx/fastcgi_params  ${NGINX_BASE}magento${MAGE_VERSION}/fastcgi_params
wget -qO /etc/nginx/nginx.conf  ${NGINX_BASE}magento${MAGE_VERSION}/nginx.conf
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
curl -s ${GITHUB_REPO_API_URL}/sites-available 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -sO "$4)}' >/dev/null
ln -s /etc/nginx/sites-available/magento${MAGE_VERSION}.conf /etc/nginx/sites-enabled/magento${MAGE_VERSION}.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
mkdir -p /etc/nginx/conf_m${MAGE_VERSION} && cd /etc/nginx/conf_m${MAGE_VERSION}/
curl -s ${GITHUB_REPO_API_URL}/conf_m2 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -sO "$4)}' >/dev/null

sed -i "s/user  nginx;/user  ${MAGE_OWNER};/" /etc/nginx/nginx.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/sites-available/magento${MAGE_VERSION}.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/nginx.conf
sed -i "s,/var/www/html,${MAGE_WEB_ROOT_PATH},g" /etc/nginx/conf_m${MAGE_VERSION}/maps.conf

PROFILER_PLACEHOLDER="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)"
sed -i "s/PROFILER_PLACEHOLDER/${PROFILER_PLACEHOLDER}/" /etc/nginx/conf_m${MAGE_VERSION}/maps.conf

sed -i "s/ADMIN_PLACEHOLDER/${MAGE_ADMIN_PATH}/g" /etc/nginx/conf_m${MAGE_VERSION}/extra_protect.conf
ADMIN_HTTP_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
htpasswd -b -c /etc/nginx/.admin admin ${ADMIN_HTTP_PASSWORD}  >/dev/null 2>&1
echo
GREENTXT "PHPMYADMIN INSTALLATION AND CONFIGURATION"
PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
PMA_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
BLOWFISHCODE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9=+_[]{}()<>-' | fold -w 64 | head -n 1)
PMA_CONFIG_FOLDER="/etc/phpMyAdmin/config.inc.php"

  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
        dnf -y -q install phpMyAdmin
  else
       add-apt-repository -y ppa:phpmyadmin/ppa
       apt-get -y update
       debconf-set-selections <<< "phpmyadmin phpmyadmin/internal/skip-preseed boolean true"
       debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect"
       debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean false"
       apt-get -y install phpmyadmin
       PMA_CONFIG_FOLDER="${PMA_CONFIG_FOLDER,,}"
       sed -i 's!/usr/share/phpMyAdmin!/usr/share/phpmyadmin!g' "/etc/nginx/conf_m${MAGE_VERSION}/phpmyadmin.conf"
       cp /usr/share/phpmyadmin/config.sample.inc.php ${PMA_CONFIG_FOLDER}
  fi
       sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISHCODE}';/" ${PMA_CONFIG_FOLDER}
       sed -i "s/PHPMYADMIN_PLACEHOLDER/mysql_${PMA_FOLDER}/g" /etc/nginx/conf_m${MAGE_VERSION}/phpmyadmin.conf
     sed -i "5i \\
           auth_basic  \"please login\"; \\
           auth_basic_user_file .mysql;"  /etc/nginx/conf_m${MAGE_VERSION}/phpmyadmin.conf
	 	   
htpasswd -b -c /etc/nginx/.mysql mysql ${PMA_PASSWORD}  >/dev/null 2>&1
echo
systemctl restart nginx.service
cat > ${MAGENX_CONFIG_PATH}/phpmyadmin <<END
PMA_FOLDER="mysql_${PMA_FOLDER}"
PMA_PASSWORD="${PMA_PASSWORD}"
END
echo
echo
if [ -f /etc/systemd/system/varnish.service ]; then
GREENTXT "VARNISH CACHE CONFIGURATION"
    sed -i "s/MAGE_OWNER/${MAGE_OWNER}/g"  /etc/systemd/system/varnish.service
    systemctl enable varnish.service
    chmod u+x ${MAGE_WEB_ROOT_PATH}/bin/magento
    su ${MAGE_OWNER} -s /bin/bash -c "${MAGE_WEB_ROOT_PATH}/bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2"
    php ${MAGE_WEB_ROOT_PATH}/bin/magento varnish:vcl:generate --export-version=6 --output-file=/etc/varnish/default.vcl
    sed -i "s,pub/health_,health_,g" /etc/varnish/default.vcl
    systemctl restart varnish.service
    wget -O /etc/varnish/devicedetect.vcl https://raw.githubusercontent.com/varnishcache/varnish-devicedetect/master/devicedetect.vcl
    wget -O /etc/varnish/devicedetect-include.vcl ${REPO_MAGENX_TMP}devicedetect-include.vcl
    YELLOWTXT "VARNISH CACHE PORT :8081"
fi
echo
GREENTXT "DOWNLOADING n98-MAGERUN2"
curl -s -o /usr/local/bin/magerun2 https://files.magerun.net/n98-magerun2.phar
echo
GREENTXT "CACHE CLEANER SCRIPT"
echo "${MAGE_OWNER} ALL=(ALL) NOPASSWD: /usr/bin/redis-cli -p 6380 flushall, /usr/bin/systemctl reload php*fpm.service, /usr/bin/systemctl reload nginx.service" >>  /etc/sudoers
cat > /usr/local/bin/cacheflush <<END
#!/bin/bash
magerun2 cache:flush
sudo /usr/bin/redis-cli -p 6380 flushall
sudo /usr/bin/systemctl reload php*fpm.service
sudo /usr/bin/systemctl reload nginx.service
END
echo
GREENTXT "SYSTEM AUTO UPDATE WITH DNF AUTOMATIC"
if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
sed -i 's/upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
sed -i 's/emit_via = stdio/emit_via = email/' /etc/dnf/automatic.conf
sed -i "s/email_from =.*/email_from = dnf-automatic@${MAGE_DOMAIN}/" /etc/dnf/automatic.conf
sed -i "s/email_to = root/email_to = ${MAGE_ADMIN_EMAIL}/" /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer
systemctl enable --now snapd.socket
fi
echo
GREENTXT "CERTBOT INSTALLATION"
snap install --classic certbot
ln -s /snap/bin/certbot /usr/local/bin/certbot
echo
GREENTXT "GENERATE DHPARAM FOR NGINX SSL"
openssl dhparam -dsaparam -out /etc/ssl/certs/dhparams.pem 4096
echo
GREENTXT "GENERATE DEFAULT NGINX SSL SERVER KEY/CERT"
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout /etc/ssl/certs/default_server.key -out /etc/ssl/certs/default_server.crt \
-subj "/CN=default_server" -days 3650 -subj "/C=US/ST=Oregon/L=Portland/O=default_server/OU=Org/CN=default_server"
echo
GREENTXT "SIMPLE LOGROTATE SCRIPT FOR MAGENTO LOGS"
cat > /etc/logrotate.d/magento <<END
${MAGE_WEB_ROOT_PATH}/var/log/*.log
{
su ${MAGE_OWNER} ${MAGE_PHP_USER}
create 660 ${MAGE_OWNER} ${MAGE_PHP_USER}
weekly
rotate 2
notifempty
missingok
compress
}
END
echo
systemctl daemon-reload
echo
GREENTXT "[!] REALTIME MALWARE MONITOR WITH E-MAIL ALERTING"
YELLOWTXT "[!] INFECTED FILES WILL BE MOVED TO QUARANTINE"
echo
cd /usr/local/src
wget -O maldetect-current.tar.gz ${MALDET}
tar -zxf maldetect-current.tar.gz
cd maldetect-*/
./install.sh

sed -i 's/email_alert="0"/email_alert="1"/' /usr/local/maldetect/conf.maldet
sed -i "s/you@domain.com/${MAGE_ADMIN_EMAIL}/" /usr/local/maldetect/conf.maldet
sed -i 's/quarantine_hits="0"/quarantine_hits="1"/' /usr/local/maldetect/conf.maldet
sed -i '/default_monitor_mode="users"/d' /usr/local/maldetect/conf.maldet
sed -i 's,# default_monitor_mode="/usr/local/maldetect/monitor_paths",default_monitor_mode="/usr/local/maldetect/monitor_paths",' /usr/local/maldetect/conf.maldet
sed -i 's/inotify_base_watches="16384"/inotify_base_watches="35384"/' /usr/local/maldetect/conf.maldet

echo -e "${MAGE_WEB_ROOT_PATH%/*}" > /usr/local/maldetect/monitor_paths

maldet --monitor /usr/local/maldetect/monitor_paths
echo
GREENTXT "MAGENTO MALWARE SCANNER"
YELLOWTXT "Hourly cronjob created"
pip3 -q install --no-cache-dir --upgrade mwscan
cat > /etc/cron.hourly/mwscan <<END
#!/bin/sh
## MAGENTO MALWARE SCANNER
mwscan --newonly --quiet ${MAGE_WEB_ROOT_PATH} | ts | tee -a /var/log/mwscan.log | ifne mailx -s "Malware found at $(hostname)" ${MAGE_ADMIN_EMAIL}
END
chmod +x /etc/cron.hourly/mwscan
echo
GREENTXT "AUDIT MAGENTO FILES AND FOLDERS"
cat >> /etc/audit/rules.d/audit.rules <<END

## audit magento files
-a never,exit -F dir=${MAGE_WEB_ROOT_PATH}/var/ -k exclude
-w ${MAGE_WEB_ROOT_PATH} -p wa -k auditmgnx
END
service auditd reload
service auditd restart
auditctl -l
echo
echo
GREENTXT "ROOT CRONJOBS"
echo "5 8 * * 7 perl /usr/local/bin/mysqltuner --nocolor 2>&1 | mailx -s \"MYSQLTUNER WEEKLY REPORT at ${MAGE_DOMAIN}\" ${MAGE_ADMIN_EMAIL}" >> rootcron
echo '@weekly /usr/local/bin/certbot renew --deploy-hook "systemctl reload nginx" >> /var/log/letsencrypt-renew.log' >> rootcron
crontab rootcron
rm rootcron
echo
GREENTXT "REDIS CACHE AND SESSION STORAGE"
echo
## cache backend
cd ${MAGE_WEB_ROOT_PATH}
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento setup:config:set \
--cache-backend=redis \
--cache-backend-redis-server=127.0.0.1 \
--cache-backend-redis-port=6380 \
--cache-backend-redis-db=1 \
--cache-backend-redis-compress-data=1 \
--cache-backend-redis-compression-lib=l4z \
-n"
## session
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento setup:config:set \
--session-save=redis \
--session-save-redis-host=127.0.0.1 \
--session-save-redis-port=6379 \
--session-save-redis-log-level=3 \
--session-save-redis-db=1 \
--session-save-redis-compression-lib=lz4 \
-n"
# varnish cache hosts
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento setup:config:set --http-cache-hosts=127.0.0.1:8081"
echo
systemctl daemon-reload
systemctl restart nginx.service
systemctl restart php*fpm.service

chown -R ${MAGE_OWNER}:${MAGE_PHP_USER} ${MAGE_WEB_ROOT_PATH}
echo
GREENTXT "CLEAN MAGENTO CACHE AND ENABLE PRODUCTION MODE"
rm -rf var/*
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento deploy:mode:set production"
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento cache:flush"
#setfacl -R -m u:${MAGE_OWNER}:rwX,g:${MAGE_PHP_USER}:r-X,o::-,d:u:${MAGE_OWNER}:rwX,d:g:${MAGE_PHP_USER}:r-X,d:o::- generated pub/static
getfacl -R ../public_html > ${MAGENX_CONFIG_PATH}/public_html.acl

echo
GREENTXT "SAVING composer.json AND env.php"
cp composer.json ${MAGENX_CONFIG_PATH}/composer.json.saved
cp composer.lock ${MAGENX_CONFIG_PATH}/composer.lock.saved
cp app/etc/env.php ${MAGENX_CONFIG_PATH}/env.php.saved
echo
echo
GREENTXT "FIXING PERMISSIONS"
chmod +x /usr/local/bin/*
chmod -R 600 ${MAGENX_CONFIG_PATH}

cd ${MAGE_WEB_ROOT_PATH}
chmod ug+x bin/magento
echo
echo
GREENTXT "MAGENTO CRONJOBS"
su ${MAGE_PHP_USER} -s /bin/bash -c "bin/magento cron:install"
echo

cd ${MAGE_WEB_ROOT_PATH%/*}

GREENTXT "GENERATE SSH KEY"
mkdir .ssh
MAGE_OWNER_SSHKEY="${MAGE_OWNER}_sshkey"
ssh-keygen -b 2048 -t rsa -f ${MAGENX_CONFIG_PATH}/${MAGE_OWNER_SSHKEY} -C "${MAGE_DOMAIN}" -q -N ""
cat ${MAGENX_CONFIG_PATH}/${MAGE_OWNER_SSHKEY}.pub > .ssh/authorized_keys
echo "MAGE_OWNER_SSHKEY=\"${MAGE_OWNER_SSHKEY}\"" >> ${MAGENX_CONFIG_PATH}/magento

cat > .bash_profile <<END
# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
# User specific environment and startup programs
PATH=\$PATH:\$HOME/bin
export PATH
END

cat > .bashrc <<END
# .bashrc
cd ${MAGE_WEB_ROOT_PATH}
PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '
END

echo

GREENTXT "CONFIGURE GOOGLE AUTH CODE FOR ADMIN ACCESS"
echo
cd ${MAGE_WEB_ROOT_PATH}
GOOGLE_TFA_CODE="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&' | fold -w 15 | head -n 1 | base32)"
su ${MAGE_OWNER} -s /bin/bash -c "bin/magento security:tfa:google:set-secret admin ${GOOGLE_TFA_CODE}"
echo "Google Authenticator mobile app configuration:"
echo "-> select: Enter a setup key"
echo "-> type in: Account name"
echo "-> Paste passkey ${GOOGLE_TFA_CODE}"
echo "-> Choose Time based"

echo
echo
pause '[] Press [Enter] key to finish and print installation log'
echo
echo
echo

REDTXT "PRINTING INSTALLATION LOG AND SAVING INTO ${MAGENX_CONFIG_PATH}/install.log"
echo
echo -e "===========================  INSTALLATION LOG  ======================================

[shop domain]: ${MAGE_DOMAIN}
[webroot path]: ${MAGE_WEB_ROOT_PATH}

[admin path]: ${MAGE_DOMAIN}/${MAGE_ADMIN_PATH}
[admin name]: ${MAGE_ADMIN_LOGIN}
[admin pass]: ${MAGE_ADMIN_PASSWORD}
[admin http auth name]: admin
[admin http auth pass]: ${ADMIN_HTTP_PASSWORD}
for additional access, please generate new user/password:
htpasswd -b -c /etc/nginx/.admin USERNAME PASSWORD

[google tfa code]: ${GOOGLE_TFA_CODE}

[ssh port]: ${SSH_PORT}

[files owner]: ${MAGE_OWNER}
[${MAGE_OWNER} ssh key]: ${MAGENX_CONFIG_PATH}/${MAGE_OWNER_SSHKEY}

[phpmyadmin url]: ${MAGE_DOMAIN}/mysql_${PMA_FOLDER}/
[phpmyadmin http auth name]: mysql
[phpmyadmin http auth pass]: ${PMA_PASSWORD}
for additional access, please generate new user/password:
htpasswd -b -c /etc/nginx/.mysql USERNAME PASSWORD

[mysql host]: ${MAGE_DB_HOST}
[mysql user]: ${MAGE_DB_USER}
[mysql pass]: ${MAGE_DB_PASSWORD}
[mysql database]: ${MAGE_DB_NAME}
[mysql root pass]: ${MYSQL_ROOT_PASSWORD}

[elk user]: elastic
[elk password]: "${ELASTIC_PASSWORD}"

[percona toolkit]: https://www.percona.com/doc/percona-toolkit/LATEST/index.html
[database monitor]: mytop
[mysql tuner]: mysqltuner

[n98-magerun2]: /usr/local/bin/magerun2
[cache cleaner]: /usr/local/bin/cacheflush

[audit log]: ausearch -k auditmgnx | aureport -f -i

[redis on port 6379]: systemctl restart redis@6379
[redis on port 6380]: systemctl restart redis@6380

[installed db dump]: ${MAGENX_CONFIG_PATH}/${MAGE_DB_NAME}.sql.gz
[composer.json copy]: ${MAGENX_CONFIG_PATH}/composer.json.saved
[env.php copy]: ${MAGENX_CONFIG_PATH}/env.php.saved
[env.php default copy]: ${MAGENX_CONFIG_PATH}/env.php.default

[ACL map]: /home/${MAGE_OWNER}/public_html.acl

when you run any command for magento cli or custom php script,
please use ${MAGE_OWNER} user, either switch to:
su ${MAGE_OWNER} -s /bin/bash

or run commands from root as user:
su ${MAGE_OWNER} -s /bin/bash -c 'bin/magento'

to copy folders for development or build use:
rsync -Aa public_html/ ./staging_html
setfacl -R -m u:${MAGE_OWNER}:rwX,g:${MAGE_PHP_USER}:rwX,o::-,d:u:${MAGE_OWNER}:rwX,d:g:${MAGE_PHP_USER}:rwX,d:o::- staging_html/generated staging_html/pub/static


===========================  INSTALLATION LOG  ======================================" | tee ${MAGENX_CONFIG_PATH}/install.log
echo
echo
GREENTXT "SERVER IS READY. THANK YOU"
echo "PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '" >> /etc/bashrc
echo
echo
## simple installation statis
curl --silent -X POST https://www.magenx.com/ping_back_domain_${MAGE_DOMAIN}_geo_${MAGE_TIMEZONE}_keep_30d >/dev/null 2>&1
echo
pause '[] Press [Enter] key to show menu'
;;

###################################################################################
###                               FIREWALL INSTALLATION                         ###
###################################################################################

"firewall")
WHITETXT "============================================================================="
echo

include_config ${MAGENX_CONFIG_PATH}/magento
include_config ${MAGENX_CONFIG_PATH}/install

echo
_echo "[?] Install CSF firewall [y/n][n]:"
read csffirewall
if [ "${csffirewall}" == "y" ];then
 echo
 GREENTXT "DOWNLOADING CSF FIREWALL"
 echo
 cd /usr/local/src/
 wget -qO - https://download.configserver.com/csf.tgz | tar -xz
  echo
  cd csf
  GREENTXT "NEXT, TEST IF YOU HAVE THE REQUIRED IPTABLES MODULES"
  echo
 if perl csftest.pl | grep "FATAL" ; then
  perl csftest.pl
  echo
  REDTXT "CSF FILERWALL TEST FATAL ERRORS"
  echo
  pause '[] Press [Enter] key to show menu'
 else
  echo
  GREENTXT "CSF FIREWALL INSTALLATION"
  echo
  sh install.sh
  echo
  GREENTXT "CSF FIREWALL HAS BEEN INSTALLED OK"
  echo
  YELLOWTXT "Add ip addresses to whitelist/ignore (paypal,api,erp,backup,github,etc)"
  echo
  read -e -p "   [?] Enter ip address/cidr each after space: " -i "${SSH_CLIENT%% *} 169.254.169.254" IP_ADDR_IGNORE
  for ip_addr_ignore in ${IP_ADDR_IGNORE}; do csf -a ${ip_addr_ignore}; done
  ### csf firewall optimization
  sed -i 's/^TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
  sed -i 's/^CT_LIMIT =.*/CT_LIMIT = "60"/' /etc/csf/csf.conf
  sed -i 's/^CT_INTERVAL =.*/CT_INTERVAL = "30"/' /etc/csf/csf.conf
  sed -i 's/^PORTFLOOD =.*/PORTFLOOD = 443;tcp;100;5' /etc/csf/csf.conf
  sed -i 's/^PS_INTERVAL =.*/PS_INTERVAL = "120"/' /etc/csf/csf.conf
  sed -i 's/^PS_LIMIT =.*/PS_LIMIT = "5"/' /etc/csf/csf.conf
  sed -i 's/^PS_PERMANENT =.*/PS_PERMANENT = "1"/' /etc/csf/csf.conf
  sed -i 's/^PS_BLOCK_TIME =.*/PS_BLOCK_TIME = "86400"/' /etc/csf/csf.conf
  sed -i 's/^LF_WEBMIN =.*/LF_WEBMIN = "5"/' /etc/csf/csf.conf
  sed -i 's/^LF_WEBMIN_EMAIL_ALERT =.*/LF_WEBMIN_EMAIL_ALERT = "1"/' /etc/csf/csf.conf
  sed -i "s/^LF_ALERT_TO =.*/LF_ALERT_TO = \"${MAGE_ADMIN_EMAIL}\"/" /etc/csf/csf.conf
  sed -i "s/^LF_ALERT_FROM =.*/LF_ALERT_FROM = \"firewall@${MAGE_DOMAIN}\"/" /etc/csf/csf.conf
  sed -i 's/^DENY_IP_LIMIT =.*/DENY_IP_LIMIT = "500000"/' /etc/csf/csf.conf
  sed -i 's/^DENY_TEMP_IP_LIMIT =.*/DENY_TEMP_IP_LIMIT = "2000"/' /etc/csf/csf.conf
  sed -i 's/^LF_IPSET =.*/LF_IPSET = "1"/' /etc/csf/csf.conf
  ### this line will block every blacklisted ip address
  sed -i "/|0|/s/^#//g" /etc/csf/csf.blocklists
  ### scan custom nginx log
  sed -i 's,CUSTOM1_LOG.*,CUSTOM1_LOG = "/var/log/nginx/access.log",' /etc/csf/csf.conf
  sed -i 's,CUSTOM2_LOG.*,CUSTOM2_LOG = "/var/log/nginx/error.log",' /etc/csf/csf.conf
  ### get custom regex template
  curl -o /usr/local/csf/bin/regex.custom.pm ${REPO_MAGENX_TMP}regex.custom.pm
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
 fi
  else
   echo
   YELLOWTXT "Firewall installation was skipped by the user. Next step"
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
include_config ${MAGENX_CONFIG_PATH}/magento
include_config ${MAGENX_CONFIG_PATH}/distro
echo
_echo "[?] Install Webmin Control Panel ? [y/n][n]:"
read webmin_install
if [ "${webmin_install}" == "y" ];then
 echo
 GREENTXT "Webmin package installation:"
 echo
if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
WEBMINEXEC=libexec
cat > /etc/yum.repos.d/webmin.repo <<END
[Webmin]
name=Webmin Distribution
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1
END
rpm --import http://www.webmin.com/jcameron-key.asc
 echo
 dnf -y install webmin
 rpm  --quiet -q webmin
else
 WEBMINEXEC=share
 echo "deb https://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
 wget https://download.webmin.com/jcameron-key.asc
 apt-key add jcameron-key.asc
 apt-get update
 apt-get install webmin
fi
if [ "$?" = 0 ]; then
 echo
 GREENTXT "WEBMIN HAS BEEN INSTALLED  -  OK"
 echo
 WEBMIN_PORT=$(shuf -i 17556-17728 -n 1)
 sed -i 's/theme=gray-theme/theme=authentic-theme/' /etc/webmin/config
 sed -i 's/preroot=gray-theme/preroot=authentic-theme/' /etc/webmin/miniserv.conf
 sed -i "s/port=10000/port=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
 sed -i "s/listen=10000/listen=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
 sed -i '/keyfile=\|certfile=/d' /etc/webmin/miniserv.conf
 echo "keyfile=/etc/letsencrypt/live/${MAGE_DOMAIN}/privkey.pem" >> /etc/webmin/miniserv.conf
 echo "certfile=/etc/letsencrypt/live/${MAGE_DOMAIN}/cert.pem" >> /etc/webmin/miniserv.conf
 
  if [ -f "/usr/local/csf/csfwebmin.tgz" ]; then
    perl /usr/${WEBMINEXEC}/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >/dev/null 2>&1
    GREENTXT "INSTALLED CSF FIREWALL PLUGIN"
  fi
  
  echo "${MAGE_OWNER}_webmin:\$1\$84720675\$F08uAAcIMcN8lZNg9D74p1:::::$(date +%s):::0::::" > /etc/webmin/miniserv.users
  sed -i "s/root:/${MAGE_OWNER}_webmin:/" /etc/webmin/webmin.acl
  WEBMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@#%^?=+_[]{}()<>-' | fold -w 15 | head -n 1)
  /usr/${WEBMINEXEC}/webmin/changepass.pl /etc/webmin/ ${MAGE_OWNER}_webmin "${WEBMIN_PASS}"
  
  systemctl enable webmin
  /etc/webmin/restart
	    
  YELLOWTXT "[!] WEBMIN PORT: ${WEBMIN_PORT}"
  YELLOWTXT "[!] USER: ${MAGE_OWNER}_webmin"
  YELLOWTXT "[!] PASSWORD: ${WEBMIN_PASS}"
  REDTXT "[!] PLEASE ENABLE TWO-FACTOR AUTHENTICATION!"
	    
cat > ${MAGENX_CONFIG_PATH}/webmin <<END
WEBMIN_PORT="${WEBMIN_PORT}"
WEBMIN_USER="${MAGE_OWNER}_webmin"
WEBADMIN_PASS="${WEBADMIN_PASS}"
END
  else
   echo
   REDTXT "WEBMIN INSTALLATION ERROR"
  fi
  else
   echo
   YELLOWTXT "Webmin installation was skipped by the user. Next step"
fi
echo
echo
pause '[] Press [Enter] key to show menu'
echo
;;
"exit")
REDTXT "[!] EXIT"
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
