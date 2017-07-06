node.reverse_merge!(
  l2tp_ipsec_vpn_server: {
    ipsec_psk: node[:secrets][:l2tp_ipsec_vpn_ipsec_psk],
    user: node[:secrets][:l2tp_ipsec_vpn_user],
    password: node[:secrets][:l2tp_ipsec_vpn_password]
    install_directory: '/usr/local/vpnserver'
  }
)

download_url = 'http://jp.softether-download.com/files/softether/v4.22-9634-beta-2016.11.27-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.22-9634-beta-2016.11.27-linux-x64-64bit.tar.gz'

directory node[:l2tp_ipsec_vpn_server][:install_directory] do
  user 'root'
  mode '755'
  owner 'root'
  group 'root'
end

execute 'install softether' do
  cwd '/tmp'
  command <<- "EOS"
    wget #{download_url}
    tar -xgz #{node[:l2tp_ipsec_vpn_server][:install_directory]}
  EOS
  not_if "test -e #{node[:l2tp_ipsec_vpn_server][:install_directory]}/vpnserver"
end

template '/etc/systemd/system/vpnserver.service' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  variables(options: options.join(' '))
  notifies :run, 'execute[systemctl daemon-reload]'
end

execute 'systemctl daemon-reload' do
  action :nothing
end

service 'vpnserver' do
  action [:enable, :start]
end
