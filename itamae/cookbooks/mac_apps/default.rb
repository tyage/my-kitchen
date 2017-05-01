node.reverse_merge!(
  mac_apps: {
    username: 'tyage',
  }
)

cask_packages = %w(gyazo skype dropbox slack night-owl virtualbox atom tunnelblick firefox google-chrome google-japanese-ime iterm2 vmware-fusion)
cask_packages.each do |pkg|
  execute "brew cask install #{pkg}" do
    user node[:mac_apps][:username]
    command "brew cask install #{pkg}"
    only_if "brew cask info #{pkg} | grep -qi 'Not Installed'"
  end
end
