packages = %w(nginx-common nginx)
packages.each do |package|
  package package do
    action :install
  end
end

service 'nginx' do
  action [:enable, :start]
end

execute 'create dhparam.pem' do
  command 'touch /etc/nginx/dhparam.pem && chown www-data:root /etc/nginx/dhparam.pem && chmod 660 /etc/nginx/dhparam.pem && openssl dhparam -out /etc/nginx/dhparam.pem 2048 && chmod 440 /etc/nginx/dhparam.pem'
  not_if 'test -e /etc/nginx/dhparam.pem'
end

execute 'chown -R www-data:www-data /var/www' do
  user 'root'
  not_if 'test "`stat -c "%U:%G" /var/www`" = "www-data:www-data"'
end
