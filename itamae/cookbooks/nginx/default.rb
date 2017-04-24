node.reverse_merge!(
  nginx: {
    letsencrypt_dir: '/var/www/letsencrypt'
  }
)

include_recipe 'apt_source.rb'

packages = %w(nginx-common nginx)
packages.each do |package|
  package package do
    action :install
  end
end

service 'nginx' do
  action [:enable, :start]
end

letsencrypt_dir = node[:nginx][:letsencrypt_dir]
execute "mkdir -p #{letsencrypt_dir}" do
  command "mkdir -p #{letsencrypt_dir}"
  not_if "test -d #{letsencrypt_dir}"
end
template '/etc/nginx/letsencrypt.conf' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies :reload, 'service[nginx]'
end
