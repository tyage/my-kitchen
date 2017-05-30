include_recipe 'docker::install'

execute 'docker pull hwdsl2/ipsec-vpn-server' do
  not_if "docker images ipsec-vpn-server | grep -qi 'ipsec-vpn-server'"
end

template '/usr/local/ipsec-vpn-server/vpn.env' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[docker restart ipsec-vpn-server]'
end

execute 'docker restart ipsec-vpn-server' do
  action :nothing
  only_if "docker container list | grep -qi 'ipsec-vpn-server'"
end

execute 'docker run ipsec-vpn-server' do
  command <<-"EOS"
    modprobe af_key &&
    docker run \
      --rm \
      --name ipsec-vpn-server \
      --env-file ./vpn.env \
      --restart=always \
      -p 500:500/udp \
      -p 4500:4500/udp \
      -v /lib/modules:/lib/modules:ro \
      -d --privileged \
      hwdsl2/ipsec-vpn-server
  EOS
  not_if "docker container list | grep -qi 'ipsec-vpn-server'"
end
