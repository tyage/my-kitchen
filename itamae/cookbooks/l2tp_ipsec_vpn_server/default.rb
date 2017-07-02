node.reverse_merge!(
  l2tp_ipsec_vpn_server: {
    ipsec_psk: node[:secrets][:l2tp_ipsec_vpn_ipsec_psk],
    user: node[:secrets][:l2tp_ipsec_vpn_user],
    password: node[:secrets][:l2tp_ipsec_vpn_password]
  }
)

include_recipe 'docker::install'

execute 'docker pull hwdsl2/ipsec-vpn-server' do
  not_if "docker images hwdsl2/ipsec-vpn-server | grep -qi 'ipsec-vpn-server'"
end

directory '/usr/local/ipsec-vpn-server' do
  user 'root'
  mode '755'
  owner 'root'
  group 'root'
end

template '/usr/local/ipsec-vpn-server/vpn.env' do
  action :create
  user 'root'
  mode '0600'
  owner 'root'
  group 'root'
  notifies :run, 'execute[docker restart ipsec-vpn-server]', :immediately
end

execute 'docker restart ipsec-vpn-server' do
  action :nothing
  command <<-"EOS"
    docker stop ipsec-vpn-server &&
    docker rm ipsec-vpn-server &&
    docker run \
      --name ipsec-vpn-server \
      --env-file /usr/local/ipsec-vpn-server/vpn.env \
      --restart=always \
      -p 500:500/udp \
      -p 4500:4500/udp \
      -v /lib/modules:/lib/modules:ro \
      -d --privileged \
      hwdsl2/ipsec-vpn-server
  EOS
  only_if "docker container list | grep -qi 'ipsec-vpn-server'"
end

execute 'docker run ipsec-vpn-server' do
  command <<-"EOS"
    modprobe af_key &&
    docker run \
      --name ipsec-vpn-server \
      --env-file /usr/local/ipsec-vpn-server/vpn.env \
      --restart=always \
      -p 500:500/udp \
      -p 4500:4500/udp \
      -v /lib/modules:/lib/modules:ro \
      -d --privileged \
      hwdsl2/ipsec-vpn-server
  EOS
  not_if "docker container list | grep -qi 'ipsec-vpn-server'"
end
