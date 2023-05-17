# Magento 2 installation - Magenx e-commerce webstack  
## Debian 11 | Ubuntu 20.04

## Production ready + AWS Graviton2 ARM support

> get your $100 credit and deploy on [DigitalOcean](https://m.do.co/c/ccc5d115377f)

## :rocket: Installation:  

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
  
## System requirements:
*Dedicated server / Container*  
*8Gb RAM*  
*like [DigitalOcean cloud servers](https://m.do.co/c/ccc5d115377f)  
   
   
## 💾 MagenX ecommerce webstack for Magento 2 Open Source  
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
- [x] Hyva Theme ready
- [x] Ready for production.

Complete linux stack including:  
- linux and webstack settings optimization
- letsencrypt
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
  
  
## 🔡 Environment / Magento mode:  
You can select the type of environment and Magento mode respectively. By installing 3 environments on one server at the same time - developer, staging and production, or one type only if you use simple development or even different servers per environment. The script configures users, folders, and all settings for a given environment.
  
  
## 📄 Get config:  
All configuration parameters saved in sqlite database.
```
sqlite3 -line /opt/magenx/config/magenx.db "SELECT * FROM magento;"
sqlite3 -line /opt/magenx/config/magenx.db "SELECT * FROM system;"
```
  
## 🛡️ SSL / HTTPS:
Once up and running, set up SSL with certbot (already installed):  
`certbot certonly --agree-tos --no-eff-email --email {EMAIL} --webroot -w /home/{USER}/public_html/pub`  
and uncomment the lines for SSL in:  
- /etc/nginx/nginx.conf
- /etc/nginx/sites-available/{DOMAIN_NAME}.conf
- /etc/nginx/conf_m2/varnish_proxy.conf

  
## :hammer_and_wrench: DevOps idea:
You have the opportunity to install a new Magento 2, and it is best to do this in a developer environment. Push the code to your Github repository and from there develop and deploy to production and staging environment using Github Actions.  
This is the safest and most productive approach.
There are few configuration files available for Github Actions [paid extra] deployments: 
 - `~/deploy.sh` - basic script to catch Github Actions deployment input and run git and magento commands
 - `~/.env` - magento 2 environment variables
 - `~/.ssh/authorized_keys` - pre-configured ssh keys

  
## 🧰 Tools:
you can use the following:
- `sudo cacheflush` - to flush magento cache and restart php-fpm / nginx
- `mysqltuner` - to see mysql metrics and parameters
- `mytop` - database query monitoring / management
- `n98-magerun2` - magento 2 extented cli
- magento profiler built in nginx - `developer?xxx`  <a href="https://github.com/magenx/Magento-nginx-config/blob/99b531d847fd8d3b232adcfc11e79b6bc952a6db/magento2/conf_m2/maps.conf#L24">Magento-nginx-config/magento2/conf_m2/maps.conf</a>

  
  
## 😻 Support the project  
You can use this for free. But its not free to create it. This takes time and research.  
If you are using this project, there are few ways you can support it:
- [x] Star and sharing the project
- [x] Open an issue to help make it better
- [x] Donate  
 
![deniszokov_paypal_qrcode](https://github.com/magenx/Magento-2-aws-cluster-terraform/assets/1591200/3175c8a5-7786-4056-87c0-b4e0727f4ede)  
  
❤️ Opensource  
