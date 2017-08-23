remote_template_directory '/etc/nginx/sites-enabled' do
  owner  'root'
  group  'root'
  source 'directories/etc/nginx/sites-enabled'
  notifies :reload, 'service[nginx]'
end

# this is for www.tyage.net
# TODO: create cookbook for below recipe
%w(nodejs npm).each do |p|
  package p
end
case node[:platform]
when 'debian', 'ubuntu'
  package 'nodejs-legacy'
end

src_dir = '/var/www/tyage.net'
git src_dir do
  user 'www-data'
  repository 'https://github.com/tyage/tyage.net'
  notifies :run, 'execute[build tyage.net]'
end

execute 'build tyage.net' do
  cwd src_dir
  command <<-'EOS'
npm install
npm run build
EOS
  action :nothing
end
