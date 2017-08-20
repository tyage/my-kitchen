require './itamae/helper/helper.rb'

node.reverse_merge!({
  znc: {
    user: 'znc',
    port: 6667
  }
})

znc_home = "/home/#{node[:znc][:user]}"
user node[:znc][:user] do
  home znc_home
  create_home true
end

packages = %w(znc)
packages.each do |package|
  package package do
    action :install
  end
end

template '/etc/nginx/sites-enabled/irc.tyage.net' do
  source 'templates/nginx/irc.tyage.net'
  owner 'root'
  group 'root'
  mode '644'
  notifies :reload, 'service[nginx]'
end

# znc service
template '/etc/systemd/system/znc.service' do
  source 'templates/znc.service'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

service 'znc' do
  action [:enable, :start]
end

# znc config files
directory "#{znc_home}/.znc" do
  user node[:znc][:user]
  mode '755'
  owner node[:znc][:user]
  group node[:znc][:user]
end
directory "#{znc_home}/.znc/configs" do
  user node[:znc][:user]
  mode '755'
  owner node[:znc][:user]
  group node[:znc][:user]
end

execute 'create pem' do
  cwd znc_home
  user node[:znc][:user]
  command 'znc --makepem'
  not_if "test -e .znc/znc.pem"
  notifies :reload, 'service[znc]'
end

config_file = "#{znc_home}/.znc/configs/znc.conf"
template config_file do
  source 'templates/znc.conf'
  owner node[:znc][:user]
  group node[:znc][:user]
  mode '644'
  not_if "test -e #{config_file}"
  notifies :reload, 'service[znc]'
end
