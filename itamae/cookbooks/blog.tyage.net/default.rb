node.reverse_merge!(
  blog_tyage_net: {
    db_name: 'wordpress',
    db_user: 'wordpress'
  }
)

packages = %w(php php-fpm mysql-server)
packages.each do |package|
  package package do
    action :install
  end
end

remote_file "/etc/nginx/sites-enabled/blog.tyage.net" do
  source 'files/nginx/blog.tyage.net'
  owner 'root'
  group 'root'
  mode '644'
  notifies :reload, 'service[nginx]'
end

git '/var/www/blog.tyage.net/public_html' do
  user 'www-data'
  repository 'https://github.com/WordPress/WordPress.git'
end

# setup database
db_name = node['blog_tyage_net']['db_name']
db_user = node['blog_tyage_net']['db_user']
db_password = node['blog_tyage_net']['db_password']

execute 'create database' do
  sql = "CREATE DATABASE IF NOT EXISTS #{db_name} character set utf8"
  user 'root'
  command "mysql -u root -e #{Shellwords.escape(sql)}"
  not_if "mysql -u root -e \"show databases\" | grep #{db_name}"
end
execute 'create user' do
  sql = <<-"EOS"
CREATE USER '#{db_user}'@'localhost' IDENTIFIED BY '#{db_password}';
GRANT ALL ON `#{db_name}`.* TO '#{db_user}'@'localhost';
EOS
  user 'root'
  command "mysql -u root -e #{Shellwords.escape(sql)}"
  not_if "mysql -u root -e \"select user from mysql.user\" | grep #{db_user}"
end
