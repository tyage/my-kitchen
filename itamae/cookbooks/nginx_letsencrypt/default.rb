node.reverse_merge!(
  nginx_letsencrypt: {
    letsencrypt_dir: '/var/www/letsencrypt'
  }
)

letsencrypt_dir = node[:nginx_letsencrypt][:letsencrypt_dir]
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
