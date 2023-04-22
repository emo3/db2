#
# Cookbook:: db2
# Recipe:: createdb
#
# Copyright:: 2019, Ed Overton, Apache 2.0

db2bin_dir = "#{node['db2']['db2_install_dir']}/bin"

package %w(whois)

directory node['db2']['db2user1-home'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

group node['db2']['db2user1-group'] do
  action :create
end

user node['db2']['db2user1-user'] do
  group node['db2']['db2user1-group']
  home node['db2']['db2user1-home']
  action :create
end

directory node['db2']['db2user1-home'] do
  owner node['db2']['db2user1-user']
  group node['db2']['db2user1-group']
  mode '0755'
  action :create
end

template "#{node['db2']['db2inst1-home']}/.bashrc" do
  source 'db2-bashrc.erb'
  variables(
    install_dir: node['db2']['db2_install_dir']
  )
  owner node['db2']['db2inst1-user']
  group node['db2']['db2user1-group']
  mode '0644'
end

template "#{node['db2']['db2inst1-home']}/.bash_profile" do
  source 'db2-bashrc.erb'
  variables(
    install_dir: node['db2']['db2_install_dir']
  )
  owner node['db2']['db2inst1-user']
  group node['db2']['db2user1-group']
  mode '0644'
end

node['db2']['db2-db-list'].each do |db|
  execute 'create-db' do
    command "su - #{node['db2']['db2inst1-user']} -c \" \
    #{db2bin_dir}/db2 create database #{db} automatic storage yes using codeset #{node['db2']['db2-codeset']} territory #{node['db2']['db2-territory']} pagesize #{node['db2']['db2-pagesize']}; \
    #{db2bin_dir}/db2 connect to #{db}; \
    #{db2bin_dir}/db2 grant dbadm on database to user #{node['db2']['db2user1-user']}; \
    #{db2bin_dir}/db2 UPDATE DB CFG FOR #{db} USING LOGFILSIZ #{node['db2']['db2-logsize']} DEFERRED; \
    #{db2bin_dir}/db2 UPDATE DB CFG FOR #{db} USING LOGSECOND #{node['db2']['db2-logsecond']} DEFERRED; \
    #{db2bin_dir}/db2 connect reset;\""
    cwd db2bin_dir
    # change to run if you want the three default databases created
    action :run
  end
end
