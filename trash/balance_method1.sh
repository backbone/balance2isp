#!/bin/bash

#https://help.ubuntu.ru/wiki/ip_balancing#%D1%81%D0%BF%D0%BE%D1%81%D0%BE%D0%B1_1

################### CONFIG ############
BeeLine="/etc/routing/BeeLine.list"
### Home Network
l_eth=docker0
l_ip=172.17.0.1
l_net=172.17.0.0/24

########### Local ISP Network #########
li_net=172.17.0.0/24

########### ISP1 ######################
i1_eth=wifi0
i1_ip=192.168.43.107
i1_net=192.168.43.0/24
i1_gw=192.168.43.1

########### ISP2 ######################
i2_eth=wan0
i2_ip=192.168.2.3
i2_net=192.168.0.0/16
i2_gw=192.168.2.2

#########ip route2 tables##############
t1=101
t2=102
#######################################

########### Flushing ##################
iptables -t mangle -F NEW_OUT_CONN
iptables -t mangle -F PREROUTING
iptables -t mangle -F OUTPUT
iptables -t mangle -X NEW_OUT_CONN
ip route flush table $t2
ip rule del table $t2
ip route flush table $t1
ip rule del table $t1
ip route flush cache
#######################################

iptables -t mangle -N NEW_OUT_CONN
iptables -t mangle -A NEW_OUT_CONN -j CONNMARK --set-mark 1
iptables -t mangle -A NEW_OUT_CONN -m statistic --mode random --probability 0.50 -j RETURN
iptables -t mangle -A NEW_OUT_CONN -j CONNMARK --set-mark 2

#for file in $BeeLine; do
#if [ -f "$file" ]; then
#{ cat "$file" ; echo ; } | while read ip_addr; do
#if [ "$ip_addr" != "" ]; then
#echo "Статическая маршрутизация для $ip_addr"
#iptables -t mangle -A NEW_OUT_CONN -d $ip_addr -j CONNMARK --set-mark 1
#fi
#done
#fi
#done

iptables -t mangle -A PREROUTING -d $l_net -j RETURN
iptables -t mangle -A PREROUTING -d $li_net -j RETURN

iptables -t mangle -A PREROUTING -s $l_net -m state --state new,related -j NEW_OUT_CONN
iptables -t mangle -A PREROUTING -s $l_net -j CONNMARK --restore-mark

iptables -t mangle -A OUTPUT -d $l_net -j RETURN
iptables -t mangle -A OUTPUT -d $li_net -j RETURN

iptables -t mangle -A OUTPUT -s $l_net -m state --state new,related -j NEW_OUT_CONN
iptables -t mangle -A OUTPUT -s $li_net -j CONNMARK --restore-mark

ip route add $l_net dev $l_eth scope link table $t1
ip route add $i2_net dev $i2_eth scope link table $t1
ip route add $i1_net dev $i1_eth scope link src $i1_ip table $t1
ip route add 127.0.0.0/8 dev lo scope link table $t1
ip route add default via $i1_gw table $t1

ip rule add prio 51 fwmark 1 table $t1
ip rule add from $i1_ip table $t1

ip route add $l_net dev $l_eth scope link table $t2
ip route add $i1_net dev $i1_eth scope link table $t2
ip route add $i2_net dev $i2_eth scope link src $i2_ip table $t2
ip route add 127.0.0.0/8 dev lo scope link table $t2
ip route add default via $i2_gw table $t2

ip rule add prio 52 fwmark 2 table $t2
ip rule add from $i2_ip table $t2
