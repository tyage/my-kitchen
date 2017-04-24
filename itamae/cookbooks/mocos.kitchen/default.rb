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
