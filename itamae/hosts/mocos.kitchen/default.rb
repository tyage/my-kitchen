certbot_auto_path = '/usr/bin/certbot-auto'

letsencrypt_dir = '/var/www/letsencrypt'
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
    webroot_path: letsencrypt_dir,
    pre_hook: '',
    post_hook: '/usr/sbin/service nginx reload'
  },
  nginx: {
    letsencrypt_dir: letsencrypt_dir
  }
)

include_cookbook 'basic'
include_cookbook 'command_line'

include_cookbook 'nginx'
include_recipe 'letsencrypt::get'
include_cookbook 'letsencrypt_renew'
include_cookbook 'mocos.kitchen'
