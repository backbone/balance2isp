#!/bin/bash
# https://www.opennet.ru/docs/RUS/LARTC/x348.html

IF1=wifi0
IF2=wifi1
IF0=docker0

set -v
set -x

IP0=$(ip -o -4 addr show $IF0 | awk -F'(\\s|/)+' '{print $4}')
P0_NET=$(echo $IP0 | cut -d. -f1,2,3).0/24

IP1=$(ip -o -4 addr show $IF1 | awk -F'(\\s|/)+' '{print $4}')
P1_NET=$(echo $IP1 | cut -d. -f1,2,3).0/24
P1=$(ip route show dev $IF1 | awk '/default/ {print $3}')
[ -z "$P1" ] && P1=$(ip route ls | grep 'nexthop.*wifi0' | awk '{print $3}')
T1=81

IP2=$(ip -o -4 addr show $IF2 | awk -F'(\\s|/)+' '{print $4}')
P2_NET=$(echo $IP2 | cut -d. -f1,2,3).0/24
P2=$(ip route show dev $IF2 | awk '/default/ {print $3}')
[ -z "$P2" ] && P2=$(ip route ls | grep 'nexthop.*wifi1' | awk '{print $3}')
T2=82

# -- CLEAR --
ip route flush table $T2
ip rule del table $T2
ip route flush table $T1
ip rule del table $T1
ip route flush cache

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

ip rule add from $IP1 table T1
ip rule add from $IP2 table T2

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

ip route add default scope global \
	nexthop via $P1 dev $IF1 weight 1 \
	nexthop via $P2 dev $IF2 weight 1
