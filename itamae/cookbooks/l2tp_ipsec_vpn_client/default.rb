node.reverse_merge!(
  l2tp_ipsec_vpn_client: {
    server: '13.113.59.63',
    ipsec_psk: node[:secrets][:l2tp_ipsec_vpn_ipsec_psk],
    user: node[:secrets][:l2tp_ipsec_vpn_user],
    password: node[:secrets][:l2tp_ipsec_vpn_password]
  }
)

include_recipe 'docker::install'

execute 'docker pull ubergarm/l2tp-ipsec-vpn-client' do
  not_if "docker images ubergarm/l2tp-ipsec-vpn-client | grep -qi 'l2tp-ipsec-vpn-client'"
end

directory '/usr/local/l2tp-ipsec-vpn-client' do
end

template '/usr/local/l2tp-ipsec-vpn-client/vpn.env' do
  action :create
  mode '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[docker restart l2tp-ipsec-vpn-client]', :immediately
end

execute 'docker restart l2tp-ipsec-vpn-client' do
  action :nothing
  command <<-"EOS"
    docker stop l2tp-ipsec-vpn-client &&
    docker rm l2tp-ipsec-vpn-client &&
    docker run \
      --name l2tp-ipsec-vpn-client \
      --env-file /usr/local/l2tp-ipsec-vpn-client/vpn.env \
      --restart=always \
      -v /lib/modules:/lib/modules:ro \
      -d --privileged \
      ubergarm/l2tp-ipsec-vpn-client
  EOS
  only_if "docker container list | grep -qi 'l2tp-ipsec-vpn-client'"
end

execute 'docker run l2tp-ipsec-vpn-client' do
  command <<-"EOS"
    docker run \
      --name l2tp-ipsec-vpn-client \
      --env-file /usr/local/l2tp-ipsec-vpn-client/vpn.env \
      --restart=always \
      -v /lib/modules:/lib/modules:ro \
      -d --privileged \
      ubergarm/l2tp-ipsec-vpn-client
  EOS
  only_if "docker container list | grep -qi 'l2tp-ipsec-vpn-client'"
end
