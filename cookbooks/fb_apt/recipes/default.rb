#
# Cookbook Name:: fb_apt
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

require 'shellwords'

unless node.debian? || node.ubuntu?
  fail 'fb_apt is only supported on Debian and Ubuntu.'
end

# rubocop:disable Chef/Modernize/ExecuteAptUpdate

package 'apt' do
  action :upgrade
end

keyring_package = value_for_platform(
  'debian' => {
    'default' => 'debian-archive-keyring',
  },
  'ubuntu' => {
    'default' => 'ubuntu-keyring',
  },
)

package keyring_package do
  action :upgrade
end

# This takes precedence over anything in /etc/apt/apt.conf.d. We can't just
# clobber that as several packages will drop configs there.
template '/etc/apt/apt.conf' do
  source 'apt.conf.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
  notifies :run, 'execute[apt-get update]'
end

# No sane package should drop stuff here, and bad preferences can seriously
# mess up a machine, so let's clobber it to be safe.
Dir.glob('/etc/apt/preferences.d/*').each do |f|
  file f do
    action :delete
  end
end

template '/etc/apt/preferences' do
  source 'preferences.erb'
  owner node.root_user
  group node.root_group
  mode '0644'
end

execute 'check keyring format' do
  only_if 'file /etc/apt/trusted.gpg | grep -q keybox'
  command '
    gpg --no-default-keyring --keyring /etc/apt/trusted.gpg --export \
      > /etc/apt/.chef-trusted-export
    mv /etc/apt/.chef-trusted-export /etc/apt/trusted.gpg
  '
  notifies :run, 'execute[apt-get update]', :immediately
end

fb_apt_keys 'process keys' do
  notifies :run, 'execute[check keyring format]', :immediately
end

# On Debian nothing should drop things here, but Ubuntu likes to use it for its
# default sources, so we optionally allow keeping its contents
Dir.glob('/etc/apt/sources.list.d/*').each do |f|
  file f do
    not_if { node['fb_apt']['preserve_sources_list_d'] }
    action :delete
    compile_time true
  end
end

fb_apt_sources_list 'populate sources list' do
  notifies :run, 'execute[apt-get update]', :immediately
end

execute 'apt-get update' do
  command(lazy do
    log_path = node['fb_apt']['apt_update_log_path']
    cmd_suffix = " >>#{Shellwords.shellescape(log_path)} 2>&1" if log_path
    "apt-get update#{cmd_suffix}"
  end)
  action :nothing
end

if Chef::VERSION.to_i >= 16
  notify_group 'periodic package cache update' do
    only_if do
      pkgcache = '/var/cache/apt/pkgcache.bin'
      !::File.exist?(pkgcache) || (
        ::File.exist?(pkgcache) &&
        ::File.mtime(pkgcache) < Time.now - node['fb_apt']['update_delay'])
    end
    action :run
    notifies :run, 'execute[apt-get update]', :immediately
  end
else
  log 'periodic package cache update' do
    only_if do
      pkgcache = '/var/cache/apt/pkgcache.bin'
      !::File.exist?(pkgcache) || (
        ::File.exist?(pkgcache) &&
        ::File.mtime(pkgcache) < Time.now - node['fb_apt']['update_delay'])
    end
    notifies :run, 'execute[apt-get update]', :immediately
  end
end
# rubocop:enable Chef/Modernize/ExecuteAptUpdate
