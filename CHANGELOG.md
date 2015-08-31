# Change Log
All notable changes to dop_common will be documented in this file.

## [0.1.0] - 2015-07-31
### Added
- Credentials hash parsing (username_password, kerberos, ssh_key)
- set_plugin_defaults and delete_plugin_defaults parsing

### Changed
- if ssh_root_pass gets parsed it will output a deprication warning now.

## [0.0.15] - 2015-07-15
### Added
- node_by_config and exclude patterns (also for node and role) parsing

### Changed
- max_in_flight and ssh_root_pass are now global keys and no longer under 'plan'.
  The old location will still work, but dop_common will show a deprecation warning.
- max_in_flight now supports the values 0 and -1. More info about this is in the
  Documentation of the DOP plan format.
- Make it possible to set max_in_flight and canary_host globaly and per step

## [0.0.14] - 2015-07-01
### Added
- Parsing for new plan name attribute in the plan
- New executable for puppet policy auto-signing of hosts in the DOP plan cache

