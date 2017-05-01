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

  packages = %w(vim zsh git tig less curl wget w3m p7zip-full libreadline-dev)
  packages.each do |pkg|
    package pkg do
      action :install
    end
  end

  # install rbenv, ruby-build
  packages = %w(build-essential libssl-dev ruby rbenv)
  packages.each do |pkg|
    package pkg do
      action :install
    end
  end

  ruby_build_path = "#{home_dir}/.rbenv/plugins/ruby-build"
  git ruby_build_path do
    user username
    repository 'https://github.com/sstephenson/ruby-build'
  end

  # install peco
  package 'golang' do
    action :install
  end

  execute 'install peco' do
    user username
    command 'go get github.com/peco/peco/cmd/peco'
    not_if 'which peco'
  end

  user username do
    home home_dir
  end
when 'darwin'
  home_dir = "/Users/#{username}"

  execute 'install homebrew' do
    user username
    command '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
    not_if 'which brew'
  end

  packages = %w(git tig p7zip node wget peco zsh neovim/neovim/neovim rbenv ruby-build)
  packages.each do |pkg|
    package pkg do
      action :install
    end
  end
else
  abort "#{node[:platform]} is not supported"
end

execute "chsh to zsh" do
  command "chsh -s `which zsh` #{username}"
  not_if "echo $ZSH_NAME"
end

execute "install ruby #{node[:command_line][:ruby_version]}" do
  user username
  command <<-"EOS"
    rbenv install #{node[:command_line][:ruby_version]}
    rbenv global #{node[:command_line][:ruby_version]}
  EOS
  not_if "rbenv versions | grep #{node[:command_line][:ruby_version]}"
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
  not_if "test -d #{home_dir}/.homesick"
end
