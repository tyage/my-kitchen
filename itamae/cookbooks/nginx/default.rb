include_recipe 'apt_source.rb'

packages = %w(nginx-common nginx)
packages.each do |package|
  package package do
    action :install
  end
end

service 'nginx' do
  action [:enable, :start]
end
