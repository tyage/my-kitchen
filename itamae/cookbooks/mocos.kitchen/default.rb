remote_directory '/var/www/mocos.kitchen' do
  owner  'root'
  group  'root'
  source 'directories/var/www/mocos.kitchen'
end

sites = %w(mocos.kitchen)
sites.each do |site|
  remote_file "/etc/nginx/sites-enabled/#{site}" do
    source "files/nginx/#{site}"
    owner  'root'
    group  'root'
    mode   '644'
    notifies :reload, 'service[nginx]'
  end
end
