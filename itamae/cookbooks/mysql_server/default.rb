package 'mysql-server'

service 'mysql' do
    action [:start, :enable]
end

execute 'initialize mysql' do
  user 'root'
  command "mysqladmin -u root password #{Shellwords.escape(node[:mysql_server][:root_password])}"
  only_if 'mysql -u root -e "show databases" | grep information_schema'
end
