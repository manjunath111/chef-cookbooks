fb_nftables Cookbook
====================
Basic cookbook to emit nftables rules natively. By default, it configures
the `inet` table family to seamlessly handle both IPv4 and IPv6 rules in a
unified configuration.

Requirements
------------

Attributes
----------
* node['fb_nftables']['enable']
* node['fb_nftables']['manage_packages']
* node['fb_nftables']['table'][$TABLE_FAMILY][$TABLE_NAME]['chain'][$CHAIN_NAME]['type']
* node['fb_nftables']['table'][$TABLE_FAMILY][$TABLE_NAME]['chain'][$CHAIN_NAME]['hook']
* node['fb_nftables']['table'][$TABLE_FAMILY][$TABLE_NAME]['chain'][$CHAIN_NAME]['priority']
* node['fb_nftables']['table'][$TABLE_FAMILY][$TABLE_NAME]['chain'][$CHAIN_NAME]['policy']
* node['fb_nftables']['table'][$TABLE_FAMILY][$TABLE_NAME]['chain'][$CHAIN_NAME]['rules'][$RULE_NAME]

Usage
-----
Include `fb_nftables` to manage nftables on a machine. By default, the cookbook
will manage the nftables packages; this can be opted out of by setting
`node['fb_nftables']['manage_packages']`. The nftables service itself is
disabled by default; to enable it set `node['fb_nftables']['enable']` to true.

On Fedora, please be aware that `firewalld` interferes with directly
managing nftables rules; the `firewalld` package will be removed if `manage_packages` is true.

### Nomenclature
The nomenclature for nftables is different from iptables. We use the definitions used
by the nftables code base which are as follows:

* `table families` dictate which type of packets the table sees. Common ones
  are `ip`, `ip6`, and `inet` (which sees both IPv4 and IPv6).
* `tables` contain chains. Unlike iptables, there are no built-in tables;
  you create them. We default to a table named `filter`.
* `chains` contain rules. They are attached to netfilter hooks (`input`,
  `forward`, `output`, etc.) with a specific `type` and `priority`.

### Default Policies
You can specify a default policy for a base chain for when no rules match
using `node['fb_nftables']['table'][$TABLE_FAMILY][$TABLE_NAME]['chain'][$CHAIN_NAME]['policy']`.
They are a target such as `accept` or `drop`. See nftables documentation for details.

### Rules
The "name" of a rule is arbitrary, it's simply there so it can be modified
or referenced later in the run if you choose. The rules hash is sorted
alphabetically by name before rendering, so prefixing your rule names with
numbers (e.g. `00_allow_localhost`) is recommended to ensure proper ordering.

Each rule simply has the raw string to be inserted into the nftables configuration file:
* `rule_content` - the actual rule (such as `ip saddr 10.1.1.0/24 drop`) - note that
  specifying the table/chain is not needed here.

### A warning about ordering and policies
As with regular firewalls, ordering matters here. The rules will be evaluated
in the order they are rendered in the configuration file (which is alphabetical
based on the rule name keys). Please keep that in mind at all times,
especially when implementing a complex ruleset.

As with iptables, you can choose between denying everything using chain policy,
then add rules to allow certain packets, or allowing everything then dropping
certain packets. Please also keep in mind this is a system-wide choice: you
might want to check that this choice hasn't already been made by a previous
cookbook.

### fb_nftables in 10 lines
Include the recipe in your own and update rules attributes.

```ruby
include_recipe 'fb_nftables'

node.default['fb_nftables']['enable'] = true
node.default['fb_nftables']['table']['inet']['filter']['chain']['input']['policy'] = 'drop'

# Rules are sorted by key name, so prepending with a number helps manage order
node.default['fb_nftables']['table']['inet']['filter']['chain']['input']['rules']['10_allow_ssh'] =
  'tcp dport 22 accept'

# IPv4 specific rule within the inet table
node.default['fb_nftables']['table']['inet']['filter']['chain']['input']['rules']['20_allow_internal'] =
  'ip saddr 192.168.0.0/16 accept'
```
