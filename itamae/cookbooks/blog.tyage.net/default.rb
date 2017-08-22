node.reverse_merge!(
  blog_tyage_net: {
    db_name: 'wordpress',
    db_user: 'wordpress'
  }
)

packages = %w(php php-fpm php-mysql mysql-server)
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

blog_dir = '/var/www/blog.tyage.net'
execute 'download and extract wordpress' do
  user 'root'
  cwd blog_dir
  command <<-'EOS'
    wget "https://ja.wordpress.org/latest-ja.zip" &&
    unzip latest-ja.zip &&
    mv wordpress public_html &&
    rm latest-ja.zip &&
    chown -R www-data:www-data ./
EOS
  not_if "test -d #{blog_dir}/public_html"
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

# deploy wp-config
keys = []
open ("https://api.wordpress.org/secret-key/1.1/salt/") {|io|
  keys << io.read
}
config_file = '/var/www/blog.tyage.net/public_html/wp-config.php'
template config_file do
  action :create
  mode '644'
  owner 'root'
  group 'root'
  variables ({
    db_name: db_name,
    db_user: db_user,
    db_password: db_password,
    secret_keys: keys.join('\n')
  })
  source 'templates/wp-config.php'
  not_if "test -e #{config_file}"
end
