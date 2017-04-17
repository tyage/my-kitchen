packages = %w(znc)
packages.each do |package|
  package package do
    action :install
  end
end

remote_file '/etc/nginx/sites-enabled/irc.tyage.net' do
  source 'files/nginx/irc.tyage.net'
  owner  'root'
  group  'root'
  mode   '644'
  notifies :reload, 'service[nginx]'
end
