package 'mysql-server'

service 'mysql' do
  action [:start, :enable]
end

execute 'initialize mysql' do
  user 'root'
  command "mysqladmin -u root password #{Shellwords.escape(node[:mysql_server][:root_password])}"
  not_if 'mysql -u root -e "select authentication_string from mysql.user where user = \'root\'" | grep -v authentication_string'
end
