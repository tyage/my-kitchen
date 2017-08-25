node.reverse_merge!(
  mackerel_agent: {
    apikey: node[:secrets][:tyage_net_mackerel_apikey]
  }
)

remote_file "/etc/apt/sources.list.d/mackerel.list"
execute "import mackerel GPG key" do
  command "curl -fsS https://mackerel.io/file/cert/GPG-KEY-mackerel-v2 | apt-key add -"
end

remote_file '/etc/apt/sources.list.d/mackerel.list' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[apt-get update]', :immediately
end

package 'mackerel-agent'

template '/etc/mackerel-agent/mackerel-agent.conf' do
  owner 'root'
  group 'root'
  mode  '0600'
end

service 'mackerel-agent' do
  action [:enable, :start]
end
