#
# Cookbook Name:: db2
# Recipe:: default
#
# Copyright 2018, OvertonClan
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

db2binary_dir = "#{Chef::Config[:file_cache_path]}/DB2binaries"
binaries = [node['db2']['package-name-1']]
checksums = [node['db2']['package1-sha256sum']]

package node['db2']['ubuntu'] if node['platform_family'] == 'debian'
package node['db2']['rhel']   if node['platform_family'] == 'rhel'

directory db2binary_dir do
  owner 'root'
  group 'root'
  mode '0755'
  not_if { File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  action :create
end

count = 0
binaries.each do |package_name|
  Chef::Log.info('copying packages')
  execute 'copy-db2' do
    action :run
    command "scp #{node['db2']['ftploginuser']}@#{node['db2']['binaryhost']}:#{node['db2']['ftppath']}/#{package_name} #{db2binary_dir}"
    cwd db2binary_dir
    only_if { node['db2']['remote_mode'] == 'ftp' }
    not_if { File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  end

  # Download file via http
  remote_file "#{db2binary_dir}/#{package_name}" do
    source "#{node['db2']['binaryhost']}/#{node['db2']['ftppath']}/#{package_name}"
    not_if { File.exist?("#{db2binary_dir}/#{package_name}") }
    # user node['db2']['db2inst1-user']
    # group node['db2']['db2inst1-group']
    mode '0755'
    only_if { node['db2']['remote_mode'] == 'http' }
    not_if { File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
    backup false
    action :create
  end

  ruby_block 'Validate Package Checksum' do
    action :run
    block do
      require 'digest'
      checksum = Digest::SHA256.file("#{db2binary_dir}/#{package_name}").hexdigest
      if checksum != checksums[count]
        raise "#{package_name} #{count} Downloaded package Checksum #{checksum} does not match known checksum #{checksums[count]}"
      end
      count += 1
    end
    not_if { File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  end

  execute 'extract-db2' do
    action :run
    command "unzip -q #{package_name}"
    cwd db2binary_dir
    not_if { File.exist?("#{db2binary_dir}/db2setup") }
    not_if { File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  end
end

template "#{db2binary_dir}/#{node['db2']['db2-responsefile']}" do
  source 'db2server.erb'
  variables(
    file: node['db2']['db2_install_dir'],
    install_type: node['db2']['install_type']
  )
  owner 'root'
  group 'root'
  mode '0644'
  not_if { File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  # notifies :run, 'execute[install-db2]', :immediately
end

execute 'install-db2' do
  command "#{db2binary_dir}/db2setup -r #{db2binary_dir}/#{node['db2']['db2-responsefile']}"
  cwd db2binary_dir
  not_if { File.exist?("#{node['db2']['db2_install_dir']}/bin/db2") }
  action :run
end

directory db2binary_dir do
  action :delete
  recursive true
end
