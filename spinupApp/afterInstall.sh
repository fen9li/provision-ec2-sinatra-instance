#!/bin/bash
# this script configure iptables firewall rules, save it and start iptables service
# run as root

iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

iptables -A INPUT -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 4567
iptables -t nat -I OUTPUT -p tcp -o lo --dport 80 -j REDIRECT --to-port 4567

service iptables save
service iptables start

exit 0
