sites = %w(00default tyage.net)
sites.each do |site|
  remote_file "/etc/nginx/sites-enabled/#{site}" do
    source "files/nginx/#{site}"
    owner  'root'
    group  'root'
    mode   '644'
    notifies :reload, 'service[nginx]'
  end
end

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
