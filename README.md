# Magento 2 installation with Ansible - WIP MVP
## Debian 12 13 | Ubuntu 22.04 24.04

<img width="731" height="138" alt="magenx_aws_ec2_set" src="https://github.com/user-attachments/assets/f7929220-73f0-4de4-8cee-c8d8bd8158d8" />

## Production ready + AWS Graviton2 ARM support

 > ["DigitalOcean" cloud servers](https://m.do.co/c/ccc5d115377f)  
 > ["Hetzner" cloud servers](https://hetzner.cloud/?ref=RjVtLXq3rlEz)

## :rocket: Installation:  
 
### Provision Magento 2 E-commerce LEMP Stack
```
mv group_vars/all.yml.template group_vars/all.yml
vim group_vars/all.yml
ansible-playbook magenx.yml
```
  
## System requirements:
*Dedicated server / Container*  
*8Gb RAM*  
 ["DigitalOcean" cloud servers](https://m.do.co/c/ccc5d115377f)  
 ["Hetzner" cloud servers](https://hetzner.cloud/?ref=RjVtLXq3rlEz)
   
   
## 💾 MagenX ecommerce webstack for Magento 2 Open Source  
Get a fully pre-configured server with Magento and LEMP stack in just 10 minutes! 🚀 

- [x] Linux system packages with automatic updates
- [x] Initial system optimization and hardening
- [x] Varnish HTTPS cache setup
- [x] MariaDB my.cnf optimization
- [x] Nginx optimized config with security
- [x] OpenSearch 2.x latest
- [x] PHP-FPM (apcu, opcache, lz4)
- [x] Redis Magento Cache and Sessions (2 instances)
- [x] RabbitMQ message queue
- [x] Certbot configuration
- [x] Separate Magento files owner and php-fpm user
- [x] Advanced ACL linux permissions, read/write protection
  
Extra premium options available:  
  
- [x] Multiple environments
- [x] Webmin control panel
- [x] SFTP advanced configuration
- [x] SSH private key access ready
- [x] UFW and Fail2ban advanced configuration
- [x] Nginx and UFW DDOS mitigation
- [x] Nginx and UFW Carding Attack mitigation
- [x] MariaDB database optimization
- [x] Mytop database monitoring
- [x] Proxysql split/cache database query
- [x] n98-magerun2 Magento 2 cli management
- [x] PhpMyAdmin custom path with http auth
- [x] Goaccess nginx log visualization
- [x] Auditd Magento 2 files monitoring
- [x] Automatic nginx images optimization
- [x] Magento 2 logs rotation
- [x] PWA Studio ready
- [x] Hyva Theme ready
- [x] Ready for production.

Complete linux stack including:  
- linux and webstack settings optimization
- iotop
- sysstat
- git
- strace
- iptraf-ng
- nginx images optimization
- geoip
- logs rotation
- separate permissions for nginx and php user
- and many more
  
  
## 🔡 Environment / Magento mode:  
The script configures webstack, users, folders, and all settings for a given environment. Productions mode. Read-only. Linux ACL
  
  
## 📄 Get config:  
All configuration parameters saved in Ansible state and templates.
```
ansible
```
  
## 🛡️ SSL / HTTPS:
Before setup up and running, set up SSL with certbot:  
`certbot certonly --agree-tos --no-eff-email --register-unsafely-without-email --webroot -w /home/{USER}/current/pub`  
and uncomment the lines for SSL in:  
- /etc/nginx/nginx.conf
- /etc/nginx/sites-available/{DOMAIN_NAME}.conf

  
## :hammer_and_wrench: DevOps idea:
You have the opportunity to install a new Magento 2, and it is best to do this in a staging environment. Push the code to your Github repository and from there develop and deploy to production and staging environment using Github Actions.  
This is the safest and most productive approach.
There are few configuration files available for Github Actions [paid extra] deployments: 
 - `/opt/deploy/deploy.py` - basic script to catch Github Actions deployment input and run zero-downtime deployment
 - `~/.env` - magento 2 environment variables
 - `~/.ssh/authorized_keys` - pre-configured ssh keys

  
### Deployment Flow:
- Create release time folder 202508211230 (date example)
- Symlink shared files into new release
- Extract new version to releases/202508211230/
- Atomically switch current symlink to new release
- Remove old releases (keep last 2-3)
  
```
/home/USER/
├── current -> releases/202508211230/    # Symlink to active version
├── releases/                            # All deployed versions
│   ├── 202508211030/                    # Previous release
│   └── 202508211230/                    # Current release
└── shared/                              # Persistent data
    ├── var                              # Logs, tmp (symlink from active version)
    └── pub/media/                       # Uploads, images (symlink from active version)
```
This gives you zero-downtime deployments and instant rollbacks.

You can use tools that help you implement the folder-based atomic deployment structure 
(with current, releases, shared directories) on your own server. 
  
## 🧰 Tools:
[**you can use the following free included**]:
- [Magento 2 deployment pipeline](https://github.com/magenx/Magento-2-deployment-pipeline) - Fully automated Magento 2 development and deployment pipeline with code review, composer check and pre-release => release workflow | MVP  
  > just create your own repository, add your magento files, copy only [.github](https://github.com/magenx/Magento-2-deployment-pipeline/tree/main/.github) folder to your reposity, it will auto init  
  > complete all [security configuration](https://github.com/magenx/Magento-2-deployment-pipeline?tab=readme-ov-file#soc-2-requirements)
- `sudo cacheflush` - to flush magento cache and restart php-fpm / nginx
- `mysqltuner` - to see mysql metrics and parameters
- `mytop` - database query monitoring / management
- `n98-magerun2` - magento 2 extented cli
- magento profiler built in nginx security header - conf_m2/maps.conf

[**paid deployment tools**]:
- deploy.py
- deploy.sh
- collection of scripts and server settings to enable zero-downtime remote deployments
  
  
## 😻 Support the project  
You can use this for free. But its not free to create it. This takes time and research.  
If you are using this project, there are few ways you can support it:
- [x] Star and sharing the project
- [x] Open an issue to help make it better
- [x] Donate
- [x] Write a review https://trustpilot.com/review/www.magenx.com  
 
![deniszokov_paypal_qrcode](https://github.com/magenx/Magento-2-aws-cluster-terraform/assets/1591200/3175c8a5-7786-4056-87c0-b4e0727f4ede)  
  
❤️ Opensource  
