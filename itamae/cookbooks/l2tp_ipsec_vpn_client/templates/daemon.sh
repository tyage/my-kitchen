#!/bin/bash

DAEMON="#{node[:l2tp_ipsec_vpn_client][:install_directory]}/vpnclient"
VPNUP=`ps -ef | grep vpnclient | grep -v grep | wc -l`
VPNNAME="vpn_vpn"
GATEWAY="192.168.30.11"
SUBNET="192.168.30.0/24"

test -x $DAEMON || exit 0

case "$1" in
  start)
    if [ $VPNUP > 0 ]; then
      echo "VPN client has already started"
      exit 1
    fi

    $DAEMON start

    VPNLINK=`ip -4 -o addr | grep -c vpn_`
    while [ $VPNLINK = 0 ]
    do
      echo "Waiting for startup vlan up..."
      sleep 1
      VPNLINK=`ip -4 -o addr | grep -c vpn_`
    done

    route add -net $SUBNET gw $GATEWAY dev $VPNNAME
  ;;
  stop)
    if [ $VPNUP = 0 ]; then
      echo "VPN client has already stoped"
      exit 1
    fi

    route del -net $SUBNET gw $GATEWAY dev $VPNNAME

    $DAEMON stop
  ;;
  restart)
    $0 stop
    sleep 3
    $0 start
  ;;
  *)
  echo "Usage: $0 {start|stop|restart}"
  exit 1
esac

exit 0
