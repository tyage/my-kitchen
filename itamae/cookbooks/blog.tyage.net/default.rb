packages = %w(php5 php5-fpm mysql)
packages.each do |package|
  package package do
    action :install
  end
end

remote_file "/etc/nginx/sites-enabled/blog.tyage.net" do
  source "files/nginx/blog.tyage.net"
  owner  'root'
  group  'root'
  mode   '644'
  notifies :reload, 'service[nginx]'
end
