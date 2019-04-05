node.reverse_merge!(
  command_line: {
    username: 'tyage',
    ruby_version: '2.6.2'
  }
)

username = node[:command_line][:username]

case node[:platform]
when 'debian', 'ubuntu'
  home_dir = "/home/#{username}"

  # create user dir
  user username do
    home home_dir
  end

  packages = %w(vim zsh git tig less curl wget ruby p7zip-full libreadline-dev htop software-properties-common peco golang-go zlib1g zlib1g-dev)
  packages.each do |pkg|
    package pkg do
      user 'root'
      action :install
    end
  end

  # install neovim
  if node[:platform] == 'ubuntu'
    execute 'add neovim repositry' do
      user 'root'
      command 'add-apt-repository -y ppa:neovim-ppa/stable'
      not_if 'test -e /etc/apt/sources.list.d/neovim-ppa-ubuntu-stable-*.list'
      notifies :run, 'execute[apt-get update]', :immediately
    end
    package 'neovim' do
      user 'root'
      action :install
    end
  end

  # install rbenv and ruby-build
  packages = %w(build-essential libssl-dev ruby rbenv)
  packages.each do |pkg|
    package pkg do
      user 'root'
      action :install
    end
  end

  ruby_build_path = "#{home_dir}/.rbenv/plugins/ruby-build"
  git ruby_build_path do
    user username
    repository 'https://github.com/rbenv/ruby-build'
  end

  # install ghq
  execute 'install ghq' do
    user username
    command "GOPATH=#{home_dir}/.gopath go get github.com/motemen/ghq"
    not_if 'test -e .gopath/bin/ghq'
  end
when 'darwin'
  home_dir = "/Users/#{username}"

  execute 'install homebrew' do
    user username
    command 'echo | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
    not_if 'which brew'
  end

  packages = %w(git tig p7zip node wget peco zsh neovim/neovim/neovim rbenv ruby-build ghq htop python3)
  packages.each do |pkg|
    package pkg do
      user username
      action :install
      only_if "brew info #{pkg} | grep -qi 'Not Installed'"
    end
  end

  execute 'install neovim with pip3' do
    user username
    command 'pip3 install neovim'
    not_if 'pip3 show neovim'
  end
else
  abort "#{node[:platform]} is not supported"
end

# change to zsh
execute 'append zsh to /etc/shells' do
  user 'root'
  command 'echo `which zsh` >> /etc/shells'
  not_if 'cat /etc/shells | grep `which zsh`'
end

execute "chsh to zsh" do
  user 'root'
  command "chsh -s `which zsh` #{username}"
  not_if "cat /etc/passwd | grep #{username} | grep -qi 'zsh'"
end

# install ruby with rbenv
execute "install ruby #{node[:command_line][:ruby_version]}" do
  user username
  command <<-"EOS"
    rbenv install #{node[:command_line][:ruby_version]}
    rbenv global #{node[:command_line][:ruby_version]}
  EOS
  not_if "rbenv versions | grep #{node[:command_line][:ruby_version]}"
end

# install dotfiles by using rbenv
execute 'homesick' do
  user username
  command <<-"EOS"
    export PATH=#{home_dir}/.rbenv/shims/:$PATH
    gem install homesick
    rbenv rehash
    homesick clone tyage/dotfiles
    yes n | homesick symlink
  EOS
  not_if "test -d #{home_dir}/.homesick"
end
