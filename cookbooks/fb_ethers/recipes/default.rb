#
# Cookbook Name:: fb_ethers
# Recipe:: default
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package 'net-tools' do
  only_if { node.linux? }
  only_if { node['fb_ethers']['manage_packages'] }
  action :upgrade
end

template '/etc/ethers' do
  source 'ethers.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
end

execute 'reload static arp entries' do
  command 'arp -f /etc/ethers'
  action :nothing
  subscribes :run, 'template[/etc/ethers]'
end
