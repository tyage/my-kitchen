node.reverse_merge!(
  docker: {
    users: ['tyage']
  },
  letsencrypt: {
    certbot_auto_path: '/usr/bin/certbot-auto',
    email: 'namatyage@gmail.com',
    cron_configuration: false,
    challenge_type: 'http-01',
    domains: ['mocos.kitchen'],
    authenticator: 'standalone',
    debug_mode: false
  },
  letsencrypt_renew: {
    certbot_auto_path: '/usr/bin/certbot-auto',
    post_hook: '/usr/sbin/service nginx reload'
  }
)

include_cookbook 'basic'

#include_cookbook 'docker'
#include_cookbook 'l2tp_ipsec_vpn_server'

include_recipe 'letsencrypt::get'
