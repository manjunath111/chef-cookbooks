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

require './spec/spec_helper'
require_relative '../../fb_helpers/libraries/node_methods'

recipe 'fb_nftables::default' do |tc|
  let(:chef_run) do
    tc.chef_run
  end

  it 'renders the minimal nftables.conf template' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_nftables']['enable'] = true
    end
    expect(chef_run).to render_file('/etc/sysconfig/nftables.conf').
      with_content(tc.fixture('nftables_min'))
  end

  it 'renders the nftables.conf template with complex rules' do
    chef_run.converge(described_recipe) do |node|
      node.default['fb_nftables']['enable'] = true
      node.default['fb_nftables']['table']['inet']['filter']['chain']['input']['rules']['test_drop'] =
        'ip saddr 10.0.0.1 drop'
      node.default['fb_nftables']['table']['inet']['filter']['chain']['input']['rules']['test_accept'] =
        'tcp dport 22 accept'
    end
    expect(chef_run).to render_file('/etc/sysconfig/nftables.conf').
      with_content(tc.fixture('nftables_complex'))
  end
end
