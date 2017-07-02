node.reverse_merge!(
  l2tp_ipsec_vpn_client: {
    local_user: 'tyage',
    server: '13.113.59.63',
    ipsec_psk: node[:secrets][:l2tp_ipsec_vpn_ipsec_psk],
    user: node[:secrets][:l2tp_ipsec_vpn_user],
    password: node[:secrets][:l2tp_ipsec_vpn_password]
  }
)

include_recipe 'docker::install'

local_user = node[:l2tp_ipsec_vpn_client][:local_user]
env_file_dir = "/home/#{local_user}/.l2tp-ipsec-vpn-client"
env_file = "#{env_file_dir}/vpn.env"

execute 'docker pull ubergarm/l2tp-ipsec-vpn-client' do
  user local_user
  not_if "docker images ubergarm/l2tp-ipsec-vpn-client | grep -qi 'l2tp-ipsec-vpn-client'"
end

directory env_file_dir do
  user local_user
  mode '755'
  owner local_user
  group local_user
end

template env_file do
  action :create
  source 'templates/vpn.env'
  user local_user
  mode '0600'
  owner local_user
  group local_user
  notifies :run, 'execute[docker restart l2tp-ipsec-vpn-client]', :immediately
end

execute 'docker restart l2tp-ipsec-vpn-client' do
  action :nothing
  user local_user
  command <<-"EOS"
    docker stop l2tp-ipsec-vpn-client &&
    docker rm l2tp-ipsec-vpn-client &&
    docker run \
      --net=host \
      --name l2tp-ipsec-vpn-client \
      --env-file #{env_file} \
      --restart=always \
      -v /lib/modules:/lib/modules:ro \
      -d --privileged \
      ubergarm/l2tp-ipsec-vpn-client
  EOS
  only_if "docker container list | grep -qi 'l2tp-ipsec-vpn-client'"
end

execute 'docker run l2tp-ipsec-vpn-client' do
  user local_user
  command <<-"EOS"
    docker run \
      --net=host \
      --name l2tp-ipsec-vpn-client \
      --env-file #{env_file} \
      --restart=always \
      -v /lib/modules:/lib/modules:ro \
      -d --privileged \
      ubergarm/l2tp-ipsec-vpn-client
  EOS
  not_if "docker container list | grep -qi 'l2tp-ipsec-vpn-client'"
end
