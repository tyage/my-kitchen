node.reverse_merge!(
  mac_apps: {
    username: 'tyage',
  }
)

taps = %w(caskroom/fonts)
taps.each do |tap|
  execute "brew tap #{tap}" do
    user node[:mac_apps][:username]
    command "brew tap #{tap}"
    not_if "brew tap | grep #{tap}"
  end
end

cask_packages = %w(gyazo skype dropbox slack night-owl virtualbox atom tunnelblick firefox google-chrome google-japanese-ime iterm2 vmware-fusion font-source-code-pro)
cask_packages.each do |pkg|
  execute "brew cask install #{pkg}" do
    user node[:mac_apps][:username]
    command "brew cask install #{pkg}"
    only_if "brew cask info #{pkg} | grep -qi 'Not Installed'"
  end
end
