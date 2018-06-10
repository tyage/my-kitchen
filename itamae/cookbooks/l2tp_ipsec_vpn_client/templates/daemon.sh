#!/bin/bash

DAEMON="<%= node[:l2tp_ipsec_vpn_client][:install_directory] %>/vpnclient"
VPNCMD="<%= node[:l2tp_ipsec_vpn_client][:install_directory] %>/vpncmd"
VPNUP=`ps -ef | grep $DAEMON | grep -v grep | wc -l`
VPNNAME="vpn_vpn"
DHCLIENT_PIDFILE="/run/dhclient.$VPNNAME.pid"

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

    dhclient $VPNNAME -pf $DHCLIENT_PIDFILE

    while [ true ]
    do
      ip -4 -o addr | grep -qi vpn_ && break
      echo "Waiting for startup vlan up..."
      sleep 1
    done

    # do not use vpn as default route
    ip route del default dev vpn_vpn
  ;;
  stop)
    if [ $VPNUP = 0 ]; then
      echo "VPN client has already stoped"
      exit 1
    fi

    kill `cat $DHCLIENT_PIDFILE`
    rm $DHCLIENT_PIDFILE

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
