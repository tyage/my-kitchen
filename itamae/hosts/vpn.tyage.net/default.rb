node.reverse_merge!(
  docker: {
    users: ['ubuntu']
  },
  command_line: {
    username: 'ubuntu'
  },
  l2tp_ipsec_vpn_client: {
    local_user: 'ubuntu',
    server: 'localhost',
    install_directory: '/home/ubuntu/.vpnclient',
  }
)

include_cookbook 'command_line'
include_cookbook 'mackerel_agent'

include_cookbook 'l2tp_ipsec_vpn_client'
include_cookbook 'l2tp_ipsec_vpn_server'

include_cookbook 'nginx'
include_cookbook 'rec.vpn.tyage.net'
