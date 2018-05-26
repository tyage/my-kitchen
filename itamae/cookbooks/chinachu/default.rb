node.reverse_merge!(
  chinachu: {
    operTweeterAuth: {},
    src_path: '/usr/local/src/docker-mirakurun-chinachu'
  }
)

user = node[:chinachu][:user]
src_path = node[:chinachu][:src_path]

include_recipe "docker::install"

git src_path do
  user 'root'
  repository 'https://github.com/Chinachu/docker-mirakurun-chinachu.git'
end

config_file = "#{src_path}/chinachu/conf/config.json"
template config_file do
  source 'templates/config.json'
  user 'root'
  owner 'root'
  group 'root'
  mode '0644'
  not_if "test -s #{config_file}"
end

docker_file = "#{src_path}/docker-compose.yml"
remote_file docker_file do
  source 'files/docker-compose.yml'
  user 'root'
  owner 'root'
  group 'root'
end

rules_file = "#{src_path}/chinachu/conf/rules.json"
remote_file rules_file do
  source 'files/rules.json'
  user 'root'
  owner 'root'
  group 'root'
  mode '0644'
  not_if "test -s #{rules_file}"
end

service_files = %w(mirakurun.service chinachu.service)
service_files.each do |file|
  distination = "/etc/systemd/system/#{file}"
  template distination do
    source "templates/#{file}"
    user 'root'
    owner 'root'
    group 'root'
    notifies :reload, "service[#{file}]"
  end
  service file do
    action :enable
  end
  service file do
    action :start
  end
end
