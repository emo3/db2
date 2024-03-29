#
# Cookbook:: db2
# Recipe:: default
#
# Copyright:: 2019, Ed Overton, Apache 2.0

db2binary_dir = "#{Chef::Config[:file_cache_path]}/DB2binaries"
binaries = [node['db2']['package-name-1']]

package node['db2']['ubuntu'] if platform_family?('debian')
package node['db2']['rhel']   if platform_family?('rhel')

directory db2binary_dir do
  mode '0755'
  not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  action :create
end

binaries.each do |package_name|
  # Chef::Log.info('copying packages')
  execute 'copy-db2' do
    action :run
    command "scp #{node['db2']['ftploginuser']}@#{node['db2']['binaryhost']}:#{node['db2']['ftppath']}/#{package_name} #{db2binary_dir}"
    cwd db2binary_dir
    only_if { node['db2']['remote_mode'] == 'ftp' }
    not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  end

  # Download file via http
  remote_file "#{db2binary_dir}/#{package_name}" do
    source "#{node['db2']['binaryhost']}/#{node['db2']['ftppath']}/#{package_name}"
    mode '0755'
    only_if { node['db2']['remote_mode'] == 'http' }
    not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
    backup false
    action :create
  end

  execute 'extract-db2' do
    action :run
    command "unzip -q #{package_name}"
    cwd db2binary_dir
    not_if { ::File.exist?("#{db2binary_dir}/db2setup") }
    not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  end
end

template "#{db2binary_dir}/#{node['db2']['db2-responsefile']}" do
  source 'db2server.erb'
  variables(
    file: node['db2']['db2_install_dir'],
    install_type: node['db2']['install_type']
  )
  mode '0644'
  not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
end

execute 'install-db2' do
  command "#{db2binary_dir}/db2setup -r #{db2binary_dir}/#{node['db2']['db2-responsefile']}"
  cwd db2binary_dir
  not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  action :run
end

directory db2binary_dir do
  action :delete
  recursive true
end
