# Copyright (c) 2018-present, Facebook, Inc.
name 'fb_ipset'
maintainer 'Facebook'
maintainer_email 'noreply@facebook.com'
license 'Apache-2.0'
description 'Installs/Configures ipset'
source_url 'https://github.com/facebook/chef-cookbooks/'
version '0.1.0'
%w{
  centos
  fedora
  redhat
  debian
  ubuntu
}.each do |sup|
  supports sup
end
depends 'fb_helpers'
