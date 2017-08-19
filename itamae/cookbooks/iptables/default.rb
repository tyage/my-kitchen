file '/etc/iptables/iptables.rules' do
  action :create
  user 'root'
  mode '0644'
  owner 'root'
  group 'root'
  content node[:iptables][:iptables_rules]
  notifies :run, 'execute[iptables-restore < /etc/iptables/iptables.rules]'
end

execute 'iptables-restore < /etc/iptables/iptables.rules' do
  action :nothing
end
