#!/bin/bash

# -- DEFAULT POLICIES --
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# https://www.opennet.ru/docs/RUS/LARTC/x348.html
IF1=wan0
IP1=192.168.2.3
P1_NET=192.168.2/24
P1=192.168.2.2
T1=81

IF2=wifi0
IP2=192.168.43.107
P2_NET=192.168.43.0/24
P2=192.168.43.1
T2=82

IF0=docker0
P0_NET=172.17.0.0/24

# -- CLEAR --
iptables -F
iptables -X
iptables -t nat -F
iptables -t mangle -F
iptables -t nat -X
iptables -t mangle -X
ip route flush table $T2
ip rule del table $T2
ip route flush table $T1
ip rule del table $T1
ip route flush cache

# -- mangl MARK ---
iptables -t mangle -N NEW_OUT_CONN
iptables -t mangle -A NEW_OUT_CONN -j CONNMARK --set-mark 1
iptables -t mangle -A NEW_OUT_CONN -m statistic --mode random --probability 0.50 -j RETURN
iptables -t mangle -A NEW_OUT_CONN -j CONNMARK --set-mark 2

iptables -t mangle -A PREROUTING -d $P0_NET -j RETURN

iptables -t mangle -A PREROUTING -s $P0_NET -m state --state new,related -j NEW_OUT_CONN
iptables -t mangle -A PREROUTING -s $P0_NET -j CONNMARK --restore-mark

iptables -t mangle -A OUTPUT -d $P0_NET -j RETURN

iptables -t mangle -A OUTPUT -s $P0_NET -m state --state new,related -j NEW_OUT_CONN
iptables -t mangle -A OUTPUT -s $P0_NET -j CONNMARK --restore-mark

# ---
ip route add $P1_NET dev $IF1 src $IP1 table T1
ip route add default via $P1 table T1
ip route add $P2_NET dev $IF2 src $IP2 table T2
ip route add default via $P2 table T2

ip route add $P1_NET dev $IF1 src $IP1
ip route add $P2_NET dev $IF2 src $IP2

ip route add default via $P1

for i in `seq 10`; do
	ip rule del from $IP1 table T1 2>/dev/null
	ip rule del from $IP2 table T2 2>/dev/null
done

#ip rule add from $IP1 table T1
#ip rule add from $IP2 table T2
ip rule add prio 51 fwmark 1 table $T1
ip rule add prio 51 fwmark 2 table $T2

ip route add $P0_NET     dev $IF0 table T1
ip route add $P2_NET     dev $IF2 table T1
ip route add 127.0.0.0/8 dev lo   table T1
ip route add $P0_NET     dev $IF0 table T2
ip route add $P1_NET     dev $IF1 table T2
ip route add 127.0.0.0/8 dev lo   table T2

route del default gw $P1 $IF1 2>/dev/null
route del default gw $P1 $IF1 2>/dev/null
route del default gw $P2 $IF2 2>/dev/null
route del default gw $P2 $IF2 2>/dev/null
ip route del default via $P1 dev $IF1 2>/dev/null
ip route del default via $P2 dev $IF2 2>/dev/null
#route add default gw $P1 $IF1
#route add default gw $P2 $IF2

ip route add default scope global nexthop via $P1 dev $IF1 weight 1 \
nexthop via $P2 dev $IF2 weight 1

iptables -t nat -A POSTROUTING -o $IF1 -j MASQUERADE
iptables -t nat -A POSTROUTING -o $IF2 -j MASQUERADE
