node.reverse_merge!(
  command_line: {
    username: 'tyage'
  }
)

username = node[:command_line][:username]
home_dir = "/home/#{username}"

packages = %w(vim zsh git tig less curl wget w3m p7zip-full libreadline-dev zsh)
packages.each do |package|
  package package do
    action :install
  end
end

user username do
  home home_dir
end

execute "chsh to zsh" do
  command "chsh -s `which zsh` #{username}"
end

# install ruby
packages = %w(build-essential libssl-dev ruby rbenv)
packages.each do |package|
  package package do
    action :install
  end
end

ruby_build_path = "#{home_dir}/.rbenv/plugins/ruby-build"
git ruby_build_path do
  user username
  repository 'https://github.com/sstephenson/ruby-build'
end

ruby_version = '2.3.0'
execute "install ruby #{ruby_version}" do
  user username
  command <<-"EOS"
    rbenv install #{ruby_version}
    rbenv global #{ruby_version}
  EOS
  not_if "rbenv versions | grep #{ruby_version}"
end

# install peco
package 'golang' do
  action :install
end

execute 'install peco' do
  user username
  command <<-'EOS'
    go get github.com/peco/peco/cmd/peco
  EOS
  not_if 'which peco'
end

# install dotfiles
execute 'homesick' do
  user username
  command <<-'EOS'
    gem install homesick
    rbenv rehash
    homesick clone tyage/dotfiles
    homesick symlink
  EOS
end
