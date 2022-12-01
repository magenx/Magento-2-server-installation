#!/bin/bash
#=================================================================================#
#        MagenX e-commerce stack for Magento 2                                    #
#        Copyright (C) 2013-present admin@magenx.com                              #
#        All rights reserved.                                                     #
#=================================================================================#
SELF=$(basename $0)
MAGENX_VERSION=$(curl -s https://api.github.com/repos/magenx/Magento-2-server-installation/tags 2>&1 | head -3 | grep -oP '(?<=")\d.*(?=")')
MAGENX_BASE="https://magenx.sh"

# Config path
MAGENX_CONFIG_PATH="/opt/magenx/config"

###################################################################################
###                              REPOSITORY AND PACKAGES                        ###
###################################################################################

# Github installation repository raw url
MAGENX_MSI_REPO="https://raw.githubusercontent.com/magenx/Magento-2-server-installation/master/"

# Magento
MAGENTO_VERSION="2"
MAGENTO_VERSION_LATEST=$(curl -s https://api.github.com/repos/magento/magento${MAGENTO_VERSION}/tags 2>&1 | grep -oP '(?<=name": ").*(?=")' | sort -r)
MAGENTO_PROJECT="composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"

## Version lock
COMPOSER_VERSION="2.2"
RABBITMQ_VERSION="3.9*"
MARIADB_VERSION="10.5.17"
ELK_VERSION="7.x"
ELK_STACK="elasticsearch kibana filebeat"
PROXYSQL_VERSION="2.3.x"
VARNISH_VERSION="70"

# Repositories
MARIADB_REPO_CONFIG="https://downloads.mariadb.com/MariaDB/mariadb_repo_setup"
REMI_RPM_REPO="http://rpms.famillecollet.com/enterprise/remi-release-8.rpm"

# WebStack Packages .deb
EXTRA_PACKAGES_DEB="curl jq gnupg2 auditd apt-transport-https apt-show-versions ca-certificates lsb-release make autoconf snapd automake libtool uuid-runtime \
perl openssl unzip recode ed screen inotify-tools iptables smartmontools clamav mlocate vim wget sudo bc apache2-utils \
logrotate git netcat patch ipset postfix strace rsyslog geoipupdate moreutils lsof sysstat acl attr iotop expect imagemagick snmp"
PERL_MODULES_DEB="liblwp-protocol-https-perl libdbi-perl libconfig-inifiles-perl libdbd-mysql-perl libterm-readkey-perl"
PHP_PACKAGES_DEB=(cli fpm common mysql zip lz4 gd mbstring curl xml bcmath intl ldap soap oauth apcu)

# WebStack Packages .rpm
EXTRA_PACKAGES_RPM="autoconf snapd jq automake libtidy libpcap gettext-devel recode gflags tbb ed lz4 libyaml libdwarf \
bind-utils screen gcc iptraf inotify-tools iptables smartmontools net-tools mlocate unzip vim wget curl sudo bc mailx clamav-filesystem clamav-server \
clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib logrotate git patch ipset strace rsyslog \
ncurses-devel GeoIP GeoIP-devel geoipupdate openssl-devel ImageMagick moreutils lsof net-snmp net-snmp-utils ncftp postfix augeas-libs libffi-devel \
mod_ssl dnf-automatic sysstat libuuid-devel uuid-devel acl attr iotop expect unixODBC gcc-c++"
PHP_PACKAGES_RPM=(cli common fpm opcache gd curl mbstring bcmath soap mcrypt mysqlnd pdo xml xmlrpc intl gmp phpseclib recode \
tcpdf tcpdf-dejavu-sans-fonts tidy snappy ldap lz4) 
PHP_PECL_PACKAGES_RPM=(pecl-redis pecl-lzf pecl-geoip pecl-zip pecl-memcache pecl-oauth pecl-apcu)
PERL_MODULES_RPM=(LWP-Protocol-https Config-IniFiles libwww-perl CPAN Template-Toolkit Time-HiRes ExtUtils-CBuilder ExtUtils-Embed ExtUtils-MakeMaker \
TermReadKey DBI DBD-MySQL Digest-HMAC Digest-SHA1 Test-Simple Moose Net-SSLeay devel)

# Nginx configuration
NGINX_VERSION=$(curl -s http://nginx.org/en/download.html | grep -oP '(?<=gz">nginx-).*?(?=</a>)' | head -1)
MAGENX_NGINX_REPO="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/"
MAGENX_NGINX_REPO_API="https://api.github.com/repos/magenx/Magento-nginx-config/contents/magento2"

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

PKG_INSTALLED="  \033[32;40mInstalled:\033[0m "

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
    echo " Supported: Ubuntu 20.04; Debian 11; RedHat 8|9; Rocky Linux 8|9; Amazon Linux 2"
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
  elif [[ "${OS_NAME%% *}" =~ (Red|Rocky) ]] && [[ "${OS_VERSION//.*}" =~ (8|9) ]]; then
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
    echo "OS_NAME=\"${OS_NAME}\"" > ${MAGENX_CONFIG_PATH}/distro
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
  dpkg-query -l curl time bc bzip2 tar >/dev/null || { apt update -o Acquire::ForceIPv4=true; apt -y install curl time bc bzip2 tar; }
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
    installed_packages="$(rpm -qa --qf '%{name} ' 'mysqld?|firewalld|rabbitmq*|elasticsearch|Percona*|maria*|php-?|nginx*|*ftp*|varnish*|certbot*|redis*|webmin')"
    else
    installed_packages="$(apt -qq list --installed mysql* rabbitmq* elasticsearch percona-server* maria* php* nginx* ufw varnish* certbot* redis* webmin 2> /dev/null | cut -d'/' -f1 | tr '\n' ' ')"
  fi
  if [ ! -z "$installed_packages" ]; then
    REDTXT  "[!] WEBSTACK PACKAGES ALREADY INSTALLED"
    YELLOWTXT "[!] YOU NEED TO REMOVE THEM OR RE-INSTALL MINIMAL OS VERSION"
    echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    echo -e "\t\t dnf remove ${installed_packages} --noautoremove"
  else
    echo -e "\t\t apt purge ${installed_packages}"
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
        echo -e "${DGREYBG}${BOLD}  MAGENTO SERVER CONFIGURATION v.${MAGENX_VERSION}  ${RESET}"
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
  dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION//.*}.noarch.rpm
  dnf config-manager --set-enabled codeready-builder-for-rhel-${OS_VERSION//.*}-rhui-rpms
  dnf -y install ${EXTRA_PACKAGES_RPM} ${PERL_MODULES_RPM[@]/#/perl-} 'dnf-command(versionlock)'
  dnf -y module reset nginx php redis varnish
  dnf -y upgrade --nobest
  echo
 elif [ "${OS_DISTRO_KEY}" == "amazon" ]; then
  dnf install -y yum-utils 'dnf-command(versionlock)'
  amazon-linux-extras install epel -y
  dnf -y install ${EXTRA_PACKAGES_RPM} ${PERL_MODULES_RPM[@]/#/perl-}
  dnf -y upgrade --nobest
  echo
 else
  debconf-set-selections <<< "postfix postfix/mailname string localhost"
  debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
  apt -y install software-properties-common
  apt-add-repository contrib
  apt update
  apt -y install ${EXTRA_PACKAGES_DEB} ${PERL_MODULES_DEB}
  echo
 fi
 if [ "$?" != 0 ]; then
  echo
  REDTXT "[!] INSTALLATION ERROR"
  REDTXT "[!] PLEASE CORRECT AND TRY AGAIN"
  exit 1
  echo
 fi
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
  curl -sS ${MARIADB_REPO_CONFIG} | bash -s -- --mariadb-server-version=${MARIADB_VERSION}
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
    apt update
    apt install -y mariadb-server
  fi
  if [ "$?" = 0 ] # if package installed then configure
    then
     echo
     GREENTXT "DATABASE INSTALLED  -  OK"
     echo
     systemctl enable mariadb
     echo
    if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
     rpm -qa 'mariadb*' | awk -v var="${PKG_INSTALLED}" '{print var,$1}'
    else
     apt -qq list --installed mariadb* 2>/dev/null | awk -v var="${PKG_INSTALLED}" '{print var,$0}'
    fi
     echo
     WHITETXT "Downloading my.cnf file from MagenX Github repository"
     curl -sSo /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
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
     YELLOWTXT "MariaDB repository installation was skipped. Next step"
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
   echo "deb http://nginx.org/packages/mainline/${OS_DISTRO_KEY} $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list
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
   apt update
   apt -y install nginx nginx-module-perl nginx-module-image-filter nginx-module-geoip
  fi
  if [ "$?" = 0 ]; then
    echo
    GREENTXT "NGINX INSTALLED  -  OK"
    echo
    systemctl enable nginx >/dev/null 2>&1
   if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    rpm -qa 'nginx*' | awk -v var="${PKG_INSTALLED}" '{print var,$1}'
   else
    apt -qq list --installed nginx* 2>/dev/null | awk -v var="${PKG_INSTALLED}" '{print var,$0}'
   fi
   else
    echo
    REDTXT "NGINX INSTALLATION ERROR"
   exit
  fi
   else
    echo
    YELLOWTXT "Nginx repository installation was skipped. Next step"
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
  read -e -p "  [?] Enter required PHP version: " -i "8.1" PHP_VERSION
  echo
 if [ "${OS_DISTRO_KEY}" == "redhat" ]; then
  dnf install -y ${REMI_RPM_REPO//8/${OS_VERSION//.*}}
  dnf -y module enable php:remi-${PHP_VERSION}
  dnf config-manager --set-enabled remi >/dev/null 2>&1
  rpm  --quiet -q remi-release
 elif [ "${OS_DISTRO_KEY}" == "amazon" ]; then
  dnf install -y ${REMI_RPM_REPO//8/7}
  dnf config-manager --set-enabled remi >/dev/null 2>&1
  rpm  --quiet -q remi-release
 elif [ "${OS_DISTRO_KEY}" == "debian" ]; then
  curl -sSo /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
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
   apt update
   apt -y install php${PHP_VERSION} ${PHP_PACKAGES_DEB[@]/#/php${PHP_VERSION}-} php-pear
  fi
  if [ "$?" = 0 ]; then
    echo
    GREENTXT "PHP ${PHP_VERSION} INSTALLED  -  OK"
    echo
   if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
    rpm -qa 'php*' | awk -v var="${PKG_INSTALLED}" '{print var,$1}'
   else
    apt -qq list --installed php${PHP_VERSION}* 2>/dev/null | awk -v var="${PKG_INSTALLED}" '{print var,$0}'
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
    YELLOWTXT "Remi repository installation was skipped. Next step"
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
  dnf -y module install redis:remi-6.0
  rpm  --quiet -q redis
 else
  curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
  apt update
  apt -y install redis
 fi
 if [ "$?" = 0 ]; then
     echo
     GREENTXT "REDIS INSTALLED OK"
     systemctl disable redis
     echo
    if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
     rpm -qa 'redis*' | awk -v var="${PKG_INSTALLED}" '{print var,$1}'
     redis_conf="/etc/redis.conf"
        else
     apt -qq list --installed redis-server* 2>/dev/null | awk -v var="${PKG_INSTALLED}" '{print var,$0}'
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
   YELLOWTXT "Redis installation was skipped. Next step"
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
   dnf -y install rabbitmq-server-${RABBITMQ_VERSION}
   rpm  --quiet -q rabbitmq-server
 else
  curl -sSL https://packages.erlang-solutions.com/${OS_DISTRO_KEY}/erlang_solutions.asc | apt-key add -
  echo "deb https://packages.erlang-solutions.com/${OS_DISTRO_KEY} $(lsb_release -cs) contrib" | tee /etc/apt/sources.list.d/erlang.list
  curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | bash
  apt -y install rabbitmq-server=${RABBITMQ_VERSION}
 fi
 if [ "$?" = 0 ]; then
 
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

## delete guest and create magento user
RABBITMQ_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
rabbitmqctl delete_user guest
rabbitmqctl add_user magento ${RABBITMQ_PASSWORD}
rabbitmqctl set_permissions -p / magento ".*" ".*" ".*"

cat > ${MAGENX_CONFIG_PATH}/rabbitmq <<END
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
END
   GREENTXT "RabbitMQ INSTALLED  -  OK"
   echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   rpm -qa 'rabbitmq*' 'erlang*' | awk -v var="${PKG_INSTALLED}" '{print var,$1}'
  else
   apt -qq list --installed rabbitmq* erlang* 2>/dev/null | awk -v var="${PKG_INSTALLED}" '{print var,$0}'
  fi
  else
   echo
   REDTXT "RabbitMQ INSTALLATION ERROR"
   exit 1
  fi
  else
   echo
   YELLOWTXT "RabbitMQ installation was skipped. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo
_echo "[?] Install Varnish Cache ? [y/n][n]:"
read varnish_install
if [ "${varnish_install}" == "y" ];then
 if [ "${OS_DISTRO_KEY}" == "redhat" ]; then
   curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.rpm.sh | bash
   dnf -y install varnish
   rpm  --quiet -q varnish
  elif [ "${OS_DISTRO_KEY}" == "amazon" ]; then
   curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.rpm.sh | bash os=el dist=7
   echo
   dnf -y install varnish
   rpm  --quiet -q varnish
  else
  curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.deb.sh | bash
  apt update
  apt -y install varnish
 fi
 if [ "$?" = 0 ]; then
   echo
   curl -sSo /etc/systemd/system/varnish.service ${MAGENX_MSI_REPO}varnish.service
   curl -sSo /etc/varnish/varnish.params ${MAGENX_MSI_REPO}varnish.params
   uuidgen > /etc/varnish/secret
   systemctl daemon-reload
   GREENTXT "VARNISH INSTALLED  -  OK"
   echo
  if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   rpm -qa 'varnish*' | awk -v var="${PKG_INSTALLED}" '{print var,$1}'
  else
   apt -qq list --installed varnish* 2>/dev/null | awk -v var="${PKG_INSTALLED}" '{print var,$0}'
  fi
  else
   echo
   REDTXT "VARNISH INSTALLATION ERROR"
   exit 1
  fi
  else
   echo
   YELLOWTXT "Varnish installation was skipped. Next step"
fi
echo
WHITETXT "============================================================================="
echo
_echo "[?] Install ElasticSearch ${ELK_VERSION} ? [y/n][n]:"
read elastic_install
if [ "${elastic_install}" == "y" ];then
echo
if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
GREENTXT "Elasticsearch installation:"
echo
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elastic.repo << EOF
[elasticsearch-${ELK_VERSION}]
name=Elasticsearch repository for ${ELK_VERSION} packages
baseurl=https://artifacts.elastic.co/packages/${ELK_VERSION}/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
echo
   dnf -y install --enablerepo=elasticsearch-${ELK_VERSION} ${ELK_STACK}
   rpm  --quiet -q ${ELK_STACK}
  else
   curl -sSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
   echo "deb https://artifacts.elastic.co/packages/${ELK_VERSION}/apt stable main" > /etc/apt/sources.list.d/elastic-${ELK_VERSION}.list
   apt update
   apt -y install ${ELK_STACK}
  fi
  if [ "$?" = 0 ]; then
echo
## elasticsearch settings
if ! grep -q "xpack.security.enabled: true" /etc/elasticsearch/elasticsearch.yml >/dev/null 2>&1 ; then
echo "discovery.type: single-node" >> /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*cluster.name.*/cluster.name: magento/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*node.name.*/node.name: magento-node1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*network.host.*/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*http.port.*/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*-Xms.*/-Xms512m/" /etc/elasticsearch/jvm.options
sed -i "s/.*-Xmx.*/-Xmx2048m/" /etc/elasticsearch/jvm.options
## use builtin java
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
  sed -i "s,#ES_JAVA_HOME=,ES_JAVA_HOME=/usr/share/elasticsearch/jdk/," /etc/sysconfig/elasticsearch
 else
  sed -i "s,#ES_JAVA_HOME=,ES_JAVA_HOME=/usr/share/elasticsearch/jdk/," /etc/default/elasticsearch
 fi
fi

chown -R :elasticsearch /etc/elasticsearch/*
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service

if [ ! -f ${MAGENX_CONFIG_PATH}/elasticsearch ]; then
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
fi

include_config ${MAGENX_CONFIG_PATH}/elasticsearch

## kibana settings
KIBANA_PORT=$(shuf -i 15741-15997 -n 1)
sed -i "s/.*#server.port:.*/server.port: ${KIBANA_PORT}/" /etc/kibana/kibana.yml
sed -i "s/.*#server.host:.*/server.host: \"0.0.0.0\"/" /etc/kibana/kibana.yml
sed -i "s/.*#elasticsearch.username:.*/elasticsearch.username: \"kibana_system\"/" /etc/kibana/kibana.yml
sed -i "s/.*#elasticsearch.password:.*/elasticsearch.password: \"${KIBANA_SYSTEM_PASSWORD}\"/" /etc/kibana/kibana.yml
echo
YELLOWTXT "KIBANA PORT :${KIBANA_PORT}"
echo
for elk_user in logs indexer
do
ROLE_CREATED=$(curl -X POST -u elastic:${ELASTIC_PASSWORD} "http://127.0.0.1:9200/_security/role/magento_${elk_user}" \
-H 'Content-Type: application/json' -sS \
-d @<(cat <<EOF
{
  "cluster": ["manage_index_templates", "monitor", "manage_ilm"],
  "indices": [
    {
      "names": [ "magento_${elk_user}*"],
      "privileges": ["all"]
    }
  ]
}
EOF
)|jq -r ".role.created")
USER_ENABLED=$(curl -X GET -u elastic:${ELASTIC_PASSWORD} "http://127.0.0.1:9200/_security/user/magento_${elk_user}" \
-H 'Content-Type: application/json' -sS | jq -r ".[].enabled")
if [[ ${ROLE_CREATED} == true ]] && [[ ${USER_ENABLED} != true ]]; then
echo
USER_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
echo MAGENTO_${elk_user^^}_PASSWORD=\"${USER_PASSWORD}\" >> ${MAGENX_CONFIG_PATH}/elasticsearch
echo
curl -X POST -u elastic:${ELASTIC_PASSWORD} "http://127.0.0.1:9200/_security/user/magento_${elk_user}" \
-H 'Content-Type: application/json' -sS \
-d "$(cat <<EOF
{
  "password" : "${USER_PASSWORD}",
  "roles" : [ "magento_${elk_user}"],
  "full_name" : "ELK User for Magento 2 ${elk_user}"
}
EOF
)"
else
REDTXT "  [!] ELK return error for role magento_${elk_user} "
fi
done

rm -rf /tmp/elasticsearch

echo
echo
GREENTXT "ELASTICSEARCH ${ELK_VERSION} INSTALLED  -  OK"
echo
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
  rpm -qa '${ELK_STACK}' | awk -v var="${PKG_INSTALLED}" '{print var,$1}'
 else
  apt -qq list --installed ${ELK_STACK} 2>/dev/null | awk -v var="${PKG_INSTALLED}" '{print var,$0}'
 fi
 else
echo
REDTXT "ELASTICSEARCH INSTALLATION ERROR"
exit 1
fi
else
echo
YELLOWTXT "ElasticSearch installation was skipped. Next step"
fi
echo
echo
## keep versions for critical services to avoid disruption
 if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
   dnf versionlock add ${ELK_STACK} erlang rabbitmq-server
  else
   apt-mark hold ${ELK_STACK} erlang rabbitmq-server
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
BLUEBG "[~]    DOWNLOAD MAGENTO ${MAGENTO_VERSION}    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo
echo
     _echo "[?] GET YOUR MAGENTO VERSION: "
     updown_menu "$(curl -s https://api.github.com/repos/magento/magento2/tags 2>&1 | grep -oP '(?<=name": ").*(?=")' | sort -r)" MAGENTO_VERSION_INSTALLED
     echo
     echo
     read -e -p "  [?] ENTER YOUR DOMAIN OR IP ADDRESS: " -i "storedomain.net" MAGENTO_DOMAIN
     read -e -p "  [?] ENTER MAGENTO FILES OWNER NAME: " -i "example" MAGENTO_OWNER
	 
     MAGENTO_WEB_ROOT_PATH="/home/${MAGENTO_OWNER}/public_html"
	 
     echo
     _echo "[!] MAGENTO ${MAGENTO_VERSION_INSTALLED} WILL BE DOWNLOADED TO ${MAGENTO_WEB_ROOT_PATH}"
     echo

          mkdir -p ${MAGENTO_WEB_ROOT_PATH} && cd $_
          ## create root user
          useradd -d ${MAGENTO_WEB_ROOT_PATH%/*} -s /bin/bash ${MAGENTO_OWNER}
          ## create root php user
          MAGENTO_PHP_USER="php-${MAGENTO_OWNER}"
          useradd -M -s /sbin/nologin -d ${MAGENTO_WEB_ROOT_PATH%/*} ${MAGENTO_PHP_USER}
          usermod -g ${MAGENTO_PHP_USER} ${MAGENTO_OWNER}
          chmod 711 ${MAGENTO_WEB_ROOT_PATH%/*}
	  mkdir -p ${MAGENTO_WEB_ROOT_PATH%/*}/{.config,.cache,.local,.composer}
	  chmod 2750 ${MAGENTO_WEB_ROOT_PATH%/*}/{.config,.cache,.local,.composer}
	  chown -R ${MAGENTO_OWNER}:${MAGENTO_OWNER} ${MAGENTO_WEB_ROOT_PATH%/*}/{.config,.cache,.local,.composer}
          chown -R ${MAGENTO_OWNER}:${MAGENTO_PHP_USER} ${MAGENTO_WEB_ROOT_PATH}
          chmod 2750 ${MAGENTO_WEB_ROOT_PATH}
	  setfacl -R -m m:rx,u:${MAGENTO_OWNER}:rwx,g:${MAGENTO_PHP_USER}:r-x,o::-,d:u:${MAGENTO_OWNER}:rwx,d:g:${MAGENTO_PHP_USER}:r-x,d:o::- ${MAGENTO_WEB_ROOT_PATH}
	  setfacl -R -m u:nginx:r-x,d:u:nginx:r-x ${MAGENTO_WEB_ROOT_PATH}
	  
echo
MAGENTO_MINIMAL_OPT="MINIMAL SET OF MODULES"
GREENTXT "${MAGENTO_MINIMAL_OPT} INSTALLATION"
echo
GREENTXT "Benefits of removing bloatware packages:"
WHITETXT "[!] Better memory allocation!"
WHITETXT "[!] Faster cli, backend and frontend operations!"
WHITETXT "[!] Less maintenance work!"
WHITETXT "[!] Less dependencies and security risks!"
echo
pause '[] Press [Enter] key to start'
echo

## composer version 2 latest
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --${COMPOSER_VERSION} --install-dir=/usr/bin --filename=composer
php -r "unlink('composer-setup.php');"

su ${MAGENTO_OWNER} -s /bin/bash -c "composer -n -q config -g http-basic.repo.magento.com 8c681734f22763b50ea0c29dff9e7af2 02dfee497e669b5db1fe1c8d481d6974"
su ${MAGENTO_OWNER} -s /bin/bash -c "${MAGENTO_PROJECT}=${MAGENTO_VERSION_INSTALLED} . --no-install"
curl -sO ${MAGENX_MSI_REPO}composer_replace

##replace?
sed -i '/"conflict":/ {
r composer_replace
N
}' composer.json
##replace?

rm composer_replace
su ${MAGENTO_OWNER} -s /bin/bash -c "composer install"

su ${MAGENTO_OWNER} -s /bin/bash -c "echo 007 > magento_umask"
su ${MAGENTO_OWNER} -s /bin/bash -c "mkdir -p var/tmp"
setfacl -R -m u:${MAGENTO_OWNER}:rwx,g:${MAGENTO_PHP_USER}:rwx,o::-,d:u:${MAGENTO_OWNER}:rwx,d:g:${MAGENTO_PHP_USER}:rwx,d:o::- var pub/media

## make magento great again
sed -i "s/2-4/2-5/" app/etc/di.xml

echo
GREENTXT "[~]    MAGENTO ${MAGENTO_MINIMAL_OPT} DOWNLOADED AND READY FOR SETUP    [~]"
WHITETXT "--------------------------------------------------------------------"
echo

mkdir -p ${MAGENX_CONFIG_PATH}
cat > ${MAGENX_CONFIG_PATH}/magento <<END
# ${MAGENTO_MINIMAL_OPT}
MAGENTO_VERSION="2"
MAGENTO_VERSION_INSTALLED="${MAGENTO_VERSION_INSTALLED}"
MAGENTO_DOMAIN="${MAGENTO_DOMAIN}"
MAGENTO_OWNER="${MAGENTO_OWNER}"
MAGENTO_PHP_USER="${MAGENTO_PHP_USER}"
MAGENTO_WEB_ROOT_PATH="${MAGENTO_WEB_ROOT_PATH}"
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
fi
chmod 600 /root/.my.cnf /root/.mytop
echo
GREENTXT "GENERATE MYSQL USER AND DATABASE NAMES WITH NEW PASSWORD"
MAGENTO_DB_PASSWORD_GEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9%^&=+_{}()<>-' | fold -w 15 | head -n 1)
MAGENTO_DB_PASSWORD="${MAGENTO_DB_PASSWORD_GEN}${RANDOM}"
MAGENTO_DB_HASH="$(openssl rand -hex 4)"
echo
MAGENTO_DB_HOST="localhost" 
MAGENTO_DB_NAME="${MAGENTO_DOMAIN//[-.]/}_m${MAGENTO_VERSION}_${MAGENTO_DB_HASH}_live" 
MAGENTO_DB_USER="${MAGENTO_DOMAIN//[-.]/}_m${MAGENTO_VERSION}_${MAGENTO_DB_HASH}"
GREENTXT "CREATE MYSQL STATEMENT AND EXECUTE IT"
echo
mariadb <<EOMYSQL
CREATE USER '${MAGENTO_DB_USER}'@'${MAGENTO_DB_HOST}' IDENTIFIED BY '${MAGENTO_DB_PASSWORD}';
CREATE DATABASE ${MAGENTO_DB_NAME};
GRANT ALL PRIVILEGES ON ${MAGENTO_DB_NAME}.* TO '${MAGENTO_DB_USER}'@'${MAGENTO_DB_HOST}' WITH GRANT OPTION;
exit
EOMYSQL

GREENTXT "SAVE VARIABLES TO CONFIG FILE"
mkdir -p ${MAGENX_CONFIG_PATH}
cat > ${MAGENX_CONFIG_PATH}/database <<END
MAGENTO_DB_HOST="${MAGENTO_DB_HOST}"
MAGENTO_DB_NAME="${MAGENTO_DB_NAME}"
MAGENTO_DB_USER="${MAGENTO_DB_USER}"
MAGENTO_DB_PASSWORD="${MAGENTO_DB_PASSWORD}"
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
BLUEBG   "[~]    MAGENTO ${MAGENTO_VERSION_INSTALLED} SETUP    [~]"
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
echo
echo
cd ${MAGENTO_WEB_ROOT_PATH}
chown -R ${MAGENTO_OWNER}:${MAGENTO_PHP_USER} *
chmod u+x bin/magento
echo
WHITETXT "Admin name, email and base url"
echo
read -e -p "  [?] Admin first name: " -i "Magento"  MAGENTO_ADMIN_FIRSTNAME
read -e -p "  [?] Admin last name: " -i "Administrator"  MAGENTO_ADMIN_LASTNAME
read -e -p "  [?] Admin email: " -i "admin@${MAGENTO_DOMAIN}"  MAGENTO_ADMIN_EMAIL
read -e -p "  [?] Admin login name: " -i "admin"  MAGENTO_ADMIN_LOGIN
MAGENTO_ADMIN_PASSWORD_GEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 10 | head -n 1)
read -e -p "  [?] Admin password: " -i "${MAGENTO_ADMIN_PASSWORD_GEN}${RANDOM}"  MAGENTO_ADMIN_PASSWORD
read -e -p "  [?] Shop base url: " -i "http://${MAGENTO_DOMAIN}/"  MAGENTO_BASE_URL
echo
WHITETXT "Language, Currency and Timezone settings"
updown_menu "$(bin/magento info:language:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGENTO_LOCALE
updown_menu "$(bin/magento info:currency:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGENTO_CURRENCY
updown_menu "$(bin/magento info:timezone:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGENTO_TIMEZONE
echo
echo
GREENTXT "SETUP MAGENTO ${MAGENTO_VERSION} (${MAGENTO_VERSION_INSTALLED}) WITHOUT SAMPLE DATA"
echo
pause '[] Press [Enter] key to run setup'
echo
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento setup:install --base-url=${MAGENTO_BASE_URL} \
--db-host=${MAGENTO_DB_HOST} \
--db-name=${MAGENTO_DB_NAME} \
--db-user=${MAGENTO_DB_USER} \
--db-password='${MAGENTO_DB_PASSWORD}' \
--admin-firstname=${MAGENTO_ADMIN_FIRSTNAME} \
--admin-lastname=${MAGENTO_ADMIN_LASTNAME} \
--admin-email=${MAGENTO_ADMIN_EMAIL} \
--admin-user=${MAGENTO_ADMIN_LOGIN} \
--admin-password='${MAGENTO_ADMIN_PASSWORD}' \
--language=${MAGENTO_LOCALE} \
--currency=${MAGENTO_CURRENCY} \
--timezone=${MAGENTO_TIMEZONE} \
--cleanup-database \
--use-rewrites=1 \
--session-save=redis \
--session-save-redis-host=127.0.0.1 \
--session-save-redis-port=6379 \
--session-save-redis-log-level=3 \
--session-save-redis-db=0 \
--session-save-redis-compression-lib=lz4 \
--cache-backend=redis \
--cache-backend-redis-server=127.0.0.1 \
--cache-backend-redis-port=6380 \
--cache-backend-redis-db=0 \
--cache-backend-redis-compress-data=1 \
--cache-backend-redis-compression-lib=l4z \
--amqp-host=127.0.0.1 \
--amqp-port=5672 \
--amqp-user=magento \
--amqp-password='${RABBITMQ_PASSWORD}' \
--amqp-virtualhost='/' \
--consumers-wait-for-messages=0 \
--search-engine=elasticsearch7 \
--elasticsearch-host=127.0.0.1 \
--elasticsearch-port=9200 \
--elasticsearch-index-prefix=magento_indexer_${MAGENTO_DOMAIN} \
--elasticsearch-enable-auth=1 \
--elasticsearch-username=magento_indexer \
--elasticsearch-password='${MAGENTO_INDEXER_PASSWORD}'"


if [ "$?" != 0 ]; then
  echo
  REDTXT "[!] SETUP ERROR"
  REDTXT "[!] PLEASE CORRECT AND TRY AGAIN"
  echo
  exit 1
fi

mkdir -p ${MAGENX_CONFIG_PATH}
mysqldump --single-transaction --routines --triggers --events ${MAGENTO_DB_NAME} | gzip > ${MAGENX_CONFIG_PATH}/${MAGENTO_DB_NAME}.sql.gz
cp app/etc/env.php  ${MAGENX_CONFIG_PATH}/env.php.default
echo
echo
echo
    WHITETXT "============================================================================="
    echo
    GREENTXT "INSTALLED MAGENTO ${MAGENTO_VERSION_INSTALLED} WITHOUT SAMPLE DATA"
    echo
    WHITETXT "============================================================================="
echo
cat > ${MAGENX_CONFIG_PATH}/install <<END
MAGENTO_ADMIN_LOGIN="${MAGENTO_ADMIN_LOGIN}"
MAGENTO_ADMIN_PASSWORD="${MAGENTO_ADMIN_PASSWORD}"
MAGENTO_ADMIN_EMAIL="${MAGENTO_ADMIN_EMAIL}"
MAGENTO_TIMEZONE="${MAGENTO_TIMEZONE}"
MAGENTO_LOCALE="${MAGENTO_LOCALE}"
MAGENTO_ADMIN_PATH="$(grep -Po "(?<='frontName' => ')\w*(?=')" ${MAGENTO_WEB_ROOT_PATH}/app/etc/env.php)"
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
  php_fpm_pool_path="/etc/php-fpm.d/"
  php_ini_path_overrides="/etc/php.d/"
 else
  PHP_VERSION="$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")"
  php_ini="/etc/php/${PHP_VERSION}/fpm/php.ini"
  php_fpm_pool_path="/etc/php/${PHP_VERSION}/fpm/pool.d/"
  php_ini_path_overrides="/etc/php/${PHP_VERSION}/{cli,fpm}/conf.d/"
fi

echo
BLUEBG "[~]    POST-INSTALLATION CONFIGURATION    [~]"
WHITETXT "-------------------------------------------------------------------------------------"
echo
## filebeat settings
curl -o /etc/filebeat/filebeat.yml -s ${MAGENX_MSI_REPO}filebeat.yml
sed -i "s|MAGENTO_WEB_ROOT_PATH|${MAGENTO_WEB_ROOT_PATH}|" /etc/filebeat/filebeat.yml
sed -i "s|MAGENTO_TIMEZONE|${MAGENTO_TIMEZONE}|" /etc/filebeat/filebeat.yml
sed -i "s/MAGENTO_DOMAIN/${MAGENTO_DOMAIN}/" /etc/filebeat/filebeat.yml
sed -i "s/MAGENTO_LOGS_PASSWORD/${MAGENTO_LOGS_PASSWORD}/" /etc/filebeat/filebeat.yml

systemctl restart filebeat kibana

echo
cat >> /etc/sysctl.conf <<END
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

GREENTXT "SERVER HOSTNAME SETTINGS"
hostnamectl set-hostname server.${MAGENTO_DOMAIN} --static
echo
GREENTXT "CREATE MOTD"
curl -o /etc/motd -s ${MAGENX_MSI_REPO}motd
sed -i "s/MAGENTO_VERSION_INSTALLED/${MAGENTO_VERSION_INSTALLED}/" /etc/motd
sed -i "s/MAGENX_VERSION/${MAGENX_VERSION}/" /etc/motd
echo
GREENTXT "SERVER TIMEZONE SETTINGS"
timedatectl set-timezone ${MAGENTO_TIMEZONE}
echo
GREENTXT "MYSQL TOOLS AND PROXYSQL"
curl -sSo /usr/local/bin/mysqltuner ${MYSQL_TUNER}
curl -sSo /usr/local/bin/mytop ${MYSQL_TOP}

if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
cat > /etc/yum.repos.d/proxysql.repo <<END
   [proxysql_repo]
   name=ProxySQL YUM repository
   baseurl=https://repo.proxysql.com/ProxySQL/proxysql-${PROXYSQL_VERSION}/centos/latest
   gpgcheck=1
   gpgkey=https://repo.proxysql.com/ProxySQL/repo_pub_key
END
   dnf -y install proxysql*
 else
   curl -sS 'https://repo.proxysql.com/ProxySQL/repo_pub_key' | apt-key add - 
   echo deb https://repo.proxysql.com/ProxySQL/proxysql-${PROXYSQL_VERSION}/$(lsb_release -sc)/ ./ | tee /etc/apt/sources.list.d/proxysql.list
   apt update
   apt -y install proxysql*
fi

systemctl disable proxysql

echo
GREENTXT "PHP SETTINGS"

cat <<END | eval tee ${php_ini_path_overrides}/zz-${MAGENTO_OWNER}-overrides.ini 
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
date.timezone = "${MAGENTO_TIMEZONE}"
END

echo
GREENTXT "PHP-FPM SETTINGS"

cat > ${php_fpm_pool_path}/${MAGENTO_OWNER}.conf <<END
[${MAGENTO_OWNER}]

user = php-\$pool
group = php-\$pool

listen = /var/run/\$pool.sock
listen.owner = nginx
listen.group = php-\$pool
listen.mode = 0660

pm = ondemand
pm.max_children = 100
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 10000

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
php_admin_value[date.timezone] = "${MAGENTO_TIMEZONE}"
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
echo
GREENTXT "NGINX SETTINGS"
curl -sSo /etc/nginx/fastcgi_params  ${MAGENX_NGINX_REPO}magento${MAGENTO_VERSION}/fastcgi_params
curl -sSo /etc/nginx/nginx.conf  ${MAGENX_NGINX_REPO}magento${MAGENTO_VERSION}/nginx.conf
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
curl -s ${MAGENX_NGINX_REPO_API}/sites-available 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -sO "$4)}' >/dev/null
ln -s /etc/nginx/sites-available/magento${MAGENTO_VERSION}.conf /etc/nginx/sites-enabled/magento${MAGENTO_VERSION}.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
mkdir -p /etc/nginx/conf_m${MAGENTO_VERSION} && cd /etc/nginx/conf_m${MAGENTO_VERSION}/
curl -s ${MAGENX_NGINX_REPO_API}/conf_m2 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -sO "$4)}' >/dev/null

sed -i "s/example.com/${MAGENTO_DOMAIN}/g" /etc/nginx/sites-available/magento${MAGENTO_VERSION}.conf
sed -i "s/example.com/${MAGENTO_DOMAIN}/g" /etc/nginx/nginx.conf
sed -i "s,/var/www/html,${MAGENTO_WEB_ROOT_PATH}," /etc/nginx/conf_m${MAGENTO_VERSION}/maps.conf

PROFILER_PLACEHOLDER="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)"
sed -i "s/PROFILER_PLACEHOLDER/${PROFILER_PLACEHOLDER}/" /etc/nginx/conf_m${MAGENTO_VERSION}/maps.conf
sed -i "s|127.0.0.1:9000|unix:/var/run/${MAGENTO_OWNER}.sock|" /etc/nginx/conf_m${MAGENTO_VERSION}/maps.conf

sed -i "s/ADMIN_PLACEHOLDER/${MAGENTO_ADMIN_PATH}/g" /etc/nginx/conf_m${MAGENTO_VERSION}/extra_protect.conf
ADMIN_HTTP_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
htpasswd -b -c /etc/nginx/.admin ${MAGENTO_ADMIN_LOGIN} ${ADMIN_HTTP_PASSWORD}  >/dev/null 2>&1

echo
GREENTXT "PHPMYADMIN INSTALLATION AND CONFIGURATION"
PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
PMA_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
BLOWFISH_SECRET=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p /usr/share/phpMyAdmin && cd $_
composer -n create-project phpmyadmin/phpmyadmin .
cp config.sample.inc.php config.inc.php
sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';/" config.inc.php
sed -i "s|.*UploadDir.*|\$cfg['UploadDir'] = '/tmp/';|"  config.inc.php
sed -i "s|.*SaveDir.*|\$cfg['SaveDir'] = '/tmp/';|"  config.inc.php
sed -i "/SaveDir/a\
\$cfg['TempDir'] = '\/tmp\/';"  config.inc.php

sed -i "s/PHPMYADMIN_PLACEHOLDER/mysql_${PMA_FOLDER}/g" /etc/nginx/conf_m${MAGENTO_VERSION}/phpmyadmin.conf
     sed -i "5i \\
           auth_basic \$authentication; \\
           auth_basic_user_file .mysql;"  /etc/nginx/conf_m${MAGENTO_VERSION}/phpmyadmin.conf
	 	   
PHP_FPM_LISTEN="php${PHP_VERSION}-fpm.sock"
sed -i "s|^listen =.*|listen = /var/run/${PHP_FPM_LISTEN}|" ${php_fpm_pool_path}/www.conf
sed -i "s/^listen.owner.*/listen.owner = nginx/" ${php_fpm_pool_path}/www.conf
sed -i "s|127.0.0.1:9000|unix:/var/run/${PHP_FPM_LISTEN}|"  /etc/nginx/conf_m${MAGENTO_VERSION}/phpmyadmin.conf

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
    systemctl enable varnish.service
    chmod u+x ${MAGENTO_WEB_ROOT_PATH}/bin/magento
    su ${MAGENTO_OWNER} -s /bin/bash -c "${MAGENTO_WEB_ROOT_PATH}/bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2"
    php ${MAGENTO_WEB_ROOT_PATH}/bin/magento varnish:vcl:generate --export-version=6 --output-file=/etc/varnish/default.vcl
    sed -i "s,pub/health_,health_,g" /etc/varnish/default.vcl
    sed -i 's,if (req.url ~ "^/(pub/)?(media|static)/"),if (req.url ~ "^/media/"),' /etc/varnish/default.vcl
    sed -i '/# Static files should/{n;s/^/\t#/}' /etc/varnish/default.vcl
    sed -i 's/#unset/unset/g' /etc/varnish/default.vcl
    systemctl restart varnish.service
    curl -sSo /etc/varnish/devicedetect.vcl https://raw.githubusercontent.com/varnishcache/varnish-devicedetect/master/devicedetect.vcl
    curl -sSo /etc/varnish/devicedetect-include.vcl ${MAGENX_MSI_REPO}devicedetect-include.vcl
    YELLOWTXT "VARNISH CACHE PORT :8081"
fi
echo
GREENTXT "DOWNLOADING n98-MAGERUN2"
curl -s -o /usr/local/bin/magerun2 https://files.magerun.net/n98-magerun2.phar
echo
GREENTXT "CACHE CLEANER SCRIPT"
echo "${MAGENTO_OWNER} ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart php*fpm.service, /usr/bin/systemctl restart nginx.service" >>  /etc/sudoers
cat > /usr/local/bin/cacheflush <<END
#!/bin/bash
magerun2 cache:flush
sudo /usr/bin/systemctl restart php*fpm.service
sudo /usr/bin/systemctl restart nginx.service
END
echo
GREENTXT "SYSTEM AUTO UPDATE WITH DNF AUTOMATIC"
if [[ "${OS_DISTRO_KEY}" =~ (redhat|amazon) ]]; then
sed -i 's/upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
sed -i 's/emit_via = stdio/emit_via = email/' /etc/dnf/automatic.conf
sed -i "s/email_from =.*/email_from = dnf-automatic@${MAGENTO_DOMAIN}/" /etc/dnf/automatic.conf
sed -i "s/email_to = root/email_to = ${MAGENTO_ADMIN_EMAIL}/" /etc/dnf/automatic.conf
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
${MAGENTO_WEB_ROOT_PATH}/var/log/*.log
{
su ${MAGENTO_OWNER} ${MAGENTO_PHP_USER}
create 660 ${MAGENTO_OWNER} ${MAGENTO_PHP_USER}
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
curl -sSLo maldetect-current.tar.gz ${MALDET}
tar -zxf maldetect-current.tar.gz
cd maldetect-*/
./install.sh

sed -i 's/email_alert="0"/email_alert="1"/' /usr/local/maldetect/conf.maldet
sed -i "s/you@domain.com/${MAGENTO_ADMIN_EMAIL}/" /usr/local/maldetect/conf.maldet
sed -i 's/quarantine_hits="0"/quarantine_hits="1"/' /usr/local/maldetect/conf.maldet
sed -i '/default_monitor_mode="users"/d' /usr/local/maldetect/conf.maldet
sed -i 's,# default_monitor_mode="/usr/local/maldetect/monitor_paths",default_monitor_mode="/usr/local/maldetect/monitor_paths",' /usr/local/maldetect/conf.maldet
sed -i 's/inotify_base_watches="16384"/inotify_base_watches="35384"/' /usr/local/maldetect/conf.maldet

echo -e "${MAGENTO_WEB_ROOT_PATH%/*}" > /usr/local/maldetect/monitor_paths

maldet --monitor /usr/local/maldetect/monitor_paths
echo
GREENTXT "AUDIT MAGENTO FILES AND FOLDERS"
cat >> /etc/audit/rules.d/audit.rules <<END

## audit magento files
-a never,exit -F dir=${MAGENTO_WEB_ROOT_PATH}/var/ -k exclude
-w ${MAGENTO_WEB_ROOT_PATH} -p wa -k ${MAGENTO_OWNER}
END
service auditd reload
service auditd restart
auditctl -l
echo
echo
GREENTXT "ROOT CRONJOBS"
echo 'MAILTO=""' > rootcron
echo "5 8 * * 7 perl /usr/local/bin/mysqltuner --nocolor 2>&1 | mailx -s \"MYSQLTUNER WEEKLY REPORT at ${MAGENTO_DOMAIN}\" ${MAGENTO_ADMIN_EMAIL}" >> rootcron
crontab rootcron
rm rootcron
echo
cd ${MAGENTO_WEB_ROOT_PATH}
# varnish cache hosts
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento setup:config:set --http-cache-hosts=127.0.0.1:8081"
echo
systemctl daemon-reload
systemctl restart nginx.service
systemctl restart php*fpm.service

chown -R ${MAGENTO_OWNER}:${MAGENTO_PHP_USER} ${MAGENTO_WEB_ROOT_PATH}
echo
GREENTXT "CLEAN MAGENTO CACHE ADD OPTIMIZATIONS AND ENABLE PRODUCTION MODE"
rm -rf var/*
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set trans_email/ident_general/email ${MAGENTO_ADMIN_EMAIL}"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set web/url/catalog_media_url_format image_optimization_parameters"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set dev/css/minify_files 1"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set dev/js/minify_files 1"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set dev/js/move_script_to_bottom 1"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set web/secure/enable_hsts 1"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set web/secure/enable_upgrade_insecure 1"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento config:set dev/caching/cache_user_defined_attributes 1"

#su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento module:disable Magento_TwoFactorAuth Magento_AdobeIms Magento_AdobeImsApi Magento_AdminAdobeIms"
su ${MAGENTO_OWNER} -s /bin/bash -c "mkdir -p var/tmp"
su ${MAGENTO_OWNER} -s /bin/bash -c "composer config --no-plugins allow-plugins.cweagans/composer-patches true"
su ${MAGENTO_OWNER} -s /bin/bash -c "composer require magento/quality-patches cweagans/composer-patches -n"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento setup:upgrade"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento deploy:mode:set production"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento cache:flush"

rm -rf ${MAGENTO_WEB_ROOT_PATH}/var/log/*.log

getfacl -R ../public_html > ${MAGENX_CONFIG_PATH}/public_html.acl

echo
GREENTXT "SAVING composer.json , env.php , config.php"
cp composer.json ${MAGENX_CONFIG_PATH}/composer.json.saved
cp composer.lock ${MAGENX_CONFIG_PATH}/composer.lock.saved
cp app/etc/env.php ${MAGENX_CONFIG_PATH}/env.php.saved
cp app/etc/config.php ${MAGENX_CONFIG_PATH}/config.php.saved
echo
echo
GREENTXT "MAGENTO CRONJOBS"
cd ${MAGENTO_WEB_ROOT_PATH}
chmod ug+x bin/magento
su ${MAGENTO_PHP_USER} -s /bin/bash -c "bin/magento cron:install"
echo

cd ${MAGENTO_WEB_ROOT_PATH%/*}

GREENTXT "GENERATE SSH KEYS"
mkdir .ssh
MAGENTO_OWNER_SSHKEY="${MAGENTO_OWNER}_sshkey"
ssh-keygen -o -a 256 -t ed25519 -f ${MAGENX_CONFIG_PATH}/${MAGENTO_OWNER_SSHKEY} -C "magento ${MAGENTO_DOMAIN}" -q -N ""
cat ${MAGENX_CONFIG_PATH}/${MAGENTO_OWNER_SSHKEY}.pub > .ssh/authorized_keys
echo "MAGENTO_OWNER_SSHKEY" >> ${MAGENX_CONFIG_PATH}/magento
echo "${MAGENTO_OWNER_SSHKEY}" >> ${MAGENX_CONFIG_PATH}/magento

echo "" >> ${MAGENX_CONFIG_PATH}/magento

GITHUB_ACTIONS_SSHKEY="github_actions_sshkey"
ssh-keygen -o -a 256 -t ed25519 -f ${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSHKEY} -C "github actions ${MAGENTO_DOMAIN}" -q -N ""
cat ${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSHKEY}.pub >> .ssh/authorized_keys
echo "GITHUB_ACTIONS_SSHKEY" >> ${MAGENX_CONFIG_PATH}/magento
echo "${GITHUB_ACTIONS_SSHKEY}" >> ${MAGENX_CONFIG_PATH}/magento

chmod +x /usr/local/bin/*
chmod -R 600 ${MAGENX_CONFIG_PATH}

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
cd ${MAGENTO_WEB_ROOT_PATH}
PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '
END

echo
cd ${MAGENTO_WEB_ROOT_PATH}

GREENTXT "CONFIGURE GOOGLE AUTH CODE FOR ADMIN ACCESS"
echo
GOOGLE_TFA_CODE="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&' | fold -w 15 | head -n 1 | base32)"
su ${MAGENTO_OWNER} -s /bin/bash -c "bin/magento security:tfa:google:set-secret ${MAGENTO_ADMIN_LOGIN} ${GOOGLE_TFA_CODE}"
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

[shop domain]: ${MAGENTO_DOMAIN}
[webroot path]: ${MAGENTO_WEB_ROOT_PATH}

[admin path]: ${MAGENTO_DOMAIN}/${MAGENTO_ADMIN_PATH}
[admin name]: ${MAGENTO_ADMIN_LOGIN}
[admin pass]: ${MAGENTO_ADMIN_PASSWORD}
[admin http auth name]: ${MAGENTO_ADMIN_LOGIN}
[admin http auth pass]: ${ADMIN_HTTP_PASSWORD}
for additional access, please generate new user/password:
htpasswd -b -c /etc/nginx/.admin USERNAME PASSWORD

[google tfa code]: ${GOOGLE_TFA_CODE}

[ssh port]: ${SSH_PORT}

[files owner]: ${MAGENTO_OWNER}
[${MAGENTO_OWNER} ssh key]: ${MAGENX_CONFIG_PATH}/${MAGENTO_OWNER_SSHKEY}
[Github Actions ssh key]: ${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSHKEY}

[phpmyadmin url]: ${MAGENTO_DOMAIN}/mysql_${PMA_FOLDER}/
[phpmyadmin http auth name]: mysql
[phpmyadmin http auth pass]: ${PMA_PASSWORD}
for additional access, please generate new user/password:
htpasswd -b -c /etc/nginx/.mysql USERNAME PASSWORD

[mysql host]: ${MAGENTO_DB_HOST}
[mysql user]: ${MAGENTO_DB_USER}
[mysql pass]: ${MAGENTO_DB_PASSWORD}
[mysql database]: ${MAGENTO_DB_NAME}
[mysql root pass]: ${MYSQL_ROOT_PASSWORD}

[elk user]: elastic
[elk password]: "${ELASTIC_PASSWORD}"

[percona toolkit]: https://www.percona.com/doc/percona-toolkit/LATEST/index.html

[database monitor]: /usr/local/bin/mytop
[mysqltuner]: /usr/local/bin/mysqltuner
[n98-magerun2]: /usr/local/bin/magerun2
[cache cleaner]: /usr/local/bin/cacheflush

[audit log]: ausearch -k ${MAGENTO_OWNER} | aureport -f -i

[redis on port 6379]: systemctl restart redis@6379
[redis on port 6380]: systemctl restart redis@6380

[installed db dump]: ${MAGENX_CONFIG_PATH}/${MAGENTO_DB_NAME}.sql.gz
[composer.json copy]: ${MAGENX_CONFIG_PATH}/composer.json.saved
[env.php copy]: ${MAGENX_CONFIG_PATH}/env.php.saved
[config.php copy]: ${MAGENX_CONFIG_PATH}/config.php.saved
[env.php default copy]: ${MAGENX_CONFIG_PATH}/env.php.default

[ACL map]: /home/${MAGENTO_OWNER}/public_html.acl

when you run any command for magento cli or custom php script,
please use ${MAGENTO_OWNER} user, either switch to:
su ${MAGENTO_OWNER} -s /bin/bash

or run commands from root as user:
su ${MAGENTO_OWNER} -s /bin/bash -c 'bin/magento'

to copy folders for development use:
useradd -d /home/staging -s /bin/bash staging
useradd -M -s /sbin/nologin -d /home/staging php-staging
usermod -g php-staging staging
rsync -a ${MAGENTO_WEB_ROOT_PATH} /home/staging/
chown -R staging:php-staging /home/staging/public_html
chmod 711 /home/staging
chmod 2750 /home/staging/public_html
setfacl -R -m m:rx,u:staging:rwx,g:php-staging:r-x,o::-,d:u:staging:rwx,d:g:php-staging:r-x,d:o::- /home/staging/public_html
cd /home/staging/public_html
setfacl -R -m u:staging:rwx,g:php-staging:rwx,o::-,d:u:staging:rwx,d:g:php-staging:rwx,d:o::- generated var pub/media pub/static
setfacl -R -m u:nginx:r-x,d:u:nginx:r-x /home/staging/public_html

===========================  INSTALLATION LOG  ======================================" | tee ${MAGENX_CONFIG_PATH}/install.log
echo
echo
GREENTXT "SERVER IS READY. THANK YOU"
echo "PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '" >> /etc/bashrc
echo
echo
## simple installation statis
curl --silent -X POST https://www.magenx.com/ping_back_domain_${MAGENTO_DOMAIN}_geo_${MAGENTO_TIMEZONE}_keep_30d >/dev/null 2>&1
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
 curl -sSL https://download.configserver.com/csf.tgz | tar -xz
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
  sed -i "s/^LF_ALERT_TO =.*/LF_ALERT_TO = \"${MAGENTO_ADMIN_EMAIL}\"/" /etc/csf/csf.conf
  sed -i "s/^LF_ALERT_FROM =.*/LF_ALERT_FROM = \"firewall@${MAGENTO_DOMAIN}\"/" /etc/csf/csf.conf
  sed -i 's/^DENY_IP_LIMIT =.*/DENY_IP_LIMIT = "500000"/' /etc/csf/csf.conf
  sed -i 's/^DENY_TEMP_IP_LIMIT =.*/DENY_TEMP_IP_LIMIT = "2000"/' /etc/csf/csf.conf
  sed -i 's/^LF_IPSET =.*/LF_IPSET = "1"/' /etc/csf/csf.conf
  ### this line will block every blacklisted ip address
  sed -i "/|0|/s/^#//g" /etc/csf/csf.blocklists
  ### scan custom nginx log
  sed -i 's,CUSTOM1_LOG.*,CUSTOM1_LOG = "/var/log/nginx/access.log",' /etc/csf/csf.conf
  sed -i 's,CUSTOM2_LOG.*,CUSTOM2_LOG = "/var/log/nginx/error.log",' /etc/csf/csf.conf
  ### get custom regex template
  curl -o /usr/local/csf/bin/regex.custom.pm ${MAGENX_MSI_REPO}regex.custom.pm
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
   YELLOWTXT "Firewall installation was skipped. Next step"
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
 curl -sSL https://download.webmin.com/jcameron-key.asc | apt-key add -
 apt update
 apt -y install webmin
fi
if [ "$?" = 0 ]; then
 WEBMIN_PORT=$(shuf -i 17556-17728 -n 1)
 sed -i 's/theme=gray-theme/theme=authentic-theme/' /etc/webmin/config
 sed -i 's/preroot=gray-theme/preroot=authentic-theme/' /etc/webmin/miniserv.conf
 sed -i "s/port=10000/port=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
 sed -i "s/listen=10000/listen=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
 sed -i '/keyfile=\|certfile=/d' /etc/webmin/miniserv.conf
 echo "keyfile=/etc/letsencrypt/live/${MAGENTO_DOMAIN}/privkey.pem" >> /etc/webmin/miniserv.conf
 echo "certfile=/etc/letsencrypt/live/${MAGENTO_DOMAIN}/cert.pem" >> /etc/webmin/miniserv.conf
 
  if [ -f "/usr/local/csf/csfwebmin.tgz" ]; then
    perl /usr/${WEBMINEXEC}/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >/dev/null 2>&1
    GREENTXT "INSTALLED CSF FIREWALL PLUGIN"
  fi
  
  echo "${MAGENTO_OWNER}_webmin:\$1\$84720675\$F08uAAcIMcN8lZNg9D74p1:::::$(date +%s):::0::::" > /etc/webmin/miniserv.users
  sed -i "s/root:/${MAGENTO_OWNER}_webmin:/" /etc/webmin/webmin.acl
  WEBMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@#%^?=+_[]{}()' | fold -w 15 | head -n 1)
  /usr/${WEBMINEXEC}/webmin/changepass.pl /etc/webmin/ ${MAGENTO_OWNER}_webmin "${WEBMIN_PASS}"
  
  systemctl enable webmin
  /etc/webmin/restart

  echo
  GREENTXT "WEBMIN INSTALLED - OK"
  echo
  YELLOWTXT "[!] WEBMIN PORT: ${WEBMIN_PORT}"
  YELLOWTXT "[!] USER: ${MAGENTO_OWNER}_webmin"
  YELLOWTXT "[!] PASSWORD: ${WEBMIN_PASS}"
  REDTXT "[!] PLEASE ENABLE TWO-FACTOR AUTHENTICATION!"
	    
cat > ${MAGENX_CONFIG_PATH}/webmin <<END
WEBMIN_PORT="${WEBMIN_PORT}"
WEBMIN_USER="${MAGENTO_OWNER}_webmin"
WEBMIN_PASS="${WEBMIN_PASS}"
END
  else
   echo
   REDTXT "WEBMIN INSTALLATION ERROR"
  fi
  else
   echo
   YELLOWTXT "Webmin installation was skipped. Next step"
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
