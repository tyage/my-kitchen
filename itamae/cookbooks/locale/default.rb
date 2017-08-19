package 'locales'

remote_file '/etc/default/locale'

remote_file '/etc/locale.gen' do
  notifies :run, 'execute[/usr/sbin/locale-gen]'
end

execute '/usr/sbin/locale-gen' do
  action :nothing
end
