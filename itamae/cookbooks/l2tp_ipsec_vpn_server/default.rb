node.reverse_merge!(
  l2tp_ipsec_vpn_server: {
    server_password: node[:secrets][:l2tp_ipsec_vpn_server_password],
    ipsec_psk: node[:secrets][:l2tp_ipsec_vpn_ipsec_psk],
    user: node[:secrets][:l2tp_ipsec_vpn_user],
    password: node[:secrets][:l2tp_ipsec_vpn_password]
    install_directory: '/usr/local/vpnserver'
    download_url: 'http://jp.softether-download.com/files/softether/v4.22-9634-beta-2016.11.27-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.22-9634-beta-2016.11.27-linux-x64-64bit.tar.gz'
  }
)

def nt_hash(password)
  utf16_password = password.chars.map{ |c| c + "\0" }.join('')
  md4(utf16_password)
end

directory node[:l2tp_ipsec_vpn_server][:install_directory] do
  user 'root'
  mode '755'
  owner 'root'
  group 'root'
end

execute 'install softether' do
  cwd '/tmp'
  command <<- "EOS"
    wget #{node[:l2tp_ipsec_vpn_server][:download_url]}
    tar -xgz #{node[:l2tp_ipsec_vpn_server][:install_directory]}
    cd #{node[:l2tp_ipsec_vpn_server][:install_directory]}
    make <<!
1
1
1
!
  EOS
  not_if "test -e #{node[:l2tp_ipsec_vpn_server][:install_directory]}/vpnserver"
end

execute 'setup softether vpn config' do
  cwd node[:l2tp_ipsec_vpn_server][:install_directory]
  command <<- "EOS"
    ./vpnserver start
    ./vpncmd <<!
1


ServerPasswordSet
#{node[:secrets][:softether_password]}
#{node[:secrets][:softether_password]}
HubCreate VPN
#{node[:l2tp_ipsec_vpn_server][:ipsec_psk]}
#{node[:l2tp_ipsec_vpn_server][:ipsec_psk]}
Hub VPN
SecureNatEnable
UserCreate #{node[:l2tp_ipsec_vpn_server][:user]}

#{node[:l2tp_ipsec_vpn_server][:user]}

UserPasswordSet #{node[:l2tp_ipsec_vpn_server][:user]}
#{node[:l2tp_ipsec_vpn_server][:password]}
#{node[:l2tp_ipsec_vpn_server][:password]}
IPsecEnable VPN
!
    ./vpnserver stop
  EOS
  not_if "test -e #{node[:l2tp_ipsec_vpn_server][:install_directory]}/vpn_server.config"
end

template '/etc/systemd/system/vpnserver.service' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[systemctl daemon-reload]'
end

execute 'systemctl daemon-reload' do
  action :nothing
end

service 'vpnserver' do
  action [:enable, :start]
end
