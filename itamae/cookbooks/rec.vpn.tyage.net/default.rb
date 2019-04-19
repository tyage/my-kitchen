# TODO: store .htpasswd
#remote_file "/etc/nginx/.htpasswd" do
#  owner  'root'
#  group  'root'
#  mode   '644'
#  notifies :reload, 'service[nginx]'
#end

sites = %w(rec.vpn.tyage.net)
sites.each do |site|
  remote_file "/etc/nginx/sites-enabled/#{site}" do
    source "files/nginx/#{site}"
    owner  'root'
    group  'root'
    mode   '644'
    notifies :reload, 'service[nginx]'
  end
end
