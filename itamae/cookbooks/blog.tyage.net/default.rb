remote_template_directory '/etc/nginx/sites-enabled' do
  owner  'root'
  group  'root'
  source 'directories/etc/nginx/sites-enabled'
  notifies :reload, 'service[nginx]'
end

