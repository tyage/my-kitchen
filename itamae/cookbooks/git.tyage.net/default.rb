include_cookbook 'nginx'

# install gitlab
packages = %w(curl openssh-server ca-certificates postfix)
packages.each do |package|
  package package do
    action :install
  end
end

execute 'install gitlab' do
  user 'root'
  command <<-'EOS'
    curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
  EOS
end

package 'gitlab-ce' do
  action :install
end

execute 'reconfigure gitlab' do
  user 'root'
  command <<-'EOS'
    gitlab-ctl reconfigure
  EOS
end

# create a nginx config file
# TODO
