template '/etc/systemd/system/certbot.service' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
end

file '/etc/systemd/system/certbot.timer' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies 'execute[systemctl enable certbot.timer]'
end
