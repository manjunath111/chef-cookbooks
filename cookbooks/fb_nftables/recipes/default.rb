# Copyright (c) 2026-present, Meta Platforms, Inc. and affiliates.
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

include_recipe 'fb_nftables::packages'

template '/etc/sysconfig/nftables.conf' do
  only_if { node['fb_nftables']['enable'] }
  source 'nftables.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0600'
  notifies :restart, 'service[nftables]'
end

service 'nftables' do
  only_if { node['fb_nftables']['enable'] }
  action :enable
end

service 'nftables start' do
  only_if { node['fb_nftables']['enable'] }
  only_if { node['fb_nftables']['start'] }
  service_name 'nftables'
  action :start
end

service 'disable nftables' do
  not_if { node['fb_nftables']['enable'] }
  service_name 'nftables'
  action :disable
end
