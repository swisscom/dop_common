# Change Log
All notable changes to dop_common will be documented in this file.

## [0.15.0]
### Added
- Some small API addition to the log stuff to get the current log file

## [0.14.2] - 2017-05-01
### Fixed
- Some errors in the config class when using ruby 1.8.7

## [0.14.1] - 2017-04-26
### Changed
- Remove hiera dependency in gem to avoid problems with the RPM form the
  Puppetlabs repo

## [0.14.0] - 2017-04-24
### Added
- Add node property thin_clone for vmware

## [0.13.0] - 2017-03-28
### Added
- Moved thread context logger from dopi to dop_common and reworked it so it is
  easier to understand.
- Some common global cli options for all clis

### Fixed
- Include loops are now detected

## [0.12.2] - 2017-03-06
### Fixed
- Added stale lockfile detection to the plan store which detects if the locking
  process is still running.

## [0.12.1] - 2017-02-14
### Fixed
- Floating IP network should refer to a network name rather than to IP

## [0.12.0] - 2017-01-25
### Added
- Configuration class moved and reworked from Dopi
- Support import of external files in plans
- Signal handler class was moved from Dopi

### Changed
- The roles and config selection for nodes should now work in all tools since the
  hiera part was moved to dop_common from DOPi

## [0.11.3] - 2017-01-11
### Changed
- Add caching to the credential lookups

## [0.11.2] - 2016-12-22
### Added
-  Add `max_in_flight` options into `infrastructure` 

### Fixed
- Raise an exception in case a program that generates credentials fails

## [0.11.1] - 2016-12-14
### Changed
- will raise a specific exeption if the plan already exists when adding

## [0.11.0] - 2016-12-07
### Changed
- Remove Dopi and keep Dopv state per default to avoid confusion for the user

## [0.10.3] - 2016-12-06
### Fixed
- Create valid hooks even if they are not present in the deployment file

## [0.10.2] - 2016-12-05
### Fixed
- Make hooks available to node subparser as this is required by DOPv

## [0.10.1] - 2016-12-03
### Changed
- Hooks parser moved to global context

## [0.10.0] - 2016-11-30
### Added
- Hooks parser
- Move the node parser code from Dopi to DopCommon

## [0.9.2] - 2016-11-28
### Fixed
- Add zero padding to the version string for the plan store
- Removed a misleading error message when a plan was updated and the state was still new
- Add lower version boundry for hashdiff to make sure the fixed version is used

## [0.9.1] - 2016-11-15
### Fixed
- Sanitize shell environment before command(s) execution

## [0.9.0] - 2016-11-07
### Added
- DNS parser
- Data disks
- Security groups
- Support for V3 identity API
- Implementation of an actual plan cache
- Implementation of a general state store with locking and transactions

### Changed
- Node credentials
- Infrastructure properties -> config drive
- Infrastructure properties -> keep_ha
- Utils -> redesign of data sizing
- Reimplementation of the plan store
- Reimplementation of the Hiera plugin and update to the latest Backend API

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

