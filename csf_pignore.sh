#!/bin/bash
## disable noisy firewall alerts
for program in $(grep -o 'EXE:.*' /var/log/lfd.log | awk -F' ' '{print tolower($1)}' | sort -u)
do 
echo "${program}" >> /etc/csf/csf.pignore
done

csf -ra
