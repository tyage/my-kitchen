node.reverse_merge!(
  chinachu: {
    operTweeterAuth: {}
  }
)

%w(build-essential curl git-core libssl-dev yasm libtool autoconf).each do |p|
  package p
end

chinachu_home_path = '/home/chinachu'
chinachu_src_path = "#{chinachu_home_path}/chinachu"

user 'chinachu' do
  home chinachu_home_path
  create_home true
end

# clone
git chinachu_src_path do
  user 'chinachu'
  repository 'https://github.com/kanreisa/Chinachu'
end

config_file = "#{chinachu_src_path}/config.json"
template config_file do
  source 'templates/config.json'
  user 'chinachu'
  owner 'chinachu'
  group 'chinachu'
  not_if "test -e #{config_file}"
end

rules_file = "#{chinachu_src_path}/rules.json"
remote_file rules_file do
  source 'files/rules.json'
  user 'chinachu'
  owner 'chinachu'
  group 'chinachu'
  not_if "test -e #{rules_file}"
end

execute 'install chinachu' do
  cwd chinachu_src_path
  user 'chinachu'
  command <<-'EOS'
    echo 1 | ./chinachu installer
  EOS
  not_if "test -d #{chinachu_src_path}/node_modules"
end

execute 'set init.d of chinachu and start' do
  cwd chinachu_src_path
  user 'root'
  command <<-'EOS'
    ./chinachu service operator initscript > /tmp/chinachu-operator
    ./chinachu service wui initscript > /tmp/chinachu-wui
    chown root:root /tmp/chinachu-operator /tmp/chinachu-wui
    chmod +x /tmp/chinachu-operator /tmp/chinachu-wui
    mv /tmp/chinachu-operator /tmp/chinachu-wui /etc/init.d/

    insserv chinachu-operator
    insserv chinachu-wui

    service chinachu-operator start
    service chinachu-wui start
  EOS
  not_if "test -e /etc/init.d/chinachu-operator"
end
