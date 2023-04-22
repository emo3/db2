#
# Cookbook:: db2
# Recipe:: default
#
# Copyright:: 2019, Ed Overton, Apache 2.0

db2binary_dir = "#{Chef::Config[:file_cache_path]}/DB2binaries"
binaries = 'ibm_ds4120_lin.tar.gz'

directory db2binary_dir do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Download file via http
remote_file "#{db2binary_dir}/#{binaries}" do
  source "#{node['db2']['binaryhost']}/#{node['db2']['ftppath']}/#{binaries}"
  mode '0755'
  backup false
  action :create
end
