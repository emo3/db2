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

binary_dir = Chef::Config[:file_cache_path]

group node['db2']['db2fence1-group'] do
  action :create
end

user node['db2']['db2fence1-user'] do
  group node['db2']['db2fence1-group']
  home node['db2']['db2fence1-home']
  action :create
end

group node['db2']['db2inst1-group'] do
  action :create
end

user node['db2']['db2inst1-user'] do
  gid node['db2']['db2inst1-group']
  shell '/bin/bash'
  home node['db2']['db2inst1-home']
  password node['db2']['db2-epassword']
  manage_home true
  action :create
end

directory node['db2']['db2fence1-home'] do
  owner node['db2']['db2fence1-user']
  group node['db2']['db2fence1-group']
  mode '0755'
  action :create
end

directory node['db2']['db2inst1-home'] do
  owner node['db2']['db2inst1-user']
  group node['db2']['db2inst1-group']
  mode '0755'
  action :create
end

template "#{binary_dir}/#{node['db2']['db2inst1-INS']}.rsp" do
  source "#{node['db2']['db2inst1-INS']}.erb"
  variables(
    file: node['db2']['db2_install_dir'],
    instance_name: node['db2']['instance_name'],
    instance_type: node['db2']['instance_type'],
    db_inst1_user: node['db2']['db2inst1-user'],
    db_inst1_group: node['db2']['db2inst1-group'],
    db_inst1_home: node['db2']['db2inst1-home'],
    db_fence1_user: node['db2']['db2fence1-user'],
    db_fence1_group: node['db2']['db2fence1-group'],
    db_fence1_home: node['db2']['db2fence1-home'],
    auto_start: node['db2']['auto_start'],
    port_number: node['db2']['port_number'],
    fcm_port_number: node['db2']['fcm_port_number'],
    max_logical_nodes: node['db2']['max_logical_nodes'],
    configure_text_search: node['db2']['configure_text_search']
  )
  owner 'root'
  group 'root'
  mode '0644'
  not_if { File.exist?("#{node['db2']['db2inst1-home']}/sqllib/db2profile") }
  # notifies :run, 'execute[install-db2]', :immediately
end

execute 'create-instance' do
  command "#{node['db2']['db2_install_dir']}/instance/db2isetup -r #{binary_dir}/#{node['db2']['db2inst1-INS']}.rsp"
  cwd binary_dir
  not_if { File.exist?("#{node['db2']['db2inst1-home']}/sqllib/db2profile") }
  action :run
end

# update instance account bash profile
template "#{node['db2']['db2inst1-home']}/.bash_profile" do
  source 'bash_profile.erb'
  user node['db2']['db2inst1-user']
  group node['db2']['db2inst1-group']
end
