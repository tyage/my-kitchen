#!/bin/bash

DAEMON="<%= node[:l2tp_ipsec_vpn_client][:install_directory] %>/vpnclient"
VPNCMD="<%= node[:l2tp_ipsec_vpn_client][:install_directory] %>/vpncmd"
VPNUP=`ps -ef | grep $DAEMON | grep -v grep | wc -l`
VPNNAME="vpn_vpn"

test -x $DAEMON || exit 0

case "$1" in
  start)
    if [ $VPNUP -gt 0 ]; then
      echo "VPN client has already started"
      exit 1
    fi

    $DAEMON start
    $VPNCMD localhost /CLIENT /CMD AccountConnect VPN
    dhclient $VPNNAME

    VPNLINK=`ip -4 -o addr | grep -c vpn_`
    while [ $VPNLINK = 0 ]
    do
      echo "Waiting for startup vlan up..."
      sleep 1
      VPNLINK=`ip -4 -o addr | grep -c vpn_`
    done
  ;;
  stop)
    if [ $VPNUP = 0 ]; then
      echo "VPN client has already stoped"
      exit 1
    fi

    $VPNCMD localhost /CLIENT /CMD AccountDisconnect VPN
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
