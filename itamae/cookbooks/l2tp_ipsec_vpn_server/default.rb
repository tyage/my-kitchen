require 'openssl'
require 'base64'

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

def sha0_base64(data)
  digest = OpenSSL::Digest.new('sha')
  digest.update(data)
  Base64.strict_encode64(digest.digest)
end

def nt_hash_base64(password)
  utf16_password = password.chars.map{ |c| c + "\0" }.join('')
  digest = OpenSSL::Digest.new('md4')
  digest.update(utf16_password)
  Base64.strict_encode64(digest.digest)
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

template "#{node[:l2tp_ipsec_vpn_server][:install_directory]}/vpn_server.config" do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  source 'templates/vpn_server.config'
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
