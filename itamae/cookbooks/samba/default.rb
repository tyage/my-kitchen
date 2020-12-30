node.reverse_merge!(
  samba: {
    path: '/mnt/share',
    user: 'tyage',
  }
)

package 'samba'

directory node[:samba][:path] do
  owner  'user'
  owner  'root'
  group  'root'
  mode   '0777'
  not_if "test -d #{node[:samba][:path]}"
end

template "/etc/samba/smb.conf" do
  owner  'root'
  group  'root'
  mode   '644'
  notifies :reload, 'service[smbd]'
end

service 'smbd' do
  action [:enable, :start]
end