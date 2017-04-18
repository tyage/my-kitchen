node.reverse_merge!(
  docker: {
    users: ['tyage']
  },
  letsencrypt: {
    certbot_auto_path: '/usr/bin/certbot-auto',
    email: 'namatyage@gmail.com',
    cron_configuration: false,
    challenge_type: 'http-01',
    domains: ['tyage.net', 'www.tyage.net', 'blog.tyage.net', 'irc.tyage.net'],
    authenticator: 'standalone',
    debug_mode: false
  }
)

include_cookbook 'basic'

include_cookbook 'nginx'
include_cookbook 'blog.tyage.net'
include_cookbook 'irc.tyage.net'

include_recipe 'letsencrypt::get'
