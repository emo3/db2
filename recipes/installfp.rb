#
# Cookbook:: db2
# Recipe:: installfp
#
# Copyright:: 2019, Ed Overton, Apache 2.0

db2fixpack_dir = "#{Chef::Config[:file_cache_path]}/DB2fixpack"
fpbinaries = [node['db2']['packagefp1-name-1']]
base_dir = node['db2']['db2_install_dir']

package node['db2']['ubuntu'] if platform_family?('debian')
package node['db2']['rhel']   if platform_family?('rhel')

directory db2fixpack_dir do
  mode '0755'
  not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2csap") }
  action :create
end

directory base_dir do
  mode '0755'
  recursive true
  not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2csap") }
  action :create
end

fpbinaries.each do |package_name|
  # Chef::Log.info('copying packages')
  execute 'copy-db2' do
    action :run
    command "scp #{node['db2']['ftploginuser']}@#{node['db2']['binaryhost']}:#{node['db2']['ftppath']}/#{package_name} #{db2fixpack_dir}"
    cwd db2fixpack_dir
    only_if { node['db2']['remote_mode'] == 'ftp' }
    not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2csap") }
  end

  # Download file via http
  remote_file "#{db2fixpack_dir}/#{package_name}" do
    source "#{node['db2']['binaryhost']}/#{node['db2']['ftppath']}/#{package_name}"
    mode '0755'
    only_if { node['db2']['remote_mode'] == 'http' }
    not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2csap") }
    action :create
  end

  execute 'extract-db2' do
    action :run
    command "tar -xvzf #{package_name}"
    cwd db2fixpack_dir
    not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2csap") }
  end
end

execute 'install-db2' do
  command "#{db2fixpack_dir}/server_t/installFixPack -b #{base_dir}"
  cwd db2fixpack_dir
  not_if { ::File.exist?("#{node['db2']['db2_install_dir']}/bin/db2csap") }
  action :run
end

directory db2fixpack_dir do
  action :delete
  recursive true
end
