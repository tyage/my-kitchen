node.reverse_merge!(
  chinachu: {
    operTweeterAuth: {},
    src_path: '/usr/local/src/docker-mirakurun-chinachu'
  }
)

user = node[:chinachu][:user]
src_path = node[:chinachu][:src_path]

include_recipe "docker::install"

package 'docker-compose' do
  user 'root'
  action :install
end

git src_path do
  user 'root'
  repository 'https://github.com/Chinachu/docker-mirakurun-chinachu.git'
end

docker_file = "#{src_path}/docker-compose.yml"
remote_file docker_file do
  source 'files/docker-compose.yml'
  owner 'root'
  group 'root'
  mode '0644'
end
docker_file = "#{src_path}/chinachu/Dockerfile"
remote_file docker_file do
  source 'files/Dockerfile'
  owner 'root'
  group 'root'
  mode '0644'
end
service_file = "#{src_path}/chinachu/services.sh"
remote_file service_file do
  source 'files/services.sh'
  owner 'root'
  group 'root'
  mode '0755'
end

# send config and rule files
config_file = "#{src_path}/chinachu/conf/config.json"
template config_file do
  source 'templates/config.json'
  owner 'root'
  group 'root'
  mode '0666'
  not_if "test -s #{config_file}"
end

rules_file = "#{src_path}/chinachu/conf/rules.json"
remote_file rules_file do
  source 'files/rules.json'
  owner 'root'
  group 'root'
  mode '0666'
  not_if "test -s #{rules_file}"
end

# make data directory writable
directory "#{src_path}/chinachu/data" do
  owner 'root'
  group 'root'
  mode '0777'
end

execute 'build chinachu' do
user 'root'
  cwd src_path
  command 'docker-compose build'
  not_if "docker images | grep -qi chinachu"
end

# disable pcscd because it is managed in mirakurun container
service 'pcscd.socket' do
  action :stop
end
service 'pcscd.socket' do
  action :disable
end

# register service
service_files = %w(mirakurun.service chinachu.service)
service_files.each do |file|
  distination = "/etc/systemd/system/#{file}"
  template distination do
    source "templates/#{file}"
    owner 'root'
    group 'root'
    notifies :restart, "service[#{file}]"
  end
  service file do
    action [:enable, :start]
  end
end
