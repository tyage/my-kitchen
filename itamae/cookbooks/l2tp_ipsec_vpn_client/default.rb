require './itamae/helper/helper.rb'

node.reverse_merge!(
  l2tp_ipsec_vpn_client: {
    local_user: 'tyage',
    server: '13.113.59.63',
    user: node[:secrets][:l2tp_ipsec_vpn_user],
    user_password: node[:secrets][:l2tp_ipsec_vpn_password],
    install_directory: '/home/tyage/.vpnclient',
    softether_download_url: 'http://jp.softether-download.com/files/softether/v4.27-9666-beta-2018.04.21-tree/Linux/SoftEther_VPN_Client/64bit_-_Intel_x64_or_AMD64/softether-vpnclient-v4.27-9666-beta-2018.04.21-linux-x64-64bit.tar.gz'
  }
)

local_user = node[:l2tp_ipsec_vpn_client][:local_user]
systemd_dir = "/home/#{local_user}/.config/systemd/user/"

directory node[:l2tp_ipsec_vpn_client][:install_directory] do
  user local_user
  mode '755'
  owner local_user
  group local_user
end

execute 'install softether' do
  user local_user
  cwd '/tmp'
  command <<-"EOS"
    wget #{node[:l2tp_ipsec_vpn_client][:softether_download_url]} -O vpnclient.tar.gz
    tar zxvf vpnclient.tar.gz
    mv vpnclient/* #{node[:l2tp_ipsec_vpn_client][:install_directory]}
    mv vpnclient/.* #{node[:l2tp_ipsec_vpn_client][:install_directory]}
    rm -rf vpnclient.tar.gz vpnclient
    cd #{node[:l2tp_ipsec_vpn_client][:install_directory]}
    make <<!
1
1
1
!
  EOS
  not_if "test -e #{node[:l2tp_ipsec_vpn_client][:install_directory]}/vpnclient"
end

auth_password = md5_base64(node[:l2tp_ipsec_vpn_client][:user_password] + node[:l2tp_ipsec_vpn_client][:user].upcase)
template "#{node[:l2tp_ipsec_vpn_client][:install_directory]}/vpn_client.config" do
  action :create
  mode '0600'
  owner local_user
  group local_user
  variables(
    auth_password: auth_password
  )
  source 'templates/vpn_client.config'
end

template "#{node[:l2tp_ipsec_vpn_client][:install_directory]}/daemon.sh" do
  action :create
  mode '0755'
  owner local_user
  group local_user
  source 'templates/daemon.sh'
end

directory systemd_dir do
  user local_user
  mode '755'
  owner local_user
  group local_user
end

template "#{systemd_dir}/vpnclient.service" do
  action :create
  mode '0644'
  owner local_user
  group local_user
  notifies :run, 'execute[systemctl --user daemon-reload]', :immediately
  source 'templates/vpnclient.service'
end

# XXX: this command may fail... do it in terminal
execute 'start vpnclient' do
  user local_user
  command <<-"EOS"
    systemctl --user enable vpnclient
    systemctl --user start vpnclient
  EOS
  only_if "systemctl --user --quiet is-enabled vpnclient"
end
