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

    while [ true ]
    do
      $VPNCMD localhost /CLIENT /CMD AccountStatusGet VPN | grep "Session Status" | grep -qi "Connection Completed" && break
      echo "Waiting for vpn connection..."
      sleep 1
    done

    dhclient $VPNNAME

    while [ true ]
    do
      ip -4 -o addr | grep -qi vpn_ && break
      echo "Waiting for startup vlan up..."
      sleep 1
    done
  ;;
  stop)
    if [ $VPNUP = 0 ]; then
      echo "VPN client has already stoped"
      exit 1
    fi

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
