apt_key 'C300EE8C'

file '/etc/apt/sources.list.d/nginx.list' do
  owner 'root'
  group 'root'
  mode '0644'

  content <<-EOC
deb http://ppa.launchpad.net/nginx/development/ubuntu trusty main
deb-src http://ppa.launchpad.net/nginx/development/ubuntu trusty main
  EOC

  notifies :run, "execute[apt-get update]", :immediately
end
