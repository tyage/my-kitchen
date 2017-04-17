%w(build-essential curl git-core libssl-dev yasm libtool autoconf).each do |p|
  package p
end

# clone
chinachu_src_path = '/home/chinachu/chinachu'

user 'chinachu' do
  home '/home/chinachu'
  create_home true
end

git chinachu_src_path do
  user 'chinachu'
  repository 'https://github.com/kanreisa/Chinachu'
end

remote_file "#{chinachu_src_path}/config.json" do
  source 'files/config.json'
end

remote_file "#{chinachu_src_path}/rules.json" do
  source 'files/rules.json'
end

execute 'install chinachu' do
  cwd chinachu_src_path
  user 'chinachu'
  command <<-'EOS'
    echo 1 | ./chinachu installer
    ./chinachu service operator initscript > /tmp/chinachu-operator
    ./chinachu service wui initscript > /tmp/chinachu-wui
  EOS
end

execute 'set init.d of chinachu and start' do
  cwd '/tmp'
  user 'root'
  command <<-'EOS'
    chown root:root /tmp/chinachu-operator /tmp/chinachu-wui
    chmod +x /tmp/chinachu-operator /tmp/chinachu-wui
    mv /tmp/chinachu-operator /tmp/chinachu-wui /etc/init.d/

    insserv chinachu-operator
    insserv chinachu-wui

    service chinachu-operator start
    service chinachu-wui start
  EOS
end
