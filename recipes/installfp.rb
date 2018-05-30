#
# Cookbook Name:: db2
# Recipe:: default
#
# Copyright 2018, OvertonClan
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

db2fixpack_dir = "#{Chef::Config[:file_cache_path]}/DB2fixpack"
fpbinaries = [node['db2']['packagefp1-name-1']]
checksums = [node['db2']['packagefp1-sha256sum']]
base_dir = node['db2']['db2_install_dir']

package node['db2']['ubuntu'] if node['platform_family'] == 'debian'
package node['db2']['rhel']   if node['platform_family'] == 'rhel'

directory db2fixpack_dir do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory base_dir do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

count = 0

fpbinaries.each do |package_name|
  Chef::Log.info('copying packages')
  execute 'copy-db2' do
    action :run
    command "scp #{node['db2']['ftploginuser']}@#{node['db2']['binaryhost']}:#{node['db2']['ftppath']}/#{package_name} #{db2fixpack_dir}"
    cwd db2fixpack_dir
    only_if { node['db2']['remote_mode'] == 'ftp' }
  end

  # Download file via http
  remote_file "#{db2fixpack_dir}/#{package_name}" do
    source "#{node['db2']['binaryhost']}/#{node['db2']['ftppath']}/#{package_name}"
    not_if { File.exist?("#{db2fixpack_dir}/#{package_name}") }
    # user node['db2']['db2inst1-user']
    # group node['db2']['db2inst1-group']
    mode '0755'
    only_if { node['db2']['remote_mode'] == 'http' }
    action :create
  end

  ruby_block 'Validate Package Checksum' do
    action :run
    block do
      require 'digest'
      checksum = Digest::SHA256.file("#{db2fixpack_dir}/#{package_name}").hexdigest
      if checksum != checksums[count]
        raise "#{package_name} #{count} Downloaded package Checksum #{checksum} does not match known checksum #{checksums[count]}"
      end
      count += 1
    end
  end

  execute 'extract-db2' do
    action :run
    command "tar -xvzf #{package_name}"
    cwd db2fixpack_dir
  end
end

execute 'install-db2' do
  command "#{db2fixpack_dir}/server_t/installFixPack -b #{base_dir}"
  cwd db2fixpack_dir
  action :run
end

directory db2fixpack_dir do
  action :delete
  recursive true
end
