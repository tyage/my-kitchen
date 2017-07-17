require 'shellwords'

options = [
  "-a #{node[:letsencrypt_renew][:authenticator]}"
]
options << "-w \"#{node[:letsencrypt_renew][:webroot_path]}\"" if node[:letsencrypt_renew][:webroot_path]
options << "--pre-hook \"#{node[:letsencrypt_renew][:pre_hook]}\"" if node[:letsencrypt_renew][:pre_hook]
options << "--post-hook \"#{node[:letsencrypt_renew][:post_hook]}\"" if node[:letsencrypt_renew][:post_hook]

template '/etc/systemd/system/certbot.service' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  variables(options: options.join(' '))
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

remote_file '/etc/systemd/system/certbot.timer' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

service 'certbot.timer' do
  action [:enable, :start]
end
