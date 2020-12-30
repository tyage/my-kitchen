execute "import tailscale GPG key" do
  command <<-"EOS"
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
apt update
EOS
  not_if "test -e /etc/apt/sources.list.d/tailscale.list"
end

package 'tailscale'