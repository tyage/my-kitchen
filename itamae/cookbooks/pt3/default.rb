%w(pcscd libpcsclite-dev libccid pcsc-tools make gcc unzip pkg-config autoconf).each do |p|
  package p
end

# pt3 driver
pt3_src_path = '/usr/local/src/pt3'

git pt3_src_path do
  repository 'https://github.com/m-tsudo/pt3'
end

# uname -r should be remote
package "linux-headers-#{node['os_version']}" do
  action :install
end

execute 'install pt3 driver' do
  cwd pt3_src_path
  user 'root'
  command <<-'EOS'
    make
    make install
  EOS
end

# recpt1
recpt1_src_path = '/usr/local/src/recpt1'

git recpt1_src_path do
  repository 'https://github.com/stz2012/recpt1'
end

execute 'install recpt1' do
  cwd recpt1_src_path
  user 'root'
  command <<-'EOS'
    cd recpt1
    ./autogen.sh
    ./configure --enable-b25
    make
    make install
  EOS
end

execute 'edit blacklist' do
  user 'root'
  command <<-'EOS'
    echo '' >> /etc/modprobe.d/blacklist.conf
    echo 'blacklist earth-pt1' >> /etc/modprobe.d/blacklist.conf
    echo "blacklist earth-pt3" >> /etc/modprobe.d/blacklist.conf
  EOS
end
