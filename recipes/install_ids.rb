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
  not_if { File.exist?("#{db2binary_dir}/#{binaries}") }
  mode '0755'
  backup false
  action :create
end
