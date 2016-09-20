# Change Log
All notable changes to dop_common will be documented in this file.

## [unreleased]
### Added
- DNS parser

### Changed
- Node credentials
- Infrastructure properties -> config drive
- Infrastructure properties -> keep_ha

## [0.8.0] - 2016-05-25
### Added
- Parsing for max_per_role on step and plan level

### Removed
- Deprecated ssh_root_pass
- Deprecated plan subhash for plan settings

## [0.7.0] - 2016-04-18
### Added
- Implemented `use_config_drive` infrastructure property, which is used to
  select a configuration backend of OpenStack providers. By default a config
  drive is used. A user should specify `false` should he require metadata
  service fo configuration.
- Credentials support for the nodes class

### Changed
- Credentials can now all be specified inline or loaded from a file
- Support multiple commands in a single step

## [0.6.1] - 2016-01-27
### Fixed
- Fixed a bug which filtered all the log output away if a credential other than
  username_password was defined

## [0.6.0] - 2016-01-27
### Added
- dop_common can now get secrets in credentials from external files or return values of executables.

## [0.5.0] - 2015-11-17
### Added
- Allow defaults overwrites from plugins
- Infrastructure property parser

### Fixed
- Support all types of objects with log filters, not just strings

## [0.4.0] - 2015-11-09
### Added
- dop_common now filters all the secrets from the logs

## [0.3.0] - 2015-10-12
### Added
- The dop hiera plugin now supports merging operations
- New step set parsing

### Changed
- Infrastructure hash parsing
- Extended node hash parsing

## [0.2.0] - 2015-08-16
### Added
- Basic interface hash parsing in node
- Parsing for generic command plugin option 'verify_after_run'

### Changed
- Allow dashes in plan names

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

