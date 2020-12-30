net = IO.read(Pathname.pwd + "itamae/data_bags/network.json")
net = JSON.parse(net)

node.reverse_merge!(
  network: net,
  chinachu: {
    operTweeterAuth: {
      consumerKey: node[:secrets][:yukari_chinachu_tweeter_consumer_key],
      consumerSecret: node[:secrets][:yukari_chinachu_tweeter_consumer_secret],
      accessToken: node[:secrets][:yukari_chinachu_tweeter_access_token],
      accessTokenSecret: node[:secrets][:yukari_chinachu_tweeter_access_token_secret]
    }
  }
)

include_cookbook 'command_line'
include_cookbook 'tailscale'
include_cookbook 'samba'
include_role 'record'
