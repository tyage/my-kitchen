node.reverse_merge!(
  epgstation: {
    src_path: '/usr/local/src/epgstation'
  }
)

user = node[:epgstation][:user]
src_path = node[:epgstation][:src_path]

include_recipe "docker::install"

package 'docker-compose' do
  user 'root'
  action :install
end

git src_path do
  user 'root'
  repository 'https://github.com/l3tnun/docker-mirakurun-epgstation.git'
end

# setup https://github.com/l3tnun/docker-mirakurun-epgstation/blob/v2/setup.sh
docker_file = "#{src_path}/docker-compose.yml"
remote_file docker_file do
  source 'files/docker-compose.yml'
  owner 'root'
  group 'root'
  mode '0644'
end

# config files
config_files = {
  'enc.js' => 'epgstation/config/enc.js',
  'config.yml' => 'epgstation/config/config.yml',
  'operatorLogConfig.yml' => 'epgstation/config/operatorLogConfig.yml',
  'epgUpdaterLogConfig.yml' => 'epgstation/config/epgUpdaterLogConfig.yml',
  'serviceLogConfig.yml' => 'epgstation/config/serviceLogConfig.yml'
}
config_files.each do |src, dest|
  source_path = "files/#{src}"
  remote_path = "#{src_path}/#{dest}"
  remote_file remote_path do
    source source_path
    owner 'root'
    group 'root'
    mode '0644'
  end
end

# create a directory to save recorded files
directory '/videos/recorded' do
  user 'root'
  owner 'root'
  group 'root'
  mode '0777'
end

# disable pcscd because it is managed in mirakurun container
service 'pcscd.socket' do
  action :stop
end
service 'pcscd.socket' do
  action :disable
end

# register service
template '/etc/systemd/system/epgstation.service' do
  source 'templates/epgstation.service'
  owner 'root'
  group 'root'
  notifies :restart, 'service[epgstation.service]'
end
service 'epgstation.service' do
  action [:enable, :start]
end
