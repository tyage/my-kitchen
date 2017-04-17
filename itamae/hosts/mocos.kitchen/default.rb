node.reverse_merge!(
  docker: {
    users: ['tyage']
  },
  letsencrypt: {
    certbot_auto_path: '/usr/bin/certbot-auto',
    email: 'namatyage@gmail.com',
    cron_user: 'root',
    cron_file_path: '/etc/cron.d/itamae-letsencrypt',
    cron_configuration: true,
    challenge_type: 'http-01',
    domains: ['mocos.kitchen'],
    authenticator: 'webroot',
    webroot_path: '/tmp/letsencrypt-auto',
    debug_mode: false
  }
)

include_cookbook 'basic'

#include_cookbook 'docker'
#include_cookbook 'l2tp_ipsec_vpn_server'

include_recipe 'letsencrypt::get'
