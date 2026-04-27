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

default['fb_nftables'] = {
  'enable' => false,
  'start' => false,
  'manage_packages' => true,
  'table' => {
    'inet' => {
      'filter' => {
        'chain' => {
          'input' => {
            'type' => 'filter',
            'hook' => 'input',
            'priority' => 0,
            'policy' => 'accept',
            'rules' => {},
          },
          'forward' => {
            'type' => 'filter',
            'hook' => 'forward',
            'priority' => 0,
            'policy' => 'accept',
            'rules' => {},
          },
          'output' => {
            'type' => 'filter',
            'hook' => 'output',
            'priority' => 0,
            'policy' => 'accept',
            'rules' => {},
          },
        },
      },
    },
  },
}
