certbot_auto_path = '/usr/bin/certbot-auto'

letsencrypt_dir = '/var/www/letsencrypt'
node.reverse_merge!(
  iptables: {
    iptables_rules: <<-'EOS'
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [4009:619411]
:f2b-sshd - [0:0]
-A INPUT -p tcp -m multiport --dports 22 -j f2b-sshd
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m comment --comment "accept http" -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m comment --comment "accept https" -m tcp --dport 443 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
-A f2b-sshd -j RETURN
COMMIT
EOS
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
  nginx_letsencrypt: {
    letsencrypt_dir: letsencrypt_dir
  }
)

include_cookbook 'basic'
include_cookbook 'command_line'
include_cookbook 'locale'

include_cookbook 'iptables'
include_cookbook 'nginx'
include_cookbook 'nginx_letsencrypt'
include_recipe 'letsencrypt::get'
include_cookbook 'letsencrypt_renew'
include_cookbook 'mocos.kitchen'
