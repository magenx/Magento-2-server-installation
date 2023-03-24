# Magento 2 installation - Magenx ecommerce webstack  
## Debian 11 | Ubuntu 20.04
## Also supports AWS Graviton2 ARM and OCI ARM
### (Amazon Linux 2 | RedHat 8 | Rocky Linux 8) on request

## The easiest way to deploy Magento for production or development!

> get your $100 credit and deploy on [DigitalOcean](https://m.do.co/c/ccc5d115377f)

to install simply call:  

```
curl -Lo magenx.sh https://magenx.sh && bash magenx.sh
```  
https://user-images.githubusercontent.com/1591200/128596448-2bf94578-8e80-47bf-b770-1799ae97df53.mp4  

you can run in `screen` to have indestructible session:

```
dnf install -y epel-release; dnf install -y screen
screen
bash magenx.sh
```
Once up and running, set up SSL with certbot (already installed) and edit the lines for SSL in:
- /etc/nginx/sites-available/magento2.conf

#### MagenX ecommerce webstack - server configuration for Magento 2 Open Source  
Get a fully pre-configured server with Magento and LEMP stack in just 10 minutes! 🚀 

- [x] Linux system packages with automatic updates
- [x] Initial system optimization and hardening
- [x] Varnish HTTPS cache setup
- [x] MariaDB my.cnf optimization
- [x] Nginx optimized config with security
- [x] ELK 7.x stack - Elasticsearch latest (log4j2 fixed)
- [x] PHP-FPM (apcu, opcache, lzf, snappy, redis)
- [x] Redis Magento Cache and Sessions (2 instances)
- [x] RabbitMQ message queue
- [x] Letsencrypt/certbot configuration
- [x] Separate Magento files owner and php-fpm user
- [x] Advanced ACL linux permissions, read/write protection
- [x] Chroot configuration: jailed ssh and php user (optional)
  
Extra premium options available:  
  
- [x] Multiple environments
- [x] Webmin control panel
- [x] SFTP advanced configuration
- [x] SSH private key access ready
- [x] ConfigServer Security and Firewall advanced configuration
- [x] Nginx and CSF Firewall DDOS mitigation
- [x] Nginx and CSF Firewall Carding Attack mitigation
- [x] MariaDB database optimization
- [x] Mytop database monitoring
- [x] Proxysql split database / custom port
- [x] n98-magerun2 Magento 2 cli management
- [x] PhpMyAdmin custom path with http auth
- [x] Goaccess nginx log visualization
- [x] Malware scanner (mwscan,maldet) with email alerts
- [x] Auditd Magento 2 files monitoring
- [x] Automatic nginx images optimization
- [x] Magento 2 logs rotation
- [x] PWA Studio ready
- [x] Ready for production.

Complete linux stack including: <br/>
- linux and webstack settings optimization
- [letsencrypt (snapd)](https://certbot.eff.org/lets-encrypt/snap-other)
- [goaccess](http://rt.goaccess.io)
- iotop
- sysstat
- git/svn
- strace
- python-pip
- iptraf
- nginx images optimization
- geoip
- logs rotation
- separate permissions for nginx and php user
- and many more

  
## Get config:
```
sqlite3 -line /opt/magenx/config/magenx.db "SELECT * FROM magento;"
sqlite3 -line /opt/magenx/config/magenx.db "SELECT * FROM system;"
```
  
## DevOps idea:
You have the opportunity to install a new Magento 2, and it is best to do this in a developer environment. Push the code to your Github repository and from there develop and deploy to production and staging environment using Github Actions.  
This is the safest and most productive approach.
  
  
**System requirements**:<br/>
*Dedicated server / Container*<br/>
*8Gb RAM*<br/>
*like [DigitalOcean cloud servers](https://m.do.co/c/ccc5d115377f)

