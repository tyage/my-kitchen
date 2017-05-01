net = IO.read(Pathname.pwd + "itamae/data_bags/network.json")
net = JSON.parse(net)

node.reverse_merge!(network: net)

include_cookbook 'command_line'
include_cookbook 'mac_apps'
