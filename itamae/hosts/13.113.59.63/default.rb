node.reverse_merge!(
  docker: {
    users: ['ubuntu']
  },
  command_line: {
    username: 'ubuntu'
  }
)

include_cookbook 'command_line'
include_cookbook 'mackerel_agent'

include_cookbook 'l2tp_ipsec_vpn_server'
