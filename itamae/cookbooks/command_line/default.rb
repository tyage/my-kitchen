node.reverse_merge!(
  command_line: {
    username: 'tyage',
    ruby_version: '2.4.1'
  }
)

username = node[:command_line][:username]

case node[:platform]
when 'debian', 'ubuntu'
  home_dir = "/home/#{username}"

  packages = %w(vim zsh git tig less curl wget w3m p7zip-full libreadline-dev zsh)
  packages.each do |pkg|
    package pkg do
      action :install
    end
  end

  user username do
    home home_dir
  end
when 'darwin'
  home_dir = "/Users/#{username}"
else
  abort "#{node[:platform]} is not supported"
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

execute "install ruby #{node[:command_line][:ruby_version]}" do
  user username
  command <<-"EOS"
    rbenv install #{node[:command_line][:ruby_version]}
    rbenv global #{node[:command_line][:ruby_version]}
  EOS
  not_if "rbenv versions | grep #{node[:command_line][:ruby_version]}"
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
