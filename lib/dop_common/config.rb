#
# Configration for DopCommon
#
# Configure the module in a block:
#
#   DopCommon.configure do |config|
#     config.use_hiera = true
#   end
#
require 'etc'
require 'dop_common/config/helper'

module DopCommon

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end

  def self.configure=(options_hash)
    options_hash.each do |key, value|
      variable_name = '@' + key.to_s
      if config.instance_variable_defined?( variable_name )
        config.instance_variable_set( variable_name , value )
      end
    end
  end

  class Config
    include DopCommon::Config::Helper

		conf_var :trace,
			default: false
		conf_var :config_file,
			default: is_root? ? '/etc/dop/dop.conf' : File.join(dop_home, 'dop.conf')
		conf_var :plan_store_dir,
			default: is_root? ? '/var/lib/dop/cache' : File.join(dop_home, 'cache')
		conf_var :use_hiera,
			default: true
		conf_var :hiera_yaml,
			default: is_root? ? '/etc/puppet/hiera.yaml' : File.join(user.dir, '.puppet', 'hiera.yaml')
    conf_var :load_facts,
      default: false
    conf_var :facts_dir,
      default: is_root? ? '/var/lib/puppet/yaml/facts' : File.join(user.dir, '.puppet', 'var', 'yaml', 'facts')
		conf_var :role_variable,
			default: 'role'
		conf_var :role_default,
			default: nil
		conf_var :connection_check_timeout,
			default: 5
		conf_var :mco_config,
			default: is_root? ? '/etc/mcollective/client.cfg' : File.join(user.dir, '.mcollective')
		conf_var :mco_dopi_logger,
			default: true
		conf_var :log_dir,
			default: is_root? ? '/var/log/dop/' : File.join(dop_home, 'log')
    conf_var :log_level,
      default: 'DEBUG'

  end

end
