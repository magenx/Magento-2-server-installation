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
###                              VARIABLES CONSTRUCTOR                          ###
###################################################################################
MAGENX_CONFIG_PATH="/opt/magenx/config"
OWNER="${DOMAIN//[-.]/}"
PHP_USER="php-${OWNER}"
ROOT_PATH="/home/${OWNER}/public_html"


###################################################################################
###                              REPOSITORY AND PACKAGES                        ###
###################################################################################

# Github installation repository raw url
MAGENX_INSTALL_GITHUB_REPO="https://raw.githubusercontent.com/magenx/Magento-2-server-installation/master"

# Magento
MAGENTO_COMPOSER="composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"

COMPOSER_NAME="8c681734f22763b50ea0c29dff9e7af2" 
COMPOSER_PASSWORD="02dfee497e669b5db1fe1c8d481d6974" 

## Version lock
COMPOSER_VERSION="2.2"
RABBITMQ_VERSION="3.12*"
MARIADB_VERSION="10.6"
ELASTICSEARCH_VERSION="7.x"
VARNISH_VERSION="73"
REDIS_VERSION="7"

# Repositories
MARIADB_REPO_CONFIG="https://downloads.mariadb.com/MariaDB/mariadb_repo_setup"

# Nginx configuration
NGINX_VERSION=$(curl -s http://nginx.org/en/download.html | grep -oP '(?<=gz">nginx-).*?(?=</a>)' | head -1)
MAGENX_NGINX_GITHUB_REPO="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/"
MAGENX_NGINX_GITHUB_REPO_API="https://api.github.com/repos/magenx/Magento-nginx-config/contents/magento2"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"
MYSQL_TOP="https://raw.githubusercontent.com/magenx/Magento-mysql/master/mytop"

# WebStack Packages .deb
WEB_STACK_CHECK="mysql* rabbitmq* elasticsearch opensearch percona-server* maria* php* nginx* ufw varnish* certbot* redis* webmin"

EXTRA_PACKAGES="curl jq gnupg2 auditd apt-transport-https apt-show-versions ca-certificates lsb-release make autoconf snapd automake libtool uuid-runtime \
perl openssl unzip screen nfs-common inotify-tools iptables smartmontools mlocate vim wget sudo apache2-utils \
logrotate git netcat-openbsd patch ipset postfix strace rsyslog geoipupdate moreutils lsof sysstat acl attr iotop expect imagemagick snmp"

PERL_MODULES="liblwp-protocol-https-perl libdbi-perl libconfig-inifiles-perl libdbd-mysql-perl libterm-readkey-perl"

PHP_PACKAGES=(cli fpm common mysql zip lz4 gd mbstring curl xml bcmath intl ldap soap oauth apcu)

###################################################################################
###           CHECK IF ROOT AND CREATE DATABASE TO SAVE ALL SETTINGS            ###
###################################################################################
# root?
if [[ ${EUID} -ne 0 ]]; then
  exit 1
fi

###################################################################################
###                              CHECK IF WE CAN RUN IT                         ###
###################################################################################
## Ubuntu Debian
## Distro detectction

# Check distribution name and version
 . /etc/os-release
 DISTRO_NAME="${NAME}"
 DISTRO_VERSION="${VERSION_ID}"
 # Check if distribution is supported
 if [ "${DISTRO_NAME%% *}" == "Ubuntu" ] && [[ "${DISTRO_VERSION}" =~ ^(20.04|22.04) ]]; then
      DISTRO_NAME="Ubuntu"
 elif [ "${DISTRO_NAME%% *}" == "Debian" ] && [[ "${DISTRO_VERSION}" =~ ^(11|12) ]]; then
      DISTRO_NAME="Debian"
 else
   exit 1
 fi

# network is up?
host1=${MAGENX_BASE}
host2=github.com

RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ "${RESULT}" != "up" ]]; then
  exit 1
fi

# install packages to run CPU and HDD test
dpkg-query -l curl time bc bzip2 tar >/dev/null || { echo; echo; apt -qq update -o Acquire::ForceIPv4=true; apt -qq -y install curl time bc bzip2 tar; }

# check if web stack is clean and clean it
  installed_packages="$(apt -qq list --installed ${WEB_STACK_CHECK} 2> /dev/null | cut -d'/' -f1 | tr '\n' ' ')"
  if [ ! -z "$installed_packages" ]; then
    apt -qq -y remove "${installed_packages}"
  fi

# configure system/magento timezone
if [ -z "${TIMEZONE}" ]; then
    TIMEZONE="UTC"
    ln -fs /usr/share/zoneinfo/"${TIMEZONE}" /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
  else
    ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
fi

# change ssh port
if [ "${SSH_PORT}" != "22" ]; then
    sed -i "s/.*Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
    sed -i "s/.*LoginGraceTime.*/LoginGraceTime 30/" /etc/ssh/sshd_config
    sed -i "s/.*MaxAuthTries.*/MaxAuthTries 6/" /etc/ssh/sshd_config     
    sed -i "s/.*X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
    sed -i "s/.*PrintLastLog.*/PrintLastLog yes/" /etc/ssh/sshd_config
    sed -i "s/.*TCPKeepAlive.*/TCPKeepAlive yes/" /etc/ssh/sshd_config
    sed -i "s/.*ClientAliveInterval.*/ClientAliveInterval 600/" /etc/ssh/sshd_config
    sed -i "s/.*ClientAliveCountMax.*/ClientAliveCountMax 3/" /etc/ssh/sshd_config
    sed -i "s/.*UseDNS.*/UseDNS no/" /etc/ssh/sshd_config
    sed -i "s/.*PrintMotd.*/PrintMotd no/" /etc/ssh/sshd_config
    systemctl restart sshd.service
fi


###################################################################################
###                                  AGREEMENT                                  ###
###################################################################################

# THIS SOFTWARE AND ALL SOFTWARE PROVIDED AS IS
# UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE

if [ "${TERMS}" != "y" ]; then
   exit 1
fi

###################################################################################
###                             LEMP WEBSTACK INSTALLATION                      ###
###################################################################################
RUN_LEMP () {
# Redirect stderr to a log file
  exec 2>> /tmp/report

# check if system update still required
if [ "${SYSTEM_UPDATE}" == "y" ]; then
  ## install all extra packages
  debconf-set-selections <<< "postfix postfix/mailname string localhost"
  debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
  apt -qq update
  apt -y -qq install software-properties-common
  apt-add-repository -y contrib
  apt -qq update
  apt -qq -y install ${EXTRA_PACKAGES} ${PERL_MODULES}
 if [ "$?" != 0 ]; then
  exit 1
 fi
fi
  
###################################################################################
###                          LEMP WEB STACK INSTALLATION                        ###
###################################################################################
# MARIADB INSTALLATION
  if [ "${INSTALL_MARIADB}" == "y" ]; then
  echo
  curl -sS ${MARIADB_REPO_CONFIG} | bash -s -- --mariadb-server-version="mariadb-${MARIADB_VERSION}" --skip-verify --skip-eol-check
  echo
   if [ "$?" = 0 ] # if repository installed then install package
   then
    apt -qq update
    apt -qq -y install mariadb-server
    if [ "$?" = 0 ] # if package installed then configure
    then
     systemctl enable mariadb
     curl -sSo /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
     INNODB_BUFFER_POOL_SIZE=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
     if [ "${INNODB_BUFFER_POOL_SIZE}" == "0" ]; then IBPS=1; fi
     sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${INNODB_BUFFER_POOL_SIZE}G/" /etc/my.cnf
    else
    exit 1 # if package is not installed then exit
  fi
    else
    exit 1 # if repository is not installed then exit
   fi
fi

# NGINX INSTALLATION
  if [ "${INSTALL_NGINX}" == "y" ]; then
  echo "deb http://nginx.org/packages/mainline/${DISTRO_NAME,,} $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list
  curl -sfL https://nginx.org/keys/nginx_signing.key | apt-key add -
  echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx
   if [ "$?" = 0 ]; then # if repository installed then install package
    apt -qq update
    apt -qq -y install nginx nginx-module-perl nginx-module-image-filter nginx-module-geoip
    if [ "$?" = 0 ]; then
     systemctl enable nginx >/dev/null 2>&1
    else
    exit 1 # if package is not installed then exit
  fi
    else
    exit 1
    fi
fi

# PHP INSTALLATION
if [ "${INSTALL_PHP}" == "y" ]; then
 if [ "${DISTRO_NAME}" == "Debian" ]; then
  curl -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
 else
  add-apt-repository ppa:ondrej/php -y
 fi
 if [ "$?" = 0 ]; then
   apt -qq update
   apt -qq -y install php${PHP_VERSION} ${PHP_PACKAGES[@]/#/php${PHP_VERSION}-} php-pear
  if [ "$?" = 0 ]; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --${COMPOSER_VERSION} --install-dir=/usr/bin --filename=composer
    php -r "unlink('composer-setup.php');"
   else
   exit 1 # if package is not installed then exit
   fi
    else
    exit 1 # if repository is not installed then exit
  fi
fi

# REDIS INSTALLATION
if [ "${INSTALL_REDIS}" == "y" ]; then
  curl -fL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/redis.list
 if [ "$?" = 0 ]; then
     apt -qq update
     apt -qq -y install redis   
   if [ "$?" = 0 ]; then
systemctl stop redis-server
systemctl disable redis-server

# Create Redis config
cat > /etc/systemd/system/redis@.service <<END
[Unit]
Description=Advanced key-value store for %i
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

REDIS_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@%&?' | fold -w 32 | head -n 1)"

for SERVICE in session cache
do
cat > /etc/redis/${SERVICE}.conf<<END

bind ${REDIS_SERVER_IP}
port ${PORT}

daemonize yes
supervised auto
protected-mode yes
timeout 0

requirepass ${REDIS_PASSWORD}

dir /var/lib/redis
logfile /var/log/redis/${SERVICE}.log
pidfile /run/redis/${SERVICE}.pid

save ""

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

systemctl daemon-reload
systemctl enable redis@${SERVICE}
systemctl restart redis@${SERVICE}
done

   else
   exit 1 # if package is not installed then exit
   fi
 else
 exit 1
 fi
fi

# RABBITMQ INSTALLATION
if [ "${INSTALL_RABBITMQ}" == "y" ];then
  curl -1sLf 'https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/setup.deb.sh' | bash
  curl -1sLf 'https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/setup.deb.sh' | bash
  if [ "$?" = 0 ]; then
    apt -qq -y install rabbitmq-server=${RABBITMQ_VERSION} 
    if [ "$?" = 0 ]; then
     systemctl stop rabbitmq-server
     systemctl stop epmd*
     epmd -kill

cat > /etc/rabbitmq/rabbitmq-env.conf <<END
NODENAME=rabbit@${RABBITMQ_SERVER_IP}
NODE_IP_ADDRESS=${RABBITMQ_SERVER_IP}
ERL_EPMD_ADDRESS=${RABBITMQ_SERVER_IP}
PID_FILE=/var/lib/rabbitmq/mnesia/rabbitmq_pid
END

echo '[{kernel, [{inet_dist_use_interface, {${RABBITMQ_SERVER_IP//./,}}}]},{rabbit, [{tcp_listeners, [{"${RABBITMQ_SERVER_IP}", 5672}]}]}].' > /etc/rabbitmq/rabbitmq.config

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
ExecStart=/usr/bin/epmd -address ${RABBITMQ_SERVER_IP} -daemon
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
rabbitmqctl add_user ${OWNER} ${RABBITMQ_PASSWORD}
rabbitmqctl set_permissions -p / ${OWNER} ".*" ".*" ".*"

   else
   exit 1 # if package is not installed then exit
   fi
  else
   exit 1
  fi
fi

# VARNISH INSTALLATION
if [ "${INSTALL_VARNISH}" == "y" ]; then 
  curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.deb.sh | bash
  if [ "$?" = 0 ]; then
    apt -qq update
    apt -qq -y install varnish
   if [ "$?" = 0 ]; then
     curl -sSo /etc/systemd/system/varnish.service ${MAGENX_INSTALL_GITHUB_REPO}/varnish.service
     curl -sSo /etc/varnish/varnish.params ${MAGENX_INSTALL_GITHUB_REPO}/varnish.params
     uuidgen > /etc/varnish/secret
     systemctl daemon-reload
     # Varnish Cache configuration file
     systemctl enable varnish.service
     curl -o /etc/varnish/devicedetect.vcl https://raw.githubusercontent.com/varnishcache/varnish-devicedetect/master/devicedetect.vcl
     curl -o /etc/varnish/devicedetect-include.vcl ${MAGENX_INSTALL_GITHUB_REPO}/devicedetect-include.vcl
     curl -o /etc/varnish/default.vcl ${MAGENX_INSTALL_GITHUB_REPO}/default.vcl
     sed -i "s/PROFILER_PLACEHOLDER/${PROFILER_PLACEHOLDER}/" /etc/varnish/default.vcl
     sed -i "s/example.com/${DOMAIN}/" /etc/varnish/default.vcl
     ## Download nginx config only if cluster and varnish server separate
     if [ "${VARNISH_SERVER_IP}" != "${PRIVATE_IP}" ]; then 
       # Downloading nginx configuration files
       curl -o /etc/nginx/fastcgi_params  ${MAGENX_NGINX_GITHUB_REPO}magento2/fastcgi_params
       curl -o /etc/nginx/nginx.conf  ${MAGENX_NGINX_GITHUB_REPO}magento2/nginx.conf
       mkdir -p /etc/nginx/sites-enabled
       mkdir -p /etc/nginx/sites-available && cd $_
       curl ${MAGENX_NGINX_GITHUB_REPO_API}/sites-available 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -O "$4)}' >/dev/null
       ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
       mkdir -p /etc/nginx/conf_m2 && cd /etc/nginx/conf_m2/
       curl ${MAGENX_NGINX_GITHUB_REPO_API}/conf_m2 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -O "$4)}' >/dev/null
       # Nginx configuration for domain
       cp /etc/nginx/sites-available/magento2.conf  /etc/nginx/sites-available/${DOMAIN}.conf
       ln -s /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/${DOMAIN}.conf
       sed -i "s/example.com/${DOMAIN}/g" /etc/nginx/sites-available/${DOMAIN}.conf
       sed -i "s/example.com/${DOMAIN}/g" /etc/nginx/nginx.conf
       sed -i "s,default.*production app folder,default ${ROOT_PATH}; # ${ENV} app folder," /etc/nginx/conf_m2/maps.conf
     fi
    else
   exit 1
   fi
  else
   exit 1
  fi
fi

# ELASTICSEARCH INSTALLATION
if [ "${INSTALL_ELASTICSEARCH}" == "y" ];then
  curl -L https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
  echo "deb https://artifacts.elastic.co/packages/${ELASTICSEARCH_VERSION}/apt stable main" > /etc/apt/sources.list.d/elastic-${ELASTICSEARCH_VERSION}.list
  if [ "$?" = 0 ]; then
    apt -qq update
    apt -qq -y install elasticsearch jq
   if [ "$?" = 0 ]; then
    ## elasticsearch settings
    if ! grep -q "magento" /etc/elasticsearch/elasticsearch.yml >/dev/null 2>&1 ; then
      cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/_elasticsearch.yml_default
cat > /etc/elasticsearch/elasticsearch.yml <<END
#--------------------------------------------------------------------#
#----------------------- MAGENX CONFIGURATION -----------------------#
# -------------------------------------------------------------------#
# original config saved: /etc/elasticsearch/_elasticsearch.yml_default

cluster.name: magento
node.name: magento-node1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

network.host: ${ELASTICSEARCH_SERVER_IP}
http.host: ${ELASTICSEARCH_SERVER_IP}

discovery.type: single-node
xpack.security.enabled: true
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.security.authc.api_key.enabled: true

END

      sed -i "s/.*-Xms.*/-Xms1024m/" /etc/elasticsearch/jvm.options
      sed -i "s/.*-Xmx.*/-Xmx1024m/" /etc/elasticsearch/jvm.options
      ## use builtin java
      sed -i "s,#ES_JAVA_HOME=,ES_JAVA_HOME=/usr/share/elasticsearch/jdk/," /etc/default/elasticsearch
    fi

chown -R :elasticsearch /etc/elasticsearch/*
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service

    if [ "$?" != 0 ]; then    
      exit 1
    fi

/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto -b > /tmp/elasticsearch
ELASTICSEARCH_PASSWORD="$(awk '/PASSWORD elastic/ { print $4 }' /tmp/elasticsearch)"
rm /tmp/elasticsearch

# generate elasticsearch password
INDEXER_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)"
  
# create and check if role already created
ROLE_CREATED=$(curl -X POST -u elastic:${ELASTICSEARCH_PASSWORD} "http://${ELASTICSEARCH_SERVER_IP}:9200/_security/role/${OWNER}" \
-H 'Content-Type: application/json' -sS \
-d @<(cat <<EOF
{
  "cluster": ["manage_index_templates", "monitor", "manage_ilm"],
  "indices": [
    {
      "names": [ "${OWNER}*"],
      "privileges": ["all"]
    }
  ]
}
EOF
) | jq -r ".role.created")

# create and check if we have user enabled
USER_ENABLED=$(curl -X GET -u elastic:${ELASTICSEARCH_PASSWORD} "http://${ELASTICSEARCH_SERVER_IP}:9200/_security/user/${OWNER}" \
-H 'Content-Type: application/json' -sS | jq -r ".[].enabled")

if [[ ${ROLE_CREATED} == true ]] && [[ ${USER_ENABLED} != true ]]; then
curl -X POST -u elastic:${ELASTICSEARCH_PASSWORD} "http://${ELASTICSEARCH_SERVER_IP}:9200/_security/user/${OWNER}" \
-H 'Content-Type: application/json' -sS \
-d "$(cat <<EOF
{
  "password" : "${INDEXER_PASSWORD}",
  "roles" : [ "${OWNER}"],
  "full_name" : "Magento 2 indexer for ${OWNER}"
}
EOF
)"
else
echo "ELK return error for role ${OWNER} "
fi
done
  else
   exit 1
   fi
 else
exit 1
fi
fi

## keep versions for critical services to avoid issues
apt-mark hold elasticsearch erlang rabbitmq-server
}

###################################################################################
###                            MEDIA SERVER CONFIGURATION                       ###
###################################################################################
RUN_MEDIA () {

apt-get -qq update
apt-get -qq -y install nfs-kernel-server

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
echo "${ROOT_PATH}/pub/media  ${MEDIA_SERVER_IP%%.*}.0.0.0/24(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
echo "${ROOT_PATH}/pub/static  ${MEDIA_SERVER_IP%%.*}.0.0.0/24(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
echo "${ROOT_PATH}/var/log  ${MEDIA_SERVER_IP%%.*}.0.0.0/24(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
echo "${ROOT_PATH}/generated  ${MEDIA_SERVER_IP%%.*}.0.0.0/24(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
exports -ra
systemctl restart nfs-server

}
  
###################################################################################
###                                  MAGENTO DOWNLOAD                           ###
###################################################################################
RUN_MAGENTO () {
# Redirect stderr to a log file
  exec 2>> /tmp/report

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

 touch ${ROOT_PATH%/*}/${ENV}
 cd ${ROOT_PATH}
 
if [ "${DOWNLOAD_MAGENTO}" == "y" ]; then
   ## create some temp dirs
   COMPOSER_TMP=".config,.cache,.local,.composer"
   mkdir -p ${ROOT_PATH%/*}/{.config,.cache,.local,.composer}
   chmod 2750 ${ROOT_PATH%/*}/{.config,.cache,.local,.composer}
   chown -R ${OWNER}:${OWNER} ${ROOT_PATH%/*}/{.config,.cache,.local,.composer}
   ##

   su ${OWNER} -s /bin/bash -c "composer -n -q config -g http-basic.repo.magento.com ${COMPOSER_NAME} ${COMPOSER_PASSWORD}"
   su ${OWNER} -s /bin/bash -c "${MAGENTO_COMPOSER}=${VERSION_INSTALLED} . --no-install"

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
      exit 1
    fi
   
   # make magento great again
   sed -i "s/2-4/2-6/" app/etc/di.xml
 fi
  
   # reset permissions
   if [ "${ENV}" == "developer" ]; then
     DEVELOPER_FOLDERS="generated pub/static"
   fi
   
   # check if media nfs
   if [ "${MEDIA_NFS}" == "y" ]; then
     echo "media:/${ROOT_PATH}/pub/media ${ROOT_PATH}/pub/media nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
     su ${OWNER} -s /bin/bash -c "mv ${ROOT_PATH}/pub/media /tmp/media_move"
     su ${OWNER} -s /bin/bash -c "mkdir -p ${ROOT_PATH}/pub/media"
     mount -a
     chmod 2775 ${ROOT_PATH}/pub/media
     su ${OWNER} -s /bin/bash -c "cp -R /tmp/media_move/* ${ROOT_PATH}/pub/media/"
     su ${OWNER} -s /bin/bash -c "mkdir -p var/tmp"
     su ${OWNER} -s /bin/bash -c "echo 007 > umask"
     setfacl -R -m u:${OWNER}:rwX,g:${PHP_USER}:rwX,o::-,d:u:${OWNER}:rwX,d:g:${PHP_USER}:rwX,d:o::- ${DEVELOPER_FOLDERS} var 
   fi
  
}

###################################################################################
###                                  DATABASE SETUP                             ###
###################################################################################
RUN_DATABASE () {
# Redirect stderr to a log file
  exec 2>> /tmp/report
  
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

cat > /root/.mytop <<END
user=root
host=${MARIADB_SERVER_IP}
pass=${MYSQL_ROOT_PASSWORD}
db=mysql
END
cat > /root/.my.cnf <<END
[client]
user=root
host=${MARIADB_SERVER_IP}
password="${MYSQL_ROOT_PASSWORD}"
END

fi

chmod 600 /root/.my.cnf /root/.mytop

# configure database
DATABASE_NAME="${OWNER}_m2_${ENV}"
DATABASE_USER="${OWNER}_m2_${ENV}"
DATABASE_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9%^&+_{}()<>-' | fold -w 15 | head -n 1)${RANDOM}"

mariadb <<EOMYSQL
 CREATE USER '${DATABASE_USER}'@'${MARIADB_SERVER_IP}' IDENTIFIED BY '${DATABASE_PASSWORD}';
 CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME};
 GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO '${DATABASE_USER}'@'${MARIADB_SERVER_IP}' WITH GRANT OPTION;
 exit
EOMYSQL

}

###################################################################################
###                                  MAGENTO SETUP                              ###
###################################################################################
RUN_INSTALL () {
# Redirect stderr to a log file
  exec 2>> /tmp/report
  
if [ -f "${ROOT_PATH}/bin/magento" ]; then
 
SERVICES=(
  "${REDIS_SERVER_IP}:6379"
  "${REDIS_SERVER_IP}:6380"
  "${ELASTICSEARCH_SERVER_IP}:9200"
  "${RABBITMQ_SERVER_IP}:5672"
  "${MARIADB_SERVER_IP}:3306"
)

for SERVICE in "${SERVICES[@]}"; do
  IP_TO_PORT=(${SERVICE//:/ })
  IP=${!IP_TO_PORT[0]}
  PORT=${IP_TO_PORT[1]}
  
  nc -4zvw3 "$IP" "$PORT"

  if [ "$?" != 0 ]; then
    exit 1
  fi
done


 cd ${ROOT_PATH}
 chown -R ${OWNER}:${PHP_USER} *
 chmod u+x bin/magento
 ADMIN_PASSWORD="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9%&?=' | fold -w 10 | head -n 1)${RANDOM}"
 
 echo "${MARIADB_SERVER_IP} mariadb" >> /etc/hosts
 echo "${REDIS_SERVER_IP} cache-${ENV} session-${ENV}" >> /etc/hosts
 echo "${RABBITMQ_SERVER_IP} rabbitmq" >> /etc/hosts
 echo "${VARNISH_SERVER_IP} varnish" >> /etc/hosts
 echo "${ELASTICSEARCH_SERVER_IP} elasticsearch" >> /etc/hosts

 su ${OWNER} -s /bin/bash -c "bin/magento setup:install --base-url=http://${DOMAIN}/ \
 --db-host=mariadb \
 --db-name=${DATABASE_NAME} \
 --db-user=${DATABASE_USER} \
 --db-password='${DATABASE_PASSWORD}' \
 --admin-firstname=${ADMIN_FIRST_NAME} \
 --admin-lastname=${ADMIN_LAST_NAME} \
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
 --session-save-redis-port=6379 \
 --session-save-redis-log-level=3 \
 --session-save-redis-db=0 \
 --session-save-redis-password='${REDIS_PASSWORD}' \
 --session-save-redis-compression-lib=lz4 \
 --cache-backend=redis \
 --cache-backend-redis-server=cache \
 --cache-backend-redis-port=6380 \
 --cache-backend-redis-db=0 \
 --cache-backend-redis-password='${REDIS_PASSWORD}' \
 --cache-backend-redis-compress-data=1 \
 --cache-backend-redis-compression-lib=l4z \
 --amqp-host=rabbitmq \
 --amqp-port=5672 \
 --amqp-user=${OWNER} \
 --amqp-password='${RABBITMQ_PASSWORD}' \
 --amqp-virtualhost='/' \
 --consumers-wait-for-messages=0 \
 --search-engine=elasticsearch7 \
 --elasticsearch-host=elasticsearch \
 --elasticsearch-port=9200 \
 --elasticsearch-index-prefix=${OWNER} \
 --elasticsearch-enable-auth=1 \
 --elasticsearch-username=${OWNER} \
 --elasticsearch-password='${INDEXER_PASSWORD}'"

 if [ "$?" != 0 ]; then
   exit 1
 fi
 
done
}

###################################################################################
###                                FINAL CONFIGURATION                          ###
###################################################################################
RUN_CONFIG () {
# Redirect stderr to a log file
  exec 2>> /tmp/report
  
# network is up?
host1=google.com
host2=github.com

RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ "${RESULT}" != "up" ]]; then
  exit 1
fi

hostnamectl set-hostname "${DOMAIN}" --static

# Create motd banner
curl -o /etc/motd "${MAGENX_INSTALL_GITHUB_REPO}/motd"
sed -i "s/MAGENX_VERSION/${MAGENX_VERSION}/" /etc/motd

# Sysctl parameters
cat <<END > /etc/sysctl.conf
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

# Downloading mysqltuner and mytop
curl -o /usr/local/bin/mysqltuner ${MYSQL_TUNER}
curl -o /usr/local/bin/mytop ${MYSQL_TOP}

for dir in cli fpm
do
cat <<END > /etc/php/${PHP_VERSION}/$dir/conf.d/zz-magenx-overrides.ini
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

# Downloading: /usr/local/bin/n98-magerun2
curl -o /usr/local/bin/n98-magerun2 https://files.magerun.net/n98-magerun2.phar

# Creating cache cleaner script: /usr/local/bin/cacheflush
cat <<END > /usr/local/bin/cacheflush
#!/bin/bash
sudo -u \${SUDO_USER} n98-magerun2 --root-dir=/home/\${SUDO_USER}/public_html cache:flush
/usr/bin/systemctl restart php${PHP_VERSION}-fpm.service
nginx -t && /usr/bin/systemctl restart nginx.service || echo "[!] Error: check nginx config"
END

# Downloading nginx configuration files
curl -o /etc/nginx/fastcgi_params  ${MAGENX_NGINX_GITHUB_REPO}magento2/fastcgi_params
curl -o /etc/nginx/nginx.conf  ${MAGENX_NGINX_GITHUB_REPO}magento2/nginx.conf
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
curl ${MAGENX_NGINX_GITHUB_REPO_API}/sites-available 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -O "$4)}' >/dev/null
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
mkdir -p /etc/nginx/conf_m2 && cd /etc/nginx/conf_m2/
curl ${MAGENX_NGINX_GITHUB_REPO_API}/conf_m2 2>&1 | awk -F'"' '/download_url/ {print $4 ; system("curl -O "$4)}' >/dev/null

# Nginx configuration for domain
cp /etc/nginx/sites-available/magento2.conf  /etc/nginx/sites-available/${DOMAIN}.conf
ln -s /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/${DOMAIN}.conf
sed -i "s/example.com/${DOMAIN}/g" /etc/nginx/sites-available/${DOMAIN}.conf

sed -i "s/example.com/${DOMAIN}/g" /etc/nginx/nginx.conf
sed -i "s,default.*production php-fpm,default unix:/var/run/${OWNER}.sock; # ${ENV} php-fpm,"  /etc/nginx/conf_m2/maps.conf
sed -i "s,default.*production app folder,default ${ROOT_PATH}; # ${ENV} app folder," /etc/nginx/conf_m2/maps.conf


# Magento profiler configuration in nginx
PROFILER_PLACEHOLDER="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)"
sed -i "s/PROFILER_PLACEHOLDER/${PROFILER_PLACEHOLDER}/" /etc/nginx/conf_m2/maps.conf

# phpMyAdmin installation and configuration
PHPMYADMIN_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
PHPMYADMIN_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
BLOWFISH_SECRET=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p /usr/share/phpMyAdmin && cd $_
composer -n create-project phpmyadmin/phpmyadmin .
cp config.sample.inc.php config.inc.php
sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';/" config.inc.php
sed -i "s|.*UploadDir.*|\$cfg['UploadDir'] = '/tmp/';|"  config.inc.php
sed -i "s|.*SaveDir.*|\$cfg['SaveDir'] = '/tmp/';|"  config.inc.php
sed -i "/SaveDir/a\
\$cfg['TempDir'] = '\/tmp\/';"  config.inc.php

sed -i "s/PHPMYADMIN_PLACEHOLDER/mysql_${PHPMYADMIN_FOLDER}/g" /etc/nginx/conf_m2/phpmyadmin.conf
     sed -i "5i \\
           auth_basic \$authentication; \\
           auth_basic_user_file .mysql;"  /etc/nginx/conf_m2/phpmyadmin.conf
	 	   
sed -i "s|^listen =.*|listen = /var/run/php${PHP_VERSION}-fpm.sock|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i "s/^listen.owner.*/listen.owner = nginx/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i "s|127.0.0.1:9000|unix:/var/run/php${PHP_VERSION}-fpm.sock|"  /etc/nginx/conf_m2/phpmyadmin.conf

htpasswd -b -c /etc/nginx/.mysql mysql ${PHPMYADMIN_PASSWORD}  >/dev/null 2>&1

# Php-fpm pool configuration
cat <<END > /etc/php/${PHP_VERSION}/fpm/pool.d/${OWNER}.conf
[${OWNER}]

;;
;; Pool user
user = php-\$pool
group = php-\$pool

listen = /var/run/\$pool.sock
listen.owner = nginx
listen.group = php-\$pool
listen.mode = 0660

;;
;; Pool size and settings
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

# Add user to sudo to execute cacheflush"
cat <<END >> /etc/sudoers
${OWNER} ALL=(ALL) NOPASSWD: /usr/local/bin/cacheflush
END

# Logrotate script for Magento logs in ${ENV} environment
cat <<END > /etc/logrotate.d/${OWNER}
${ROOT_PATH}/var/log/*.log
{
su ${OWNER} ${PHP_USER}
create 660 ${OWNER} ${PHP_USER}
weekly
rotate 2
notifempty
missingok
compress
}
END

# Audit configuration for Magento folders and files
cat <<END >> /etc/audit/rules.d/audit.rules
## audit magento files for ${OWNER}
-a never,exit -F dir=${ROOT_PATH}/var/ -k exclude
-w ${ROOT_PATH} -p wa -k ${OWNER}
END
service auditd reload
service auditd restart
auditctl -l

if [ -f "${ROOT_PATH}/bin/magento" ]; then
 if [ "${APPLY_MAGENTO_CONFIG}" == "y" ]; then
 
 cd ${ROOT_PATH}
 chmod u+x bin/magento
 su ${OWNER} -s /bin/bash -c "${ROOT_PATH}/bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2"
 su ${OWNER} -s /bin/bash -c "bin/magento setup:config:set --http-cache-hosts=varnish:8081"

 chown -R ${OWNER}:${PHP_USER} ${ROOT_PATH}
 
 rm -rf var/*
 su ${OWNER} -s /bin/bash -c "bin/magento config:set trans_email/ident_general/email ${ADMIN_EMAIL}"
 su ${OWNER} -s /bin/bash -c "bin/magento config:set web/url/catalog_media_url_format image_optimization_parameters"
 su ${OWNER} -s /bin/bash -c "bin/magento config:set dev/css/minify_files 1"
 su ${OWNER} -s /bin/bash -c "bin/magento config:set dev/js/minify_files 1"
 su ${OWNER} -s /bin/bash -c "bin/magento config:set dev/js/move_script_to_bottom 1"
 su ${OWNER} -s /bin/bash -c "bin/magento config:set web/secure/enable_hsts 1"
 su ${OWNER} -s /bin/bash -c "bin/magento config:set web/secure/enable_upgrade_insecure 1"
 su ${OWNER} -s /bin/bash -c "bin/magento config:set dev/caching/cache_user_defined_attributes 1"
 su ${OWNER} -s /bin/bash -c "mkdir -p var/tmp"
 su ${OWNER} -s /bin/bash -c "composer config --no-plugins allow-plugins.cweagans/composer-patches true"
 su ${OWNER} -s /bin/bash -c "composer require magento/quality-patches cweagans/composer-patches -n"
 su ${OWNER} -s /bin/bash -c "bin/magento setup:upgrade"
 su ${OWNER} -s /bin/bash -c "bin/magento deploy:mode:set ${ENV}"
 su ${OWNER} -s /bin/bash -c "bin/magento cache:flush"

 rm -rf var/log/*.log
 rm -rf ../{.config,.cache,.local,.composer}/*
 
 GOOGLE_TFA_CODE="$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&' | fold -w 15 | head -n 1 | base32)"
 su ${OWNER} -s /bin/bash -c "bin/magento security:tfa:google:set-secret ${ADMIN_LOGIN} ${GOOGLE_TFA_CODE}"
 echo "  Google Authenticator mobile app configuration:"
 echo "  - select: Enter a setup key"
 echo "  - type in: Account name"
 echo "  - Paste passkey: ${GOOGLE_TFA_CODE}"
 echo "  - Choose Time based"
 
 sed -i "s/VERSION_INSTALLED/${VERSION_INSTALLED}/" /etc/motd
fi
fi

# Add Magento cronjob to ${PHP_USER} user crontab
BP_HASH="$(echo -n "${ROOT_PATH}" | openssl dgst -sha256 | awk '{print $2}')"
crontab -l -u ${PHP_USER} > /tmp/${PHP_USER}_crontab
cat <<END >> /tmp/${PHP_USER}_crontab
#~ MAGENTO START ${BP_HASH}
* * * * * /usr/bin/php${PHP_VERSION} ${ROOT_PATH}/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> ${ROOT_PATH}/var/log/magento.cron.log
#~ MAGENTO END ${BP_HASH}
END
crontab -u ${PHP_USER} /tmp/${PHP_USER}_crontab
rm /tmp/${PHP_USER}_crontab

# Creating Magento environment variables to ~/.env
cat <<END > /home/${OWNER}/.env
MODE="${MODE}"
DOMAIN="${DOMAIN}"
ADMIN_PATH="$(awk -F"'" '/frontName/{print $4}' ${ROOT_PATH}/app/etc/env.php)"
REDIS_PASSWORD="${REDIS_PASSWORD}"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD}"
CRYPT_KEY="$(awk -F"'" '/key/{print $4}' ${ROOT_PATH}/app/etc/env.php)"
GRAPHQL_ID_SALT="$(awk -F"'" '/id_salt/{print $4}' ${ROOT_PATH}/app/etc/env.php)"
DATABASE_NAME="${DATABASE_NAME}"
DATABASE_USER="${DATABASE_USER}"
DATABASE_PASSWORD="${DATABASE_PASSWORD}"
INDEXER_PASSWORD="${INDEXER_PASSWORD}"
END

# Generating SSH keys for Magento user and Github Actions deployment
mkdir .ssh
SSH_KEY="private_ssh_key_${ENV}"
ssh-keygen -o -a 256 -t ed25519 -f ${MAGENX_CONFIG_PATH}/${SSH_KEY} -C "ssh for ${DOMAIN} ${ENV}" -N ""
PRIVATE_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${SSH_KEY}")
PUBLIC_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${SSH_KEY}.pub")
cat <<END >> .ssh/authorized_keys
${PUBLIC_SSH_KEY}
END

GITHUB_ACTIONS_SSH_KEY="ga_private_ssh_key_${ENV}"
ssh-keygen -o -a 256 -t ed25519 -f ${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY} -C "github actions for ${DOMAIN} ${ENV}" -N ""
GITHUB_ACTIONS_PRIVATE_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY}")
GITHUB_ACTIONS_PUBLIC_SSH_KEY=$(cat "${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY}.pub")
deploy_command="command=\"build_version=\${SSH_ORIGINAL_COMMAND} /home/${OWNER}/deploy.sh\" "
awk -v var="${deploy_command}" '{print var $0}' ${MAGENX_CONFIG_PATH}/${GITHUB_ACTIONS_SSH_KEY}.pub >> .ssh/authorized_keys

# Creating Github Actions deployment script deploy.sh
cat <<END > deploy.sh
#!/bin/bash
cd public_html/
git fetch origin \${build_version}
git reset origin/\${build_version} --hard
git clean -f -d
bin/magento setup:db:status --no-ansi -n
if [[ \$? -ne 0 ]]; then
bin/magento setup:upgrade --keep-generated --no-ansi -n
fi
cacheflush
END

# Creating bash_profile
cat <<END > .bash_profile
# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
# User specific environment and startup programs
PATH=\$PATH:\$HOME/bin
export PATH
END

# Creating bashrc
cat <<END > .bashrc
# .bashrc
# history timestamp
export HISTTIMEFORMAT="%d/%m/%y %T "
# got to app root folder
cd ~/public_html/
# change prompt color
PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '
END

done

# Add timestamp to bash history
cat <<END >> ~/.bashrc
export HISTTIMEFORMAT="%d/%m/%y %T "
END

# clean config directory and set permissions
chmod +x /usr/local/bin/*
chmod -R 600 ${MAGENX_CONFIG_PATH}

systemctl daemon-reload
systemctl restart nginx.service
systemctl restart php*fpm.service
systemctl restart varnish.service

###############################################
# send email to admin about server installation
## generate report log
cat >> /tmp/report <<END

Uptime: "$(uptime)"
Report time: $(date -R)
Service status:

END
systemctl status mysql* nginx php${PHP_VERSION}-fpm elasticsearch rabbitmq* redis* varnish* >> /tmp/report
## send email
cat /tmp/report | mail -s "[+][MAGENX CONFIG]: New server created at $(hostname)" -r "Droplet Created<${ADMIN_EMAIL}>" ${ADMIN_EMAIL}
###############################################

echo "PS1='\[\e[37m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[37m\]@\[\e[m\]\[\e[35m\]\h\[\e[m\]\[\e[37m\]:\[\e[m\]\[\e[36m\]\W\[\e[m\]\[\e[37m\]]\[\e[m\]$ '" >> /etc/bashrc

## simple installation stats
curl --silent -X POST https://www.magenx.com/ping_back_os_${DISTRO_NAME}_domain_${DOMAIN}_geo_${TIMEZONE}_keep_30d >/dev/null 2>&1
}

###################################################################################
###                               FIREWALL INSTALLATION                         ###
###################################################################################
RUN_FIREWALL () {
if [ "${csf_firewall}" == "y" ]; then

 cd /usr/local/src/
 curl -sSL https://download.configserver.com/csf.tgz | tar -xz
  cd csf
 if perl csftest.pl | grep "FATAL" ; then
  perl csftest.pl
  exit 1
 else
  sh install.sh
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
  ### this line will block every blacklisted ip address
  sed -i "/|0|/s/^#//g" /etc/csf/csf.blocklists
  ### scan custom nginx log
  sed -i 's,CUSTOM1_LOG.*,CUSTOM1_LOG = "/var/log/nginx/access.log",' /etc/csf/csf.conf
  sed -i 's,CUSTOM2_LOG.*,CUSTOM2_LOG = "/var/log/nginx/error.log",' /etc/csf/csf.conf
  ### get custom regex template
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
cat <<END >> /tmp/csf_crontab
0 */4 * * * /etc/csf/csf_pignore.sh && crontab -l | grep -v "csf_pignore.sh" | crontab -
END
crontab /tmp/csf_crontab
rm /tmp/csf_crontab
 fi
  else
  exit 1
fi
echo
echo
}

###################################################################################
###                                  WEBMIN INSTALLATION                        ###
###################################################################################

RUN_WEBMIN () {

if [ "${webmin_install}" == "y" ];then
 echo "deb https://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
 curl -sSL https://download.webmin.com/jcameron-key.asc | apt-key add -
 apt -qq update
 apt -qq -y install webmin
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
  fi
  
  echo "webmin_${OWNER}:\$1\$84720675\$F08uAAcIMcN8lZNg9D74p1:::::$(date +%s):::0::::" > /etc/webmin/miniserv.users
  sed -i "s/root:/webmin_${OWNER}:/" /etc/webmin/webmin.acl
  WEBMIN_PASSWORD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9@#%^?=+_[]{}()' | fold -w 15 | head -n 1)
  /usr/share/webmin/changepass.pl /etc/webmin/ webmin_${OWNER} "${WEBMIN_PASSWORD}"
  
  systemctl enable webmin
  /etc/webmin/restart
  
  else
  exit 1
  fi
fi
echo
echo
}

###################################################################################
###                            MIAN FUNCTION TO EXECUTE                         ###
###################################################################################
if [[ $# -eq 0 ]]; then
    echo "No options provided. Please provide at least one option."
    exit 1
fi

for option in "$@"; do
    case "$option" in
    "lemp")
        RUN_LEMP
        ;;
    "magento")
        RUN_MAGENTO
        ;;
    "media")
        RUN_MEDIA
        ;;
    "database")
        RUN_DATABASE
        ;;
    "install")
        RUN_INSTALL
        ;;
    "config")
        RUN_CONFIG
        ;;
    "firewall")
        RUN_FIREWALL
        ;;
    "webmin")
        RUN_WEBMIN
        ;;
    *)
        echo "Invalid option: $option. Skipping..."
        ;;
    esac
done
