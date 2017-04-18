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
    domains: ['tyage.net', 'www.tyage.net', 'blog.tyage.net', 'irc.tyage.net'],
    authenticator: 'standalone',
    debug_mode: false
  },
  letsencrypt_renew: {
    certbot_auto_path: certbot_auto_path,
    authenticator: 'webroot',
    webroot_path: '/tmp/letsencrypt-auto',
    post_hook: '/usr/sbin/service nginx reload'
  }
)

include_cookbook 'basic'

include_recipe 'letsencrypt::get'
include_cookbook 'letsencrypt_renew'

include_cookbook 'nginx'
include_cookbook 'blog.tyage.net'
include_cookbook 'irc.tyage.net'
