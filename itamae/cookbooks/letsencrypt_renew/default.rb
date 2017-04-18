require 'shellwords'

options = [
  "-a #{node[:letsencrypt_renew][:authenticator]}"
]
options << "-w #{Shellwords.escape(node[:letsencrypt_renew][:webroot_path])}" if node[:letsencrypt_renew][:webroot_path]
options << "--post-hook #{Shellwords.escape(node[:letsencrypt_renew][:post_hook])}" if node[:letsencrypt_renew][:post_hook]

template '/etc/systemd/system/certbot.service' do
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

remote_file '/etc/systemd/system/certbot.timer' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[systemctl enable certbot.timer]'
end

execute 'systemctl enable certbot.timer' do
  action :nothing
end
