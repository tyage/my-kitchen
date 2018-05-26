node.reverse_merge!(
  chinachu: {
    user: 'tyage',
    operTweeterAuth: {},
    src_path: '/usr/local/docker-mirakurun-chinachu'
  }
)

user = node[:chinachu][:user]
src_path = node[:chinachu][:src_path]

include_recipe "docker::install"

git src_path do
  user user
  repository 'https://github.com/Chinachu/docker-mirakurun-chinachu.git'
end

config_file = "#{src_path}/chinachu/conf/config.json"
template config_file do
  source 'templates/config.json'
  user user
  owner user
  group user
  not_if "test -s #{config_file}"
end

docker_file = "#{src_path}/docker-compose.yml"
remote_file docker_file do
  source 'files/docker-compose.yml'
  user user
  owner user
  group user
  not_if "test -e #{docker_file}"
end

rules_file = "#{src_path}/chinachu/conf/rules.json"
remote_file rules_file do
  source 'files/rules.json'
  user user
  owner user
  group user
  not_if "test -e #{rules_file}"
end

service_files = %w(mirakurun.service chinachu.service)
service_files.each do |file|
  distination = "/etc/systemd/system/#{file}"
  template distination do
    source "templates/#{file}"
    user user
    owner user
    group user
    notifies :reload, "service[#{file}]"
  end
  service file do
    action :enable
  end
  service file do
    action :start
  end
end
