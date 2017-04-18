certbot_auto_path = '/usr/bin/certbot-auto'

node.reverse_merge!(
  docker: {
    users: ['tyage']
  },
  letsencrypt: {
    certbot_auto_path: certbot_auto_path,
    email: 'namatyage@gmail.com',
    cron_configuration: false,
    challenge_type: 'http-01',
    domains: ['mocos.kitchen'],
    authenticator: 'standalone',
    debug_mode: false,
    pre_hook: '/usr/sbin/service nginx stop',
    post_hook: '/usr/sbin/service nginx start'
  },
  letsencrypt_renew: {
    certbot_auto_path: certbot_auto_path,
    authenticator: 'webroot',
    webroot_path: '/tmp/letsencrypt-auto',
    post_hook: '/usr/sbin/service nginx reload'
  }
)

include_cookbook 'basic'

include_cookbook 'nginx'
#include_cookbook 'docker'
#include_cookbook 'l2tp_ipsec_vpn_server'

include_recipe 'letsencrypt::get'
include_cookbook 'letsencrypt_renew'
#include_cookbook 'mocos.kitchen'
