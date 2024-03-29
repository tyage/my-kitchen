require './itamae/helper/helper.rb'

node.reverse_merge!(
  l2tp_ipsec_vpn_server: {
    server_password: node[:secrets][:l2tp_ipsec_vpn_server_password],
    ipsec_psk: node[:secrets][:l2tp_ipsec_vpn_ipsec_psk],
    user: node[:secrets][:l2tp_ipsec_vpn_user],
    user_password: node[:secrets][:l2tp_ipsec_vpn_password],
    install_directory: '/usr/local/vpnserver',
    softether_download_url: 'https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.37-9758-beta/softether-vpnserver-v4.37-9758-beta-2021.08.16-linux-x64-64bit.tar.gz'
  }
)

directory node[:l2tp_ipsec_vpn_server][:install_directory] do
  user 'root'
  mode '755'
  owner 'root'
  group 'root'
end

execute 'install softether' do
  cwd '/tmp'
  command <<-"EOS"
    wget #{node[:l2tp_ipsec_vpn_server][:softether_download_url]} -O vpnserver.tar.gz
    tar zxvf vpnserver.tar.gz
    mv vpnserver/* #{node[:l2tp_ipsec_vpn_server][:install_directory]}
    mv vpnserver/.* #{node[:l2tp_ipsec_vpn_server][:install_directory]}
    rm -rf vpnserver.tar.gz vpnserver
    cd #{node[:l2tp_ipsec_vpn_server][:install_directory]}
    make <<!
1
1
1
!
  EOS
  not_if "test -e #{node[:l2tp_ipsec_vpn_server][:install_directory]}/vpnserver"
end

hashed_server_password = sha0_base64(node[:l2tp_ipsec_vpn_server][:server_password])
auth_ntlm_secure_hash = nt_hash_base64(node[:l2tp_ipsec_vpn_server][:user_password])
auth_password = sha0_base64(node[:l2tp_ipsec_vpn_server][:user_password] + node[:l2tp_ipsec_vpn_server][:user].upcase)
config_file = "#{node[:l2tp_ipsec_vpn_server][:install_directory]}/vpn_server.config"
template config_file do
  action :create
  mode '0600'
  owner 'root'
  group 'root'
  variables(
    hashed_server_password: hashed_server_password,
    auth_ntlm_secure_hash: auth_ntlm_secure_hash,
    auth_password: auth_password
  )
  source 'templates/vpn_server.config'
  not_if "test -e #{config_file}"
end

template '/etc/systemd/system/vpnserver.service' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  source 'templates/vpnserver.service'
end

service 'vpnserver' do
  action [:enable, :start]
end
